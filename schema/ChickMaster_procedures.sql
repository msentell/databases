
-- ==================================================================
-- call IMAGES_getImageLayer('LOCATION',1,1,1,1);
-- call IMAGES_getImageLayer('ASSET',1,1,1,1);
-- call IMAGES_getImageLayer('ASSET-PART',1,1,1,1);


DROP procedure IF EXISTS `IMAGES_getImageLayer`;

DELIMITER $$
CREATE  PROCEDURE IMAGES_getImageLayer(
IN _action VARCHAR(100),
IN _customerId VARCHAR(32),
IN _userId VARCHAR(32),
IN _startingPoint INT,
IN _id INT
)
IMAGES_getImageLayer: BEGIN


IF (_id is NULL OR _id='') THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid value id';
ELSEIF (_action is NULL OR _action='') THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid value action';
END IF;

-- isPrimary may be enumerated (i.e 1,2,3 )  
--   where 1=top most
-- 			2 = layer down
-- 			3 = layer down again
--  	The reason is maybe the top layer is all site locations, but we really want to start the user
-- 		at a more reasonable layer such as inside their facility.  We can store the layer start
-- 		position as part of a preference

if (_customerId is null) THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'customerId required';
END IF;


If (_action = 'LOCATION') THEN

	if (_startingPoint is not null) THEN

		SELECT loc.*
		from location loc 
        where loc.location_customerUUID = _customerId AND loc.location_isPrimary = _startingPoint;
	
	ELSE

		SELECT loc.*
		from location loc where loc.locationUUID = _id;
	
	END IF;

ELSEIF (_action = 'ASSET') THEN

	select a.*,p.* from asset a
	left join asset_part p on (a.asset_partUUID = p.asset_partUUID) 
    where assetUUID=_id;

ELSEIF (_action = 'ASSET-PART') THEN

	SELECT ap.* from asset_part ap where ap.asset_partUUID = _id;

END IF;

END$$


-- ==================================================================
-- call DIAGNOSTIC_getNode(null,1,1,'633a54011d76432b9fa18b0b6308c189',null); -- will get the starting tree node
-- call DIAGNOSTIC_getNode(null,1,1,null,'1834487471bb4cccbaa8b0dc1cedc463'); -- will get the next node


DROP procedure IF EXISTS `DIAGNOSTIC_getNode`;

DELIMITER $$
CREATE  PROCEDURE DIAGNOSTIC_getNode(
IN _action VARCHAR(100),
IN _customerId char(32),
IN _userId char(32),
IN _diagnosticId char(32),
IN _nodeId char(32)
)
DIAGNOSTIC_getNode: BEGIN



-- isPrimary may be enumerated (i.e 1,2,3 )  
--   where 1=top most
-- 			2 = layer down
-- 			3 = layer down again
--  	The reason is maybe the top layer is all site locations, but we really want to start the user
-- 		at a more reasonable layer such as inside their facility.  We can store the layer start
-- 		position as part of a preference

if (_customerId is null) THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'customerId required';
END IF;


If (_diagnosticId is not null and _nodeId is null) THEN

	-- get the starting node

		SELECT n.*,d.* from diagnostic_tree d
        left join diagnostic_node n on (d.diagnosticUUID=n.diagnostic_node_diagnosticUUID and d.diagnostic_startNodeUUID = n.diagnostic_nodeUUID) 
        where diagnosticUUID = _diagnosticId;

ELSEIF (_nodeId is not null) THEN

		SELECT n.* from diagnostic_node n
        -- left join diagnostic_tree d on (d.diagnosticUUID=n.diagnostic_node_diagnosticUUID) 
        where diagnostic_nodeUUID = _nodeId;

END IF;

END$$


-- ==================================================================
-- call BUTTON_options(null,'1c5a0f1a10b841699ee5b5f431d01e03','CONTACT|CHAT|STARTCHECKLIST|ADDLOG'); 

DROP procedure IF EXISTS `BUTTON_options`;

DELIMITER $$
CREATE  PROCEDURE BUTTON_options(
IN _action VARCHAR(100),
IN _asset_partUUID char(32),
IN _otherOptions varchar(255)
)
BUTTON_options: BEGIN

-- TODO, select security to turn on/off
-- 'CONTACT,CHAT,STARTCHECKLIST,ADDLOG'
select ap.asset_partUUID,
(case when asset_part_isPurchasable=1 is not null then 1 else 0 end) BUTTON_viewOrderParts,
(case when asset_part_diagnosticUUID is not null then 1 else 0 end) as BUTTON_diagnoseAProblem,
(select count(apaj_asset_partUUID) from  asset_part_attachment_join where apaj_asset_partUUID = ap.asset_partUUID limit 1) as BUTTON_viewManual,
(select count(pkj_part_partUUID) from part_knowledge_join where pkj_part_partUUID = ap.asset_partUUID limit 1 ) as BUTTON_qa,
(select count(wapj_asset_partUUID) from workorder_asset_part_join where wapj_asset_partUUID = ap.asset_partUUID limit 1 ) as BUTTON_serviceHistory,
(case when locate('CONTACT',_otherOptions)>0 THEN 1 ELSE 0 END) as BUTTON_contactCheckMaster,
(case when locate('CHAT',_otherOptions)>0 THEN 1 ELSE 0 END) as BUTTON_liveChat,
(case when locate('STARTCHECKLIST',_otherOptions)>0 THEN 1 ELSE 0 END) as BUTTON_startAChecklist,
(case when locate('ADDLOG',_otherOptions)>0 THEN 1 ELSE 0 END) as BUTTON_addALogEntry,
ap.*
from asset_part ap
where asset_partUUID=_asset_partUUID;

END$$


-- ==================================================================
-- call NOTIFICATION_notification('GET','1',null); 
-- call NOTIFICATION_notification('ACKNOWLEDGE','1',1001); 

DROP procedure IF EXISTS `NOTIFICATION_notification`;

DELIMITER $$
CREATE  PROCEDURE NOTIFICATION_notification(
IN _action VARCHAR(100),
IN _userUUID char(32),
IN _notificationId INT
)
NOTIFICATION_notification: BEGIN

-- TODO, need to discuss acknowledgement and history.  It is not really the same as our notificaiton_queue

if (_action='GET') THEN
	select 'There was a flag on the last PRE-SET CHECKLIST';
ELSEIF (_action='ACKNOWLEDGE') THEN
	select 1001;
END IF;

END$$


-- ==================================================================
-- call CLIENT_getDetails(null,null, 6770);


DROP procedure IF EXISTS `CLIENT_getDetails`;

DELIMITER $$
CREATE PROCEDURE `CLIENT_getDetails`(
IN _action varchar(100),
IN _clientId INT,
IN _recruitId INT
)
CLIENT_getDetails: BEGIN

IF (_clientId is NULL and _recruitId is null) THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid value arguments';
    leave CLIENT_getDetails;
END IF;


if (_recruitId is null and _clientId is not null) THEN
	
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid value arguments';
    leave CLIENT_getDetails;
	
    
elseif (_recruitId is not null ) THEN
	
    
    SELECT 
        `cnt`.`contractId` AS `contract_number`,
        `cnt`.`contract_clientId` AS `contract_clientId`,
        `c`.`client_clientName` AS `contract_clientName`,
        `cnt`.`contract_expirationDate` AS `contract_expirationDate`,
        `cnt`.`contract_executionDate` AS `contract_executionDate`,
        `cnt`.`contract_startDate` AS `contract_startDate`,
        `cnt`.`contract_endDate` AS `contract_endDate`,
        `cnt`.`contract_statusId` AS `contract_statusId`,
        `stat`.`contract_status` AS `contract_status`,
        `cnt`.`contract_billingAddressId` AS `contract_billingAddressId`,
        `cnt`.`att_lt_dh` AS `contract_att_lt_dh`,
        `cnt`.`contract_pocId` AS `contract_pocId`,
        (SELECT 
                ENTITY_FORMATNAME(`poc`.`entity_firstName`,
                            `poc`.`entity_middleName`,
                            `poc`.`entity_lastName`,
                            NULL,
                            NULL)
            FROM
                `entity` `poc`
            WHERE
                (`poc`.`entityId` = `cnt`.`contract_pocId`)) AS `contract_pocName`,
        (SELECT 
                GROUP_CONCAT(`contract_specialty`.`att_specialties`
                        SEPARATOR ',')
            FROM
                `contract_specialty`
            WHERE
                (`contract_specialty`.`contract_specialty_contractId` = `cnt`.`contractId`)) AS `contract_specialty`,
                
        -- need to get the address
        
        -- `prez`.`presentation_orderId` AS `presentation_orderId`,
        max(`prez`.`presentation_entityId`) AS `presentation_entityId`,
        (SELECT 
                ENTITY_FORMATNAME(`entity`.`entity_firstName`,
                            `entity`.`entity_middleName`,
                            `entity`.`entity_lastName`,
                            NULL,
                            NULL)
            FROM
                `entity`
            WHERE
                (`entity`.`entityId` = max(`prez`.`presentation_entityId`))) AS `presentation_recruitName`,
		addr.*
        -- `prez`.`att_order_presentation_status` AS `att_order_presentation_status`,
        -- `prez`.`att_lt_dh` AS `presentation_lt_dh`,
        -- `prez`.`presentation_presentedDate` AS `presentation_presentedDate`,
        -- `prez`.`presentation_executionDate` AS `presentation_executionDate`,
        -- `prez`.`presentation_startDate` AS `presentation_startDate`,
        -- `prez`.`presentation_endDate` AS `presentation_endDate`
    FROM
        `contract` `cnt`
        LEFT JOIN `client` `c` ON (`c`.`clientId` = `cnt`.`contract_clientId`)
        LEFT JOIN `att_contract_status` `stat` ON (`stat`.`contract_statisId` = `cnt`.`contract_statusId`)
        LEFT JOIN `order_presentation` `prez` ON (`prez`.`presentation_clientId` = `cnt`.`contract_clientId` and prez.att_order_presentation_status='Accepted')
        left join global_address addr on (addr.addressId  =c.client_addressId_work)
        where `prez`.`presentation_entityId`=_recruitId
		group by cnt.contractId;

    
END IF;



END$$

DELIMITER ; 

-- ==================================================================

-- call WORKORDER_workOrder(_action, _customerId); 
-- call WORKORDER_workOrder('GET', 'a30af0ce5e07474487c39adab6269d5f');

DROP procedure IF EXISTS `WORKORDER_workOrder`;

DELIMITER $$
CREATE PROCEDURE `WORKORDER_workOrder` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100)
)
WORKORDER_workOrder: BEGIN

IF(_action IS NULL or _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _action can not be empty';
	LEAVE WORKORDER_workOrder;
END IF;

IF(_customerId IS NULL or _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _customerId can not be empty';
	LEAVE WORKORDER_workOrder;
END IF;

IF(_action ='GET') THEN
	SELECT wo.* FROM workorder wo WHERE wo.workorder_customerUUID = _customerId;
ELSE
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _action is of type invalid';
	LEAVE WORKORDER_workOrder;
END IF;

END$$

DELIMITER ; 

-- ==================================================================

-- call CUSTOMER_getCustomerDetails(_action, _customerId); 
-- call CUSTOMER_getCustomerDetails('GET-LIST', NULL);

DROP procedure IF EXISTS `CUSTOMER_getCustomerDetails`;

DELIMITER $$
CREATE PROCEDURE `CUSTOMER_getCustomerDetails` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100)
)
CUSTOMER_getCustomerDetails: BEGIN

IF(_action IS NULL or _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CUSTOMER_getCustomerDetails: _action can not be empty';
	LEAVE CUSTOMER_getCustomerDetails;
END IF;

IF(_action ='GET-LIST') THEN
	SELECT * FROM cm_hms.customer;
ELSE
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CUSTOMER_getCustomerDetails: _action is of type invalid';
	LEAVE CUSTOMER_getCustomerDetails;
END IF;

END$$

DELIMITER ;





-- ==================================================================

-- call LOCATION_Location(action, _location_userUUID, location_customerUUID, locationUUID, location_statusId,location_type, location_name, location_description, location_isPrimary, location_imageUrl, location_hotSpotJSON, location_addressTypeId, location_address, location_address_city, location_address_state, location_address_zip, location_country, location_contact_name, location_contact_email, location_contact_phone); 
-- call LOCATION_Location('GET', '1', 'a30af0ce5e07474487c39adab6269d5f', null, null,null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);   -- GET ALL LOCATIONS
-- call LOCATION_Location('GET', '1', 'a30af0ce5e07474487c39adab6269d5f', '179d6406ac1241e0bd148d3f1ccabf36', null,null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null);   -- GET SINGLE LOCATIONS
-- call LOCATION_Location('CREATE', '1', 'a30af0ce5e07474487c39adab6269d5f', 10, null,'LOCATION', 'location_name', 'location_description', 1, 'location_imageUrl', 'location_hotSpotJSON', 1, 'location_address', 'location_address_city', 'location_address_state', 'location_address_zip', 'location_country', 'location_contact_name', 'location_contact_email', 'location_contact_phone'); 
-- call LOCATION_Location('UPDATE', '1', 'a30af0ce5e07474487c39adab6269d5f', 10, null,'LOCATION', 'location_name2', 'location_description2', 1, 'location_imageUrl2', 'location_hotSpotJSON', 1, 'location_address', 'location_address_city', 'location_address_state', 'location_address_zip', 'location_country', 'location_contact_name', 'location_contact_email', 'location_contact_phone'); 
-- call LOCATION_Location('DELETE', '1', 'a30af0ce5e07474487c39adab6269d5f', 10, null,null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);   -- GET ALL LOCATIONS


DROP procedure IF EXISTS `LOCATION_Location`;

DELIMITER $$
CREATE PROCEDURE `LOCATION_Location` (
IN _action VARCHAR(100),
IN _location_userUUID VARCHAR(100),
IN _location_customerUUID VARCHAR(100),
IN _locationUUID VARCHAR(100),
IN _location_statusId INT,
IN _location_type VARCHAR(255),
IN _location_name VARCHAR(255),
IN _location_description VARCHAR(1000),
IN _location_isPrimary INT,
IN _location_imageUrl  VARCHAR(1000),
IN _location_hotSpotJSON TEXT,
IN _location_addressTypeId INT,
IN _location_address VARCHAR(255), 
IN _location_address_city VARCHAR(255), 
IN _location_address_state VARCHAR(25),
IN _location_address_zip VARCHAR(25),
IN _location_country VARCHAR(25),
IN _location_contact_name VARCHAR(100),
IN _location_contact_email VARCHAR(100),
IN _location_contact_phone VARCHAR(50)
)
LOCATION_Location: BEGIN
DECLARE commaNeeded INT DEFAULT 0;

DECLARE DEBUG INT DEFAULT 0;


IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_Location: _action can not be empty';
	LEAVE LOCATION_Location;
END IF;

IF(_location_userUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_userUUID missing';
	LEAVE LOCATION_Location;
END IF;

IF(_location_customerUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID missing';
	LEAVE LOCATION_Location;
END IF;

IF(_action = 'GET') THEN

	SET @l_SQL = 'SELECT l.* FROM location l';
	IF(_location_customerUUID IS NULL OR _location_customerUUID = '') THEN
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID can not be empty';
		LEAVE LOCATION_Location;
	ELSE
        SET @l_SQL = CONCAT(@l_SQL, '  WHERE l.location_customerUUID =\'', _location_customerUUID,'\'');
        
		IF(_locationUUID IS NOT NULL AND _locationUUID!='') THEN
			SET @l_SQL = CONCAT(@l_SQL, '  AND l.locationUUID =\'', _locationUUID,'\'');
		END IF;
		IF(_location_isPrimary IS NOT NULL) THEN
			SET @l_SQL = CONCAT(@l_SQL, '  AND l.location_isPrimary =', _location_isPrimary);
		END IF;
        
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
        
        PREPARE stmt FROM @l_SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
	END IF;

ELSEIF(_action = 'CREATE') THEN

	IF (DEBUG=1) THEN select _action,_locationUUID, _location_customerUUID, 1, _location_type, _location_name, _location_description, _location_isPrimary, _location_imageUrl, _location_hotSpotJSON, _location_addressTypeId, _location_address, _location_address_city, _location_address_state, _location_address_zip, _location_country, _location_contact_name, _location_contact_email, _location_contact_phone; END IF;
    
	IF(_locationUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID missing';
		LEAVE LOCATION_Location;
	END IF;
    
    insert into location 
    (locationUUID, location_customerUUID, location_statusId, location_type, location_name, location_description, location_isPrimary, location_imageUrl, location_hotSpotJSON, location_addressTypeId, location_address, location_address_city, location_address_state, location_address_zip, location_country, location_contact_name, location_contact_email, location_contact_phone,
    location_createdByUUID, location_updatedByUUID, location_updatedTS, location_createdTS, location_deleteTS)
	values
    (_locationUUID, _location_customerUUID, 1, _location_type, _location_name, _location_description, _location_isPrimary, _location_imageUrl, _location_hotSpotJSON, _location_addressTypeId, _location_address, _location_address_city, _location_address_state, _location_address_zip, _location_country, _location_contact_name, _location_contact_email, _location_contact_phone,
    _location_userUUID, _location_userUUID, now(), now(), null);

ELSEIF(_action = 'UPDATE') THEN


	IF(_locationUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID missing';
		LEAVE LOCATION_Location;
	END IF;

		set  @l_sql = CONCAT('update location set location_updatedTS=now(), location_updatedByUUID=\'', _location_userUUID,'\'');		
                
        if (_location_statusId is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_statusId = ', _location_statusId);
        END IF;
        if (_location_type is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_type = \'', _location_type,'\'');
        END IF;
        if (_location_name is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_name = \'', _location_name,'\'');
        END IF;
        if (_location_description is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_description = \'', _location_description,'\'');
        END IF;
        if (_location_isPrimary is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_isPrimary = ', _location_isPrimary);
        END IF;
        if (_location_imageUrl is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_imageUrl = \'', _location_imageUrl,'\'');
        END IF;
        if (_location_hotSpotJSON is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_hotSpotJSON = \'', _location_hotSpotJSON,'\'');
        END IF;
        if (_location_addressTypeId is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_addressTypeId = ', _location_addressTypeId);
        END IF;
        if (_location_address is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_address = \'', _location_address,'\'');
        END IF;
        if (_location_address_city is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_address_city = \'', _location_address_city,'\'');
        END IF;
        if (_location_address_state is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_address_state = \'', _location_address_state,'\'');
        END IF;
        if (_location_address_zip is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_address_zip = \'', _location_address_zip,'\'');
        END IF;
        if (_location_country is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_country = \'', _location_country,'\'');
        END IF;
        if (_location_contact_name is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_contact_name = \'', _location_contact_name,'\'');
        END IF;
        if (_location_contact_email is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_contact_email = \'', _location_contact_email,'\'');
        END IF;
        if (_location_contact_phone is not null) THEN
			set @l_sql = CONCAT(@l_sql,',location_contact_phone = \'', _location_contact_phone,'\'');
        END IF;

		set @l_sql = CONCAT(@l_sql,' where locationUUID = \'', _locationUUID,'\';');
       
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
        

ELSEIF(_action = 'DELETE') THEN

	IF (DEBUG=1) THEN select _action,_locationUUID; END IF;
    
	IF(_locationUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID missing';
		LEAVE LOCATION_Location;
	END IF;

	update location set location_deleteTS=now(), location_statusId=2, location_updatedByUUID=_location_userUUID where locationUUID = _locationUUID and location_customerUUID=_location_customerUUID;
	-- TBD, figure out what cleanup may be involved
    -- ? user profiles

END IF;

END$$


DELIMITER ;







-- ==================================================================

-- call ASSET_asset(action, _userUUID, asset_customerUUID, assetUUID, asset_locationUUID, asset_partUUID, asset_statusId, asset_name, asset_shortName, asset_installDate); 
-- call ASSET_asset('GET', '1', 'a30af0ce5e07474487c39adab6269d5f',  null, null, null, null, null, null, null); 
-- call ASSET_asset('GET', '1', 'a30af0ce5e07474487c39adab6269d5f',  '00c93791035c44fd98d4f40ff2cdfe0a', null, null, null, null, null, null); 
-- call ASSET_asset('CREATE', '1', 'a30af0ce5e07474487c39adab6269d5f',  10, 'asset_locationUUID', 'asset_partUUID', 1, 'asset_name', 'asset_shortName', Date(now())); 
-- call ASSET_asset('UPDATE', '1', 'a30af0ce5e07474487c39adab6269d5f',  10, 'asset_locationUUID1', 'asset_partUUID2', 1, 'asset_name3', 'asset_shortName4', Date(now())); 
-- call ASSET_asset('DELETE', '1', 'a30af0ce5e07474487c39adab6269d5f', 10, null, null, null, null, null, null); 


DROP procedure IF EXISTS `ASSET_asset`;

DELIMITER $$
CREATE PROCEDURE `ASSET_asset` (
IN _action VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _customerUUID VARCHAR(100),
IN _assetUUID VARCHAR(100),
IN _asset_locationUUID VARCHAR(100),
IN _asset_partUUID VARCHAR(100),
IN _asset_statusId INT,
IN _asset_name VARCHAR(255),
IN _asset_shortName VARCHAR(255),
IN _asset_installDate  Date
)
ASSET_asset: BEGIN

DECLARE DEBUG INT DEFAULT 0;

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_asset: _action can not be empty';
	LEAVE ASSET_asset;
END IF;

IF(_userUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _userUUID missing';
	LEAVE ASSET_asset;
END IF;

IF(_customerUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _customerUUID missing';
	LEAVE ASSET_asset;
END IF;

IF(_action = 'GET') THEN

	SET @l_SQL = 'SELECT * FROM asset ';
	
        SET @l_SQL = CONCAT(@l_SQL, '  WHERE asset_customerUUID =\'', _customerUUID,'\'');
        
		IF(_assetUUID IS NOT NULL AND _assetUUID!='') THEN
			SET @l_SQL = CONCAT(@l_SQL, '  AND assetUUID =\'', _assetUUID,'\'');
		END IF;
		IF(_asset_partUUID IS NOT NULL AND _asset_partUUID!='') THEN
			SET @l_SQL = CONCAT(@l_SQL, '  AND asset_partUUID =\'', _asset_partUUID,'\'');
		END IF;
        
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
        
        PREPARE stmt FROM @l_SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

ELSEIF(_action = 'CREATE') THEN

	IF (DEBUG=1) THEN select _action, _userUUID, _customerUUID, _assetUUID, _asset_locationUUID, _asset_partUUID, _asset_statusId, _asset_name, _asset_shortName, _asset_installDate; END IF;
    
	IF(_assetUUID IS NULL or asset_partUUID is null) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _assetUUID or asset_partUUID missing';
		LEAVE ASSET_asset;
	END IF;
    
    insert into asset 
    (assetUUID, asset_locationUUID, asset_partUUID, asset_customerUUID, asset_statusId, asset_name, asset_shortName, asset_installDate,
    asset_createdByUUID, asset_updatedByUUID, asset_updatedTS, asset_createdTS, asset_deleteTS)
	values
    (_assetUUID, _asset_locationUUID, _asset_partUUID, _customerUUID, _asset_statusId, _asset_name, _asset_shortName, _asset_installDate,
    _userUUID, _userUUID, now(), now(), null);

ELSEIF(_action = 'UPDATE') THEN


	IF(_assetUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _assetUUID missing';
		LEAVE ASSET_asset;
	END IF;

		set  @l_sql = CONCAT('update asset set asset_updatedTS=now(), asset_updatedByUUID=\'', _userUUID,'\'');		

        if (_asset_locationUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_locationUUID = \'', _asset_locationUUID,'\'');
        END IF;
        if (_asset_partUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_partUUID = \'', _asset_partUUID,'\'');
        END IF;
        if (_asset_shortName is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_shortName = \'', _asset_shortName,'\'');
        END IF;
        if (_asset_statusId is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_statusId = ', _asset_statusId);
        END IF;
        if (_asset_installDate is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_installDate = \'', _asset_installDate,'\'');
        END IF;
        if (_asset_name is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_name = \'', _asset_name,'\'');
        END IF;
        

		set @l_sql = CONCAT(@l_sql,' where assetUUID = \'', _assetUUID,'\';');
       
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
        

ELSEIF(_action = 'DELETE') THEN

	IF (DEBUG=1) THEN select _action,_assetUUID; END IF;
    
	IF(_assetUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _assetUUID missing';
		LEAVE ASSET_asset;
	END IF;

	update asset set asset_deleteTS=now(), asset_statusId=2, asset_updatedByUUID=_userUUID where  assetUUID= _assetUUID and asset_customerUUID=_customerUUID;
	-- TBD, figure out what cleanup may be involved

END IF;

END$$


DELIMITER ;






-- ==================================================================

-- call ASSETPART_assetpart(action, _userUUID, _customerUUID, asset_partUUID, asset_part_template_part_sku,asset_part_statusId, asset_part_sku,asset_part_name, asset_part_description, asset_part_userInstruction, asset_part_shortName, asset_part_imageURL, asset_part_imageThumbURL, asset_part_hotSpotJSON, asset_part_isPurchasable, asset_part_diagnosticUUID, asset_part_magentoUUID, asset_part_vendor); 
-- call ASSETPART_assetpart('GET', '1', '3792f636d9a843d190b8425cc06257f5', null, null,null, null, null, null, null, null, null, null, null, null, null, null, null); 
-- call ASSETPART_assetpart('GET', '1', '3792f636d9a843d190b8425cc06257f5',  '0090d1d3b414471485c5e8b6f390a150', null,null, null, null, null, null, null, null, null, null, null, null, null, null); 
-- call ASSETPART_assetpart('CREATE', '1', '3792f636d9a843d190b8425cc06257f5',  10, 'asset_part_template_part_sku',1, 'asset_part_sku', 'asset_part_name', 'asset_part_description', 'asset_part_userInstruction', 'asset_part_shortName', 'asset_part_imageURL', 'asset_part_imageThumbURL', 'asset_part_hotSpotJSON', 1, 'asset_part_diagnosticUUID', 'asset_part_magentoUUID', 'asset_part_vendor'); 
-- call ASSETPART_assetpart('UPDATE', '1', '3792f636d9a843d190b8425cc06257f5',   10, 'asset_part_template_part_sku2',1, 'asset_part_sku', 'asset_part_name', 'asset_part_description', 'asset_part_userInstruction', 'asset_part_shortName', 'asset_part_imageURL', 'asset_part_imageThumbURL', 'asset_part_hotSpotJSON', 0, 'asset_part_diagnosticUUID', 'asset_part_magentoUUID', 'asset_part_vendor'); 
-- call ASSETPART_assetpart('DELETE', '1', '3792f636d9a843d190b8425cc06257f5',  10, null,null, null, null,null,null,null,null,null,null,null,null, null,null); 


DROP procedure IF EXISTS `ASSETPART_assetpart`;

DELIMITER $$
CREATE PROCEDURE `ASSETPART_assetpart` (
IN _action VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _customerUUID VARCHAR(100),
IN _asset_partUUID VARCHAR(100),
IN _asset_part_template_part_sku VARCHAR(100),
IN _asset_part_statusId INT,
IN _asset_part_sku VARCHAR(100),
IN _asset_part_name VARCHAR(255),
IN _asset_part_description VARCHAR(255),
IN _asset_part_userInstruction  VARCHAR(255),
IN _asset_part_shortName  VARCHAR(255),
IN _asset_part_imageURL  VARCHAR(255),
IN _asset_part_imageThumbURL  VARCHAR(255),
IN _asset_part_hotSpotJSON  VARCHAR(255),
IN _asset_part_isPurchasable  VARCHAR(255),
IN _asset_part_diagnosticUUID  VARCHAR(255),
IN _asset_part_magentoUUID  VARCHAR(255),
IN _asset_part_vendor VARCHAR(255)
)
ASSETPART_assetpart: BEGIN



DECLARE DEBUG INT DEFAULT 1;



IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _action can not be empty';
	LEAVE ASSETPART_assetpart;
END IF;

IF(_userUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _userUUID missing';
	LEAVE ASSETPART_assetpart;
END IF;

IF(_customerUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _customerUUID missing';
	LEAVE ASSETPART_assetpart;
END IF;

IF(_action = 'GET') THEN



	SET @l_SQL = 'SELECT * FROM asset_part ';
	
        SET @l_SQL = CONCAT(@l_SQL, '  WHERE asset_part_customerUUID =\'', _customerUUID,'\'');
        
		IF(_asset_partUUID IS NOT NULL AND _asset_partUUID!='') THEN
			SET @l_SQL = CONCAT(@l_SQL, '  AND asset_partUUID =\'', _asset_partUUID,'\'');
		END IF;
       
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
        
        PREPARE stmt FROM @l_SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

ELSEIF(_action = 'CREATE') THEN

	IF (DEBUG=1) THEN select _action, _userUUID, _customerUUID, _asset_partUUID, _asset_part_template_part_sku,_asset_part_statusId, _asset_part_sku, _asset_part_name, _asset_part_description, _asset_part_userInstruction, _asset_part_shortName, _asset_part_imageURL, _asset_part_imageThumbURL, _asset_part_hotSpotJSON, _asset_part_isPurchasable, _asset_part_diagnosticUUID, _asset_part_magentoUUID, _asset_part_vendor; END IF;
    
	IF(_asset_partUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_partUUID missing';
		LEAVE ASSETPART_assetpart;
	END IF;
    
    if (_asset_part_isPurchasable is null) then set _asset_part_isPurchasable=0; end if;
    
    insert into asset_part 
    (asset_partUUID, asset_part_template_part_sku,asset_part_customerUUID,asset_part_statusId, asset_part_sku, asset_part_name, asset_part_description, asset_part_userInstruction, asset_part_shortName, asset_part_imageURL, asset_part_imageThumbURL, asset_part_hotSpotJSON, asset_part_isPurchasable, asset_part_diagnosticUUID, asset_part_magentoUUID, asset_part_vendor,
    asset_part_createdByUUID, asset_part_updatedByUUID, asset_part_updatedTS, asset_part_createdTS, asset_part_deleteTS)
	values
    (_asset_partUUID, _asset_part_template_part_sku, _customerUUID, _asset_part_statusId, _asset_part_sku, _asset_part_name, _asset_part_description, _asset_part_userInstruction, _asset_part_shortName, _asset_part_imageURL, _asset_part_imageThumbURL, _asset_part_hotSpotJSON, _asset_part_isPurchasable, _asset_part_diagnosticUUID, _asset_part_magentoUUID, _asset_part_vendor,
    _userUUID, _userUUID, now(), now(), null);

ELSEIF(_action = 'UPDATE') THEN


	IF(_asset_partUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_partUUID missing';
		LEAVE ASSETPART_assetpart;
	END IF;

		set  @l_sql = CONCAT('update asset_part set asset_part_updatedTS=now(), asset_part_updatedByUUID=\'', _userUUID,'\'');		

        if (_asset_partUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_partUUID = \'', _asset_partUUID,'\'');
        END IF;
        if (_asset_part_template_part_sku is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_template_part_sku = \'', _asset_part_template_part_sku,'\'');
        END IF;
        if (_asset_part_sku is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_sku = \'', _asset_part_sku,'\'');
        END IF;
        if (_asset_part_statusId is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_statusId = ', _asset_part_statusId);
        END IF;
        if (_asset_part_name is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_name = \'', _asset_part_name,'\'');
        END IF;
        if (_asset_part_description is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_description = \'', _asset_part_description,'\'');
        END IF;
		if (_asset_part_userInstruction is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_userInstruction = \'', _asset_part_userInstruction,'\'');
        END IF;
        if (_asset_part_shortName is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_shortName = \'', _asset_part_shortName,'\'');
        END IF;
        if (_asset_part_imageURL is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_imageURL = \'', _asset_part_imageURL,'\'');
        END IF;
        if (_asset_part_imageThumbURL is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_imageThumbURL = \'', _asset_part_imageThumbURL,'\'');
        END IF;
        if (_asset_part_hotSpotJSON is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_hotSpotJSON = \'', _asset_part_hotSpotJSON,'\'');
        END IF;
        if (_asset_part_diagnosticUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_diagnosticUUID = \'', _asset_part_diagnosticUUID,'\'');
        END IF;
        if (_asset_part_magentoUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_magentoUUID = \'', _asset_part_magentoUUID,'\'');
        END IF;
        if (_asset_part_vendor is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_vendor = \'', _asset_part_vendor,'\'');
        END IF;
        if (_asset_part_isPurchasable is not null) THEN
			set @l_sql = CONCAT(@l_sql,',asset_part_isPurchasable = ', _asset_part_isPurchasable);
        END IF;


		set @l_sql = CONCAT(@l_sql,' where asset_partUUID = \'', _asset_partUUID,'\';');
       
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
        

ELSEIF(_action = 'DELETE') THEN

	IF (DEBUG=1) THEN select _action,_asset_partUUID; END IF;
    
	IF(_asset_partUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_partUUID missing';
		LEAVE ASSETPART_assetpart;
	END IF;

	update asset_part set asset_part_deleteTS=now(), asset_part_statusId=2, asset_part_updatedByUUID=_userUUID where  asset_partUUID= _asset_partUUID and asset_part_customerUUID=_customerUUID;
	-- TBD, figure out what cleanup may be involved

END IF;

END$$


DELIMITER ;