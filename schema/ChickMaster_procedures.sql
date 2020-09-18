
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
IN _id VARCHAR(32)
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
        where loc.location_customerUUID = _customerId AND loc.location_isPrimary = _startingPoint AND loc.locationUUID = _id;
	
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

-- call DIAGNOSTIC_tree(action,userId,diagnosticUUID, diagnostic_statusId, diagnostic_name, diagnostic_description, diagnostic_startNodeUUID); 
-- call DIAGNOSTIC_tree('GET', '1', null, null, null, null, null); 
-- call DIAGNOSTIC_tree('CREATE', '1', '10', null, 'diagnostic_name', 'diagnostic_description', null); 
-- call DIAGNOSTIC_tree('UPDATE', '1', '10', null, 'diagnostic_name2', 'diagnostic_description2', 10); 
-- call DIAGNOSTIC_tree('DELETE', '1',  '10', null, null, null,null); 

DROP procedure IF EXISTS `DIAGNOSTIC_tree`;

DELIMITER $$
CREATE PROCEDURE `DIAGNOSTIC_tree` (
IN _action VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _diagnosticUUID VARCHAR(100),
IN _diagnostic_statusId INT,
IN _diagnostic_name VARCHAR(100),
IN _diagnostic_description VARCHAR(255),
IN _diagnostic_startNodeUUID VARCHAR(255)
)
DIAGNOSTIC_tree: BEGIN
DECLARE commaNeeded INT DEFAULT 0;

DECLARE DEBUG INT DEFAULT 0;

IF(_action IS NULL ) THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: _action can not be empty';
	LEAVE DIAGNOSTIC_tree;
END IF;

IF(_userUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: _userUUID missing';
	LEAVE DIAGNOSTIC_tree;
END IF;

IF(_action = 'GET') THEN

	SET @l_SQL = 'SELECT * FROM diagnostic_tree ';
	
		IF(_diagnosticUUID IS NOT NULL or _diagnostic_startNodeUUID IS NOT NULL or _diagnostic_name IS NOT NULL) THEN
			SET @l_SQL = CONCAT(@l_SQL, '  WHERE ');
		END IF;

		IF(_diagnosticUUID IS NOT NULL) THEN
			IF (commaNeeded>0) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF; 
			SET @l_SQL = CONCAT(@l_SQL, ' diagnosticUUID =\'', _diagnosticUUID,'\'');
			set commaNeeded =1;			
		END IF;

		IF(_diagnostic_startNodeUUID IS NOT NULL) THEN
			IF (commaNeeded>0) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF; 
			SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_startNodeUUID =\'', _diagnostic_startNodeUUID,'\'');
			set commaNeeded =1;			
		END IF;
        
		IF(_diagnostic_name IS NOT NULL) THEN
			IF (commaNeeded>0) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF; 
			SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_name =\'', _diagnostic_name,'\'');
			set commaNeeded =1;			
		END IF;
        
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
        
        PREPARE stmt FROM @l_SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

ELSEIF(_action = 'CREATE') THEN

	IF (DEBUG=1) THEN select _action, _userUUID, _diagnosticUUID, _diagnostic_statusId, _diagnostic_name, _diagnostic_description, _diagnostic_startNodeUUID; END IF;
    
	IF(_diagnosticUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: diagnosticUUID missing';
		LEAVE DIAGNOSTIC_tree;
	END IF;
    
    insert into diagnostic_tree 
    (diagnosticUUID, diagnostic_statusId, diagnostic_name, diagnostic_description, diagnostic_startNodeUUID,
    diagnostic_createdByUUID, diagnostic_updatedByUUID, diagnostic_updatedTS, diagnostic_createdTS, diagnostic_deleteTS)
	values
    (_diagnosticUUID, 1, _diagnostic_name, _diagnostic_description, _diagnostic_startNodeUUID,
    _userUUID, _userUUID, now(), now(), null);

ELSEIF(_action = 'UPDATE') THEN

	IF(_diagnosticUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: diagnosticUUID missing';
		LEAVE DIAGNOSTIC_tree;
	END IF;


		set  @l_sql = CONCAT('update diagnostic_tree set diagnostic_updatedTS=now(), diagnostic_updatedByUUID=\'', _userUUID,'\'');		

        if (_diagnostic_name is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_name = \'', _diagnostic_name,'\'');
        END IF;
        if (_diagnostic_description is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_description = \'', _diagnostic_description,'\'');
        END IF;
        if (_diagnostic_startNodeUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_startNodeUUID = \'', _diagnostic_startNodeUUID,'\'');
        END IF;
        if (_diagnostic_statusId is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_statusId = ', _diagnostic_statusId);
        END IF;

		set @l_sql = CONCAT(@l_sql,' where diagnosticUUID = \'', _diagnosticUUID,'\';');
       
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
        

ELSEIF(_action = 'DELETE') THEN

	IF (DEBUG=1) THEN select _action,_diagnosticUUID; END IF;
    
	IF(_diagnosticUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: _diagnosticUUID missing';
		LEAVE DIAGNOSTIC_tree;
	END IF;

	update diagnostic_tree set diagnostic_deleteTS=now(), diagnostic_statusId=2, diagnostic_updatedByUUID=_userUUID where  diagnosticUUID= _diagnosticUUID;
	-- TBD, figure out what cleanup may be involved

END IF;

END$$


DELIMITER ;
-- ==================================================================


-- call DIAGNOSTIC_node(action,userId,diagnostic_nodeUUID, diagnostic_node_diagnosticUUID, diagnostic_node_statusId,diagnostic_node_title, diagnostic_node_prompt, diagnostic_node_optionPrompt, diagnostic_node_hotSpotJSON, diagnostic_node_imageSetJSON, diagnostic_node_optionSetJSON,diagnostic_node_warning,diagnostic_node_warningSeverity); 
-- call DIAGNOSTIC_node('GETNODE', '1', '5d84cb09d6fb473baba1b8914fc', '633a54011d76432b9fa18b0b6308c189', null,null, null, null, null, null, null,null,null,null,null); 
-- call DIAGNOSTIC_node('GET', '1', '5d84cb09d6fb473baba1b8914fc', '633a54011d76432b9fa18b0b6308', null,null, null, null, null, null, null,null,null,null,null); 
-- call DIAGNOSTIC_node('CREATE', '1', '10', '633a54011d76432b9fa18b0b6308c189', null,'diagnostic_node_title', 'diagnostic_node_prompt', 'diagnostic_node_optionPrompt', 'diagnostic_node_hotSpotJSON', 'diagnostic_node_imageSetJSON', 'diagnostic_node_optionSetJSON',null,null); 
-- call DIAGNOSTIC_node('UPDATE', '1', '10', '633a54011d76432b9fa18b0b6308c189', null,'diagnostic_node_title2', 'diagnostic_node_prompt2', 'diagnostic_node_optionPrompt', 'diagnostic_node_hotSpotJSON', 'diagnostic_node_imageSetJSON', 'diagnostic_node_optionSetJSON','diagnostic_node_warning',diagnostic_node_warningSeverity); 
-- call DIAGNOSTIC_node('DELETE', '1',  '10', null, null,null, null, null, null, null, null,null,null); 
-- call DIAGNOSTIC_node('UPDATE','1','5d84cb09d6fb473baba1b8914fc', '633a54011d76432b9fa18b0b6308', null ,'testing_tiltle rtghjy', 'diagnosticnodeprompt', 'diagnostic_node_optionPrompt', '[{"coordinates":[{}],"color":"red","forwardId":"1599760999552"}]', 'https://jcmi.sfo2.digitaloceanspaces.com/demodata/Hendrix/diagnostics/Heating1.JPG', 'false','hello','hijky');

DROP procedure IF EXISTS `DIAGNOSTIC_node`;


DELIMITER $$
CREATE PROCEDURE `DIAGNOSTIC_node` (
IN _action VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _diagnostic_nodeUUID VARCHAR(100),
IN _diagnostic_node_diagnosticUUID VARCHAR(100),
IN _diagnostic_node_statusId INT,
IN _diagnostic_node_title VARCHAR(100),
IN _diagnostic_node_prompt VARCHAR(255),
IN _diagnostic_node_optionPrompt VARCHAR(255),
IN _diagnostic_node_hotSpotJSON text,
IN _diagnostic_node_imageSetJSON text,
IN _diagnostic_node_optionSetJSON text,
IN _diagnostic_node_warning VARCHAR(255),
IN _diagnostic_node_warningSeverity VARCHAR(45)
)
DIAGNOSTIC_node: BEGIN
DECLARE commaNeeded INT DEFAULT 0;

DECLARE DEBUG INT DEFAULT 0;

IF(_action IS NULL ) THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _action can not be empty';
	LEAVE DIAGNOSTIC_node;
END IF;

IF(_userUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _userUUID missing';
	LEAVE DIAGNOSTIC_node;
END IF;

IF(_action = 'GETNODE') THEN

	If (_diagnostic_node_diagnosticUUID is not null and _diagnostic_nodeUUID is null) THEN

			SELECT n.*,d.* from diagnostic_tree d
			left join diagnostic_node n on (d.diagnosticUUID=n.diagnostic_node_diagnosticUUID and d.diagnostic_startNodeUUID = n.diagnostic_nodeUUID) 
			where diagnosticUUID = _diagnostic_node_diagnosticUUID;

	ELSEIF (_diagnostic_nodeUUID is not null) THEN

			SELECT n.* from diagnostic_node n
			-- left join diagnostic_tree d on (d.diagnosticUUID=n.diagnostic_node_diagnosticUUID) 
			where diagnostic_nodeUUID = _diagnostic_nodeUUID;
	
	END IF;

ELSEIF(_action = 'GET') THEN

		SET @l_SQL = 'SELECT * FROM diagnostic_node ';
	
		IF(_diagnostic_nodeUUID IS NOT NULL or _diagnostic_node_diagnosticUUID IS NOT NULL or _diagnostic_node_title IS NOT NULL) THEN
			SET @l_SQL = CONCAT(@l_SQL, '  WHERE ');
		END IF;

		IF(_diagnostic_nodeUUID IS NOT NULL) THEN
			IF (commaNeeded>0) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF; 
			SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_nodeUUID =\'', _diagnostic_nodeUUID,'\'');
			set commaNeeded =1;			
		END IF;

		IF(_diagnostic_node_diagnosticUUID IS NOT NULL) THEN
			IF (commaNeeded>0) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF; 
			SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_node_diagnosticUUID =\'', _diagnostic_node_diagnosticUUID,'\'');
			set commaNeeded =1;			
		END IF;
        
		IF(_diagnostic_node_title IS NOT NULL) THEN
			IF (commaNeeded>0) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF; 
			SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_node_title like \'','%', _diagnostic_node_title,'%','\'');
			set commaNeeded =1;			
		END IF;
        
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
        
        PREPARE stmt FROM @l_SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

    
ELSEIF(_action = 'CREATE') THEN

	IF (DEBUG=1) THEN select _action, _userUUID, _diagnostic_nodeUUID, _diagnostic_node_diagnosticUUID, 1, 
	_diagnostic_node_title, _diagnostic_node_prompt, _diagnostic_node_optionPrompt, 
	_diagnostic_node_hotSpotJSON, _diagnostic_node_imageSetJSON, _diagnostic_node_optionSetJSON; END IF;
    
	IF(_diagnostic_nodeUUID IS NULL or _diagnostic_node_diagnosticUUID is null) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call _diagnostic_nodeUUID: _diagnostic_nodeUUID or _diagnostic_node_diagnosticUUID missing';
		LEAVE DIAGNOSTIC_node;
	END IF;
    
    insert ignore into diagnostic_node 
    (diagnostic_nodeUUID, diagnostic_node_diagnosticUUID, diagnostic_node_statusId, 
	diagnostic_node_title, diagnostic_node_prompt, diagnostic_node_optionPrompt, 
	diagnostic_node_hotSpotJSON, diagnostic_node_imageSetJSON, diagnostic_node_optionSetJSON,
    diagnostic_node_createdByUUID, diagnostic_node_updatedByUUID, diagnostic_node_updatedTS, diagnostic_node_createdTS, diagnostic_node_deleteTS)
	values
    (_diagnostic_nodeUUID, _diagnostic_node_diagnosticUUID, 1, 
	_diagnostic_node_title, _diagnostic_node_prompt, _diagnostic_node_optionPrompt, 
	_diagnostic_node_hotSpotJSON, _diagnostic_node_imageSetJSON, _diagnostic_node_optionSetJSON,
    _userUUID, _userUUID, now(), now(), null);

ELSEIF(_action = 'UPDATE') THEN

	IF(_diagnostic_nodeUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _diagnostic_nodeUUID missing';
		LEAVE DIAGNOSTIC_node;
	END IF;

		set  @l_sql = CONCAT('update diagnostic_node set diagnostic_node_updatedTS=now(), diagnostic_node_updatedByUUID=\'', _userUUID,'\'');		

        if (_diagnostic_node_diagnosticUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_node_diagnosticUUID = \'', _diagnostic_node_diagnosticUUID,'\'');
        END IF;
        if (_diagnostic_node_title is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_node_title = \'', _diagnostic_node_title,'\'');
        END IF;
        if (_diagnostic_node_prompt is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_node_prompt = \'', _diagnostic_node_prompt,'\'');
        END IF;
        if (_diagnostic_node_statusId is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_node_statusId = ', _diagnostic_node_statusId);
        END IF;
        if (_diagnostic_node_optionPrompt is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_node_optionPrompt = \'', _diagnostic_node_optionPrompt,'\'');
        END IF;
        if (_diagnostic_node_hotSpotJSON is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_node_hotSpotJSON = \'', _diagnostic_node_hotSpotJSON,'\'');
        END IF;
        if (_diagnostic_node_imageSetJSON is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_node_imageSetJSON = \'', _diagnostic_node_imageSetJSON,'\'');
        END IF;
        if (_diagnostic_node_optionSetJSON is not null) THEN
			set @l_sql = CONCAT(@l_sql,',diagnostic_node_optionSetJSON = \'', _diagnostic_node_optionSetJSON,'\'');
        END IF;
		if(_diagnostic_node_warning is not null)THEN
		set @l_sql = CONCAT(@l_sql,',diagnostic_node_warning= \'', _diagnostic_node_warning,'\'');
		END IF;
		if(_diagnostic_node_warningSeverity is not null)THEN
		set @l_sql = CONCAT(@l_sql,',diagnostic_node_warningSeverity= \'', _diagnostic_node_warningSeverity,'\'');
		END IF;

		set @l_sql = CONCAT(@l_sql,' where diagnostic_nodeUUID = \'', _diagnostic_nodeUUID,'\';');
       
        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
        

ELSEIF(_action = 'DELETE') THEN

	IF (DEBUG=1) THEN select _action,_diagnostic_nodeUUID; END IF;
    
	IF(_diagnostic_nodeUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _diagnostic_nodeUUID missing';
		LEAVE DIAGNOSTIC_node;
	END IF;

	update diagnostic_node set diagnostic_node_deleteTS=now(), diagnostic_node_statusId=2, diagnostic_node_updatedByUUID=_userUUID where  diagnostic_nodeUUID= _diagnostic_nodeUUID;
	-- TBD, figure out what cleanup may be involved

END IF;

END$$


DELIMITER ;




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

	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call DIAGNOSTIC_getNode: deprecated use: call DIAGNOSTIC_node(GET, 1, null, 633a54011d76432b9fa18b0b6308c189, null,null, null, null, null, null, null); ';
	LEAVE DIAGNOSTIC_getNode;


/*
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
*/

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

/*
call WORKORDER_workOrder(_action, _customerId,_userUUID
_workorderUUID,_workorder_locationUUID,_workorder_userUUID,_workorder_groupUUID,_workorder_assetUUID,
_workorder_checklistUUID,_workorder_status,_workorder_type,_workorder_name,_workorder_number,_workorder_details,
_workorder_actions,_workorder_priority,_workorder_dueDate,_workorder_completeDate,
_workorder_rescheduleDate,_workorder_frequency,_workorder_frequencyScope,_wapj_asset_partUUID,
_wapj_quantity
);

call WORKORDER_workOrder('GET', 'a30af0ce5e07474487c39adab6269d5f',1,
'0d59f068ed4c462aaaa23c5acd71e4d6',null,null,null,null,
null,null,null,null,null,null,
null,null,null,null,
null,null,null,null,
null);
*/
DROP procedure IF EXISTS `WORKORDER_workOrder`;


DELIMITER $$
CREATE PROCEDURE `WORKORDER_workOrder` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _workorderUUID VARCHAR(100),
IN _workorder_locationUUID VARCHAR(100),
IN _workorder_userUUID VARCHAR(100),
IN _workorder_groupUUID VARCHAR(100),
IN _workorder_assetUUID VARCHAR(100),
IN _workorder_checklistUUID VARCHAR(100),
IN _workorder_status varchar(100),
IN _workorder_type VARCHAR(100),
IN _workorder_name VARCHAR(100),
IN _workorder_number VARCHAR(100),
IN _workorder_details VARCHAR(100),
IN _workorder_actions TEXT,
IN _workorder_priority VARCHAR(100),
IN _workorder_dueDate VARCHAR(100),
IN _workorder_completeDate VARCHAR(100),
IN _workorder_rescheduleDate VARCHAR(100),
IN _workorder_frequency INT,
IN _workorder_frequencyScope VARCHAR(100),
IN _wapj_asset_partUUID VARCHAR(100),
IN _wapj_quantity INT
)
WORKORDER_workOrder: BEGIN

DECLARE _DEBUG INT DEFAULT 0;

DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%Y';
DECLARE _maxWO INT;
DECLARE _commaNeeded INT;
DECLARE _workorder_definition varchar(100);

IF(_action ='GET') THEN
	
	IF(_customerId IS NULL or _customerId = '') THEN
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _customerId can not be empty';
		LEAVE WORKORDER_workOrder;
	END IF;

	if (_workorder_dueDate IS NOT NULL) THEN set _workorder_dueDate = STR_TO_DATE(_workorder_dueDate, _dateFormat); END IF;

		set  @l_sql = CONCAT('SELECT * FROM workorder WHERE ');

        if (_workorderUUID IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,'workorderUUID = \'', _workorderUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_customerId IS NOT NULL) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'workorder_customerUUID = \'', _customerId,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_userUUID IS NOT NULL) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'workorder_userUUID = \'', _workorder_userUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_groupUUID IS NOT NULL) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'workorder_groupUUID = \'', _workorder_groupUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_locationUUID IS NOT NULL) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'workorder_locationUUID = \'', _workorder_locationUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_status IS NOT NULL) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'workorder_status = \'', _workorder_status,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_dueDate IS NOT NULL) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'DATE(now()) <= \'', _workorder_dueDate,'\'');
            set _commaNeeded=1;
        END IF;

        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

ELSEIF(_action ='CREATE' and _workorderUUID is not null) THEN

	IF(_customerId IS NULL or _customerId = '') THEN
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _customerId can not be empty';
		LEAVE WORKORDER_workOrder;
	END IF;

	-- RULES and CONVERSIONS
	if (_workorder_dueDate IS NOT NULL) THEN set _workorder_dueDate = STR_TO_DATE(_workorder_dueDate, _dateFormat); END IF;
	if (_workorder_rescheduleDate IS NOT NULL) THEN set _workorder_rescheduleDate = STR_TO_DATE(_workorder_rescheduleDate, _dateFormat); END IF;
	if (_workorder_userUUID is null) THEN set  _workorder_userUUID =_userUUID; END IF;


	-- TODO get configuration for workorder naming
    set _workorder_definition = 'CM-';
    select count(*) into _maxWO from workorder;
	set _workorder_number = CONCAT(_workorder_definition,_maxWO);
	set _workorder_status = 'OPEN';
	
    
	insert into workorder (workorderUUID,
    workorder_customerUUID, workorder_locationUUID, workorder_userUUID, workorder_groupUUID, 
    workorder_assetUUID, workorder_checklistUUID, workorder_status, workorder_type, 
    workorder_number, workorder_name, workorder_details, workorder_actions, workorder_priority, 
    workorder_dueDate, workorder_rescheduleDate, workorder_completeDate, workorder_frequency, 
    workorder_frequencyScope,
	workorder_createdByUUID, workorder_updatedByUUID, workorder_updatedTS, workorder_createdTS
    ) values (_workorderUUID,
    _customerId, _workorder_locationUUID, _workorder_userUUID, _workorder_groupUUID, 
    _workorder_assetUUID, _workorder_checklistUUID, _workorder_status, _workorder_type, 
    _workorder_number, _workorder_name, _workorder_details, _workorder_actions, _workorder_priority, 
    _workorder_dueDate, _workorder_rescheduleDate, _workorder_completeDate, _workorder_frequency, 
    _workorder_frequencyScope, 
    _userUUID, _userUUID, now(), now()
    );
	
ELSEIF(_action ='UPDATE') THEN

		set  @l_sql = CONCAT('update workorder set workorder_updatedTS=now(), workorder_updatedByUUID=', _userUUID);		

        if (_workorder_status IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,',workorder_status = \'', _workorder_status,'\'');
        END IF;
        if (_workorder_name IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,',workorder_name = \'', _workorder_name,'\'');
        END IF;
        if (_workorder_details IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,',workorder_details = \'', _workorder_details,'\'');
        END IF;
        if (_workorder_actions IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,',workorder_actions = \'', _workorder_actions,'\'');
        END IF;
        if (_workorder_priority IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,',workorder_priority = \'', _workorder_priority,'\'');
        END IF;
        if (_workorder_dueDate IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,',workorder_dueDate = \'', _workorder_dueDate,'\'');
        END IF;
        if (_workorder_assetUUID IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,',workorder_assetUUID = \'', _workorder_assetUUID,'\'');
        END IF;
        if (_workorder_rescheduleDate IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,',workorder_rescheduleDate = \'', _workorder_rescheduleDate,'\'');
        END IF;

		set @l_sql = CONCAT(@l_sql,' where workorderUUID = \'', _workorderUUID,'\';');
       
        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;


ELSEIF(_action ='REMOVE' and _workorderUUID is not null) THEN

	if (_wapj_asset_partUUID IS NOT NULL) THEN
		delete from workorder_asset_part_join where wapj_asset_partUUID=_wapj_asset_partUUID 
        and wapj_workorderUUID = _workorderUUID;
    ELSE
		update workorder set workorder_deleteTS = now(),workorder_updatedTS = now(), 
        workorder_updatedByUUID=_userUUID where workorderUUID=_workorderUUID;
    END IF;
    
ELSEIF(_action ='ASSIGN') THEN

		update workorder set workorder_status='OPEN', workorder_completeDate =null, 
		workorder_userUUID = _workorder_userUUID,
		workorder_updatedTS = now(), workorder_updatedByUUID=_userUUID 
        where workorderUUID=_workorderUUID;

ELSEIF(_action ='START') THEN

		update workorder set workorder_status='IN_PROGRESS', workorder_completeDate =null, 
        workorder_updatedTS = now(), workorder_updatedByUUID=_userUUID 
        where workorderUUID=_workorderUUID;

ELSEIF(_action ='COMPLETE') THEN

		update workorder set workorder_status='COMPLETE', workorder_completeDate = DATE(now()), 
        workorder_updatedTS = now(), workorder_updatedByUUID=_userUUID 
        where workorderUUID=_workorderUUID;

ELSEIF(_action ='ADDPART' and _wapj_asset_partUUID is not null) THEN

		REPLACE INTO workorder_asset_part_join (wapj_workorderUUID, wapj_asset_partUUID, 
		wapj_quantity, wapj_createdTS)
		values (
		_workorderUUID,_wapj_asset_partUUID,_wapj_quantity,now()
		);
	
ELSE
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _action is of type invalid';
	LEAVE WORKORDER_workOrder;
END IF;


IF (_DEBUG=1) THEN 
	select _action,_workorderUUID,
    _customerId, _workorder_locationUUID, _workorder_userUUID, _workorder_groupUUID, 
    _workorder_assetUUID, _workorder_checklistUUID, _workorder_status, _workorder_type, 
    _workorder_number, _workorder_name, _workorder_details, _workorder_actions, _workorder_priority, 
    _workorder_dueDate, _workorder_rescheduleDate, _workorder_completeDate, _workorder_frequency, 
    _workorder_frequencyScope, 
    _userUUID;
    
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
	SELECT * FROM customer;
ELSEIF(_action ='GET') THEN
	SELECT * FROM customer where customerUUID = _customerId;
END IF;

END$$

DELIMITER ;


-- ==================================================================

-- call CUSTOMER_getCustomerBrandDetails(_action, _customerId);
-- call CUSTOMER_getCustomerBrandDetails('GET-LIST', NULL);

DROP procedure IF EXISTS `CUSTOMER_CustomerBrand`;

DELIMITER $$
CREATE PROCEDURE `CUSTOMER_CustomerBrand` (
IN _action VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _brandUUID VARCHAR(100),
IN _brandName VARCHAR(50),
IN _brandLogo VARCHAR(255),
IN _brandPreferenceJSON TEXT
)
CUSTOMER_CustomerBrand: BEGIN


DECLARE _DEBUG INT DEFAULT 0;
DECLARE _commaNeeded INT;
IF(_action IS NULL or _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _action can not be empty';
	LEAVE CUSTOMER_CustomerBrand;
END IF;

IF(_userUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _userUUID missing';
	LEAVE CUSTOMER_CustomerBrand;
END IF;

IF(_action ='GET-LIST') THEN
	SELECT * FROM customer_brand;
ELSEIF(_action ='GET') THEN
    set @l_sql = 'SELECT b.* FROM customer_brand b';
    IF((_brandUUID IS NULL OR _brandUUID = '') AND (_brandName IS NULL or _brandName = '')) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _brandUUID or _brandName missing';
        LEAVE CUSTOMER_CustomerBrand;
    END IF;
    IF(_brandUUID IS NOT NULL and _brandUUID != '') THEN
        set @l_sql = CONCAT(@l_sql, ' WHERE b.brandUUID = \'',_brandUUID,'\'');
        set _commaNeeded=1;
    END IF;
    if(_brandName IS NOT NULL AND _brandName != '') THEN
        if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql, ' AND '); ELSE set @l_sql = CONCAT(@l_sql, ' WHERE '); END IF;
        set @l_sql = CONCAT(@l_sql, 'b.brand_name LIKE \'%',_brandName,'%\'');
    END IF;
    IF (_DEBUG = 1) THEN SELECT _action, @l_sql; END IF;
    PREPARE stmt FROM @l_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

ELSEIF(_action = 'CREATE') THEN

	IF(_brandUUID IS NULL) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _brandUUID missing';
		LEAVE CUSTOMER_CustomerBrand;
	END IF;
	IF(_brandName IS NULL) THEN
    		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _brandName missing';
    		LEAVE CUSTOMER_CustomerBrand;
    	END IF;
    INSERT INTO customer_brand
    (brandUUID, brand_name, brand_logo, brand_preferenceJSON, brand_createdByUUID, brand_created)
	VALUES
    (_brandUUID, _brandName, _brandLogo, _brandPreferenceJSON, _userUUID, now());
ELSEIF(_action = 'UPDATE') THEN
    IF(_brandUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _brandUUID missing';
        LEAVE CUSTOMER_CustomerBrand;
    END IF;
    SET @l_sql = 'UPDATE customer_brand SET ';
    SET _commaNeeded = 0;
    IF (_brandName IS NOT NULL) THEN
        SET @l_sql = CONCAT(@l_sql,'brand_name = \'',_brandName,'\'');
        SET _commaNeeded = 1;
    END IF;
    IF (_brandLogo IS NOT NULL) THEN
        IF (_commaNeeded=1) THEN SET @l_sql = CONCAT(@l_sql, ','); END IF;
        SET @l_sql = CONCAT(@l_sql, 'brand_logo = \'',_brandLogo,'\'');
        SET _commaNeeded = 1;
    END IF;
    IF (_brandPreferenceJSON IS NOT NULL) THEN
        IF (_commaNeeded=1) THEN SET @l_sql = CONCAT(@l_sql, ','); END IF;
        SET @l_sql = CONCAT(@l_sql, 'brand_preferenceJSON = \'',_brandPreferenceJSON,'\'');
        SET _commaNeeded = 1;
    END IF;
    SET @l_sql = CONCAT(@l_sql, ' WHERE brandUUID = \'',_brandUUID,'\'');
    -- to do: securityBitwise
    IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

    PREPARE stmt FROM @l_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
ELSEIF(_action = 'REMOVE' AND _brandUUID IS NOT NULL AND _brandUUID != '') THEN
    DELETE FROM customer_brand WHERE brandUUID = _brandUUID;
END IF;

END$$

DELIMITER ;

-- ==================================================================

-- call USER_userGroup(_action, _userUUID, _customerUUID, _groupUUID, _groupName);
-- call USER_userGroup('GET-LIST', 1, 1, null, null);
-- call USER_userGroup('GET-LIST', 1,1,1, null,null ; GET GROUPS FOR SPECIFIC CUSTOMER

DROP procedure IF EXISTS `USER_userGroup`;

DELIMITER $$
CREATE PROCEDURE `USER_userGroup` (
    IN _action VARCHAR(100),
    IN _userUUID VARCHAR(100),
    IN _customerUUID VARCHAR(100),
    IN _groupUUID VARCHAR(100),
    IN _groupName VARCHAR(255)
)
USER_userGroup: BEGIN
    DECLARE _DEBUG INT DEFAULT 0;
    IF(_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_userGroup: _action can not be empty';
        LEAVE USER_userGroup;
    END IF;

    IF(_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call USER_userGroup: _userUUID missing';
        LEAVE USER_userGroup;
    END IF;

    IF(_action ='GET-LIST') THEN
        SET @l_sql = 'SELECT * FROM user_group';
        IF _customerUUID IS NOT NULL AND _customerUUID != '' THEN
            SET @l_sql = CONCAT(@l_sql,' WHERE group_customerUUID = \'',_customerUUID,'\'');
        END IF;
        IF (_DEBUG = 1) THEN SELECT _action, @l_sql; END IF;
        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF(_action ='GET') THEN
        set @l_sql = 'SELECT ug.* FROM user_group ug';
        IF(_groupUUID IS NULL OR _groupUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call USER_userGroup: _groupUUID missing';
            LEAVE USER_userGroup;
        END IF;
        SELECT ug.* FROM user_group ug WHERE ug.groupUUID = _groupUUID;
    ELSEIF(_action = 'CREATE') THEN
        IF(_groupUUID IS NULL OR _groupUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call USER_userGroup: _groupUUID missing';
            LEAVE USER_userGroup;
        END IF;
        IF(_groupName IS NULL OR _groupName = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call USER_userGroup: _groupName missing';
            LEAVE USER_userGroup;
        END IF;
        IF(_customerUUID IS NULL OR _customerUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call USER_userGroup: _customerUUID missing';
            LEAVE USER_userGroup;
        END IF;
        INSERT INTO user_group (groupUUID, group_customerUUID, group_name, group_createdByUUID, group_createdTS, group_updatedByUUID, group_updatedTS)
        VALUES (_groupUUID, _customerUUID, _groupName, _userUUID, now(), _userUUID, now());
    ELSEIF(_action = 'UPDATE') THEN
        IF(_groupUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call USER_userGroup: _groupUUID missing';
            LEAVE USER_userGroup;
        END IF;
        SET @l_sql = CONCAT('UPDATE user_group SET group_updatedTS=now(), group_updatedByUUID=\'',_userUUID,'\'');
        IF (_customerUUID IS NOT NULL AND _customerUUID != '') THEN
            SET @l_sql = CONCAT(@l_sql,',group_customerUUID = \'',_customerUUID,'\'');
        END IF;
        IF (_groupName IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',group_name = \'',_groupName,'\'');
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE groupUUID = \'',_groupUUID,'\'');
        -- to do: securityBitwise
        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF(_action = 'REMOVE' AND _groupUUID IS NOT NULL AND _groupUUID != '') THEN
        DELETE FROM user_group WHERE groupUUID = _groupUUID;
    END IF;

END$$

DELIMITER ;

-- ==================================================================
-- call USER_userGroup(_action, _userUUID, _customerUUID, _groupUUID, _groupName);
-- call USER_userGroup('GET-LIST', 1, 1, null, null);
-- call USER_userGroup('GET-LIST', 1,1,1, null,null ; GET GROUPS FOR SPECIFIC CUSTOMER

DROP procedure IF EXISTS `CUSTOMER_customer`;

DELIMITER $$
CREATE PROCEDURE `CUSTOMER_customer` (
    IN _action VARCHAR(100),
    IN _userUUID VARCHAR(100),
    IN _customerUUID VARCHAR(100),
    IN _customerBrandUUID VARCHAR(100),
    IN _customerStatusId INT,
    IN _customerName VARCHAR(100),
    IN _customerLogo VARCHAR(255),
    IN _customerSecurityBitwise BIGINT,
    IN _customerPreferenceJSON TEXT
)
CUSTOMER_customer: BEGIN
    DECLARE _DEBUG INT DEFAULT 1;
    IF(_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _action can not be empty';
        LEAVE CUSTOMER_customer;
    END IF;

    IF(_userUUID IS NULL OR _userUUID = '') THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _userUUID missing';
        LEAVE CUSTOMER_customer;
    END IF;

    IF(_action ='GET-LIST') THEN
        SELECT * FROM customer;
    ELSEIF(_action ='GET') THEN
        IF(_customerUUID IS NULL or _customerUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;
        SELECT * FROM customer WHERE customerUUID = _customerUUID;
    ELSEIF(_action = 'CREATE') THEN
        IF(_customerUUID IS NULL OR _customerUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;
        IF(_customerName IS NULL OR _customerName = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerName missing';
            LEAVE CUSTOMER_customer;
        END IF;
        INSERT INTO customer (customerUUID, customer_externalName,customer_brandUUID, customer_statusId, customer_name,
                              customer_logo, customer_securityBitwise, customer_preferenceJSON, customer_createdByUUID,
                              customer_updatedByUUID, customer_updatedTS, customer_createdTS, customer_deleteTS)
        VALUES (_customerUUID, _customerName,_customerBrandUUID,_customerStatusId,_customerName,_customerLogo,
                _customerSecurityBitwise, _customerPreferenceJSON, _userUUID,_userUUID,now(),now(),null);
    ELSEIF(_action = 'UPDATE') THEN
        IF(_customerUUID IS NULL or _customerUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;
        SET @l_sql = CONCAT('UPDATE customer SET customer_updatedTS=now(), customer_updatedByUUID=\'',_userUUID,'\'');
        IF (_customerStatusId IS NOT NULL AND _customerStatusId != '') THEN
            SET @l_sql = CONCAT(@l_sql,',customer_statusId = \'',_customerStatusId,'\'');
        END IF;
        IF (_customerName IS NOT NULL and _customerName != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_name = \'',_customerName,'\'');
        END IF;
        IF (_customerLogo IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_logo = \'',_customerLogo,'\'');
        END IF;
        IF (_customerSecurityBitwise IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_securityBitwise = \'',_customerSecurityBitwise,'\'');
        END IF;
        IF (_customerPreferenceJSON IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_preferenceJSON = \'',_customerPreferenceJSON,'\'');
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE customerUUID = \'',_customerUUID,'\'');
        -- to do: securityBitwise
        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF(_action = 'REMOVE' AND _customerUUID IS NOT NULL AND _customerUUID != '') THEN
        DELETE FROM customer WHERE customerUUID = _customerUUID;
    END IF;

END$$

Delimiter ;

-- ==================================================================
# KNOWLEDGE BASE
-- call USER_userGroup(_action, _userUUID, _customerUUID, _groupUUID, _groupName);
-- call USER_userGroup('GET-LIST', 1, 1, null, null);
-- call USER_userGroup('GET-LIST', 1,1,1, null,null ; GET GROUPS FOR SPECIFIC CUSTOMER

DROP procedure IF EXISTS `KB_knowledge_base`;

DELIMITER $$
CREATE PROCEDURE `KB_knowledge_base` (
    IN _action VARCHAR(100),
    IN _userUUID VARCHAR(100),
    IN _knowledgebaseUUID VARCHAR(100),
    IN _knowledge_statusId INT,
    IN _knowledge_imageURL VARCHAR(255),
    IN _knowledge_tags VARCHAR(500),
    IN _knowledge_categories VARCHAR(500),
    IN _knowledge_title VARCHAR(100),
    IN _knowledge_content VARCHAR(1000),
    IN _knowledge_customerUUID CHAR(32),
    IN _knowledge_relatedArticle TEXT
)
KB_knowledge_base: BEGIN
    DECLARE _DEBUG INT DEFAULT 1;
    IF(_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call KB_knowledge_base: _action can not be empty';
        LEAVE KB_knowledge_base;
    END IF;

    IF(_userUUID IS NULL OR _userUUID = '') THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _userUUID missing';
        LEAVE KB_knowledge_base;
    END IF;

    IF(_action ='GET-LIST') THEN
        SELECT * FROM knowledge_base;
    ELSEIF(_action ='GET') THEN
        IF(_knowledgebaseUUID IS NULL or _knowledgebaseUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _knowledgebaseUUID missing';
            LEAVE KB_knowledge_base;
        END IF;
        SELECT * FROM knowledge_base WHERE knowledgeUUID = _knowledgebaseUUID;
    ELSEIF(_action = 'CREATE') THEN
        IF(_knowledgebaseUUID IS NULL OR _knowledgebaseUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _knowledgebaseUUID missing';
            LEAVE KB_knowledge_base;
        END IF;
        IF(_knowledge_title IS NULL OR _knowledge_title = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _knowledge_title missing';
            LEAVE KB_knowledge_base;
        END IF;
        INSERT INTO knowledge_base (knowledgeUUID, knowledge_statusId, knowledge_imageURL, knowledge_tags, knowledge_categories,
                                    knowledge_title, knowledge_customerUUID, knowledge_content, knowledge_createdByUUID, knowledge_acknowledgedByUUID,
                                    knowledge_updatedTS, knowledge_createdTS, knowledge_deleteTS)
        VALUES (_knowledgebaseUUID, _knowledge_statusId, _knowledge_imageURL, _knowledge_tags, _knowledge_categories,
                _knowledge_title, _knowledge_customerUUID, _knowledge_content,
                _userUUID, _userUUID, now(), now(), null);
    ELSEIF(_action = 'UPDATE') THEN
        IF(_knowledgebaseUUID IS NULL or _knowledgebaseUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _knowledgebaseUUID missing';
            LEAVE KB_knowledge_base;
        END IF;
        SET @l_sql = CONCAT('UPDATE knowledge_base SET knowledge_updatedTS=now(), knowledge_updatedByUUID=\'',_userUUID,'\'');
        IF (_knowledge_statusId IS NOT NULL AND _knowledge_statusId != '') THEN
            SET @l_sql = CONCAT(@l_sql,',knowledge_statusId = \'',_knowledge_statusId,'\'');
        END IF;
        IF (_knowledge_imageURL IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_imageURL = \'',_knowledge_imageURL,'\'');
        END IF;
        IF (_knowledge_tags IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_tags = \'',_knowledge_tags,'\'');
        END IF;
        IF (_knowledge_categories IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_categories = \'',_knowledge_categories,'\'');
        END IF;
        IF (_knowledge_title IS NOT NULL AND _knowledge_title != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_title = \'',_knowledge_title,'\'');
        END IF;
        IF (_knowledge_content IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_content = \'',_knowledge_content,'\'');
        END IF;
        IF (_knowledge_customerUUID IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_customerUUID = ',_knowledge_customerUUID);
        END IF;
        IF (_knowledge_relatedArticle IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_relatedArticle = ',_knowledge_relatedArticle);
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE knowledgeUUID = \'',_knowledgebaseUUID,'\'');
        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;
        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF(_action = 'REMOVE' AND _knowledgebaseUUID IS NOT NULL AND _knowledgebaseUUID != '') THEN
        DELETE FROM knowledge_base WHERE knowledgeUUID = _knowledgebaseUUID;
    ELSEIF(_action = 'LIKE') THEN
        UPDATE knowledge_base SET knowledge_likes = knowledge_likes+1 where knowledgeUUID=_knowledgebaseUUID;
    ELSEIF(_action = 'UNLIKE') THEN
        UPDATE knowledge_base SET knowledge_likes = knowledge_likes-1 where knowledgeUUID=_knowledgebaseUUID;
    ELSEIF (_action = 'DISLIKE') THEN
        UPDATE knowledge_base SET knowledge_dislikes = knowledge_dislikes+1 where knowledgeUUID=_knowledgebaseUUID;
    ELSEIF (_action = 'UNDISLIKE') THEN
        UPDATE knowledge_base SET knowledge_dislikes = knowledge_dislikes-1 where knowledgeUUID=_knowledgebaseUUID;
    END IF;
END$$

DELIMITER ;

-- ==================================================================
-- call PLAN_plan(_action)

DROP procedure IF EXISTS `PLAN_plan`;

DELIMITER $$
CREATE PROCEDURE `PLAN_plan` (
    IN _action VARCHAR(100),
    IN _userUUID VARCHAR(100),
    IN _planUUID VARCHAR(100),
    IN _planName VARCHAR(100),
    IN _planSecurityBitwise BIGINT,
    IN _planMaxUsers BIGINT
)
PLAN_plan: BEGIN
    DECLARE _DEBUG INT DEFAULT 0;
    IF(_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call PLAN_plan: _action can not be empty';
        LEAVE PLAN_plan;
    END IF;

    IF(_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _userUUID missing';
        LEAVE PLAN_plan;
    END IF;

    IF(_action ='GET-LIST') THEN
        SELECT * FROM plan;
    ELSEIF(_action ='GET') THEN
        IF(_planUUID IS NULL or _planUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _planUUID missing';
            LEAVE PLAN_plan;
        END IF;
        SELECT * FROM plan WHERE planUUID = _planUUID;
    ELSEIF(_action = 'CREATE') THEN
        IF(_planUUID IS NULL OR _planUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _planUUID missing';
            LEAVE PLAN_plan;
        END IF;
        IF(_planName IS NULL OR _planName = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _planName missing';
            LEAVE PLAN_plan;
        END IF;
        INSERT INTO plan (planUUID, plan_name, plan_securityBitwise, plan_maxUsers, plan_createdByUUID,
                          plan_updatedByUUID, plan_updatedTS, plan_createdTS, plan_deleteTS)
        VALUES (_planUUID, _planName, _planSecurityBitwise, _planMaxUsers, _userUUID,_userUUID,now(),now(),null);
    ELSEIF(_action = 'UPDATE') THEN
        IF(_planUUID IS NULL or _planUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _planUUID missing';
            LEAVE PLAN_plan;
        END IF;
        SET @l_sql = CONCAT('UPDATE plan SET plan_updatedTS=now(), plan_updatedByUUID=\'',_userUUID,'\'');
        IF (_planName IS NOT NULL AND _planName != '') THEN
            SET @l_sql = CONCAT(@l_sql,',plan_name = \'',_planName,'\'');
        END IF;
        IF (_planSecurityBitwise IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',plan_securityBitwise = ',_planSecurityBitwise);
        END IF;
        IF (_planMaxUsers IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',plan_maxUsers = ',_planMaxUsers);
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE _planUUID = \'',_planUUID,'\'');
        -- to do: securityBitwise
        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF(_action = 'REMOVE' AND _planUUID IS NOT NULL AND _planUUID != '') THEN
        DELETE FROM plan WHERE planUUID = _planUUID;
    END IF;

END$$

DELIMITER ;
-- ==================================================================

-- call LOCATION_action(action, _userUUID, _customerUUID, _type, _name,_objUUID, 0);
-- call LOCATION_action('SEARCH', '1', 'a30af0ce5e07474487c39adab6269d5f', 'LOCATION', 'test123Lo',null, 0);
-- call LOCATION_action('SEARCH', '1', 'a30af0ce5e07474487c39adab6269d5f', 'ASSET', 'setter',null, 0);
-- call LOCATION_action('SEARCH', '1', '3792f636d9a843d190b8425cc06257f5', 'ASSET-PART', 'Avida Symphony',null, 0); 
-- call LOCATION_action('CREATE', '1', '3792f636d9a843d190b8425cc06257f5', 'LOCATION', 'DAVID',55, 0); 
-- call LOCATION_action('CREATE', '1', '3792f636d9a843d190b8425cc06257f5', 'ASSET', 'ASSETDAVID',55, 0); 
-- call LOCATION_action('CREATE', '1', '3792f636d9a843d190b8425cc06257f5', 'ASSET-PART', 'ASSETPARTDAVID',22, 0); 


DROP procedure IF EXISTS `LOCATION_action`;

DELIMITER $$
CREATE PROCEDURE `LOCATION_action` (
IN _action VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _customerUUID VARCHAR(100),
IN _type VARCHAR(100),
IN _name VARCHAR(100),
IN _objUUID VARCHAR(100),
IN _isPrimary INT,
IN _locationId VARCHAR(100)
)
LOCATION_action: BEGIN

DECLARE _itemFound varchar(100);

DECLARE DEBUG INT DEFAULT 0;

IF(_action IS NULL OR _action = '') THEN
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_action: _action can not be empty';
	LEAVE LOCATION_action;
END IF;

IF(_userUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _userUUID missing';
	LEAVE LOCATION_action;
END IF;

IF(_customerUUID IS NULL) THEN
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _customerUUID missing';
	LEAVE LOCATION_action;
END IF;

IF(_action = 'SEARCH') THEN


	set _name = concat('%',_name,'%');
    
	if (_type = 'ASSET') THEN

		-- SELECT assetUUID as objUUID, null as ImageURL,null as ThumbURL, asset_name as `name`,_type as `Type` 
		-- 	FROM asset where asset_name like _name and  asset_customerUUID=_customerUUID;

        SET @l_SQL = CONCAT('SELECT assetUUID as objUUID, null as ImageURL,null as ThumbURL, asset_name as `name`, \'',_type,'\' as `Type`
			FROM asset where asset_name like \'', _name,'\'  and  asset_customerUUID= \'',_customerUUID,'\'');
    
    ELSEif (_type = 'ASSET-PART') THEN
    
		-- SELECT asset_partUUID as objUUID,asset_part_imageURL as ImageURL,asset_part_imageThumbURL as ThumbURL,asset_part_name  as `name`,_type as `Type` 
		-- 	FROM asset_part where asset_part_name like _name and asset_part_customerUUID =_customerUUID;

        SET @l_SQL = CONCAT('SELECT asset_partUUID as objUUID,asset_part_imageURL as ImageURL,asset_part_imageThumbURL as ThumbURL,asset_part_name  as `name`, \'',_type,'\' as `Type` 
			FROM asset_part where asset_part_name like \'', _name,'\'  and  asset_part_customerUUID= \'',_customerUUID,'\'');
    
    ELSEif (_type = 'LOCATION') THEN 

		-- SELECT locationUUID as objUUID, location_imageUrl as ImageURL, location_imageUrl as ThumbURL, location_name as `name`,_type as `Type` 
		-- 	FROM location where location_name like _name and location_customerUUID =_customerUUID;

        SET @l_SQL = CONCAT('SELECT locationUUID as objUUID, location_imageUrl as ImageURL, location_imageUrl as ThumbURL, location_name as `name`, \'',_type,'\' as `Type` 
			FROM location where location_name like \'', _name,'\'  and  location_customerUUID= \'',_customerUUID,'\'');

	else
    
	SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _type not valid';
	LEAVE LOCATION_action;

	END IF;

        IF (DEBUG=1) THEN select _action,@l_SQL; END IF;
        
        PREPARE stmt FROM @l_SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;



ELSEIF(_action = 'CREATE') THEN

	IF (DEBUG=1) THEN select _action, _userUUID, _customerUUID, _type, _name,_objUUID; END IF;
    
	IF(_name IS NULL or _type is null or _objUUID is null ) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _name or _type or _objUUID missing';
		LEAVE LOCATION_action;
	END IF;

	if (_type = 'ASSET') THEN

		select assetUUID into _itemFound from asset where asset_name = _name and asset_customerUUID = _customerUUID;


		if ( _itemFound is not null) THEN
		
			SELECT assetUUID as objUUID, null as ImageURL,null as ThumbURL, asset_name as `name`,_type as `Type` 
			FROM asset where assetUUID = _itemFound;
            			
		ELSE
		
			-- location,part required?
            
			insert into asset 
			(assetUUID, asset_locationUUID, asset_partUUID, asset_customerUUID, asset_statusId, asset_name, asset_shortName, asset_installDate,
			asset_createdByUUID, asset_updatedByUUID, asset_updatedTS, asset_createdTS, asset_deleteTS)
			values
			(_objUUID, _locationId, null, _customerUUID, 1, _name, _name, null,
			_userUUID, _userUUID, now(), now(), null);

			SELECT assetUUID as objUUID, null as ImageURL,null as ThumbURL, asset_name as `name`,_type as `Type` 
			FROM asset where assetUUID = _objUUID;

		END IF;


    
    ELSEif (_type = 'ASSET-PART') THEN
    
		select asset_partUUID into _itemFound from asset_part where asset_part_name = _name and asset_part_customerUUID = _customerUUID;
			
		if ( _itemFound is not null) THEN
		
			SELECT asset_partUUID as objUUID,asset_part_imageURL as ImageURL,asset_part_imageThumbURL as ThumbURL,asset_part_name  as `name`,_type as `Type` 
				FROM asset_part where asset_partUUID = _itemFound;
			
		ELSE
		
			insert into asset_part 
			(asset_partUUID, asset_part_template_part_sku,asset_part_customerUUID,asset_part_statusId, asset_part_sku, asset_part_name, asset_part_description, asset_part_userInstruction, asset_part_shortName, asset_part_imageURL, asset_part_imageThumbURL, asset_part_hotSpotJSON, asset_part_isPurchasable, asset_part_diagnosticUUID, asset_part_magentoUUID, asset_part_vendor,
			asset_part_createdByUUID, asset_part_updatedByUUID, asset_part_updatedTS, asset_part_createdTS, asset_part_deleteTS)
			values
			(_objUUID, null, _customerUUID, 1, null, _name, _name, null, _name, null, null, null, null, null, null, null,
			_userUUID, _userUUID, now(), now(), null);

			SELECT asset_partUUID as objUUID,asset_part_imageURL as ImageURL,asset_part_imageThumbURL as ThumbURL,asset_part_name  as `name`,_type as `Type` 
				FROM asset_part where asset_partUUID = _objUUID;

		END IF;

    
    ELSEif (_type = 'LOCATION') THEN 



		select locationUUID into _itemFound from location where location_name = _name and location_customerUUID = _customerUUID;
			
		if ( _itemFound is not null) THEN
		
			SELECT locationUUID as objUUID, location_imageUrl as ImageURL, location_imageUrl as ThumbURL, location_name as `name`,_type as `Type` 
				FROM location where locationUUID = _itemFound;
			
		ELSE
		
		   insert into location 
			(locationUUID, location_customerUUID, location_statusId, location_type, location_name, location_description, location_isPrimary, location_imageUrl, location_hotSpotJSON, location_addressTypeId, location_address, location_address_city, location_address_state, location_address_zip, location_country, location_contact_name, location_contact_email, location_contact_phone,
			location_createdByUUID, location_updatedByUUID, location_updatedTS, location_createdTS, location_deleteTS)
			values
			(_objUUID, _customerUUID, 1, 'LOCATION', _name, _name, _isPrimary, null, null, null, null, null, null, null, null, null, null, null,
			_userUUID, _userUUID, now(), now(), null);

			SELECT locationUUID as objUUID, location_imageUrl as ImageURL, location_imageUrl as ThumbURL, location_name as `name`,_type as `Type` 
				FROM location where locationUUID = _objUUID;

		END IF;




	END IF;



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
			
		SET @l_SQL = CONCAT(@l_SQL, '  AND l.location_statusId = \'1\'');
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
-- call ASSET_asset('GET', '1', 'a30af'GET', '1', 'a30af0ce5e07474487c39adab6269d5f',  '00c93791035c44fd98d4f40ff2cdfe0a', null, null, null, null, null, null); 
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
    
	IF(_assetUUID IS NULL or _asset_partUUID is null) THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _assetUUID or _asset_partUUID missing';
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


-- ==================================================================

/*
call USER_user(_action, _customerId,
_userUUID,_user_userUUID,_user_userName,_user_loginEmail,_user_loginPW,
_user_statusId,_user_securityBitwise,_user_profile_locationUUID,_user_profile_phone,_user_profile_preferenceJSON,
_user_profile_avatarSrc,_groupUUID
);


-- create or update
call USER_user('UPDATE', _customerId,
_userUUID,_user_userUUID,_user_userName,_user_loginEmail,_user_loginPW,
_user_statusId,_user_securityBitwise,_user_profile_locationUUID,_user_profile_phone,_user_profile_preferenceJSON,
_user_profile_avatarSrc,_groupUUID
);

call USER_user('GET', '7e7165375b344ab4892c18effb3296f7',1,null,null,null,null,null,null,null,null,null,null,null);

call USER_user('REMOVE', null,_userUUID,_user_userUUID,null,null,null,null,null,null,null,null,null,_groupUUID);

call USER_user('ADDGROUP', null,_userUUID,_user_userUUID,null,null,null,null,null,null,null,null,null,_groupUUID);

call USER_user('CHANGEPASSWORD', null,_userUUID,_user_userUUID,null,null,_user_loginPW,null,null,null,null,null,null,null);

call USER_user('LOGOUT', null,null,_user_userUUID,null,null,null,null,null,null,null,null,null,null);

*/

DROP procedure IF EXISTS `USER_user`;

DELIMITER $$
CREATE PROCEDURE `USER_user` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
IN _userUUID char(32), -- user making the request
IN _user_userUUID char(32), -- target user
IN _user_userName VARCHAR(100),
IN _user_loginEmail VARCHAR(255),
IN _user_loginPW VARCHAR(100),
IN _user_statusId INT,
IN _user_securityBitwise BIGINT,
IN _user_profile_locationUUID char(32),
IN _user_profile_phone VARCHAR(100),
IN _user_profile_preferenceJSON VARCHAR(1000),
IN _user_profile_avatarSrc varchar(255),
IN _groupUUID char(32)

)
USER_user: BEGIN

DECLARE _DEBUG INT DEFAULT 0;

DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%Y';
DECLARE _userFoundUUID char(32);
DECLARE _commaNeeded INT;


IF(_action ='GET') THEN
	
	IF(_customerId IS NULL or _customerId = '') THEN
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_user: _customerId can not be empty';
		LEAVE USER_user;
	END IF;

		set  @l_sql = CONCAT('select c.customer_name, c.customerUUID, u.*,l.*,p.user_profile_phone,p.user_profile_preferenceJSON,p.user_profile_avatarSrc ');


        if (_groupUUID is not null) THEN
			set  @l_sql = CONCAT(@l_sql,',g.group_name, g.groupUUID ');
		end if;

		set  @l_sql = CONCAT(@l_sql,' from `user` u');
		set  @l_sql = CONCAT(@l_sql,' left join customer c on (c.customerUUID=u.user_customerUUID)');
		set  @l_sql = CONCAT(@l_sql,' left join user_profile p on (p.user_profile_userUUID = u.userUUID)');
		set  @l_sql = CONCAT(@l_sql,' left join location l on (l.locationUUID = p.user_profile_locationUUID)');
        
        if (_groupUUID is not null) THEN
			set  @l_sql = CONCAT(@l_sql,' left join user_group_join gj on (gj.ugj_userUUID = u.userUUID)');
			set  @l_sql = CONCAT(@l_sql,' left join user_group g on (g.groupUUID = gj.ugj_groupUUID)');
		end if;
        
		set  @l_sql = CONCAT(@l_sql,' where ');		

        if (_customerId is not null) THEN
			set @l_sql = CONCAT(@l_sql,'u.user_customerUUID = \'', _customerId,'\'');
            set _commaNeeded=1;
        END IF;
        if (_user_userUUID is not null) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'u.userUUID = \'', _user_userUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_groupUUID is not null) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'g.groupUUID = \'', _groupUUID,'\'');
            set _commaNeeded=1;
        END IF;

		set @l_sql = CONCAT(@l_sql,';');

        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

ELSEIF(_action ='UPDATE' and _user_userUUID is not null) THEN

	IF(_customerId IS NULL or _customerId = '') THEN
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_user: _customerId can not be empty';
		LEAVE USER_user;
	END IF;

	-- RULES and CONVERSIONS

	select userUUID into _userFoundUUID from `user` where userUUID=_user_userUUID;

	IF (_userFoundUUID is null) THEN

		insert into `user` (

		userUUID, user_customerUUID, user_userName, user_loginEmail,
        user_loginPW, user_statusId, 
		user_securityBitwise, 
		user_createdByUUID, user_updatedByUUID, user_updatedTS, user_createdTS, user_deleteTS    
		)
		values (
		_user_userUUID, _customerId, _user_userName, _user_loginEmail,
        _user_loginPW, 1, 
		_user_securityBitwise, 
		_userUUID, _userUUID, now(), now(), null 
		);
        
        -- handle creating the profile record;
        
        replace into user_profile (
        user_profile_userUUID, user_profile_avatarSrc, user_profile_phoneTypeId, user_profile_phone, user_profile_addressTypeId, user_profile_locationUUID, user_profile_preferenceJSON,
        user_profile_createdByUUID, user_profile_updatedByUUID, user_profile_updatedTS, user_profile_createdTS, user_profile_deleteTS
        ) values (
        _user_userUUID, _user_profile_avatarSrc, 3, _user_profile_phone, 2, _user_profile_locationUUID, _user_profile_preferenceJSON, 
        _userUUID, _userUUID, now(), now(), null
        );
			
	ELSE -- update

		set  @l_sql = CONCAT('update user set user_updatedTS =now(), user_updatedByUUID =', _userUUID);		

        if (_user_userName is null) THEN
			set @l_sql = CONCAT(@l_sql,',user_userName = \'', _user_userName,'\'');
        END IF;
        if (_user_loginEmail is null) THEN
			set @l_sql = CONCAT(@l_sql,',user_loginEmail = \'', _user_loginEmail,'\'');
        END IF;
        if (_user_statusId is null) THEN
			set @l_sql = CONCAT(@l_sql,',user_statusId = ', _user_statusId);
        END IF;
        if (_user_securityBitwise is null) THEN
			set @l_sql = CONCAT(@l_sql,',user_securityBitwise = ', _user_securityBitwise);
        END IF;

		set @l_sql = CONCAT(@l_sql,' where _userUUID = \'', _user_userUUID,'\';');
       
        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

		
        if (_user_statusId = 3) THEN
			update `user` set user_deleteTS=now() where userUUID = _user_userUUID;
        else 
			update `user` set user_deleteTS=null where userUUID = _user_userUUID;
        END IF;


		if (_user_profile_locationUUID is not null or _user_profile_phone is not null
        or _user_profile_preferenceJSON is not null or _user_profile_avatarSrc is not null) THEN
        
			set  @l_sql= null;
            
			set  @l_sql = CONCAT('update user_profile set user_profile_updatedTS =now(), user_profile_updatedByUUID =', _userUUID);		

			if (_user_profile_locationUUID is null) THEN
				set @l_sql = CONCAT(@l_sql,',user_profile_locationUUID = \'', _user_profile_locationUUID,'\'');
			END IF;
			if (_user_profile_phone is null) THEN
				set @l_sql = CONCAT(@l_sql,',user_profile_phone = \'', _user_profile_phone,'\'');
			END IF;
			if (_user_profile_preferenceJSON is null) THEN
				set @l_sql = CONCAT(@l_sql,',user_profile_preferenceJSON = \'', _user_profile_preferenceJSON,'\'');
			END IF;
			if (_user_profile_avatarSrc is null) THEN
				set @l_sql = CONCAT(@l_sql,',user_profile_avatarSrc = \'', _user_profile_avatarSrc,'\'');
			END IF;


			set @l_sql = CONCAT(@l_sql,' where user_profile_userUUID = \'', _user_userUUID,'\';');
		   
			IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;
				
			PREPARE stmt FROM @l_sql;
			EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
        
        END IF;

	END IF;	

ELSEIF(_action ='REMOVE' ) THEN

	if (_groupUUID is not null) THEN

		delete from user_group_join where ugj_groupUUID=_groupUUID and 
        ugj_userUUID = _user_userUUID;
    
    END IF;
    
    if (_user_userUUID is not null) THEN
		update `user` set user_deleteTS=now(), user_updatedByUUID=_userUUID, user_updatedTS=now()
		where userUUID = _user_userUUID;
    END IF;
    
    
    
    
ELSEIF(_action ='ADDGROUP' and _user_userUUID is not null and _groupUUID is not null) THEN

	insert ignore into user_group_join 
    (ugj_groupUUID, ugj_userUUID, ugj_createdByUUID, ugj_createdTS)
    values (_groupUUID, _user_userUUID, _userUUID, now() );
    
ELSEIF(_action ='CHANGEPASSWORD' and _user_userUUID is not null and _user_loginPW is not null) THEN

		update `user` set user_loginPW=_user_loginPW, user_updatedByUUID=_userUUID, user_updatedTS=now()
        where userUUID = _user_userUUID;

ELSEIF(_action ='LOGOUT') THEN

		update `user` set user_loginSessionExpire = now()
        where userUUID = _user_userUUID;

ELSE
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_user: _action is of type invalid';
	LEAVE USER_user;
END IF;


IF (_DEBUG=1) THEN 
	select _action,_user_userUUID, _customerId, _user_userName, _user_loginEmail,
        _user_loginPW,_user_securityBitwise, _userUUID,_groupUUID;
    
END IF;


END$$

DELIMITER ; 



-- ==================================================================
-- call ATT_getPicklist(null, null, 1); -- returns all the picklists
-- call ATT_getPicklist('att_userlevel_predefined', null, null); 
-- call ATT_getPicklist('checklist', 'a30af0ce5e07474487c39adab6269d5f', null); 
-- call ATT_getPicklist('group', 'a30af0ce5e07474487c39adab6269d5f', null); 
-- call ATT_getPicklist('asset', 'a30af0ce5e07474487c39adab6269d5f', null); 
-- call ATT_getPicklist('location', 'a30af0ce5e07474487c39adab6269d5f', null); 
-- call ATT_getPicklist('user', 'a30af0ce5e07474487c39adab6269d5f', null); 

DROP procedure IF EXISTS `ATT_getPicklist`;

DELIMITER //
CREATE PROCEDURE `ATT_getPicklist`( 
IN _tables varchar(1000),
_customerId char(32), 
_userId char(32))
getPicklist: BEGIN
	
    IF (LOCATE('att_address_type', _tables) > 0) THEN
		select 'att_address_type' as tableName, id as id, name as value, name as name from att_address_type order by name;
	END IF; 
    
    IF (LOCATE('att_phone', _tables) > 0) THEN
		select 'att_phone' as tableName, id as id, name as value, name as name from att_phone order by name;
	END IF; 
        
    IF (LOCATE('customer', _tables) > 0) THEN
		select 'customer' as tableName, customerUUID as id, customer_name as value, customer_name as name from customer order by customer_name;
	END IF; 

    IF (LOCATE('checklist', _tables) > 0) THEN
    
		if (_customerId is null) Then
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
		LEAVE getPicklist;
        END IF;
        
		select 'checklist' as tableName, checklistUUID as id, checklist_name as value, checklist_name as name 
        from checklist where checklist_customerUUID = _customerId
        order by checklist_name;
	END IF; 


    IF (LOCATE('group', _tables) > 0) THEN
    
		if (_customerId is null) Then
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
		LEAVE getPicklist;
        END IF;
        
		select 'group' as tableName, groupUUID as id, group_name as value, group_name as name 
        from user_group where group_customerUUID = _customerId
        order by group_name;
	END IF; 

    IF (LOCATE('asset', _tables) > 0) THEN
    
		if (_customerId is null) Then
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
		LEAVE getPicklist;
        END IF;
        
		select 'group' as tableName, assetUUID as id, asset_name as value, asset_name as name 
        from asset where asset_customerUUID = _customerId
        order by asset_name;
	END IF; 

    IF (LOCATE('location', _tables) > 0) THEN
    
		if (_customerId is null) Then
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
		LEAVE getPicklist;
        END IF;
        
		select 'location' as tableName, locationUUID as id, location_name as value, location_name as name 
        from location where location_customerUUID = _customerId
        order by location_name;
	END IF; 

    IF (LOCATE('user', _tables) > 0) THEN
    
		if (_customerId is null) Then
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
		LEAVE getPicklist;
        END IF;
        
		select 'user' as tableName, userUUID as id, user_userName as value, user_userName as name 
        from `user` where user_customerUUID = _customerId and user_statusId=1
        order by user_userName;
	END IF; 
    
    IF (LOCATE('att_userlevel_predefined', _tables) > 0) THEN
		select 'att_userlevel_predefined' as tableName, description as id, bitwise as value, bitwise as name from att_userlevel_predefined order by description;
	END IF; 

END //
DELIMITER ;

-- ==================================================================
-- call SECURITY_bitwise('CALCULATE',1,1,null,null);
-- call SECURITY_bitwise('ADDUSERSECURITY',1,1,null,8);
-- call SECURITY_bitwise('REMOVESECURITY',1,1,null,8);

DROP procedure IF EXISTS `SECURITY_bitwise`;

/*

Name	Description
&	Bitwise AND
>>	Right shift
<<	Left shift
^	Bitwise XOR
BIT_COUNT()	Return the number of bits that are set
|	Bitwise OR
~	Bitwise inversion

*/

DELIMITER $$
CREATE  PROCEDURE SECURITY_bitwise(
IN _action VARCHAR(100),
IN _userId char(32),
IN _targetUserId CHAR(32),
IN _att_userlevel_predefined INT,
IN _att_bitwise BIGINT
)
SECURITY_bitwise: BEGIN

DECLARE _DEBUG INT DEFAULT 1;

DECLARE _att_userlevel_predefined_bitwise BIGINT DEFAULT 0;
DECLARE _customer_securityBitwise BIGINT DEFAULT 0;
DECLARE _brand_securityBitwise BIGINT DEFAULT 0;
DECLARE _group_securityBitwise BIGINT DEFAULT 0;
DECLARE _user_individualSecurityBitwise BIGINT DEFAULT 0;

DECLARE _user_securityBitwise BIGINT DEFAULT 0;

DECLARE _customerId char(32);
DECLARE _brandId char(32);

if (_action = 'ADDUSERSECURITY') THEN

	select user_customerUUID,user_securityBitwise,user_individualSecurityBitwise 
	INTO
	_customerId,_user_securityBitwise,_user_individualSecurityBitwise
    from `user`
	where userUUID=_targetUserId;

	select _user_individualSecurityBitwise | _att_bitwise into _user_individualSecurityBitwise;

	update `user` set user_individualSecurityBitwise=_user_individualSecurityBitwise where userUUID=_targetUserId;

	set _action = 'CALCULATE';
    
ELSEif (_action = 'REMOVESECURITY') THEN

	select user_customerUUID,user_securityBitwise,user_individualSecurityBitwise 
	INTO
	_customerId,_user_securityBitwise,_user_individualSecurityBitwise
    from `user`
	where userUUID=_targetUserId;

	select _user_individualSecurityBitwise ^ _att_bitwise into _user_individualSecurityBitwise;

	update `user` set user_individualSecurityBitwise=_user_individualSecurityBitwise where userUUID=_targetUserId;

	set _action = 'CALCULATE';

END IF;

if (_action = 'CALCULATE') THEN

	-- user
	select user_customerUUID,user_securityBitwise,user_individualSecurityBitwise 
	INTO
	_customerId,_user_securityBitwise,_user_individualSecurityBitwise
    from `user`
	where _targetUserId=userUUID;

	-- customer
	select customer_securityBitwise into _customer_securityBitwise from customer where customerUUID = _customerId;
	
    -- brand
    select ifnull(brand_securityBitwise,0) into _brand_securityBitwise 
    from customer_brand b
    left join customer c on (c.customer_brandUUID = b.brandUUID) where c.customerUUID = _customerId;

	-- groups
    -- select into _group_securityBitwise where ugj_userUUID = userUUID;

	set _user_securityBitwise = _customer_securityBitwise | _brand_securityBitwise | _group_securityBitwise | _user_individualSecurityBitwise;

	update `user` set user_securityBitwise=_user_securityBitwise where userUUID=_targetUserId;

END IF;

IF (_DEBUG=1) THEN select _action,_customerId,_user_securityBitwise,_customer_securityBitwise,_user_individualSecurityBitwise,_brand_securityBitwise,_group_securityBitwise,_targetUserId; END IF;

END$$


-- ==================================================================

/*
call NOTIFICATION_notification(
_action,_userUUID,
_notification_templateId,_notificationId,_notificationType,
_notification_toEmail,_notification_toSMS,_notification_toUserUUID,_notification_toGroupUUID,_notification_toAppUUID,
_notification_fromAppUUID,_notification_fromUserUUID,
_notification_readyOn,_notification_expireOn,
_notification_content,_notification_subject,_notification_hook
);

call NOTIFICATION_notification(
'CREATE',1,
1,null,'APP',
null,null,1,null,null,
null,2,
'22-05-2020T01:25Z','22-05-2021T01:25Z',
'Content','_notification_subject','_notification_hook'
);


call NOTIFICATION_notification('GETAPP',1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
call NOTIFICATION_notification('GETSMS',1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
call NOTIFICATION_notification('GETEMAIL',1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);

call NOTIFICATION_notification('ACKNOWLEDGE',null,null,1,null,null,null,null,null,null,null,null,null,null,null,null,null);

call NOTIFICATION_notification('CLEANUP',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);

*/

DROP procedure IF EXISTS `NOTIFICATION_notification`;

DELIMITER $$
CREATE PROCEDURE `NOTIFICATION_notification` (
IN _action VARCHAR(100),
IN _userUUID char(32),
IN _notification_templateKey varchar(25),
IN _notificationId INT,
IN _notification_type VARCHAR(25),
IN _notification_toEmail VARCHAR(255),
IN _notification_toSMS VARCHAR(100),
IN _notification_toUserUUID char(32),
IN _notification_toGroupUUID char(32),
IN _notification_toAppUUID char(32),
IN _notification_fromAppUUID char(32),
IN _notification_fromUserUUID char(32),
IN _notification_readyOn VARCHAR(32),
IN _notification_expireOn VARCHAR(32),
IN _notification_content TEXT,
IN _notification_subject VARCHAR(255),
IN _notification_hook VARCHAR(255)
)
NOTIFICATION_notification: BEGIN

DECLARE _DEBUG INT DEFAULT 0;

DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%YT%h:%iZ';
DECLARE _notificationFoundId INT;
DECLARE _commaNeeded INT;

DECLARE _readyDate datetime;
DECLARE _expireDate datetime;


IF(_action ='GETAPP') THEN
	
	select * from notification_queue where notification_type='APP' 
    and notification_toUserUUID = _userUUID and notification_expireOn > now() and notification_readyOn < now()
    and notification_statusId =1
    union all
	select * from notification_queue where notification_type='APP' 
    and notification_toGroupUUID in ( select ugj_groupUUID from user_group_join where ugj_userUUID=_userUUID) 
    and notification_expireOn > now() and notification_readyOn < now()
    and notification_statusId =1;

ELSEIF(_action ='GETSMS') THEN

	select * from notification_queue where notification_type='SMS'and notification_expireOn > now() 
    and notification_readyOn < now() and notification_statusId =1;

ELSEIF(_action ='GETEMAIL') THEN

	select * from notification_queue where notification_type='EMAIL'and notification_expireOn > now() 
    and notification_readyOn < now() and notification_statusId =1;

ELSEIF(_action ='CREATE') THEN

	if (_notification_readyOn IS NOT NULL) THEN 
		set _readyDate = (STR_TO_DATE(_notification_readyOn, _dateFormat)); 
    ELSE 
		set _readyDate = now();
    END IF;
	
    if (_notification_expireOn IS NOT NULL) THEN 
		set _expireDate = (STR_TO_DATE(_notification_expireOn, _dateFormat));
    ELSE 
		set _expireDate = DATE_ADD(now() , INTERVAL 2 WEEK);
    END IF;

	-- attempt to find duplicates

	-- select userUUID into _notificationFoundId from `notification_queue` 
    -- where notification_subject=_notification_subject;

	IF (_notificationFoundId is null) THEN

		insert into `notification_queue` (
notification_type, 
notification_toEmail, notification_toSMS, notification_toGroupUUID, notification_toAppUUID, notification_toUserUUID, 
notification_fromAppUUID, notification_fromUserUUID, 
notification_readyOn, notification_expireOn, 
notification_statusId, notification_content, notification_subject, notification_hook, 
notification_createdTS   
		)
		values (
_notification_type, 
_notification_toEmail, _notification_toSMS, _notification_toGroupUUID, _notification_toAppUUID, _notification_toUserUUID, 
_notification_fromAppUUID, _notification_fromUserUUID, 
_readyDate, _expireDate, 
1, _notification_content, _notification_subject, _notification_hook, 
now()  
		);
	
    END IF;

ELSEIF(_action ='DELETE') THEN

		if (_notificationId is not null) then
			DELETE from notification_queue where notificationId = _notificationId;
		elseif (_notification_toUserUUID is not null) then
			DELETE from notification_queue where notification_toUserUUID = _notification_toUserUUID; -- deleted
		elseif (_notification_toGroupUUID is not null) then
			DELETE from notification_queue where notification_toGroupUUID = _notification_toGroupUUID; -- deleted
		END IF;
        
ELSEIF(_action ='CLEANUP') THEN

		DELETE from notification_queue where notification_expireOn < now();
		DELETE from notification_queue where notification_statusId = 3; -- deleted
        
ELSEIF(_action ='ACKNOWLEDGE' and _notificationId is not null) THEN

	update notification_queue set notification_statusId=3 where notificationId=_notificationId;
    
ELSE
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call NOTIFICATION_notification: _action is of type invalid';
	LEAVE NOTIFICATION_notification;
END IF;


IF (_DEBUG=1) THEN 
	select _action,_notification_type, 
_notification_toEmail, _notification_toSMS, _notification_toGroupUUID, _notification_toAppUUID, _notification_toUserUUID, 
_notification_fromAppUUID, _notification_fromUserUUID, 
_readyDate, _expireDate, 
_notification_statusId, _notification_content, _notification_subject, _notification_hook;
    
END IF;


END$$

DELIMITER ; 



-- ==================================================================

/* 
call USER_login(_action, _userId, _entityId, 
_USER_loginEmail, _USER_loginPW, _USER_loginEmailValidationCode, _USER_loginEnabled, 
_USER_loginPWReset);



call USER_login('ACCESS', null, 1, null, null, null, 0, null);
call USER_login('ACCESS', null, 1, 'mail@mail.com', null, null, 1, null);
call USER_login('VERIFYEMAIL', null, null, 'mail@mail.com', null, '5997055', null, null);
call USER_login('FORGOTPASSWORD', null, null, 'mail@mail.com', null, null, null, null);
call USER_login('RESETPASSWORD', null, 1, null, '12345', null, null, null);
call USER_login('LOGIN', null, null, 'mail@mail.com', '12345', null, null, null);
call USER_login('RESENDMFA', null, 1, null, null, null, null, null);
call USER_login('MFA', null, null, 'mail@mail.com', null, '2015', null, null);

*/


DROP procedure IF EXISTS `USER_login`;

DELIMITER $$
CREATE PROCEDURE `USER_login` (
IN _action VARCHAR(100),
IN _userId  char(32),

IN _entityId char(32),
IN _USER_loginEmail VARCHAR(100),
IN _USER_loginPW VARCHAR(100), 
IN _USER_loginEmailValidationCode VARCHAR(100), 
IN _USER_loginEnabled INT, 
IN _USER_loginPWReset INT
)
USER_login: BEGIN

DECLARE _USER_loginLast DATETIME;
DECLARE _USER_loginFailedAttempts INT;
DECLARE _USER_loginPWExpire DATETIME;
DECLARE _password varchar(100);
DECLARE _USER_loginEmailVerified DATETIME;

DECLARE _DISABLE_MFA INT default 1; -- 0 is enable MFA

DECLARE DEBUG INT DEFAULT 0;


IF(_action IS NULL ) THEN
  SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_login: _action can not be empty';
  LEAVE USER_login;
END IF;

IF(_action = 'LOGIN' and _USER_loginEmail is NOT null and _USER_loginPW is not null) THEN

  
    select userUUID,user_loginEnabled , user_loginPW, user_loginEmailVerified
    into _entityId, _USER_loginEnabled,_password,_USER_loginEmailVerified 
    from `user` where 
    user_loginEmail=_USER_loginEmail; 

  if (DEBUG=1) THEN select _action,_USER_loginEmail,_USER_loginPW,_entityId, _USER_loginEnabled,_password,_USER_loginEmailVerified; END IF;
    
  if (_entityId is null) THEN
    SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call USER_login: user not found';
      LEAVE USER_login;
    END IF;

  if (_USER_loginEnabled =0) THEN
      SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call USER_login: login not enabled';
      LEAVE USER_login;
    END IF;

  if (_USER_loginEmailVerified is null) THEN
      SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call USER_login: email not verified';
      LEAVE USER_login;
    END IF;

  if (_USER_loginPW <> _password) THEN
      SIGNAL SQLSTATE '41007'  SET MESSAGE_TEXT = 'call USER_login: password not correct';
      LEAVE USER_login;
    END IF;
    
    if (_DISABLE_MFA = 0) THEN
		select SESSION_generateAccessCode(4) into _USER_loginEmailValidationCode;
    

		  update `user` set user_loginLast=now(), user_loginSessionExpire= DATE_ADD( now(), INTERVAL 4 MINUTE ),
			user_loginEmailValidationCode=_USER_loginEmailValidationCode,
				user_loginFailedAttempts=0 where userUUID=_entityId;

		call NOTIFICATION_notification(
		'CREATE',null,
		'MFA',null,'SMS',
		null,_entityId,null,null,null,
		null,2,
		null,null,
		concat('You have 4 minutes to enter this access code: ',_USER_loginEmailValidationCode),
		concat('You have 4 minutes to enter this access code: ',_USER_loginEmailValidationCode),null
		);
		call NOTIFICATION_notification(
		'CREATE',null,
		'MFA',null,'EMAIL',
		_entityId,null,null,null,null,
		null,2,
		null,null,
		concat('You have 4 minutes to enter this access code: ',_USER_loginEmailValidationCode),
		concat('You have 4 minutes to enter this access code: ',_USER_loginEmailValidationCode),null
		);
 
		select _entityId as entityId, _USER_loginEmailValidationCode as accessCode, 4 as expiresInMinutes;

    ELSE 
    
        -- call ENTITY_session('CREATE', _entityId,null,@accessToken);
		select SESSION_generateSession(25) into _USER_loginEmailValidationCode;
        
        update `user` set user_loginEmailValidationCode=null,user_loginSession=_USER_loginEmailValidationCode,
         user_loginLast= now(), user_loginSessionExpire=DATE_ADD( now(), INTERVAL 8 HOUR )
        where userUUID=_entityId;
    
		select _entityId as entityId, _USER_loginEmailValidationCode as sessionToken;

	END IF;

     
    -- TODO, handle login in attempts and lockout in the future.    
    
ELSEIF(_action = 'MFA' and _USER_loginEmail is NOT null and _USER_loginEmailValidationCode is not null) THEN

    select userUUID, user_loginEnabled, user_loginPW,user_loginEmailVerified 
    into _entityId, _USER_loginEnabled,_password,_USER_loginEmailVerified 
    from `user` where 
    user_loginEmail=_USER_loginEmail and user_loginEmailValidationCode = _USER_loginEmailValidationCode
    and now() < user_loginSessionExpire;


  if (DEBUG=1) THEN select _action,_entityId, _USER_loginEnabled,_USER_loginEmailValidationCode,_USER_loginEmail; END IF;

  if (_entityId is not null) THEN
    
        -- call ENTITY_session('CREATE', _entityId,null,@accessToken);
		select SESSION_generateSession(25) into _USER_loginEmailValidationCode;
        
        update `user` set user_loginEmailValidationCode=null,user_loginSession=_USER_loginEmailValidationCode,
         user_loginLast= now(), user_loginSessionExpire=DATE_ADD( now(), INTERVAL 8 HOUR )
        where userUUID=_entityId;
    
    select _entityId as entityId, _USER_loginEmailValidationCode as sessionToken;
        
    else
      SIGNAL SQLSTATE '45004'  SET MESSAGE_TEXT = 'Your authentication code has expired or does not match.', MYSQL_ERRNO =12;
      LEAVE USER_login;
    
    END IF;

ELSEIF(_action = 'FORGOTPASSWORD' and _USER_loginEmail is not null) THEN

        -- set _USER_loginEmailValidationCode = SESSION_generateAccessCode(7);
    select userUUID, user_loginEnabled, `user_loginPW`,user_loginEmailVerified 
    into _entityId, _USER_loginEnabled,_USER_loginPW,_USER_loginEmailVerified 
    from `user` where 
      user_loginEmail=_USER_loginEmail and user_loginEnabled=1; 
    
        if (_entityId is not null and _USER_loginEnabled>0 and  _USER_loginEmailVerified is not null) THEN
    
        -- update contact set password=_USER_loginEmailValidationCode, emailValidationCode=_USER_loginEmailValidationCode where contactId=_entityId;
    -- call updateNotificationQueue('ADD',null,null,'PASSWORD_TEMPORARY','EMAIL',null,_entityId,null,0,null,null);
call NOTIFICATION_notification(
'CREATE',null,
'PASSWORD_TEMPORARY',null,'EMAIL',
_entityId,null,null,null,null,
null,2,
null,null,
concat('Your password is: ',_USER_loginPW, ' Please change once you log back in.'),
'Password Reminder',null
);
    
        END IF;

    if (DEBUG=1) THEN select _action,_entityId,_USER_loginPW,_USER_loginEnabled,_USER_loginEmailVerified; END IF;
    
ELSEIF(_action = 'RESETPASSWORD' and _entityId is not null and _USER_loginPW is not null) THEN
      
    select  user_loginEnabled, user_loginPW,user_loginEmailVerified 
    into  _USER_loginEnabled,_password,_USER_loginEmailVerified 
    from `user` where 
      userUUID=_entityId; 
    
        if (_entityId is not null and _USER_loginEnabled>0 and _USER_loginEmailVerified is not null) THEN

      update `user` set user_loginEmailValidationCode=null,
      `user_loginPW`= _USER_loginPW,
      user_loginFailedAttempts=0 where userUUID=_entityId;

    end if;
  -- update entity set USER_loginPW=_USER_loginPW, USER_loginPWReset=0  where entityId=_entityId;
    
    if (DEBUG=1) THEN select _action,_entityId,_password as oldPass,_USER_loginPW,_USER_loginEnabled,_USER_loginEmailVerified; END IF;

    -- call updateNotificationQueue('ADD',null,'MFA','EMAIL',null,_entityId,null,0,null,null);

ELSEIF(_action = 'ACCESS' and _USER_loginEnabled is NOT null and _entityId is not null ) THEN
    
    if (_USER_loginEnabled=0) THEN
 
		update `user` set user_loginEnabled=0, user_loginPWReset=1, user_loginPWExpire=now(), 
        user_loginEmailValidationCode=null,user_loginSession=null 
        where userUUID=_entityId;

    ELSE
        
		if (_USER_loginEmail is not null) then
			update `user` set user_loginEmail=_USER_loginEmail where userUUID=_entityId; 
        END IF;

		if (_USER_loginPW is not null) then
			update `user` set user_loginPW=_USER_loginPW where userUUID=_entityId; 
        END IF;

		select  user_loginEnabled, user_loginPW,user_loginEmail 
		into  _USER_loginEnabled,_password,_USER_loginEmail 
		from `user` where 
		  userUUID=_entityId; 

		if (_password is null) then
			update `user` set user_loginPW=SESSION_generateAccessCode(7) where userUUID=_entityId; 
        END IF;
		

		if (_USER_loginEmail is null) then
			  SIGNAL SQLSTATE '45007'  SET MESSAGE_TEXT = 'User login can not be enabled if email is not valid.', MYSQL_ERRNO =12;
			  LEAVE USER_login;
        END IF;
        
        set _USER_loginEmailValidationCode = SESSION_generateAccessCode(7);
        
		update `user` set user_loginEnabled=1, user_loginEmailValidationCode=_USER_loginEmailValidationCode where userUUID=_entityId;
		-- call updateNotificationQueue('ADD',null,null,'INVITELOGIN','EMAIL',null,_entityId,null,0,null,null);

call NOTIFICATION_notification(
'CREATE',null,
'INVITELOGIN',null,'EMAIL',
_entityId,null,null,null,null,
null,2,
null,null,
concat('Please verify your email: http://action=VERIFY'),
'Invitatin',null
);

  END IF;
    
  if (DEBUG=1) THEN select _action,_entityId,_USER_loginEnabled,_USER_loginEmailValidationCode; END IF;
    
ELSEIF(_action = 'RESENDMFA' and _entityId is not null) THEN

    set _USER_loginEmailValidationCode= SESSION_generateAccessCode(4) ;
 
  update `user` set user_loginLast=now(), user_loginSessionExpire= DATE_ADD( now(), INTERVAL 4 MINUTE ),
    user_loginEmailValidationCode=_USER_loginEmailValidationCode,
        user_loginFailedAttempts=0 where userUUID=_entityId;

    
call NOTIFICATION_notification(
'CREATE',null,
'MFA',null,'SMS',
null,_entityId,null,null,null,
null,2,
null,null,
concat('You have 4 minutes to enter this access code: ',_USER_loginEmailValidationCode),
concat('You have 4 minutes to enter this access code: ',_USER_loginEmailValidationCode),null
);
call NOTIFICATION_notification(
'CREATE',null,
'MFA',null,'EMAIL',
_entityId,null,null,null,null,
null,2,
null,null,
concat('You have 4 minutes to enter this access code: ',_USER_loginEmailValidationCode),
concat('You have 4 minutes to enter this access code: ',_USER_loginEmailValidationCode),null
);
    select _entityId as entityId, _USER_loginEmailValidationCode as accessCode, 4 as expiresInMinutes;

    if (DEBUG=1) THEN select _action,_entityId,_USER_loginEmailValidationCode; END IF;

    -- select _entityId as entityId, _USER_loginEmailValidationCode as validationCode;

ELSEIF(_action = 'VERIFYEMAIL' and _USER_loginEmailValidationCode is NOT null and _USER_loginEmail is not null) THEN

  select userUUID into _entityId from `user` where user_loginEmail=_USER_loginEmail
    and user_loginEmailValidationCode=_USER_loginEmailValidationCode;
    

  if (DEBUG=1) THEN select _action,_entityId,_USER_loginEmail,_USER_loginEmailValidationCode; END IF;

    if (_entityId is null) THEN
      SIGNAL SQLSTATE '45006'  SET MESSAGE_TEXT = 'Verification code not valid', MYSQL_ERRNO =12;
      LEAVE USER_login;
        END IF;

  update `user` set user_loginEmailVerified=now(),user_loginEmailValidationCode=null where  userUUID= _entityId;
        
END IF;

END$$


DELIMITER ;


-- ==================================================================

/*
call CHECKLIST_checklist(
_action,_userUUID,_customerUUID,
_checklistUUID, _historyUUID, _workorderUUID, 
_checklist_statusId,_checklist_name, _checklist_recommendedFrequency,_checklist_rulesJSON,
_checklist_itemUUID,_checklist_item_statusId,_checklist_item_sortOrder, 
_checklist_item_prompt, _checklist_item_type, _checklist_item_optionSetJSON, 
_checklist_item_successPrompt, _checklist_item_successRange
);


call CHECKLIST_checklist(
'GET_TEMPLATE','1',null,
'2b61b61eb4d141799a9560cccb109f59', null, null, null,null, null,null,null,null,null, null, null, null, null, null
);

call CHECKLIST_checklist(
'GET_HISTORY','1',null,
null, null, '2b61b61eb4d141799a9560cccb109f59', null,null, null,null,null,null,null, null, null, null, null, null
);


*/

DROP procedure IF EXISTS `CHECKLIST_checklist`;

DELIMITER $$
CREATE PROCEDURE `CHECKLIST_checklist` (
IN _action VARCHAR(100),
IN _userUUID char(32),
IN _customerUUID char(32),
IN _checklistUUID char(32), 
IN _historyUUID char(32), 
IN _workorderUUID char(32), 
IN _checklist_statusId INT, 
IN _checklist_name varchar(255), 
IN _checklist_recommendedFrequency varchar(25), -- [HOURLY,DAILY,WEEKLY,MONTHLY,YEARLY]
IN _checklist_rulesJSON TEXT,

IN _checklist_itemUUID char(32),
IN _checklist_item_statusId INT, -- 0,1 
IN _checklist_item_sortOrder INT, 
IN _checklist_item_prompt varchar(255), 
IN _checklist_item_type varchar(255), 
IN _checklist_item_optionSetJSON TEXT, 
IN _checklist_item_successPrompt varchar(255), 
IN _checklist_item_successRange varchar(255)
)
CHECKLIST_checklist: BEGIN

DECLARE _DEBUG INT DEFAULT 0;

DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%YT%h:%iZ';
DECLARE _foundId char(32);
DECLARE _commaNeeded INT;

DECLARE _readyDate datetime;
DECLARE _expireDate datetime;

IF(_action ='GET_HISTORY' and (_historyUUID is not null or _checklistUUID is not null or _checklist_itemUUID is not null)) THEN


		set  @l_sql = CONCAT('select c.*,i.* from checklist_history c ');
		set  @l_sql = CONCAT(@l_sql,'left join checklist_item_history i on (i.checklist_history_item_historyUUID = c.checklist_historyUUID) ');
		set  @l_sql = CONCAT(@l_sql,' where ');		

        if ( _historyUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,'c.checklist_historyUUID = \'', _historyUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if ( _checklistUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,'c.checklist_history_checklistUUID. = \'', _checklistUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if ( _checklist_itemUUID is not null) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'i.checklist_history_itemUUID = \'', _checklist_itemUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if ( _workorderUUID is not null) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'i.checklist_history_workorderUUID = \'', _workorderUUID,'\'');
            set _commaNeeded=1;
        END IF;

		set @l_sql = CONCAT(@l_sql,';');

        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

ELSEIF(_action ='GET_TEMPLATE' and (_checklistUUID is not null or _checklist_itemUUID is not null)) THEN
	
		set  @l_sql = CONCAT('select c.*,i.* from checklist c ');
		set  @l_sql = CONCAT(@l_sql,'left join checklist_item i on (i.checklist_item_checklistUUID = c.checklistUUID) ');
		set  @l_sql = CONCAT(@l_sql,' where ');		

        if ( _checklistUUID is not null) THEN
			set @l_sql = CONCAT(@l_sql,'c.checklistUUID = \'', _checklistUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if ( _checklist_itemUUID is not null) THEN
			if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
			set @l_sql = CONCAT(@l_sql,'i.checklist_itemUUID = \'', _checklist_itemUUID,'\'');
            set _commaNeeded=1;
        END IF;

		set @l_sql = CONCAT(@l_sql,' order by checklist_item_sortOrder;');

        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;
			
		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

ELSEIF(_action ='UPDATE_HISTORY') THEN

	-- 1. determine if history aready exists
    
    -- 1b. determine if workorder aready exists
		-- (note, this can be called from WO create as well.  Depends on from who the caller is
			-- from workorder create
            -- from start checklist 
    
    -- 2. if not, then copy a checklistUUID into a new history instance.
    
    -- 3. else update history.
		-- update mastor record if noted
        -- update item record if noted
        
    -- 4. if all items on the checklist are completed, then close the WO
    
    select _action;
        
ELSEIF(_action ='UPDATE_TEMPLATE') THEN

	-- 1. update template
    
	if (_notification_readyOn IS NOT NULL) THEN 
		set _readyDate = (STR_TO_DATE(_notification_readyOn, _dateFormat)); 
    ELSE 
		set _readyDate = now();
    END IF;
	
    if (_notification_expireOn IS NOT NULL) THEN 
		set _expireDate = (STR_TO_DATE(_notification_expireOn, _dateFormat));
    ELSE 
		set _expireDate = DATE_ADD(now() , INTERVAL 2 WEEK);
    END IF;




ELSEIF(_action ='PASS_CHECKLIST') THEN

	-- 1. pass checklist
    -- 2. update/close workorder

    select _action;
    
ELSEIF(_action ='FAIL_CHECKLIST') THEN

	-- 1. mark as failed, no further action
    -- 2. update/close workorder
    select _action;
    
ELSEIF(_action ='FAIL_CHECKLIST_CREATEWO') THEN

	-- 1. create WO, assigned to userId with asset and other description filled out
    -- Return data to allow WO to be pulled up with pre-defined data.
    select _action;
	

ELSEIF(_action ='DELETE') THEN

	-- 1. if delete of a checklist history, then make sure wo is deleted.
    
    select _action;
        
ELSE
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CHECKLIST_checklist: _action is of type invalid';
	LEAVE CHECKLIST_checklist;
END IF;


IF (_DEBUG=1) THEN 
	select _action,_notification_type, 
_notification_toEmail, _notification_toSMS, _notification_toGroupUUID, _notification_toAppUUID, _notification_toUserUUID, 
_notification_fromAppUUID, _notification_fromUserUUID, 
_readyDate, _expireDate, 
_notification_statusId, _notification_content, _notification_subject, _notification_hook;
    
END IF;


END$$

DELIMITER ; 




