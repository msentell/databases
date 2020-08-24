
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

-- call LOCATION_getLocation(_action, _customerId, _locationId, _isPrimary); 
-- call LOCATION_getLocation('GET', 'a30af0ce5e07474487c39adab6269d5f', NULL, 1);

DROP procedure IF EXISTS `LOCATION_getLocation`;

DELIMITER $$
CREATE PROCEDURE `LOCATION_getLocation` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
IN _locationId VARCHAR(100),
IN _isPrimary INT
)
LOCATION_getLocation: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_getLocation: _action can not be empty';
	LEAVE LOCATION_getLocation;
END IF;

IF(_action = 'GET') THEN
	SET @l_SQL = 'SELECT l.* FROM location l';
	IF(_customerId IS NULL OR _customerId = '') THEN
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_getLocation: _customerId can not be empty';
		LEAVE LOCATION_getLocation;
	ELSE
        SET @l_SQL = CONCAT(@l_SQL, '  WHERE l.location_customerUUID =\'', _customerId,'\'');
        
		IF(_locationId IS NOT NULL AND _locationId!='') THEN
			SET @l_SQL = CONCAT(@l_SQL, '  AND l.locationUUID =\'', _locationId,'\'');
		END IF;
		IF(_isPrimary IS NOT NULL) THEN
			SET @l_SQL = CONCAT(@l_SQL, '  AND l.location_isPrimary =', _isPrimary);
		END IF;
        PREPARE stmt FROM @l_SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
	END IF;
ELSE
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_getLocation: _action is of type invalid';
	LEAVE LOCATION_getLocation;
END IF;

END$$

DELIMITER ;

-- ==================================================================


-- call LOCATION_updateLocation(_action, _customerId, _locationId, _locationName, _isPrimary); 
-- 'actionType', 'customerUUID', 'newlocationUUID/locationUUID', 'locationName', boolean
-- actionType - CREATE/UPDATE-IMAGE/UPDATE-NAME/UPDATE-HOTSPOT/DELETE

DROP procedure IF EXISTS `LOCATION_updateLocation`;

DELIMITER $$
CREATE PROCEDURE `LOCATION_updateLocation` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _locationId VARCHAR(100),
IN _locationName VARCHAR(100),
IN _isPrimary INT
)
LOCATION_updateLocation: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_updateLocation: _action can not be empty';
	LEAVE LOCATION_updateLocation;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_updateLocation: _customerId can not be empty';
	LEAVE LOCATION_updateLocation;
END IF;


END$$

DELIMITER ;

-- ==================================================================

-- call ASSET_updateAsset(_action, _customerId, _assetId, _assetName);
-- 'actionType', 'customerUUID', 'newassetUUID/assetUUID', 'assetName', boolean
-- actionType - CREATE/UPDATE-IMAGE/UPDATE-NAME/UPDATE-HOTSPOT/DELETE

DROP procedure IF EXISTS `ASSET_updateAsset`;

DELIMITER $$
CREATE PROCEDURE `ASSET_updateAsset` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _assetId VARCHAR(100),
IN _assetName VARCHAR(100)
)
ASSET_updateAsset: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_updateAsset: _action can not be empty';
	LEAVE ASSET_updateAsset;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_updateAsset: _customerId can not be empty';
	LEAVE ASSET_updateAsset;
END IF;

IF(_assetId IS NULL OR _assetId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_updateAsset: _assetId can not be empty';
	LEAVE ASSET_updateAsset;
END IF;


END$$

DELIMITER ;

-- ==================================================================

-- call ASSETPART_updateAssetPart(_action, _customerId, _assetPartId, _assetPartName);
-- 'actionType', 'customerUUID', 'newassetPartUUID/assetPartUUID', 'assetPartName', boolean
-- actionType - CREATE/UPDATE-IMAGE/UPDATE-NAME/UPDATE-HOTSPOT/DELETE

DROP procedure IF EXISTS `ASSETPART_updateAssetPart`;

DELIMITER $$
CREATE PROCEDURE `ASSETPART_updateAssetPart` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _assetPartId VARCHAR(100),
IN _assetPartName VARCHAR(100)
)
ASSETPART_updateAssetPart: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_updateAssetPart: _action can not be empty';
	LEAVE ASSETPART_updateAssetPart;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_updateAssetPart: _customerId can not be empty';
	LEAVE ASSETPART_updateAssetPart;
END IF;

IF(_assetPartId IS NULL OR _assetPartId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_updateAssetPart: _assetPartId can not be empty';
	LEAVE ASSETPART_updateAssetPart;
END IF;


END$$

DELIMITER ;

-- ==================================================================

-- call ASSETPART_deleteAssetPart(_action, _customerId, _assetPartId);
-- actionType - DELETE

DROP procedure IF EXISTS `ASSETPART_deleteAssetPart`;

DELIMITER $$
CREATE PROCEDURE `ASSETPART_deleteAssetPart` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _assetPartId VARCHAR(100)
)
ASSETPART_deleteAssetPart: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_deleteAssetPart: _action can not be empty';
	LEAVE ASSETPART_deleteAssetPart;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_deleteAssetPart: _customerId can not be empty';
	LEAVE ASSETPART_deleteAssetPart;
END IF;

IF(_assetPartId IS NULL OR _assetPartId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_deleteAssetPart: _assetPartId can not be empty';
	LEAVE ASSETPART_deleteAssetPart;
END IF;


END$$

DELIMITER ;

-- ==================================================================

-- call ASSET_deleteAsset(_action, _customerId, _assetId);
-- actionType - DELETE

DROP procedure IF EXISTS `ASSET_deleteAsset`;

DELIMITER $$
CREATE PROCEDURE `ASSET_deleteAsset` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _assetId VARCHAR(100)
)
ASSET_deleteAsset: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_deleteAsset: _action can not be empty';
	LEAVE ASSET_deleteAsset;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_deleteAsset: _customerId can not be empty';
	LEAVE ASSET_deleteAsset;
END IF;

IF(_assetId IS NULL OR _assetId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_deleteAsset: _assetId can not be empty';
	LEAVE ASSET_deleteAsset;
END IF;


END$$

DELIMITER ;


-- ==================================================================

-- call LOCATION_deleteLocation(_action, _customerId, _locationId, _isPrimary);
-- actionType - DELETE

DROP procedure IF EXISTS `LOCATION_deleteLocation`;

DELIMITER $$
CREATE PROCEDURE `LOCATION_deleteLocation` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _locationId VARCHAR(100)
)
LOCATION_deleteLocation: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_deleteLocation: _action can not be empty';
	LEAVE LOCATION_deleteLocation;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_deleteLocation: _customerId can not be empty';
	LEAVE LOCATION_deleteLocation;
END IF;

IF(_locationId IS NULL OR _locationId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_deleteLocation: _locationId can not be empty';
	LEAVE LOCATION_deleteLocation;
END IF;


END$$

DELIMITER ;


-- ==================================================================

-- call LOCATION_createLocation(_action, _customerId, _locationId, _isPrimary);
-- actionType - CREATE

DROP procedure IF EXISTS `LOCATION_createLocation`;

DELIMITER $$
CREATE PROCEDURE `LOCATION_createLocation` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _locationId VARCHAR(100)
)
LOCATION_createLocation: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_createLocation: _action can not be empty';
	LEAVE LOCATION_createLocation;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_createLocation: _customerId can not be empty';
	LEAVE LOCATION_createLocation;
END IF;

IF(_locationId IS NULL OR _locationId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_createLocation: _locationId can not be empty';
	LEAVE LOCATION_createLocation;
END IF;


END$$

DELIMITER ;

-- ==================================================================

-- call ASSETPART_createAssetPart(_action, _customerId, _assetPartId);
-- actionType - CREATE

DROP procedure IF EXISTS `ASSETPART_createAssetPart`;

DELIMITER $$
CREATE PROCEDURE `ASSETPART_createAssetPart` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _assetPartId VARCHAR(100)
)
ASSETPART_createAssetPart: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_createAssetPart: _action can not be empty';
	LEAVE ASSETPART_createAssetPart;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_createAssetPart: _customerId can not be empty';
	LEAVE ASSETPART_createAssetPart;
END IF;

IF(_assetPartId IS NULL OR _assetPartId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_createAssetPart: _assetPartId can not be empty';
	LEAVE ASSETPART_createAssetPart;
END IF;


END$$

DELIMITER ;

-- ==================================================================

-- call ASSET_createAsset(_action, _customerId, _assetId);
-- actionType - CREATE

DROP procedure IF EXISTS `ASSET_createAsset`;

DELIMITER $$
CREATE PROCEDURE `ASSET_createAsset` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
In _assetId VARCHAR(100)
)
ASSET_createAsset: BEGIN

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_createAsset: _action can not be empty';
	LEAVE ASSET_createAsset;
END IF;

IF(_customerId IS NULL OR _customerId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_createAsset: _customerId can not be empty';
	LEAVE ASSET_createAsset;
END IF;

IF(_assetId IS NULL OR _assetId = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_createAsset: _assetId can not be empty';
	LEAVE ASSET_createAsset;
END IF;


END$$

DELIMITER ;