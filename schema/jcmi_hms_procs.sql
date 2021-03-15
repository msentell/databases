-- ==================================================================
-- call IMAGES_getImageLayer('LOCATION',1,1,1,1);
-- call IMAGES_getImageLayer('ASSET',1,1,1,1);
-- call IMAGES_getImageLayer('ASSET-PART',1,1,1,1);
use jcmi_hms;

DROP procedure IF EXISTS `IMAGES_getImageLayer`;

DELIMITER $$
CREATE PROCEDURE IMAGES_getImageLayer(IN _action VARCHAR(100),
                                      IN _customerId VARCHAR(36),
                                      IN _userId VARCHAR(36),
                                      IN _startingPoint INT,
                                      IN _id VARCHAR(36))
IMAGES_getImageLayer:
BEGIN

	DECLARE _startLocationUUID varchar(100);

    IF (_id is NULL OR _id = '') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid value id';
    ELSEIF (_action is NULL OR _action = '') THEN
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
		If (_id ='-1') THEN
						SELECT user_profile_locationUUID INTO _startLocationUUID FROM user_profile WHERE user_profile_userUUID = _userId;
            IF (_startLocationUUID is null) THEN
				SELECT locationUUID INTO _startLocationUUID
                FROM location
                WHERE location_customerUUID = _customerId
                AND location_isPrimary = 1
                LIMIT 1;
			END IF;
            If (_startLocationUUID is not null) THEN
				SELECT loc.*
                from location loc
                where loc.location_customerUUID = _customerId
                AND loc.location_isPrimary = _startingPoint
                AND loc.locationUUID = _startLocationUUID;
            END IF;

        ELSEIF (_startingPoint is not null) THEN

            SELECT loc.*
            from location loc
            where loc.location_customerUUID = _customerId
              AND loc.location_isPrimary = _startingPoint
              AND loc.locationUUID = _id;

        ELSE

            SELECT loc.*
            from location loc
            where loc.locationUUID = _id;

        END IF;

    ELSEIF (_action = 'ASSET') THEN

        select a.*, p.*, pt.*
        from asset a
                 left join asset_part p on (a.asset_partUUID = p.asset_partUUID)
                 left join part_template pt on (p.asset_part_template_part_sku = pt.part_sku)
        where assetUUID = _id;

    ELSEIF (_action = 'ASSET-PART') THEN

        select a.*,b.part_diagnosticUUID as part_dignosticUUID  from
        asset_part a left join part_template b on (a.asset_part_template_part_sku = b.part_sku)
        where a.asset_partUUID = _id;

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
CREATE PROCEDURE `DIAGNOSTIC_tree`(IN _action VARCHAR(100),
                                   IN _userUUID VARCHAR(100),
                                   IN _diagnosticUUID VARCHAR(100),
                                   IN _diagnostic_statusId INT,
                                   IN _diagnostic_name VARCHAR(100),
                                   IN _diagnostic_description VARCHAR(255),
                                   IN _diagnostic_startNodeUUID VARCHAR(255))
DIAGNOSTIC_tree:
BEGIN
    DECLARE commaNeeded INT DEFAULT 0;

    DECLARE DEBUG INT DEFAULT 0;

    IF (_action IS NULL) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: _action can not be empty';
        LEAVE DIAGNOSTIC_tree;
    END IF;

    IF (_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: _userUUID missing';
        LEAVE DIAGNOSTIC_tree;
    END IF;

    IF (_action = 'GET') THEN

        SET @l_SQL = 'SELECT * FROM diagnostic_tree WHERE diagnostic_statusId = 1';

        IF (_diagnosticUUID IS NOT NULL) THEN
            IF (commaNeeded > 0) THEN set @l_sql = CONCAT(@l_sql, ' AND '); END IF;
            SET @l_SQL = CONCAT(@l_SQL, ' diagnosticUUID =\'', _diagnosticUUID, '\'');
            set commaNeeded = 1;
        END IF;

        IF (_diagnostic_startNodeUUID IS NOT NULL) THEN
            IF (commaNeeded > 0) THEN set @l_sql = CONCAT(@l_sql, ' AND '); END IF;
            SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_startNodeUUID =\'', _diagnostic_startNodeUUID, '\'');
            set commaNeeded = 1;
        END IF;

        IF (_diagnostic_name IS NOT NULL) THEN
            IF (commaNeeded > 0) THEN set @l_sql = CONCAT(@l_sql, ' AND '); END IF;
            SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_name =\'', _diagnostic_name, '\'');
            set commaNeeded = 1;
        END IF;

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF (_action = 'CREATE') THEN

        IF (DEBUG = 1) THEN
            select _action,
                   _userUUID,
                   _diagnosticUUID,
                   _diagnostic_statusId,
                   _diagnostic_name,
                   _diagnostic_description,
                   _diagnostic_startNodeUUID;
        END IF;

        IF (_diagnosticUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: diagnosticUUID missing';
            LEAVE DIAGNOSTIC_tree;
        END IF;

        insert into diagnostic_tree
        (diagnosticUUID, diagnostic_statusId, diagnostic_name, diagnostic_description, diagnostic_startNodeUUID,
         diagnostic_createdByUUID, diagnostic_updatedByUUID, diagnostic_updatedTS, diagnostic_createdTS,
         diagnostic_deleteTS)
        values (_diagnosticUUID, 1, _diagnostic_name, _diagnostic_description, _diagnostic_startNodeUUID,
                _userUUID, _userUUID, now(), now(), null);

    ELSEIF (_action = 'UPDATE') THEN

        IF (_diagnosticUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: diagnosticUUID missing';
            LEAVE DIAGNOSTIC_tree;
        END IF;


        set @l_sql =
                CONCAT('update diagnostic_tree set diagnostic_updatedTS=now(), diagnostic_updatedByUUID=\'', _userUUID,
                       '\'');

        if (_diagnostic_name is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_name = \'', _diagnostic_name, '\'');
        END IF;
        if (_diagnostic_description is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_description = \'', _diagnostic_description, '\'');
        END IF;
        if (_diagnostic_startNodeUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_startNodeUUID = \'', _diagnostic_startNodeUUID, '\'');
        END IF;
        if (_diagnostic_statusId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_statusId = ', _diagnostic_statusId);
        END IF;

        set @l_sql = CONCAT(@l_sql, ' where diagnosticUUID = \'', _diagnosticUUID, '\';');

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


    ELSEIF (_action = 'DELETE') THEN

        IF (DEBUG = 1) THEN select _action, _diagnosticUUID; END IF;

        IF (_diagnosticUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_tree: _diagnosticUUID missing';
            LEAVE DIAGNOSTIC_tree;
        END IF;

        update diagnostic_tree
        set diagnostic_deleteTS=now(),
            diagnostic_statusId=2,
            diagnostic_updatedByUUID=_userUUID
        where diagnosticUUID = _diagnosticUUID;
        -- TBD, figure out what cleanup may be involved

    END IF;

END$$


DELIMITER ;
-- ==================================================================

-- call DIAGNOSTIC_node(action,userId,diagnostic_nodeUUID, diagnostic_node_diagnosticUUID, diagnostic_node_statusId,diagnostic_node_title, diagnostic_node_prompt, diagnostic_node_optionPrompt, diagnostic_node_hotSpotJSON, diagnostic_node_imageSetJSON, diagnostic_node_optionSetJSON,diagnostic_node_warning,diagnostic_node_warningSeverity,diagnostic_node_fabricId);
-- call DIAGNOSTIC_node('GETNODE', '5d84cb09d6fb473baba1b8914fc', '633a54011d76432b9fa18b0b6308c189', null,null, null, null, null, null, null,null,null,null,null,null);
-- call DIAGNOSTIC_node('GET', '1', '5d84cb09d6fb473baba1b8914fc', '633a54011d76432b9fa18b0b6308', null,null, null, null, null, null, null,null,null,null,null,null);
-- call DIAGNOSTIC_node('CREATE', '1', '10', '633a54011d76432b9fa18b0b6308c189', null,'diagnostic_node_title', 'diagnostic_node_prompt', 'diagnostic_node_optionPrompt', 'diagnostic_node_hotSpotJSON', 'diagnostic_node_imageSetJSON', 'diagnostic_node_optionSetJSON',null,null,null);
-- call DIAGNOSTIC_node('UPDATE', '1', '10', '633a54011d76432b9fa18b0b6308c189', null,'diagnostic_node_title2', 'diagnostic_node_prompt2', 'diagnostic_node_optionPrompt', 'diagnostic_node_hotSpotJSON', 'diagnostic_node_imageSetJSON', 'diagnostic_node_optionSetJSON','diagnostic_node_warning',diagnostic_node_warningSeverity,null);
-- call DIAGNOSTIC_node('DELETE', '1',  '10', null, null,null, null, null, null, null, null,null,null,null);
-- call DIAGNOSTIC_node('UPDATE','1','5d84cb09d6fb473baba1b8914fc', '633a54011d76432b9fa18b0b6308', null ,'testing_tiltle rtghjy', 'diagnosticnodeprompt', 'diagnostic_node_optionPrompt', '[{"coordinates":[{}],"color":"red","forwardId":"1599760999552"}]', 'https://jcmi.sfo2.digitaloceanspaces.com/demodata/Hendrix/diagnostics/Heating1.JPG', 'false','hello','hijky',null);
-- call DIAGNOSTIC_node('GET_ASSETPARTS','1',null, '633a54011d76432b9fa18b0b6308c189', null,null, null, null, null, null, null,null,null,null);
-- call DIAGNOSTIC_node('GET_AVAILABLE_ASSETPARTS','1',null, '633a54011d76432b9fa18b0b6308c189', null,null, null, null, null, null, null,null,null,null);
-- call DIAGNOSTIC_node('UPDATE', '1', '10', null, null,null, null, null, null, 'new img url', null,null,null,'new fab id');

DROP procedure IF EXISTS `DIAGNOSTIC_node`;


DELIMITER $$
CREATE PROCEDURE `DIAGNOSTIC_node`(IN _action VARCHAR(100),
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
                                   IN _diagnostic_node_warningSeverity VARCHAR(45),
                                   IN _diagnostic_node_fabricId CHAR(36))
DIAGNOSTIC_node:
BEGIN
    DECLARE commaNeeded INT DEFAULT 0;

    DECLARE DEBUG INT DEFAULT 0;

    IF (_action IS NULL) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _action can not be empty';
        LEAVE DIAGNOSTIC_node;
    END IF;

    IF (_action = 'GETNODE') THEN

        If (_diagnostic_node_diagnosticUUID is not null and _diagnostic_nodeUUID is null) THEN

            SELECT n.*, d.*
            from diagnostic_tree d
                     left join diagnostic_node n on (d.diagnosticUUID = n.diagnostic_node_diagnosticUUID and
                                                     d.diagnostic_startNodeUUID = n.diagnostic_nodeUUID)
            where diagnosticUUID = _diagnostic_node_diagnosticUUID;

        ELSEIF (_diagnostic_nodeUUID is not null) THEN

            SELECT n.*
            from diagnostic_node n
                 -- left join diagnostic_tree d on (d.diagnosticUUID=n.diagnostic_node_diagnosticUUID)
            where diagnostic_nodeUUID = _diagnostic_nodeUUID;

        END IF;

    ELSE
     IF (_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _userUUID missing';
        LEAVE DIAGNOSTIC_node;
    END IF;

    IF (_action = 'GET') THEN

        SET @l_SQL = 'SELECT * FROM diagnostic_node ';

        IF (_diagnostic_nodeUUID IS NOT NULL or _diagnostic_node_diagnosticUUID IS NOT NULL or
            _diagnostic_node_title IS NOT NULL) THEN
            SET @l_SQL = CONCAT(@l_SQL, '  WHERE ');
        END IF;

        IF (_diagnostic_nodeUUID IS NOT NULL) THEN
            IF (commaNeeded > 0) THEN set @l_sql = CONCAT(@l_sql, ' AND '); END IF;
            SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_nodeUUID =\'', _diagnostic_nodeUUID, '\'');
            set commaNeeded = 1;
        END IF;

        IF (_diagnostic_node_diagnosticUUID IS NOT NULL) THEN
            IF (commaNeeded > 0) THEN set @l_sql = CONCAT(@l_sql, ' AND '); END IF;
            SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_node_diagnosticUUID =\'', _diagnostic_node_diagnosticUUID, '\'');
            set commaNeeded = 1;
        END IF;

        IF (_diagnostic_node_title IS NOT NULL) THEN
            IF (commaNeeded > 0) THEN set @l_sql = CONCAT(@l_sql, ' AND '); END IF;
            SET @l_SQL = CONCAT(@l_SQL, ' diagnostic_node_title like \'', '%', _diagnostic_node_title, '%', '\'');
            set commaNeeded = 1;
        END IF;

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF (_action = 'GET_ASSETPARTS') THEN

     SET @l_SQL = 'SELECT * FROM (SELECT asset_partUUID as id,asset_part_statusId as statusId,asset_part_template_part_sku as template_id,asset_part_name as name,asset_part_diagnosticUUID as diagnosticUUID ,''customer-parts'' as type FROM asset_part
	UNION All SELECT null as id,part_statusId as statusId,part_sku as template_id,part_name as name,part_diagnosticUUID as diagnosticUUID,''factory-part'' as type from part_template) assert_details where template_id is not null and statusId = 1';

    IF (_diagnostic_node_diagnosticUUID IS NOT NULL) THEN
            SET @l_SQL = CONCAT(@l_SQL, ' and diagnosticUUID =\'', _diagnostic_node_diagnosticUUID, '\'');
    END IF;

    SET @l_SQL = CONCAT(@l_SQL,';');

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF (_action = 'GET_AVAILABLE_ASSETPARTS') THEN

    IF (_diagnostic_node_diagnosticUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _diagnostic_node_diagnosticUUID missing';
        LEAVE DIAGNOSTIC_node;
    ELSE
        SET @l_SQL = 'SELECT * FROM (SELECT asset_partUUID as id,asset_part_statusId as statusId,asset_part_template_part_sku as template_id,asset_part_name as name,asset_part_diagnosticUUID as diagnosticUUID ,''customer-parts'' as type FROM asset_part
	    UNION All SELECT null as id,part_statusId as statusId,part_sku as template_id,part_name as name,part_diagnosticUUID as diagnosticUUID,''factory-part'' as type from part_template) assert_details where template_id is not null and statusId = 1';

        SET @l_SQL = CONCAT(@l_SQL, ' and diagnosticUUID !=\'', _diagnostic_node_diagnosticUUID, '\';');

            PREPARE stmt FROM @l_SQL;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

    END IF;

    ELSEIF (_action = 'CREATE') THEN

        IF (DEBUG = 1) THEN
            select _action,
                   _userUUID,
                   _diagnostic_nodeUUID,
                   _diagnostic_node_diagnosticUUID,
                   1,
                   _diagnostic_node_title,
                   _diagnostic_node_prompt,
                   _diagnostic_node_optionPrompt,
                   _diagnostic_node_hotSpotJSON,
                   _diagnostic_node_imageSetJSON,
                   _diagnostic_node_optionSetJSON;
        END IF;

        IF (_diagnostic_nodeUUID IS NULL or _diagnostic_node_diagnosticUUID is null) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT =
                    'call _diagnostic_nodeUUID: _diagnostic_nodeUUID or _diagnostic_node_diagnosticUUID missing';
            LEAVE DIAGNOSTIC_node;
        END IF;

        insert ignore into diagnostic_node
        (diagnostic_nodeUUID, diagnostic_node_diagnosticUUID, diagnostic_node_statusId,
         diagnostic_node_title, diagnostic_node_prompt, diagnostic_node_optionPrompt,
         diagnostic_node_hotSpotJSON, diagnostic_node_imageSetJSON, diagnostic_node_optionSetJSON,
         diagnostic_node_createdByUUID, diagnostic_node_updatedByUUID, diagnostic_node_updatedTS,
         diagnostic_node_createdTS, diagnostic_node_deleteTS)
        values (_diagnostic_nodeUUID, _diagnostic_node_diagnosticUUID, 1,
                _diagnostic_node_title, _diagnostic_node_prompt, _diagnostic_node_optionPrompt,
                _diagnostic_node_hotSpotJSON, _diagnostic_node_imageSetJSON, _diagnostic_node_optionSetJSON,
                _userUUID, _userUUID, now(), now(), null);

    ELSEIF (_action = 'UPDATE') THEN

        IF (_diagnostic_nodeUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _diagnostic_nodeUUID missing';
            LEAVE DIAGNOSTIC_node;
        END IF;

        set @l_sql =
                CONCAT('update diagnostic_node set diagnostic_node_updatedTS=now(), diagnostic_node_updatedByUUID=\'',
                       _userUUID, '\'');

        if (_diagnostic_node_diagnosticUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_diagnosticUUID = \'', _diagnostic_node_diagnosticUUID, '\'');
        END IF;
        if (_diagnostic_node_title is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_title = \'', _diagnostic_node_title, '\'');
        END IF;
        if (_diagnostic_node_prompt is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_prompt = \'', _diagnostic_node_prompt, '\'');
        END IF;
        if (_diagnostic_node_statusId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_statusId = ', _diagnostic_node_statusId);
        END IF;
        if (_diagnostic_node_optionPrompt is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_optionPrompt = \'', _diagnostic_node_optionPrompt, '\'');
        END IF;
        if (_diagnostic_node_hotSpotJSON is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_hotSpotJSON = \'', _diagnostic_node_hotSpotJSON, '\'');
        END IF;
        if (_diagnostic_node_imageSetJSON is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_imageSetJSON = \'', _diagnostic_node_imageSetJSON, '\'');
        END IF;
        if (_diagnostic_node_optionSetJSON is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_optionSetJSON = \'', _diagnostic_node_optionSetJSON, '\'');
        END IF;
        if (_diagnostic_node_warning is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_warning= \'', _diagnostic_node_warning, '\'');
        END IF;
        if (_diagnostic_node_warningSeverity is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_warningSeverity= \'', _diagnostic_node_warningSeverity, '\'');
        END IF;
        if (_diagnostic_node_fabricId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',diagnostic_node_fabricId= \'', _diagnostic_node_fabricId, '\'');
        END IF;

        set @l_sql = CONCAT(@l_sql, ' where diagnostic_nodeUUID = \'', _diagnostic_nodeUUID, '\';');

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


    ELSEIF (_action = 'DELETE') THEN

        IF (DEBUG = 1) THEN select _action, _diagnostic_nodeUUID; END IF;

        IF (_diagnostic_nodeUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call DIAGNOSTIC_node: _diagnostic_nodeUUID missing';
            LEAVE DIAGNOSTIC_node;
        END IF;

        update diagnostic_node
        set diagnostic_node_deleteTS=now(),
            diagnostic_node_statusId=2,
            diagnostic_node_updatedByUUID=_userUUID
        where diagnostic_nodeUUID = _diagnostic_nodeUUID;
        -- TBD, figure out what cleanup may be involved

    END IF;
END IF;
END$$

-- ==================================================================
-- call DIAGNOSTIC_getNode(null,1,1,'633a54011d76432b9fa18b0b6308c189',null); -- will get the starting tree node
-- call DIAGNOSTIC_getNode(null,1,1,null,'1834487471bb4cccbaa8b0dc1cedc463'); -- will get the next node


DROP procedure IF EXISTS `DIAGNOSTIC_getNode`;

DELIMITER $$
CREATE PROCEDURE DIAGNOSTIC_getNode(IN _action VARCHAR(100),
                                    IN _customerId CHAR(36),
                                    IN _userId CHAR(36),
                                    IN _diagnosticId CHAR(36),
                                    IN _nodeId CHAR(36))
DIAGNOSTIC_getNode:
BEGIN

    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT =
            'call DIAGNOSTIC_getNode: deprecated use: call DIAGNOSTIC_node(GET, 1, null, 633a54011d76432b9fa18b0b6308c189, null,null, null, null, null, null, null,null); ';
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
-- call BUTTON_options('ASSET-PART','5eb71fddbe04419bb7fda53fb0ef31ae','CONTACT|CHAT|STARTCHECKLIST|ADDLOG');

DROP procedure IF EXISTS `BUTTON_options`;

DELIMITER $$
CREATE PROCEDURE BUTTON_options(IN _action VARCHAR(100),
                                IN _id CHAR(36),
                                IN _otherOptions varchar(255))
BUTTON_options:
BEGIN

    DECLARE _partId varchar(100);

    If (_action = 'ASSET') THEN
		select a.asset_partUUID into _partId from asset a where assetUUID = _id;
	ELSEIF (_action = 'ASSET-PART') THEN
		set _partId=_id;
    END IF;

    If (_partId IS NOT NULL) THEN
		-- TODO, select security to turn on/off
		-- 'CONTACT,CHAT,STARTCHECKLIST,ADDLOG'
		select ap.asset_partUUID,ap.asset_part_diagnosticUUID,pt.part_diagnosticUUID,
			(case when (asset_part_isPurchasable = 1 is not null and locate('ASSET-PART', _action) > 0) then 1 else 0 end)     BUTTON_viewOrderParts,
			(case when ap.asset_part_diagnosticUUID is not null or pt.part_diagnosticUUID is not null then 1 else 0 end)       BUTTON_diagnoseAProblem,
			(case when(select count(apaj_asset_partUUID)
            from asset_part_attachment_join
            where apaj_asset_partUUID = ap.asset_partUUID
            limit 1)> 0 THEN 1 ELSE 0 END)                                                                 as BUTTON_viewManual,
			(case when (select count(pkj_part_partUUID)
            from part_knowledge_join
            where pkj_part_partUUID = pt.part_sku
            limit 1) > 0 THEN 1 ELSE 0 END)                                          as BUTTON_qa,
			-- (case when(select count(wapj_asset_partUUID)
            -- from workorder_asset_part_join
            -- where wapj_asset_partUUID = ap.asset_partUUID
            -- limit 1)> 0 THEN 1 ELSE 0 END)                                                                 as BUTTON_serviceHistory,
			(case when (locate('CONTACT', _otherOptions) > 0 and locate('ASSET-PART', _action) > 0) THEN 1 ELSE 0 END)        as BUTTON_contactCheckMaster,
			(case when locate('CHAT', _otherOptions) > 0 THEN 1 ELSE 0 END)           as BUTTON_liveChat,
			(case when locate('STARTCHECKLIST', _otherOptions) > 0 THEN 1 ELSE 0 END) as BUTTON_startAChecklist,
            (case when  locate('WORK-ORDER', _otherOptions) > 0  THEN 1 ELSE 0 END) as 	 BUTTON_createWorkOrder,
			(case when locate('ADDLOG', _otherOptions) > 0 THEN 1 ELSE 0 END)         as BUTTON_addALogEntry,
           ap.*, pt.*
		from asset_part ap left join part_template pt on (ap.asset_part_template_part_sku = pt.part_sku)
		where asset_partUUID = _partId;
    END IF;

END$$

-- ==================================================================

/*
call WORKORDER_create(_action, _customerId,_userUUID
_workorderUUID,_workorder_locationUUID,_workorder_userUUID,_workorder_groupUUID,_workorder_assetUUID,
_workorder_checklistUUID,_workorder_checklistHistoryUUID,_workorder_status,_workorder_type,_workorder_name,_workorder_number,_workorder_details,
_workorder_actions,_workorder_priority,_workorder_dueDate,_workorder_completeDate,
_workorder_scheduleDate,_workorder_rescheduleDate,_workorder_frequency,_workorder_frequencyScope,_wapj_asset_partUUID,
_wapj_quantity,_monthlyRecurrType,monthlyRecuttValue
);

call WORKORDER_create('CREATE', 'a30af0ce5e07474487c39adab6269d5f',1,
UUID(),null,null,null,null,
'2b61b61eb4d141799a9560cccb109f59',null,null,null,null,null,null,
null,null,null,null,
'24-09-2020',null,5,'DAILY',null,
null, null, null);

call WORKORDER_create('CREATE','a30af0ce5e07474487c39adab6269d5f','2',
'1606299064282','1600957239770','2',null,'edfe4b13ffcf47e0afa5fc6d3cfe19b7',
'8090644719c64be4abd2ba78f915bf5d',null,null,null,
'ABC-01',null,'ABC-01',
null,'HIGH','31-01-2021',null,
'25-11-2020','25-11-2020','4','DAILY',null,
null,'Sunday,Monday,Tuesday', null, null
);

    */
DROP procedure IF EXISTS `WORKORDER_create`;


DELIMITER $$
CREATE PROCEDURE `WORKORDER_create` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _workorderUUID VARCHAR(100),
IN _workorder_locationUUID VARCHAR(100),
IN _workorder_userUUID VARCHAR(100),
IN _workorder_groupUUID VARCHAR(100),
IN _workorder_assetUUID VARCHAR(100),
IN _workorder_checklistUUID VARCHAR(100),
IN _workorder_checklistHistoryUUID VARCHAR(100),
IN _workorder_status varchar(100),
IN _workorder_type VARCHAR(100),
IN _workorder_name VARCHAR(100),
IN _workorder_number VARCHAR(100),
IN _workorder_details VARCHAR(100),
IN _workorder_actions TEXT,
IN _workorder_priority VARCHAR(100),
IN _workorder_dueDate VARCHAR(100),
IN _workorder_completeDate VARCHAR(100),
IN _workorder_scheduleDate VARCHAR(100),
IN _workorder_rescheduleDate VARCHAR(100),
IN _workorder_frequency INT,
IN _workorder_frequencyScope VARCHAR(100),
IN _wapj_asset_partUUID VARCHAR(100),
IN _wapj_quantity INT,
IN _daysToMaintain VARCHAR(100),
IN _monthlyRecurrType VARCHAR(50),
IN monthlyRecuttValue INT
)
WORKORDER_create: BEGIN

DECLARE _DEBUG INT DEFAULT 1;

DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%Y';
DECLARE _maxWO INT;
DECLARE _commaNeeded INT;
DECLARE _workorder_definition varchar(100);
DECLARE _checklist_historyUUID char(36);
DECLARE _workorder_tag varchar(100);
DECLARE strLen    INT DEFAULT 0;
DECLARE SubStrLen INT DEFAULT 0;
DECLARE _woDates varchar(5000);
DECLARE _date varchar(100);
DECLARE _update_workorderUUID VARCHAR(100);
DECLARE _workorder_scheduleDate_withTime VARCHAR(100);
DECLARE _workorder_dueDate_withTime VARCHAR(100);

IF(_action ='CREATE') THEN

    IF(_customerId IS NULL or _customerId = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_create: _customerId can not be empty';
        LEAVE WORKORDER_create;
    END IF;

    IF(_workorderUUID is NULL) THEN set _workorderUUID = UUID();END IF;

    -- RULES and CONVERSIONS
if (_workorder_completeDate IS NOT NULL) THEN set _workorder_completeDate = STR_TO_DATE(_workorder_completeDate, _dateFormat); END IF;
    if (_workorder_rescheduleDate IS NOT NULL) THEN set _workorder_rescheduleDate = STR_TO_DATE(_workorder_rescheduleDate, _dateFormat); END IF;

    if (_workorder_scheduleDate IS NOT NULL) THEN
        set _workorder_scheduleDate = STR_TO_DATE(_workorder_scheduleDate, _dateFormat);
    ELSE
        set _workorder_scheduleDate=DATE(now());
    END IF;

     if (_workorder_dueDate IS NOT NULL) THEN
        set _workorder_dueDate = STR_TO_DATE(_workorder_dueDate, _dateFormat);
    ELSE
        set _workorder_dueDate=DATE(now());
    END IF;

    if (_workorder_userUUID is null) THEN set  _workorder_userUUID =_userUUID; END IF;

    if(_workorder_name is null) then
        select checklist_name
        into _workorder_name
        from checklist where checklistUUID = _workorder_checklistUUID;
    END IF;

    if(_workorder_details is null) then
        select checklist_name
        into _workorder_details
        from checklist where checklistUUID = _workorder_checklistUUID;
    END IF;

    if(_daysToMaintain is null) then
        IF (_workorder_frequencyScope = 'DAILY') then
         SET _daysToMaintain = 'Monday,Tuesday,Wednesday,Thursday,Friday';
        ELSEIF (_workorder_frequencyScope = 'WEEKLY' || _workorder_frequencyScope = 'MONTHLY') then
         SET _daysToMaintain = 'Monday';
        END IF;
    END IF;


  if (_workorder_frequency > 0) THEN
            if(_workorder_checklistUUID is not null) THEN
                select checklist_name,'CHECKLIST'
                into _workorder_actions,_workorder_type
                from checklist where checklistUUID = _workorder_checklistUUID;
            ELSE
                select 'action', 'CHECKLIST' into _workorder_actions, _workorder_type;
            END IF;

    if (_workorder_frequencyScope = 'DAILY') THEN

        select group_concat(dates) INTO _woDates from (
        select  DATE_FORMAT(v.selected_date, _dateFormat) as dates, row_number() over (order by selected_date) as row_num from
        (select adddate('1970-01-01',t4*10000 + t3*1000 + t2*100 + t1*10 + t0) selected_date from
        (select 0 t0 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t0,
        (select 0 t1 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t1,
        (select 0 t2 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t2,
        (select 0 t3 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t3,
        (select 0 t4 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t4) v
        where selected_date between _workorder_scheduleDate and  _workorder_completeDate
        and FIND_IN_SET (dayname(selected_date),_daysToMaintain)
        order by v.selected_date ) s  where (row_num-1) % _workorder_frequency  = 0; --  (row_num -1) is bcz it should consider from today.. elso it will not
			IF (_DEBUG=1) THEN select 'created daily,',_woDates, _workorder_completeDate, _workorder_scheduleDate,_daysToMaintain, _workorder_frequency; END IF;
    ELSEIF (_workorder_frequencyScope = 'WEEKLY') THEN

        select group_concat(dates) INTO _woDates from (
        select DATE_FORMAT(v.selected_date, _dateFormat) as dates, ROW_NUMBER() OVER (order by v.selected_date ) as row_num  from
        (select adddate('1970-01-01',t4*10000 + t3*1000 + t2*100 + t1*10 + t0) selected_date from
        (select 0 t0 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t0,
        (select 0 t1 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t1,
        (select 0 t2 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t2,
        (select 0 t3 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t3,
        (select 0 t4 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t4 ) as v
        where selected_date between _workorder_scheduleDate and _workorder_completeDate and FIND_IN_SET (dayname(v.selected_date), _daysToMaintain)  order by v.selected_date ) s where (s.row_num -1) % _workorder_frequency = 0;


    ELSEIF (_workorder_frequencyScope = 'MONTHLY') THEN
		IF(_monthlyRecurrType = 'DAY') then
				select group_concat(dates) INTO _woDates from (
				select DATE_FORMAT(v.selected_date, _dateFormat) as dates, ROW_NUMBER() over (order by selected_date) as row_num from
				(select adddate('1970-01-01',t4*10000 + t3*1000 + t2*100 + t1*10 + t0) selected_date  from
				(select 0 t0 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t0,
				(select 0 t1 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t1,
				(select 0 t2 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t2,
				(select 0 t3 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t3,
				(select 0 t4 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t4) v
				where selected_date between _workorder_scheduleDate and _workorder_completeDate
				and FIND_IN_SET (dayname(selected_date), _daysToMaintain) and  (FLOOR((DAYOFMONTH(selected_date) - 1) / 7) + 1) =  monthlyRecuttValue order by v.selected_date
				) s  where (s.row_num - 1) % _workorder_frequency = 0 ; -- (s.row_num - 1) is bcz it will consider from today.. elso no
			ELSE
				select group_concat(dates) INTO _woDates from (
				select DATE_FORMAT(v.selected_date, _dateFormat) as dates, ROW_NUMBER() over (order by selected_date) as row_num from
				(select adddate('1970-01-01',t4*10000 + t3*1000 + t2*100 + t1*10 + t0) selected_date  from
				(select 0 t0 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t0,
				(select 0 t1 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t1,
				(select 0 t2 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t2,
				(select 0 t3 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t3,
				(select 0 t4 union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t4) v
				where selected_date between _workorder_scheduleDate and _workorder_completeDate
				and  DAYOFMONTH(selected_date) =  monthlyRecuttValue order by v.selected_date
				) s  where (s.row_num - 1) % _workorder_frequency = 0 ; -- (s.row_num - 1) is bcz it will consider from today.. elso no
			END IF;
    END IF;

        set _workorderUUID = null; -- force creating of new WO's

    ELSE -- just create one.  maybe turn the WO creation into a loop, and the above calculates the loop

        set _woDates =  DATE_FORMAT(STR_TO_DATE(_workorder_scheduleDate, '%Y-%m-%d'), _dateFormat);

    END IF;

    IF (_DEBUG=1) THEN select _action,_woDates; END IF;


    set _workorder_definition = 'CM-';
    IF(_workorder_checklistUUID is not null) THEN
		set _workorder_tag = concat(_workorder_checklistUUID,':',_workorder_frequencyScope,':',_workorder_frequency);
	ELSE
    -- added unique id after checklist , as this could be dupilicated
		set _workorder_tag = concat('Checklist:', UUID(),':',_workorder_frequencyScope,':',_workorder_frequency);
	END IF;
    IF (_workorder_type = 'CHECKLIST') THEN
        set _workorder_status = 'IN_PROGRESS';
    ELSE
        set _workorder_status = 'Open';
    END IF;


            IF (CHAR_LENGTH(_woDates) > 0) THEN
            do_this:
               LOOP
                 SET strLen = CHAR_LENGTH(_woDates);

                 SET _date=SUBSTRING_INDEX(_woDates, ',', 1);


    -- TODO get configuration for workorder naming
    -- excluding first 3 charecters(CM-) and convert ti integer and get max number of workorder
    SELECT MAX(CAST(SUBSTRING(workorder_number, 4, length(workorder_number)-3) AS UNSIGNED))+1 into _maxWO FROM workorder;
    set _workorder_number = CONCAT(_workorder_definition,_maxWO);
    set _workorder_scheduleDate = STR_TO_DATE(_date, _dateFormat);
    if (_workorderUUID is null) THEN set _workorderUUID=UUID(); END IF;
    if (_workorder_dueDate IS NULL) THEN set _workorder_dueDate = STR_TO_DATE(_date, _dateFormat); END IF;
    if (_workorder_priority is null) THEN set _workorder_priority='MEDIUM'; END IF;

    set _workorder_scheduleDate_withTime = ADDTIME(STR_TO_DATE(_date, '%d-%m-%Y %H:%m'),'23:59');
    set _workorder_dueDate_withTime = ADDTIME(STR_TO_DATE(_date, '%d-%m-%Y %H:%m'),'23:59');

    -- based on frequencyScope and frequency, create 1-M WO's
    -- TODO
    insert into workorder (workorderUUID,
    workorder_customerUUID, workorder_locationUUID, workorder_userUUID, workorder_groupUUID,
    workorder_assetUUID, workorder_checklistUUID, workorder_checklistHistoryUUID, workorder_status, workorder_type,
    workorder_number, workorder_name, workorder_details, workorder_actions, workorder_priority,
    workorder_dueDate, workorder_scheduleDate,workorder_rescheduleDate, workorder_completeDate, workorder_frequency,
    workorder_frequencyScope,workorder_tag,
    workorder_createdByUUID, workorder_updatedByUUID, workorder_updatedTS, workorder_createdTS
    ) values (_workorderUUID,
    _customerId, _workorder_locationUUID, _workorder_userUUID, _workorder_groupUUID,
    _workorder_assetUUID, _workorder_checklistUUID, _workorder_checklistHistoryUUID, _workorder_status, _workorder_type,
    _workorder_number, _workorder_name, _workorder_details, _workorder_actions, _workorder_priority,
    _workorder_dueDate_withTime, _workorder_scheduleDate_withTime, _workorder_rescheduleDate, _workorder_completeDate, _workorder_frequency,
    _workorder_frequencyScope, _workorder_tag,
    _userUUID, _userUUID, now(), now()
    );

IF (_DEBUG=1) THEN
    select _action,_workorderUUID,
    _customerId, _workorder_locationUUID, _workorder_userUUID, _workorder_groupUUID,
    _workorder_assetUUID, _workorder_checklistUUID, _workorder_status, _workorder_type,
    _workorder_number, _workorder_name, _workorder_details, _workorder_actions, _workorder_priority,
    _workorder_dueDate,_workorder_scheduleDate, _workorder_rescheduleDate, _workorder_completeDate, _workorder_frequency,
    _workorder_frequencyScope, _workorder_tag
    _userUUID;
END IF;





                 SET SubStrLen = CHAR_LENGTH(SUBSTRING_INDEX(_woDates, ',', 1))+2;
                 SET _woDates = MID(_woDates, SubStrLen, strLen);

                 IF _woDates = '' or _woDates is null THEN
                   LEAVE do_this;
				 ELSE
				   set _workorderUUID=null;
                 END IF;

             END LOOP do_this;

            END IF;


    -- create notification
    if (_workorder_userUUID <> _userUUID) THEN

        call NOTIFICATION_notification(
        'CREATE',_userUUID,
        null,null,'APP',
        null,null,_workorder_userUUID,null,null,
        null,_userUUID,_workorderUUID,
        null,null,
        CONCAT('Workorder ',_workorder_number ,' has been assigned to you'),CONCAT('New Workorder ',_workorder_number),'_notification_hook',
        _workorder_assetUUID,'MEDIUM',null
        );

    END IF;



ELSE
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_create: _action is of type invalid';
    LEAVE WORKORDER_create;
END IF;


IF (_DEBUG=1) THEN
    select 'FINISHED',_action,_workorderUUID, _userUUID;
END IF;


END$$

DELIMITER ;

-- ==================================================================

/*
call WORKORDER_workOrder(_action, _customerId,_userUUID
_workorderUUID,_workorder_locationUUID,_workorder_userUUID,_workorder_groupUUID,_workorder_assetUUID,
_workorder_checklistUUID,_workorder_checklistHistoryUUID,_workorder_status,_workorder_type,_workorder_name,_workorder_number,_workorder_details,
_workorder_actions,_workorder_priority,_workorder_dueDate,_workorder_completeDate,
_workorder_scheduleDate,_workorder_rescheduleDate,_workorder_frequency,_workorder_frequencyScope,_wapj_asset_partUUID,
_wapj_quantity
);

call WORKORDER_workOrder('GET', 'a30af0ce5e07474487c39adab6269d5f',2,
'0d59f068ed4c462aaaa23c5acd71e4d6',null,null,null,null,
null,null,null,null,null,null,null,
null,null,null,null,null,
null,null,null,null,
null, null, null);

call WORKORDER_workOrder(
'GET',
'a30af0ce5e07474487c39adab6269d5f',
2,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null,
null);

call WORKORDER_workOrder('CREATE', 'a30af0ce5e07474487c39adab6269d5f',1,
UUID(),null,null,null,null,
'2b61b61eb4d141799a9560cccb109f59',null,null,null,null,null,null,
null,null,null,null,
'24-09-2020',null,5,'DAILY',null,
null);

call WORKORDER_workOrder('CREATE','a30af0ce5e07474487c39adab6269d5f','2',
'1606299064282','1600957239770','2',null,'edfe4b13ffcf47e0afa5fc6d3cfe19b7',
'8090644719c64be4abd2ba78f915bf5d',null,null,null,
'ABC-01',null,'ABC-01',
null,'HIGH','31-01-2021',null,
'25-11-2020','25-11-2020','4','DAILY',null,
null,'Sunday,Monday,Tuesday'
);


call WORKORDER_workOrder('START', 'a30af0ce5e07474487c39adab6269d5f',1,
'666e2c60-feb7-11ea-a1a5-4e53d94465b4',null,null,null,null,
null,null,null,null,null,null,null,
null,null,null,null,null,
null,null,null,null,
null);

call WORKORDER_workOrder('COMPLETE', 'a30af0ce5e07474487c39adab6269d5f',1,
'666e2c60-feb7-11ea-a1a5-4e53d94465b4',null,null,null,null,
null,null,null,null,null,null,null,
null,null,null,null,null,
null,null,null,null,
null);


*/
DROP procedure IF EXISTS `WORKORDER_workOrder`;


DELIMITER $$
CREATE PROCEDURE `WORKORDER_workOrder` (
IN _action VARCHAR(100),
IN _customerId VARCHAR(100),
IN _userUUID VARCHAR(100),
IN _workorderUUID VARCHAR(1024),
IN _workorder_locationUUID VARCHAR(100),
IN _workorder_userUUID VARCHAR(100),
IN _workorder_groupUUID VARCHAR(100),
IN _workorder_assetUUID VARCHAR(100),
IN _workorder_checklistUUID VARCHAR(100),
IN _workorder_checklistHistoryUUID VARCHAR(100),
IN _workorder_status varchar(100),
IN _workorder_type VARCHAR(100),
IN _workorder_name VARCHAR(100),
IN _workorder_number VARCHAR(100),
IN _workorder_details VARCHAR(100),
IN _workorder_actions TEXT,
IN _workorder_priority VARCHAR(100),
IN _workorder_dueDate VARCHAR(100),
IN _workorder_completeDate VARCHAR(100),
IN _workorder_scheduleDate VARCHAR(100),
IN _workorder_rescheduleDate VARCHAR(100),
IN _workorder_frequency INT,
IN _workorder_frequencyScope VARCHAR(100),
IN _wapj_asset_partUUID VARCHAR(100),
IN _wapj_quantity INT,
IN _daysToMaintain VARCHAR(100),
IN _monthlyRecurrType VARCHAR(50),
IN monthlyRecuttValue INT
)
WORKORDER_workOrder: BEGIN

DECLARE _DEBUG INT DEFAULT 0;

DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%Y';
DECLARE _maxWO INT;
DECLARE _commaNeeded INT;
DECLARE _workorder_definition varchar(100);
DECLARE _checklist_historyUUID char(36);
DECLARE _workorder_tag varchar(100);
DECLARE strLen    INT DEFAULT 0;
DECLARE SubStrLen INT DEFAULT 0;
DECLARE _woDates varchar(5000);
DECLARE _date varchar(100);

IF(_action ='GET' or _action = 'GETALL') THEN

    IF(_customerId IS NULL or _customerId = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _customerId can not be empty';
        LEAVE WORKORDER_workOrder;
    END IF;

    if (_workorder_dueDate IS NOT NULL) THEN set _workorder_dueDate = STR_TO_DATE(_workorder_dueDate, _dateFormat); END IF;

        set  @l_sql = CONCAT('SELECT w.*,u.user_userName,cl.checklist_name, cl.checklist_statusId, a.asset_name, g.group_name, clh.checklist_history_statusId, clh.checklist_history_comment FROM workorder w
        left join jcmi_core.user u on(u.userUUID = w.workorder_userUUID )
        left join checklist cl on(w.workorder_checklistUUID = cl.checklistUUID)
		left join checklist_history clh on (clh.checklist_history_checklistUUID = cl.checklistUUID and clh.checklist_history_workorderUUID = w.workorderUUID)
        left join asset a on(w.workorder_assetUUID = a.assetUUID)
        left join user_group g on(w.workorder_groupUUID =g.groupUUID) WHERE ');

        if (_workorderUUID IS NOT NULL) THEN
            set @l_sql = CONCAT(@l_sql,'w.workorderUUID = \'', _workorderUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_customerId IS NOT NULL) THEN
            if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
            set @l_sql = CONCAT(@l_sql,'w.workorder_customerUUID = \'', _customerId,'\'');
            set _commaNeeded=1;
        END IF;
        if (_userUUID IS NOT NULL and _action ='GET' ) THEN
            if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
            set @l_sql = CONCAT(@l_sql,'w.workorder_userUUID = \'', _userUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_userUUID IS NOT NULL) THEN
            if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
            set @l_sql = CONCAT(@l_sql,'w.workorder_userUUID = \'', _workorder_userUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_groupUUID IS NOT NULL) THEN
            if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
            set @l_sql = CONCAT(@l_sql,'w.workorder_groupUUID = \'', _workorder_groupUUID,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_locationUUID IS NOT NULL) THEN
            if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
            set @l_sql = CONCAT(@l_sql,'w.workorder_locationUUID = \'', _workorder_locationUUID,'\'');
            set _commaNeeded=1;
        END IF;
        -- if (_workorder_status IS NOT NULL) THEN
        --  if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
        --  set @l_sql = CONCAT(@l_sql,'w.workorder_status = \'', _workorder_status,'\'');
        --     set _commaNeeded=1;
        -- END IF;
        if (_workorder_dueDate IS NOT NULL) THEN
            if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
            set @l_sql = CONCAT(@l_sql,'DATE(now()) <= \'', _workorder_dueDate,'\'');
            set _commaNeeded=1;
        END IF;
        if (_workorder_assetUUID IS NOT NULL) THEN
            if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
             set @l_sql = CONCAT(@l_sql,'w.workorder_assetUUID = \'', _workorder_assetUUID,'\'');
            set _commaNeeded=1;
        END IF;
	if(_action ='GET') THEN
        set @l_sql = CONCAT(@l_sql,'AND w.workorder_status not like \'','Complete','\'',
                            ' AND w.workorder_deleteTS is null AND workorder_scheduleDate <= date_add(CURDATE(), interval 24*60*60 - 1 second)');
        set @l_sql = CONCAT(@l_sql,'order by w.workorder_status, workorder_scheduleDate desc');
	else
		set @l_sql = CONCAT(@l_sql,'order by w.workorder_number desc');
        END IF;
        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

ELSEIF(_action ='UPDATE' OR _action ='PARTIAL_UPDATE' OR _action = 'BATCH-UPDATE') THEN
        IF (_workorderUUID IS NULL) THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _workorderUUID is null for UPDATE action';
            LEAVE WORKORDER_workOrder;
        END IF;
			select workorder_tag, workorder_checklistUUID, workorder_checklistHistoryUUID into _workorder_tag, @checklistUid,  @checklisthistoryuuid from workorder where workorderUUID = _workorderUUID;
				IF (_action ='UPDATE') THEN

            IF (_workorder_tag IS NOT NULL) THEN
                DELETE FROM workorder WHERE workorder_tag = _workorder_tag and workorder_scheduleDate > now() ;

                call WORKORDER_create('create', _customerId, _userUUID, _workorderUUID, _workorder_locationUUID, _workorder_userUUID,
                                    _workorder_groupUUID, _workorder_assetUUID, _workorder_checklistUUID, _workorder_checklistHistoryUUID,
                                    _workorder_status, _workorder_type, _workorder_name, _workorder_number, _workorder_details, _workorder_actions,
                                    _workorder_priority, _workorder_dueDate, _workorder_completeDate, _workorder_scheduleDate, _workorder_rescheduleDate,
                                    _workorder_frequency, _workorder_frequencyScope, _wapj_asset_partUUID, _wapj_quantity, _daysToMaintain,
                                    _monthlyRecurrType, monthlyRecuttValue
                                    );
                LEAVE WORKORDER_workOrder;
            END IF;
        END IF;

        IF(@checklistUid != _workorder_checklistUUID) THEN
            update checklist_history
            set checklist_history_statusId = 3
            where checklist_historyUUID =  @checklisthistoryuuid; -- complete previous checklist bcz change in checklistId

            update workorder
            set workorder_checklistHistoryUUID = null
            where  workorderUUID = _workorderUUID; -- removed prevous checklistHistoryId
		END IF;

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
            set @l_sql = CONCAT(@l_sql,',workorder_dueDate = \'', STR_TO_DATE(_workorder_dueDate, '%d-%m-%Y'),'\'');
        END IF;
        if (_workorder_assetUUID IS NOT NULL) THEN
            set @l_sql = CONCAT(@l_sql,',workorder_assetUUID = \'', _workorder_assetUUID,'\'');
        END IF;
        if (_workorder_rescheduleDate IS NOT NULL) THEN
            set @l_sql = CONCAT(@l_sql,',workorder_rescheduleDate = \'', STR_TO_DATE(_workorder_rescheduleDate, '%d-%m-%Y'),'\'');
        END IF;
        if (_workorder_userUUID IS NOT NULL and _workorder_groupUUID IS NULL) THEN
            set @l_sql = CONCAT(@l_sql,',workorder_userUUID = \'', _workorder_userUUID,'\'');
            set @l_sql = CONCAT(@l_sql,',workorder_groupUUID  = NULL');
        END IF;
        if (_workorder_groupUUID  IS NOT NULL and _workorder_userUUID IS NULL) THEN
            set @l_sql = CONCAT(@l_sql,',workorder_groupUUID  = \'', _workorder_groupUUID ,'\'');
            set @l_sql = CONCAT(@l_sql,',workorder_userUUID = NULL');
        END IF;
       IF (_DEBUG=1) THEN select _workorder_scheduleDate,_workorder_scheduledate; END IF;
        if (_workorder_scheduleDate  IS NOT NULL) THEN
            set @l_sql = CONCAT(@l_sql,',workorder_scheduleDate  =\'', STR_TO_DATE(_workorder_scheduleDate, '%d-%m-%Y'), '\'');
        END IF;
        IF (_workorder_checklistUUID IS NOT NULL ) THEN
            set @l_sql = CONCAT(@l_sql,',workorder_checklistUUID = \'', _workorder_checklistUUID,'\'');
        END IF;

        IF(_workorder_frequency IS NOT NULL) THEN
				set @l_sql = CONCAT(@l_sql,',workorder_frequency = \'', _workorder_frequency,'\'');
        END IF;
        IF(_workorder_frequencyScope IS NOT NULL) THEN
                set @l_sql = CONCAT(@l_sql,',workorder_frequencyScope =\'', _workorder_frequencyScope, '\'');
         END IF;
        IF(_workorder_locationUUID IS NOT NULL ) THEN
				 set @l_sql = CONCAT(@l_sql,',workorder_locationUUID = \'', _workorder_locationUUID,'\'');
         END If;
        IF(_workorder_number IS NOT NULL) THEN
				set @l_sql = CONCAT(@l_sql,',workorder_number = \'', _workorder_number,'\'');
        END IF;

        IF (_action = 'BATCH-UPDATE') THEN
            set @l_sql = CONCAT(@l_sql,' where workorderUUID IN (',_workorderUUID,')');
        ELSE
           set @l_sql = CONCAT(@l_sql,' where workorderUUID = \'', _workorderUUID,'\';');
        END IF;

        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

ELSEIF((_action ='REMOVE' OR _action = 'BATCH-REMOVE') and _workorderUUID is not null) THEN

    if (_wapj_asset_partUUID IS NOT NULL) THEN
        set @l_sql = 'delete from workorder_asset_part_join where';
        set @l_sql = CONCAT(@l_sql,' wapj_asset_partUUID = \'', _wapj_asset_partUUID,'\' and');
    ELSE
        set @l_sql = 'update workorder set' ;
        set @l_sql = CONCAT(@l_sql,' workorder_deleteTS = \'',now(),'\',');
        set @l_sql = CONCAT(@l_sql,' workorder_updatedTS = \'',now(),'\',');
        set @l_sql = CONCAT(@l_sql,' workorder_updatedByUUID = \'', _userUUID,'\' where');
    END IF;

    if (_wapj_asset_partUUID IS NOT NULL) THEN
        set @workOrderColumnName = ' wapj_workorderUUID';
    else
        set @workOrderColumnName = ' workorderUUID';
    END IF;

    IF(_action = 'BATCH-REMOVE') THEN
        set @l_sql = CONCAT(@l_sql,@workOrderColumnName,' IN (',_workorderUUID,')');
    ELSE
        set @l_sql = CONCAT(@l_sql,@workOrderColumnName,' = \'', _workorderUUID,'\';');
    END IF;

    IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

    PREPARE stmt FROM @l_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    IF(_action = 'BATCH-REMOVE') THEN
        call WORKORDER_assetPart('BATCH-REMOVE', _workorderUUID, null, null);
    ELSE
        call WORKORDER_assetPart('REMOVE', _workorderUUID, null, null);
    END IF;

ELSEIF(_action ='ASSIGN') THEN

        update workorder set workorder_status='OPEN', workorder_completeDate =null,
        workorder_userUUID = _workorder_userUUID,
        workorder_updatedTS = now(), workorder_updatedByUUID=_userUUID
        where workorderUUID=_workorderUUID;

ELSEIF(_action ='START') THEN

        -- check to see if this WO was a checklist, and complete it.
        -- this checklistUUID is the template.  It will get changed to history when started.
        select workorder_assetUUID,workorder_userUUID,workorder_checklistUUID
        into _workorder_assetUUID,_workorder_userUUID,_workorder_checklistUUID
        from workorder where workorderUUID=_workorderUUID;

        if (_workorder_userUUID is null) THEN set _workorder_userUUID=_userUUID(); END IF;

        if (_workorder_checklistUUID is not null) THEN

            -- create new historical
            set _checklist_historyUUID = UUID();

            -- create a new history version of the checklist
            call CHECKLIST_checklist(
            'UPDATE_HISTORY',_userUUID,_customerId,
            _workorder_checklistUUID, _workorder_assetUUID,_checklist_historyUUID,
            _workorderUUID, null,null, null,null,null,null,null, null, null, null, null, null, null, null
            );

        END IF;

        update workorder set workorder_status='IN_PROGRESS', workorder_completeDate =null,
        workorder_updatedTS = now(), workorder_updatedByUUID=_userUUID ,
        workorder_checklistHistoryUUID=_checklist_historyUUID,workorder_userUUID=_workorder_userUUID
        where workorderUUID=_workorderUUID;

        call NOTIFICATION_notification('ACKNOWLEDGE',_userUUID,null,null,null,null,null,null,null,
        null,null,null,_workorderUUID,null,null,null,null,null,null,null,null);

IF (_DEBUG=1) THEN
    select _action,_workorderUUID, _userUUID,_workorder_checklistUUID, _workorder_assetUUID,_checklist_historyUUID;
END IF;


ELSEIF(_action ='COMPLETE' or _action ='BATCH-COMPLETE') THEN

        set  @l_sql = 'update workorder set';
        set @l_sql = CONCAT(@l_sql,' workorder_status =\'','Complete','\',');
        set @l_sql = CONCAT(@l_sql,' workorder_completeDate =\'', DATE(now()),'\',');
        set @l_sql = CONCAT(@l_sql,' workorder_updatedTS =\'',now(),'\',');
        set @l_sql = CONCAT(@l_sql,' workorder_updatedByUUID =',_userUUID);
        if(_action ='BATCH-COMPLETE') THEN
         set @l_sql = CONCAT(@l_sql,' where workorderUUID IN (',_workorderUUID,');');
        ELSE
         set @l_sql = CONCAT(@l_sql,' where workorderUUID= \'',_workorderUUID,'\';');
         END IF;

        select workorder_checklistHistoryUUID
        into _workorder_checklistHistoryUUID
        from workorder where workorderUUID=_workorderUUID;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        if (_workorder_checklistHistoryUUID is not null) THEN
            call CHECKLIST_checklist(
            'PASS_CHECKLIST',_userUUID,null,
            null, null, _workorder_checklistHistoryUUID, null,null,null, null,null,null,null,null, null, null, null, null, null, null, null
                );

        END IF;


ELSEIF(_action ='ADDPART' and _wapj_asset_partUUID is not null) THEN
        set @quantity = 0;

        select wapj_quantity into @quantity  from workorder_asset_part_join where wapj_workorderUUID=_workorderUUID and wapj_asset_partUUID =_wapj_asset_partUUID;

        REPLACE INTO workorder_asset_part_join (wapj_workorderUUID, wapj_asset_partUUID,
        wapj_quantity, wapj_createdTS)
        values (
        _workorderUUID,_wapj_asset_partUUID,@quantity+1,now()
        );

ELSEIF(_action ='GET-PART') THEN

        SELECT ap.*,wapj.wapj_quantity FROM asset_part ap LEFT JOIN workorder_asset_part_join wapj on (wapj.wapj_asset_partUUID = ap.asset_partUUID)
        WHERE wapj.wapj_workorderUUID = _workorderUUID ;

ELSE
    SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call WORKORDER_workOrder: _action is of type invalid';
    LEAVE WORKORDER_workOrder;
END IF;


IF (_DEBUG=1) THEN
    select 'FINISHED',_action,_workorderUUID, _userUUID;
END IF;


END$$

DELIMITER ;

-- =========================== END WORKORDER =============================================

-- call WORKORDER_assetPart(_action, _workorderUUID, _wapj_asset_partUUID, _wapj_quantity);
-- call WORKORDER_assetPart('REMOVE', "", null, null);

DROP procedure IF EXISTS `WORKORDER_assetPart`;

DELIMITER $$
CREATE PROCEDURE `WORKORDER_assetPart` (
IN _action VARCHAR(100),
IN _workorderUUID VARCHAR(1024),
IN _wapj_asset_partUUID VARCHAR(100),
IN _wapj_quantity INT
)
WORKORDER_assetPart: BEGIN
	IF (_action = 'REMOVE' OR _action = 'BATCH-REMOVE') THEN
		IF (_workorderUUID IS NULL OR _workorderUUID = '') THEN
			SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call WORKORDER_assetPart: invalid value passed for _workorderUUID';
			LEAVE WORKORDER_assetPart;
        END IF;

        set @l_sql = 'delete from workorder_asset_part_join where';

        IF (_wapj_asset_partUUID IS NOT NULL) THEN
			set @l_sql = CONCAT(@l_sql,' wapj_asset_partUUID = \'', _wapj_asset_partUUID,'\' and');
        END IF;

        IF (_action = 'BATCH-REMOVE') THEN
			set @l_sql = CONCAT(@l_sql,' wapj_workorderUUID = (', _workorderUUID,')');
		ELSE
			set @l_sql = CONCAT(@l_sql,' wapj_workorderUUID = \'', _workorderUUID,'\'');
		END IF;

        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

-- ==================================================================

-- call CUSTOMER_getCustomerDetails(_action, _customerId);
-- call CUSTOMER_getCustomerDetails('GET-LIST', NULL);

DROP procedure IF EXISTS `CUSTOMER_getCustomerDetails`;

DELIMITER $$
CREATE PROCEDURE `CUSTOMER_getCustomerDetails`(IN _action VARCHAR(100),
                                               IN _customerId VARCHAR(100))
CUSTOMER_getCustomerDetails:
BEGIN

    IF (_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CUSTOMER_getCustomerDetails: _action can not be empty';
        LEAVE CUSTOMER_getCustomerDetails;
    END IF;

    IF (_action = 'GET-LIST') THEN
        SELECT * FROM customer;
    ELSEIF (_action = 'GET') THEN
        SELECT * FROM customer where customerUUID = _customerId;
    END IF;

END$$

DELIMITER ;


-- ==================================================================

-- call CUSTOMER_getCustomerBrandDetails(_action, _customerId);
-- call CUSTOMER_getCustomerBrandDetails('GET-LIST', NULL);

DROP procedure IF EXISTS `CUSTOMER_CustomerBrand`;

DELIMITER $$
CREATE PROCEDURE `CUSTOMER_CustomerBrand`(IN _action VARCHAR(100),
                                          IN _userUUID VARCHAR(100),
                                          IN _brandUUID VARCHAR(100),
                                          IN _brandName VARCHAR(50),
                                          IN _brandLogo VARCHAR(255),
                                          IN _brandPreferenceJSON TEXT)
CUSTOMER_CustomerBrand:
BEGIN


    DECLARE _DEBUG INT DEFAULT 0;
    DECLARE _commaNeeded INT;
    IF (_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _action can not be empty';
        LEAVE CUSTOMER_CustomerBrand;
    END IF;

    IF (_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _userUUID missing';
        LEAVE CUSTOMER_CustomerBrand;
    END IF;

    IF (_action = 'GET-LIST') THEN
        SELECT * FROM customer_brand;
    ELSEIF (_action = 'GET') THEN
        set @l_sql = 'SELECT b.* FROM customer_brand b';
        IF ((_brandUUID IS NULL OR _brandUUID = '') AND (_brandName IS NULL or _brandName = '')) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _brandUUID or _brandName missing';
            LEAVE CUSTOMER_CustomerBrand;
        END IF;
        IF (_brandUUID IS NOT NULL and _brandUUID != '') THEN
            set @l_sql = CONCAT(@l_sql, ' WHERE b.brandUUID = \'', _brandUUID, '\'');
            set _commaNeeded = 1;
        END IF;
        if (_brandName IS NOT NULL AND _brandName != '') THEN
            if (_commaNeeded = 1) THEN
                set @l_sql = CONCAT(@l_sql, ' AND ');
            ELSE
                set @l_sql = CONCAT(@l_sql, ' WHERE ');
            END IF;
            set @l_sql = CONCAT(@l_sql, 'b.brand_name LIKE \'%', _brandName, '%\'');
        END IF;
        IF (_DEBUG = 1) THEN SELECT _action, @l_sql; END IF;
        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF (_action = 'CREATE') THEN

        IF (_brandUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _brandUUID missing';
            LEAVE CUSTOMER_CustomerBrand;
        END IF;
        IF (_brandName IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _brandName missing';
            LEAVE CUSTOMER_CustomerBrand;
        END IF;
        INSERT INTO customer_brand
        (brandUUID, brand_name, brand_logo, brand_preferenceJSON, brand_createdByUUID, brand_created)
        VALUES (_brandUUID, _brandName, _brandLogo, _brandPreferenceJSON, _userUUID, now());
    ELSEIF (_action = 'UPDATE') THEN
        IF (_brandUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_CustomerBrand: _brandUUID missing';
            LEAVE CUSTOMER_CustomerBrand;
        END IF;
        SET @l_sql = 'UPDATE customer_brand SET ';
        SET _commaNeeded = 0;
        IF (_brandName IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, 'brand_name = \'', _brandName, '\'');
            SET _commaNeeded = 1;
        END IF;
        IF (_brandLogo IS NOT NULL) THEN
            IF (_commaNeeded = 1) THEN SET @l_sql = CONCAT(@l_sql, ','); END IF;
            SET @l_sql = CONCAT(@l_sql, 'brand_logo = \'', _brandLogo, '\'');
            SET _commaNeeded = 1;
        END IF;
        IF (_brandPreferenceJSON IS NOT NULL) THEN
            IF (_commaNeeded = 1) THEN SET @l_sql = CONCAT(@l_sql, ','); END IF;
            SET @l_sql = CONCAT(@l_sql, 'brand_preferenceJSON = \'', _brandPreferenceJSON, '\'');
            SET _commaNeeded = 1;
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE brandUUID = \'', _brandUUID, '\'');
        -- to do: securityBitwise
        IF (_DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'REMOVE' AND _brandUUID IS NOT NULL AND _brandUUID != '') THEN
        DELETE FROM customer_brand WHERE brandUUID = _brandUUID;
    END IF;

END$$

DELIMITER ;

-- ==================================================================

-- call USER_userGroup(_action, _userUUID, _customerUUID, _groupUUID, _groupName);
-- call USER_userGroup('GET-LIST', 1, 1, null, null);
-- call USER_userGroup('GET-LIST', 1,1,1, null,null ; GET GROUPS FOR SPECIFIC CUSTOMER
DROP procedure IF EXISTS `BARCODE_barcode`;
DELIMITER $$
CREATE PROCEDURE `BARCODE_barcode`(IN _action VARCHAR(100),
                                   IN _userUUID VARCHAR(100),
                                   IN _barcodeUUID VARCHAR(100),
                                   IN _barcodeType VARCHAR(100),
                                   IN _barcodeDestinationURL VARCHAR(255),
                                   IN _barcodeStatus VARCHAR(100),
                                   IN _barcodeIsRegistered BOOLEAN,
                                   IN _barcodePartSKU VARCHAR(100),
                                   IN _barcodeAssetUUID VARCHAR(100),
                                   IN _barcodeLocationUUID VARCHAR(100),
                                   IN _barcodeCustomerUUID VARCHAR(100)
)
BARCODE_barcode:
BEGIN
    DECLARE _DEBUG INT DEFAULT 1;
    IF (_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call BARCODE_barcode: _action can not be empty';
        LEAVE BARCODE_barcode;
    END IF;

    IF (_userUUID IS NULL OR _userUUID = '') THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call BARCODE_barcode: _userUUID missing';
        LEAVE BARCODE_barcode;
    END IF;

    IF (_action = 'GET-LIST') THEN
        SELECT * FROM barcode;
    ELSEIF (_action = 'GET') THEN
        IF (_barcodeUUID IS NULL or _barcodeUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call BARCODE_barcode: _barcodeUUID missing';
            LEAVE BARCODE_barcode;
        END IF;
        SELECT * FROM barcode WHERE barcode_uuid = _barcodeUUID;
    ELSEIF (_action = 'GET-URL') THEN
        IF (_barcodeUUID IS NULL or _barcodeUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call BARCODE_barcode: _barcodeUUID missing';
            LEAVE BARCODE_barcode;
        END IF;
        SELECT barcode_destinationURL FROM barcode where barcode_uuid = _barcodeUUID AND barcode_destinationURL is not null;
    ELSEIF (_action = 'CREATE') THEN
        INSERT INTO barcode (    barcode_type,barcode_destinationURL,barcode_status,
                                 barcode_isRegistered,barcode_partSKU,barcode_assetUUID,barcode_locationUUID, barcode_customerUUID,
                                 barcode_createdByUUID,barcode_updatedByUUID,barcode_updatedTS)
        VALUES (_barcodeType, _barcodeDestinationURL, _barcodeStatus, _barcodeIsRegistered, _barcodePartSKU, _barcodeAssetUUID,
                _barcodeLocationUUID,_barcodeCustomerUUID, now(), _userUUID, now());
    ELSEIF (_action = 'UPDATE') THEN
        IF (_barcodeUUID IS NULL or _barcodeUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call BARCODE_barcode: _barcodeUUID missing';
            LEAVE BARCODE_barcode;
        END IF;
        SET @l_sql = CONCAT('UPDATE barcode SET barcode_updatedTS=now(), barcode_updatedByUUID=\'', _userUUID, '\'');
        IF (_barcodeType IS NOT NULL AND _barcodeType != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',barcode_type = \'', _barcodeType, '\'');
        END IF;
        IF (_barcodeDestinationURL IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',barcode_destinationURL = \'', _barcodeDestinationURL, '\'');
        END IF;
        IF (_barcodeStatus IS NOT NULL AND _barcodeStatus != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',barcode_status = \'', _barcodeStatus, '\'');
        END IF;
        IF (_barcodeIsRegistered IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',barcode_isRegistered = \'', _barcodeIsRegistered, '\'');
        END IF;
        IF (_barcodePartSKU IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',barcode_partSKU = \'', _barcodePartSKU, '\'');
        END IF;
        IF (_barcodeAssetUUID IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',barcode_assetUUID = \'', _barcodeAssetUUID, '\'');
        END IF;
        IF (_barcodeCustomerUUID IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',barcode_customerUUID = \'', _barcodeCustomerUUID, '\'');
        END IF;
        IF (_barcodeLocationUUID IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',barcode_locationUUID = \'', _barcodeLocationUUID, '\'');
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE barcode_uuid = \'', _barcodeUUID, '\'');
        -- to do: securityBitwise
        IF (_DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'DELETE' AND _barcodeUUID IS NOT NULL AND _barcodeUUID != '') THEN

        UPDATE barcode SET barcode_deleteTS=now(), barcode_updatedByUUID=_userUUID, barcode_status='DELETED' WHERE barcode_uuid=_barcodeUUID;
    ELSEIF (_action = 'REMOVE' AND _barcodeUUID IS NOT NULL AND _barcodeUUID != '') THEN
        IF (_userUUID IS NULL OR _userUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call BARCODE_barcode: _userUUID missing';
            LEAVE BARCODE_barcode;
        END IF;
        DELETE FROM barcode WHERE barcode_uuid = _barcodeUUID;
    END IF;

END$$

DELIMITER ;

DROP procedure IF EXISTS `CUSTOMER_customer`;

DELIMITER $$
CREATE PROCEDURE `CUSTOMER_customer`(IN _action VARCHAR(100),
                                     IN _userUUID VARCHAR(100),
                                     IN _customerUUID VARCHAR(100),
                                     IN _customerBrandUUID VARCHAR(100),
                                     IN _customerStatusId INT,
                                     IN _customerName VARCHAR(100),
                                     IN _customerLogo VARCHAR(255),
                                     IN _customerSecurityBitwise BIGINT,
                                     IN _customerPreferenceJSON TEXT,
                                     IN _xRefName VARCHAR(255),
                                     IN _xRefId VARCHAR(255))
CUSTOMER_customer:
BEGIN
    DECLARE _DEBUG INT DEFAULT 1;
    IF (_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _action can not be empty';
        LEAVE CUSTOMER_customer;
    END IF;

    IF (_userUUID IS NULL OR _userUUID = '') THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _userUUID missing';
        LEAVE CUSTOMER_customer;
    END IF;

    IF (_action = 'GET-LIST') THEN
        SET @l_SQL = CONCAT('SELECT * FROM customer');
        IF (_customerBrandUUID IS NOT NULL AND _customerBrandUUID != '') THEN
            SET @l_SQL = CONCAT(@l_SQL, ' WHERE customer_brandUUID = \'',_customerBrandUUID,'\'');
        END IF;
        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'GET') THEN
        IF (_customerUUID IS NULL or _customerUUID = '') AND (_xRefId IS NULL or _xRefId = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;
        IF (_xRefName IS NOT NULL AND _xRefName > '' AND _xRefId IS NOT NULL AND _xRefId > '') THEN
           SELECT * FROM customer c INNER JOIN customer_xref x on c.customerUUID = x.customerUUID WHERE x.customerx_externalName = _xRefName AND x.customerx_externalId = _xRefId;
           LEAVE CUSTOMER_customer;
        END IF;
        SELECT * FROM customer WHERE customerUUID = _customerUUID;
    ELSEIF (_action = 'CREATE') THEN
        IF (_customerUUID IS NULL OR _customerUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;
        IF (_customerName IS NULL OR _customerName = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerName missing';
            LEAVE CUSTOMER_customer;
        END IF;
        INSERT INTO customer (customerUUID, customer_externalName, customer_brandUUID, customer_statusId, customer_name,
                              customer_logo, customer_securityBitwise, customer_preferenceJSON, customer_createdByUUID,
                              customer_updatedByUUID, customer_updatedTS, customer_createdTS, customer_deleteTS)
        VALUES (_customerUUID, _customerName, _customerBrandUUID, _customerStatusId, _customerName, _customerLogo,
                _customerSecurityBitwise, _customerPreferenceJSON, _userUUID, _userUUID, now(), now(), null);
    ELSEIF (_action = 'UPDATE') THEN
        IF (_customerUUID IS NULL or _customerUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;
        SET @l_sql = CONCAT('UPDATE customer SET customer_updatedTS=now(), customer_updatedByUUID=\'', _userUUID, '\'');
        IF (_customerStatusId IS NOT NULL AND _customerStatusId != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_statusId = \'', _customerStatusId, '\'');
        END IF;
        IF (_customerName IS NOT NULL and _customerName != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_name = \'', _customerName, '\'');
        END IF;
        IF (_customerLogo IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_logo = \'', _customerLogo, '\'');
        END IF;
        IF (_customerSecurityBitwise IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_securityBitwise = \'', _customerSecurityBitwise, '\'');
        END IF;
        IF (_customerPreferenceJSON IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',customer_preferenceJSON = \'', _customerPreferenceJSON, '\'');
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE customerUUID = \'', _customerUUID, '\'');
        -- to do: securityBitwise
        IF (_DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'REMOVE' AND _customerUUID IS NOT NULL AND _customerUUID != '') THEN
        DELETE FROM customer WHERE customerUUID = _customerUUID;
    END IF;

END$$

Delimiter ;

-- ==================================================================
# KNOWLEDGE BASE
-- call KB_knowledge_base(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
-- call KB_knowledge_base('GET-PART-KNOWLEDGE', null, null, null, null, null, null, null, null, null, null, '005-008-001');

DROP procedure IF EXISTS `KB_knowledge_base`;

DELIMITER $$
CREATE PROCEDURE `KB_knowledge_base`(IN _action VARCHAR(100),
                                     IN _userUUID VARCHAR(100),
                                     IN _knowledgebaseUUID VARCHAR(100),
                                     IN _knowledge_statusId INT,
                                     IN _knowledge_imageURL VARCHAR(255),
                                     IN _knowledge_tags VARCHAR(500),
                                     IN _knowledge_categories VARCHAR(500),
                                     IN _knowledge_title VARCHAR(100),
                                     IN _knowledge_content VARCHAR(1000),
                                     IN _knowledge_customerUUID CHAR(36),
                                     IN _knowledge_relatedArticle TEXT,
                                     IN _part_sku VARCHAR(100))
KB_knowledge_base:
BEGIN
    DECLARE _DEBUG INT DEFAULT 0;
    DECLARE _SEARCH_TEXT VARCHAR(100) DEFAULT '';

    IF (_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call KB_knowledge_base: _action can not be empty';
        LEAVE KB_knowledge_base;
    END IF;

    IF ((_action not IN ('GET-LIST','GET-PART-KNOWLEDGE')) AND (_userUUID IS NULL OR _userUUID = '')) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _userUUID missing';
        LEAVE KB_knowledge_base;
    END IF;

    IF (_knowledge_title IS NOT NULL)THEN
    SET _SEARCH_TEXT = _knowledge_title;
    END IF;

    IF (_action = 'GET-LIST') THEN
        SET @l_sql = CONCAT('SELECT * FROM knowledge_base where knowledge_title like \'','%',_SEARCH_TEXT,'%\'');
        IF (_knowledge_categories is not null) THEN
			SET @l_sql = CONCAT(@l_sql, 'AND knowledge_categories like \'%',_knowledge_categories, '%\'');
		END IF;
        IF(_DEBUG = 1) THEN
			select @l_sql;
        END IF;
        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'GET') THEN
        IF (_knowledgebaseUUID IS NULL or _knowledgebaseUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _knowledgebaseUUID missing';
            LEAVE KB_knowledge_base;
        END IF;
		SELECT * FROM knowledge_base WHERE knowledgeUUID = _knowledgebaseUUID;
	ELSEIF (_action = 'GET-PART-KNOWLEDGE') THEN
		IF (_part_sku IS NULL or _part_sku = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _part_sku missing';
            LEAVE KB_knowledge_base;
        END IF;
			SET @l_sql = CONCAT('SELECT * FROM knowledge_base kb
				LEFT JOIN part_knowledge_join pkj on pkj.pkj_part_knowledgeUUID = kb.knowledgeUUID
				WHERE pkj.pkj_part_partUUID = \'', _part_sku, '\'');
			IF (_knowledge_categories is not null) THEN
				SET @l_sql = CONCAT(@l_sql, 'AND knowledge_categories like \'%',_knowledge_categories, '%\'');
            END IF;
            IF(_DEBUG = 1) THEN
				select @l_sql;
			END IF;
            PREPARE stmt FROM @l_sql;
			EXECUTE stmt;
			DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'CREATE') THEN
        IF (_knowledgebaseUUID IS NULL OR _knowledgebaseUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _knowledgebaseUUID missing';
            LEAVE KB_knowledge_base;
        END IF;
        IF (_knowledge_title IS NULL OR _knowledge_title = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _knowledge_title missing';
            LEAVE KB_knowledge_base;
        END IF;
        INSERT INTO knowledge_base (knowledgeUUID, knowledge_statusId, knowledge_imageURL, knowledge_tags,
                                    knowledge_categories,
                                    knowledge_title, knowledge_customerUUID, knowledge_relatedArticle,
                                    knowledge_content, knowledge_createdByUUID, knowledge_acknowledgedByUUID,
                                    knowledge_updatedTS, knowledge_createdTS, knowledge_deleteTS)
        VALUES (_knowledgebaseUUID, _knowledge_statusId, _knowledge_imageURL, _knowledge_tags, _knowledge_categories,
                _knowledge_title, _knowledge_customerUUID, _knowledge_relatedArticle, _knowledge_content,
                _userUUID, _userUUID, now(), now(), null);
    ELSEIF (_action = 'UPDATE') THEN
        IF (_knowledgebaseUUID IS NULL or _knowledgebaseUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call KB_knowledge_base: _knowledgebaseUUID missing';
            LEAVE KB_knowledge_base;
        END IF;
        SET @l_sql =
                CONCAT('UPDATE knowledge_base SET knowledge_updatedTS=now(), knowledge_updatedByUUID=\'', _userUUID,
                       '\'');
        IF (_knowledge_statusId IS NOT NULL AND _knowledge_statusId != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_statusId = \'', _knowledge_statusId, '\'');
        END IF;
        IF (_knowledge_imageURL IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_imageURL = \'', _knowledge_imageURL, '\'');
        END IF;
        IF (_knowledge_tags IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_tags = \'', _knowledge_tags, '\'');
        END IF;
        IF (_knowledge_categories IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_categories = \'', _knowledge_categories, '\'');
        END IF;
        IF (_knowledge_title IS NOT NULL AND _knowledge_title != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_title = \'', _knowledge_title, '\'');
        END IF;
        IF (_knowledge_content IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_content = \'', _knowledge_content, '\'');
        END IF;
        IF (_knowledge_customerUUID IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_customerUUID = ', _knowledge_customerUUID);
        END IF;
        IF (_knowledge_relatedArticle IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',knowledge_relatedArticle = \'', _knowledge_relatedArticle, '\'');
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE knowledgeUUID = \'', _knowledgebaseUUID, '\'');
        IF (_DEBUG = 1) THEN select _action, @l_SQL; END IF;
        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'REMOVE' AND _knowledgebaseUUID IS NOT NULL AND _knowledgebaseUUID != '') THEN
        DELETE FROM knowledge_base WHERE knowledgeUUID = _knowledgebaseUUID;
    ELSEIF (_action = 'LIKE') THEN
        UPDATE knowledge_base SET knowledge_likes = knowledge_likes + 1 where knowledgeUUID = _knowledgebaseUUID;
    ELSEIF (_action = 'UNLIKE') THEN
        UPDATE knowledge_base SET knowledge_likes = knowledge_likes - 1 where knowledgeUUID = _knowledgebaseUUID;
    ELSEIF (_action = 'DISLIKE') THEN
        UPDATE knowledge_base SET knowledge_dislikes = knowledge_dislikes + 1 where knowledgeUUID = _knowledgebaseUUID;
    ELSEIF (_action = 'UNDISLIKE') THEN
        UPDATE knowledge_base SET knowledge_dislikes = knowledge_dislikes - 1 where knowledgeUUID = _knowledgebaseUUID;
    END IF;
END$$

DELIMITER ;

-- ==================================================================
-- call PLAN_plan(_action)

DROP procedure IF EXISTS `PLAN_plan`;

DELIMITER $$
CREATE PROCEDURE `PLAN_plan`(IN _action VARCHAR(100),
                             IN _userUUID VARCHAR(100),
                             IN _planUUID VARCHAR(100),
                             IN _planName VARCHAR(100),
                             IN _planSecurityBitwise BIGINT,
                             IN _planMaxUsers BIGINT)
PLAN_plan:
BEGIN
    DECLARE _DEBUG INT DEFAULT 0;
    IF (_action IS NULL or _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call PLAN_plan: _action can not be empty';
        LEAVE PLAN_plan;
    END IF;

    IF (_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _userUUID missing';
        LEAVE PLAN_plan;
    END IF;

    IF (_action = 'GET-LIST') THEN
        SELECT * FROM plan;
    ELSEIF (_action = 'GET') THEN
        IF (_planUUID IS NULL or _planUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _planUUID missing';
            LEAVE PLAN_plan;
        END IF;
        SELECT * FROM plan WHERE planUUID = _planUUID;
    ELSEIF (_action = 'CREATE') THEN
        IF (_planUUID IS NULL OR _planUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _planUUID missing';
            LEAVE PLAN_plan;
        END IF;
        IF (_planName IS NULL OR _planName = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _planName missing';
            LEAVE PLAN_plan;
        END IF;
        INSERT INTO plan (planUUID, plan_name, plan_securityBitwise, plan_maxUsers, plan_createdByUUID,
                          plan_updatedByUUID, plan_updatedTS, plan_createdTS, plan_deleteTS)
        VALUES (_planUUID, _planName, _planSecurityBitwise, _planMaxUsers, _userUUID, _userUUID, now(), now(), null);
    ELSEIF (_action = 'UPDATE') THEN
        IF (_planUUID IS NULL or _planUUID = '') THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PLAN_plan: _planUUID missing';
            LEAVE PLAN_plan;
        END IF;
        SET @l_sql = CONCAT('UPDATE plan SET plan_updatedTS=now(), plan_updatedByUUID=\'', _userUUID, '\'');
        IF (_planName IS NOT NULL AND _planName != '') THEN
            SET @l_sql = CONCAT(@l_sql, ',plan_name = \'', _planName, '\'');
        END IF;
        IF (_planSecurityBitwise IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',plan_securityBitwise = ', _planSecurityBitwise);
        END IF;
        IF (_planMaxUsers IS NOT NULL) THEN
            SET @l_sql = CONCAT(@l_sql, ',plan_maxUsers = ', _planMaxUsers);
        END IF;
        SET @l_sql = CONCAT(@l_sql, ' WHERE _planUUID = \'', _planUUID, '\'');
        -- to do: securityBitwise
        IF (_DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'REMOVE' AND _planUUID IS NOT NULL AND _planUUID != '') THEN
        DELETE FROM plan WHERE planUUID = _planUUID;
    END IF;

END$$

DELIMITER ;
    -- ==================================================================

-- call LOCATION_action(action, _userUUID, _customerUUID, _type, _name,_objUUID, 0,_startLimitIndex,_dataCount);
-- call LOCATION_action('SEARCH', '1', 'a30af0ce5e07474487c39adab6269d5f', 'LOCATION', 'test123Lo',null, 0,null,null);
-- call LOCATION_action('SEARCH', '1', 'a30af0ce5e07474487c39adab6269d5f', 'ASSET', 'setter',null, 0,null,null);
-- call LOCATION_action('SEARCH', '1', '3792f636d9a843d190b8425cc06257f5', 'ASSET-PART', 'Avida Symphony',null, 0,null,null);
-- call LOCATION_action('CREATE', '1', '3792f636d9a843d190b8425cc06257f5', 'LOCATION', 'DAVID',55, 0,null,null);
-- call LOCATION_action('CREATE', '1', '3792f636d9a843d190b8425cc06257f5', 'ASSET', 'ASSETDAVID',55, 0,null,null);
-- call LOCATION_action('CREATE', '1', '3792f636d9a843d190b8425cc06257f5', 'ASSET-PART', 'ASSETPARTDAVID',22, 0,null,null);
-- call LOCATION_action('SEARCH', '1', 'a30af0ce5e07474487c39adab6269d5f', 'PARTS-USED', null,null, null,null,null,null);
DROP procedure IF EXISTS `LOCATION_action`;

DELIMITER $$
CREATE PROCEDURE `LOCATION_action`(IN _action VARCHAR(100),
                                   IN _userUUID VARCHAR(100),
                                   IN _customerUUID VARCHAR(100),
                                   IN _type VARCHAR(100),
                                   IN _name VARCHAR(100),
                                   IN _objUUID VARCHAR(100),
                                   IN _isPrimary INT,
                                   IN _locationId VARCHAR(100),
                                   IN _startIndex INT,
                                   IN _dataCount INT)
LOCATION_action:
BEGIN

    DECLARE _itemFound varchar(100);

    DECLARE DEBUG INT DEFAULT 0;

    IF (_action IS NULL OR _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_action: _action can not be empty';
        LEAVE LOCATION_action;
    END IF;

    IF (_userUUID IS NULL and _action != 'SEARCH') THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _userUUID missing';
        LEAVE LOCATION_action;
    END IF;

    IF (_customerUUID IS NULL and _action != 'SEARCH') THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _customerUUID missing';
        LEAVE LOCATION_action;
    END IF;

    IF (_action = 'SEARCH') THEN


        set _name = concat('%', _name, '%');

        if (_type = 'ASSET') THEN
            -- SELECT assetUUID as objUUID, null as ImageURL,null as ThumbURL, asset_name as `name`,_type as `Type`
            -- 	FROM asset where asset_name like _name and  asset_customerUUID=_customerUUID;

            SET @l_SQL =
                CONCAT('SELECT assetUUID as objUUID, null as ImageURL,null as ThumbURL, asset_name as `name`, \'',
                           _type, '\' as `Type`
			FROM asset where asset_statusId = 1 ');
            IF(_name is not null) THEN
            SET @l_SQL = CONCAT(@l_SQL ,'and asset_name like \'', _name, '\'');
			END IF;
			IF(_objUUID is not null) THEN
            SET @l_SQL = CONCAT(@l_SQL ,'and  assetUUID= \'',_objUUID, '\'');
			END IF;
			IF(_customerUUID is not null) THEN
				SET @l_SQL = CONCAT(@l_SQL ,'and  asset_customerUUID= \'',_customerUUID, '\'');
			END IF;
            IF(_name is not null) THEN
                 SET @l_SQL = CONCAT(@l_SQL ,'order by name');
			END IF;
        ELSEIF (_type = 'ASSET-PART' and _objUUID is not null) THEN

         SET @l_SQL = CONCAT(' SELECT asset_partUUID as objUUID,asset_part_imageURL as ImageURL,asset_part_imageThumbURL as ThumbURL, asset_part_name  as `name`, \'ASSET_PART\' as `Type`, \'CUSTOMER-PART\' as source
                                FROM asset_part WHERE asset_part_statusId = 1 AND asset_partUUID LIKE \'',_objUUID ,'\'');

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        ELSEIF (_type = 'ASSET-PART') THEN
            -- SELECT asset_partUUID as objUUID,asset_part_imageURL as ImageURL,asset_part_imageThumbURL as ThumbURL,asset_part_name  as `name`,_type as `Type`
            -- 	FROM asset_part where asset_part_name like _name and asset_part_customerUUID =_customerUUID;

			SET @l_SQL = CONCAT('SELECT * FROM (SELECT asset_partUUID as objUUID,asset_part_imageURL as ImageURL,asset_part_imageThumbURL as ThumbURL, asset_part_name  as `name`, \'ASSET_PART\' as `Type`, \'CUSTOMER-PART\' as source
                                FROM asset_part WHERE asset_part_statusId = 1 AND asset_part_name LIKE \'', _name, '\'');
			IF(_customerUUID is not null) THEN
                SET @l_SQL = CONCAT(@l_SQL ,' AND  asset_part_customerUUID= \'', _customerUUID, '\'');
            END IF;

            SET @l_SQL = CONCAT(@l_SQL ,' UNION');

            SET @l_SQL = CONCAT(@l_SQL ,' SELECT part_sku as objUUID,part_imageURL as ImageURL,part_imageThumbURL as ThumbURL, part_name  as `name`, \'ASSET_PART\' as `Type`, \'FACTORY-PART\' as source
                        FROM part_template pt WHERE part_statusId = 1 AND part_name LIKE \'', _name,'\') ap
                        LEFT JOIN part_template pt ON (ap.source = \'FACTORY-PART\' AND ap.objUUID = pt.part_sku)
                        ORDER BY name ');

			IF(_dataCount is not null)THEN
				SET @l_SQL = CONCAT(@l_SQL , ' LIMIT ');

                IF(_startIndex is not null)THEN
					SET @l_SQL = CONCAT(@l_SQL ,_startIndex,',');
				END IF;

				SET @l_SQL = CONCAT(@l_SQL , _dataCount);
            END IF;

         ELSEIF (_type = 'PARTS-USED') THEN
        -- SELECT DISTINCT  a.asset_partUUID,ap.asset_part_name as `name`,ap.* from asset a left join asset_part ap on(a.asset_partUUID = ap.asset_partUUID) where a.asset_partUUID is
        -- not null and a.asset_customerUUID =_customerUUID ;

                IF (_customerUUID IS NULL ) THEN
                    SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _customerUUID missing';
                    LEAVE LOCATION_action;
                END IF;

            SET @l_SQL = CONCAT('SELECT DISTINCT  a.asset_partUUID as objUUID,ap.asset_part_name as name , ap.* from asset a left join asset_part ap on(a.asset_partUUID = ap.asset_partUUID)
            where a.asset_partUUID is not null and a.asset_customerUUID =\'',_customerUUID,'\'');

            IF(_name is not null)THEN
                SET @l_SQL = CONCAT(@l_SQL , ' and ap.asset_part_name like \'',_name,'\'');
                SET @l_SQL = CONCAT(@l_SQL , ' or ap.asset_part_template_part_sku like \'',_name,'\'');
            END IF;

            IF(_dataCount is not null)THEN
				SET @l_SQL = CONCAT(@l_SQL , ' LIMIT ');

                IF(_startIndex is not null)THEN
					SET @l_SQL = CONCAT(@l_SQL ,_startIndex,',');
				END IF;

				SET @l_SQL = CONCAT(@l_SQL , _dataCount);
            END IF;

        ELSEIF (_type = 'LOCATION') THEN
            -- SELECT locationUUID as objUUID, location_imageUrl as ImageURL, location_imageUrl as ThumbURL, location_name as `name`,_type as `Type`
            -- 	FROM location where location_name like _name and location_customerUUID =_customerUUID;

            SET @l_SQL = CONCAT(
                    'SELECT locationUUID as objUUID, location_imageUrl as ImageURL, location_imageUrl as ThumbURL, location_name as `name`, \'',
                    _type, '\' as `Type`
			FROM location where location_statusId = 1 and location_name like \'', _name,
                    '\'  and  location_customerUUID= \'', _customerUUID, '\'');

        else

            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _type not valid';
            LEAVE LOCATION_action;

        END IF;

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


    ELSEIF (_action = 'CREATE') THEN

        IF (DEBUG = 1) THEN select _action, _userUUID, _customerUUID, _type, _name, _objUUID; END IF;

        IF (_name IS NULL or _type is null or _objUUID is null) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_action: _name or _type or _objUUID missing';
            LEAVE LOCATION_action;
        END IF;

        if (_type = 'ASSET') THEN

            select assetUUID into _itemFound from asset where asset_name = _name and asset_customerUUID = _customerUUID;


            if (_itemFound is not null) THEN

                SELECT assetUUID as objUUID, null as ImageURL, null as ThumbURL, asset_name as `name`, _type as `Type`
                FROM asset
                where assetUUID = _itemFound;

            ELSE

                -- location,part required?

                insert into asset
                (assetUUID, asset_locationUUID, asset_partUUID, asset_customerUUID, asset_statusId, asset_name,
                 asset_shortName, asset_installDate,
                 asset_createdByUUID, asset_updatedByUUID, asset_updatedTS, asset_createdTS, asset_deleteTS)
                values (_objUUID, _locationId, null, _customerUUID, 1, _name, _name, null,
                        _userUUID, _userUUID, now(), now(), null);

                SELECT assetUUID as objUUID, null as ImageURL, null as ThumbURL, asset_name as `name`, _type as `Type`
                FROM asset
                where assetUUID = _objUUID;

            END IF;


        ELSEif (_type = 'ASSET-PART') THEN

            select asset_partUUID
            into _itemFound
            from asset_part
            where asset_part_name = _name
              and asset_part_customerUUID = _customerUUID;

            if (_itemFound is not null) THEN

                SELECT asset_partUUID           as objUUID,
                       asset_part_imageURL      as ImageURL,
                       asset_part_imageThumbURL as ThumbURL,
                       asset_part_name          as `name`,
                       _type                    as `Type`
                FROM asset_part
                where asset_partUUID = _itemFound;

            ELSE

                insert into asset_part
                (asset_partUUID, asset_part_template_part_sku, asset_part_customerUUID, asset_part_statusId,
                 asset_part_sku, asset_part_name, asset_part_description, asset_part_userInstruction,
                 asset_part_shortName, asset_part_imageURL, asset_part_imageThumbURL, asset_part_hotSpotJSON,
                 asset_part_isPurchasable, asset_part_diagnosticUUID, asset_part_magentoUUID, asset_part_vendor,
                 asset_part_createdByUUID, asset_part_updatedByUUID, asset_part_updatedTS, asset_part_createdTS,
                 asset_part_deleteTS)
                values (_objUUID, null, _customerUUID, 1, null, _name, _name, null, _name, null, null, null, null, null,
                        null, null,
                        _userUUID, _userUUID, now(), now(), null);

                SELECT asset_partUUID           as objUUID,
                       asset_part_imageURL      as ImageURL,
                       asset_part_imageThumbURL as ThumbURL,
                       asset_part_name          as `name`,
                       _type                    as `Type`
                FROM asset_part
                where asset_partUUID = _objUUID;

            END IF;


        ELSEif (_type = 'LOCATION') THEN


            select locationUUID
            into _itemFound
            from location
            where location_name = _name and location_customerUUID = _customerUUID;

            if (_itemFound is not null) THEN

                SELECT locationUUID      as objUUID,
                       location_imageUrl as ImageURL,
                       location_imageUrl as ThumbURL,
                       location_name     as `name`,
                       _type             as `Type`
                FROM location
                where locationUUID = _itemFound;

            ELSE

                insert into location
                (locationUUID, location_customerUUID, location_statusId, location_type, location_name,
                 location_description, location_isPrimary, location_imageUrl, location_hotSpotJSON,
                 location_addressTypeId, location_address, location_address_city, location_address_state,
                 location_address_zip, location_country, location_contact_name, location_contact_email,
                 location_contact_phone,
                 location_createdByUUID, location_updatedByUUID, location_updatedTS, location_createdTS,
                 location_deleteTS)
                values (_objUUID, _customerUUID, 1, 'LOCATION', _name, _name, _isPrimary, null, null, null, null, null,
                        null, null, null, null, null, null,
                        _userUUID, _userUUID, now(), now(), null);

                SELECT locationUUID      as objUUID,
                       location_imageUrl as ImageURL,
                       location_imageUrl as ThumbURL,
                       location_name     as `name`,
                       _type             as `Type`
                FROM location
                where locationUUID = _objUUID;

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
CREATE PROCEDURE `LOCATION_Location`(IN _action VARCHAR(100),
                                     IN _location_userUUID VARCHAR(100),
                                     IN _location_customerUUID VARCHAR(100),
                                     IN _locationUUID VARCHAR(100),
                                     IN _location_statusId INT,
                                     IN _location_type VARCHAR(255),
                                     IN _location_name VARCHAR(255),
                                     IN _location_description VARCHAR(1000),
                                     IN _location_isPrimary INT,
                                     IN _location_imageUrl VARCHAR(1000),
                                     IN _location_hotSpotJSON TEXT,
                                     IN _location_addressTypeId INT,
                                     IN _location_address VARCHAR(255),
                                     IN _location_address_city VARCHAR(255),
                                     IN _location_address_state VARCHAR(25),
                                     IN _location_address_zip VARCHAR(25),
                                     IN _location_country VARCHAR(25),
                                     IN _location_contact_name VARCHAR(100),
                                     IN _location_contact_email VARCHAR(100),
                                     IN _location_contact_phone VARCHAR(50),
                                     IN _location_fabricId CHAR(36))
LOCATION_Location:
BEGIN
    DECLARE commaNeeded INT DEFAULT 0;

    DECLARE DEBUG INT DEFAULT 0;


    IF (_action IS NULL OR _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call LOCATION_Location: _action can not be empty';
        LEAVE LOCATION_Location;
    END IF;

    IF (_location_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_userUUID missing';
        LEAVE LOCATION_Location;
    END IF;

    IF (_location_customerUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID missing';
        LEAVE LOCATION_Location;
    END IF;

    IF (_action = 'GET') THEN

        SET @l_SQL = 'SELECT l.* FROM location l';
        IF (_location_customerUUID IS NULL OR _location_customerUUID = '') THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT =
                    'call LOCATION_Location: _location_customerUUID can not be empty';
            LEAVE LOCATION_Location;
        ELSE
            SET @l_SQL = CONCAT(@l_SQL, '  WHERE l.location_customerUUID =\'', _location_customerUUID, '\'');

            IF (_locationUUID IS NOT NULL AND _locationUUID != '') THEN
                SET @l_SQL = CONCAT(@l_SQL, '  AND l.locationUUID =\'', _locationUUID, '\'');
            END IF;
            IF (_location_isPrimary IS NOT NULL) THEN
                SET @l_SQL = CONCAT(@l_SQL, '  AND l.location_isPrimary =', _location_isPrimary);
            END IF;

            SET @l_SQL = CONCAT(@l_SQL, '  AND l.location_statusId = \'1\'');
            IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

            PREPARE stmt FROM @l_SQL;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;

    ELSEIF (_action = 'CREATE') THEN

        IF (DEBUG = 1) THEN
            select _action,
                   _locationUUID,
                   _location_customerUUID,
                   1,
                   _location_type,
                   _location_name,
                   _location_description,
                   _location_isPrimary,
                   _location_imageUrl,
                   _location_hotSpotJSON,
                   _location_addressTypeId,
                   _location_address,
                   _location_address_city,
                   _location_address_state,
                   _location_address_zip,
                   _location_country,
                   _location_contact_name,
                   _location_contact_email,
                   _location_contact_phone;
        END IF;

        IF (_locationUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID missing';
            LEAVE LOCATION_Location;
        END IF;

        insert into location
        (locationUUID, location_customerUUID, location_statusId, location_type, location_name, location_description,
         location_isPrimary, location_imageUrl, location_hotSpotJSON, location_addressTypeId, location_address,
         location_address_city, location_address_state, location_address_zip, location_country, location_contact_name,
         location_contact_email, location_contact_phone,
         location_createdByUUID, location_updatedByUUID, location_updatedTS, location_createdTS, location_deleteTS)
        values (_locationUUID, _location_customerUUID, 1, _location_type, _location_name, _location_description,
                _location_isPrimary, _location_imageUrl, _location_hotSpotJSON, _location_addressTypeId,
                _location_address, _location_address_city, _location_address_state, _location_address_zip,
                _location_country, _location_contact_name, _location_contact_email, _location_contact_phone,
                _location_userUUID, _location_userUUID, now(), now(), null);

    ELSEIF (_action = 'UPDATE') THEN


        IF (_locationUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID missing';
            LEAVE LOCATION_Location;
        END IF;

        set @l_sql =
                CONCAT('update location set location_updatedTS=now(), location_updatedByUUID=\'', _location_userUUID,
                       '\'');

        if (_location_statusId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_statusId = ', _location_statusId);
        END IF;
        if (_location_type is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_type = \'', _location_type, '\'');
        END IF;
        if (_location_name is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_name = \'', _location_name, '\'');
        END IF;
        if (_location_description is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_description = \'', _location_description, '\'');
        END IF;
        if (_location_isPrimary is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_isPrimary = ', _location_isPrimary);
        END IF;
        if (_location_imageUrl is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_imageUrl = \'', _location_imageUrl, '\'');
        END IF;
        if (_location_hotSpotJSON is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_hotSpotJSON = \'', _location_hotSpotJSON, '\'');
        END IF;
        if (_location_addressTypeId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_addressTypeId = ', _location_addressTypeId);
        END IF;
        if (_location_address is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_address = \'', _location_address, '\'');
        END IF;
        if (_location_address_city is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_address_city = \'', _location_address_city, '\'');
        END IF;
        if (_location_address_state is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_address_state = \'', _location_address_state, '\'');
        END IF;
        if (_location_address_zip is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_address_zip = \'', _location_address_zip, '\'');
        END IF;
        if (_location_country is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_country = \'', _location_country, '\'');
        END IF;
        if (_location_contact_name is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_contact_name = \'', _location_contact_name, '\'');
        END IF;
        if (_location_contact_email is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_contact_email = \'', _location_contact_email, '\'');
        END IF;
        if (_location_contact_phone is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_contact_phone = \'', _location_contact_phone, '\'');
        END IF;
         if (_location_fabricId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',location_fabricId = \'', _location_fabricId, '\'');
        END IF;

        set @l_sql = CONCAT(@l_sql, ' where locationUUID = \'', _locationUUID, '\';');

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


    ELSEIF (_action = 'DELETE') THEN

        IF (DEBUG = 1) THEN select _action, _locationUUID; END IF;

        IF (_locationUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call LOCATION_Location: _location_customerUUID missing';
            LEAVE LOCATION_Location;
        END IF;

        update location
        set location_deleteTS=now(),
            location_statusId=2,
            location_updatedByUUID=_location_userUUID
        where locationUUID = _locationUUID
          and location_customerUUID = _location_customerUUID;
        -- TBD, figure out what cleanup may be involved
        -- ? user profiles

    END IF;

END$$


DELIMITER ;


-- ==================================================================

-- call ASSET_asset(action, _userUUID, asset_customerUUID, assetUUID, asset_locationUUID, asset_partUUID, asset_statusId, asset_name, asset_shortName, asset_installDate);
-- call ASSET_asset('GET', '1', 'a30af'GET', '1', 'a30af0ce5e07474487c39adab6269d5f',  '00c93791035c44fd98d4f40ff2cdfe0a', null, null, null, null, null, null);
-- call ASSET_asset('GET', '1', 'a30af0ce5e07474487c39adab6269d5f', null, null, '283821d8e6c647828eb01df0d82b0b74', null, null, null, null);
-- call ASSET_asset('CREATE', '1', 'a30af0ce5e07474487c39adab6269d5f',  10, 'asset_locationUUID', 'asset_partUUID', 1, 'asset_name', 'asset_shortName', Date(now()));
-- call ASSET_asset('UPDATE', '1', 'a30af0ce5e07474487c39adab6269d5f',  10, 'asset_locationUUID1', 'asset_partUUID2', 1, 'asset_name3', 'asset_shortName4', Date(now()));
-- call ASSET_asset('DELETE', '1', 'a30af0ce5e07474487c39adab6269d5f', 10, null, null, null, null, null, null);

DROP procedure IF EXISTS `ASSET_asset`;

DELIMITER $$
CREATE PROCEDURE `ASSET_asset`(IN _action VARCHAR(100),
                               IN _userUUID VARCHAR(100),
                               IN _customerUUID VARCHAR(100),
                               IN _assetUUID VARCHAR(100),
                               IN _asset_locationUUID VARCHAR(100),
                               IN _asset_partUUID VARCHAR(100),
                               IN _asset_statusId INT,
                               IN _asset_name VARCHAR(255),
                               IN _asset_shortName VARCHAR(255),
                               IN _asset_installDate Date,
                               IN _asset_metaDataJSON TEXT)
ASSET_asset:
BEGIN

    DECLARE DEBUG INT DEFAULT 0;

    IF (_action IS NULL OR _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSET_asset: _action can not be empty';
        LEAVE ASSET_asset;
    END IF;

    IF (_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _userUUID missing';
        LEAVE ASSET_asset;
    END IF;

    IF (_customerUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _customerUUID missing';
        LEAVE ASSET_asset;
    END IF;

    IF (_action = 'GET') THEN

        SET @l_SQL = 'SELECT * FROM asset ';

        SET @l_SQL = CONCAT(@l_SQL, '  WHERE asset_customerUUID =\'', _customerUUID, '\'');

        IF (_assetUUID IS NOT NULL AND _assetUUID != '') THEN
            SET @l_SQL = CONCAT(@l_SQL, '  AND assetUUID =\'', _assetUUID, '\'');
        END IF;
        IF (_asset_partUUID IS NOT NULL AND _asset_partUUID != '') THEN
            SET @l_SQL = CONCAT(@l_SQL, '  AND asset_partUUID =\'', _asset_partUUID, '\'');
        END IF;

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF (_action = 'CREATE') THEN

        IF (DEBUG = 1) THEN
            select _action,
                   _userUUID,
                   _customerUUID,
                   _assetUUID,
                   _asset_locationUUID,
                   _asset_partUUID,
                   _asset_statusId,
                   _asset_name,
                   _asset_shortName,
                   _asset_installDate,
                   _asset_metaDataJSON;
        END IF;

        IF (_assetUUID IS NULL or _asset_partUUID is null) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _assetUUID or _asset_partUUID missing';
            LEAVE ASSET_asset;
        END IF;

        insert into asset
        (assetUUID, asset_locationUUID, asset_partUUID, asset_customerUUID, asset_statusId, asset_name, asset_shortName,
         asset_installDate, asset_metaDataJSON,
         asset_createdByUUID, asset_updatedByUUID, asset_updatedTS, asset_createdTS, asset_deleteTS)
        values (_assetUUID, _asset_locationUUID, _asset_partUUID, _customerUUID, _asset_statusId, _asset_name,
                _asset_shortName, _asset_installDate, _asset_metaDataJSON,
                _userUUID, _userUUID, now(), now(), null);

    ELSEIF (_action = 'UPDATE') THEN


        IF (_assetUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _assetUUID missing';
            LEAVE ASSET_asset;
        END IF;

        set @l_sql = CONCAT('update asset set asset_updatedTS=now(), asset_updatedByUUID=\'', _userUUID, '\'');

        if (_asset_locationUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_locationUUID = \'', _asset_locationUUID, '\'');
        END IF;
        if (_asset_partUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_partUUID = \'', _asset_partUUID, '\'');
        END IF;
        if (_asset_shortName is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_shortName = \'', _asset_shortName, '\'');
        END IF;
        if (_asset_statusId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_statusId = ', _asset_statusId);
        END IF;
        if (_asset_installDate is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_installDate = \'', _asset_installDate, '\'');
        END IF;
        if (_asset_name is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_name = \'', _asset_name, '\'');
        END IF;
        if (_asset_metaDataJSON is not null) THEN
                    set @l_sql = CONCAT(@l_sql, ',asset_metaDataJSON = \'', _asset_metaDataJSON, '\'');
                END IF;


        set @l_sql = CONCAT(@l_sql, ' where assetUUID = \'', _assetUUID, '\';');

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;


    ELSEIF (_action = 'DELETE') THEN

        IF (DEBUG = 1) THEN select _action, _assetUUID; END IF;

        IF (_assetUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSET_asset: _assetUUID missing';
            LEAVE ASSET_asset;
        END IF;

        update asset
        set asset_deleteTS=now(),
            asset_statusId=2,
            asset_updatedByUUID=_userUUID
        where assetUUID = _assetUUID
          and asset_customerUUID = _customerUUID;
        -- TBD, figure out what cleanup may be involved

    END IF;

END$$


DELIMITER ;



-- ==================================================================

/*
call NOTES_notes(_action,_userUUID,_assetnotesId,_assetnotes_assetUUID,_assetnote);
call NOTES_notes('UPDATE',1,null,'00c93791035c44fd98d4f40ff2cdfe0a','_assetnote');
call NOTES_notes('UPDATE',1,null,'00c93791035c44fd98d4f40ff2cdfe0a','_assetnote2');
call NOTES_notes('UPDATE',1,1,null,'_assetnote3');

*/

DROP procedure IF EXISTS `NOTES_notes`;

DELIMITER $$
CREATE PROCEDURE `NOTES_notes`(IN _action VARCHAR(100),
                                             IN _userUUID CHAR(36),
                                             IN _assetnotesId INT,
                                             IN _assetnotes_assetUUID CHAR(36),
                                             IN _assetnote TEXT)
NOTES_notes:
BEGIN

    DECLARE _DEBUG INT DEFAULT 0;

    DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%YT%h:%iZ';
    DECLARE _assetnotesFoundId INT;


    IF (_action = 'GET') THEN

        select * from asset_notes where assetnotesId=_assetnotesId;

    ELSEIF(_action = 'GET-ALL')THEN

        IF (_assetnotes_assetUUID IS NULL) THEN
              SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call NOTES_notes: _assetnotes_assetUUID missing';
              LEAVE NOTES_notes;
        END IF;


        select * from asset_notes where assetnotes_assetUUID=_assetnotes_assetUUID order by assetnotes_updatedTS desc;


    ELSEIF (_action = 'UPDATE' ) THEN

        -- IF (_assetnotesId is null) THEN
--           select assetnotesId into _assetnotesId from asset_notes where assetnotes_assetUUID=_assetnotes_assetUUID;
--         END IF;

        IF (_assetnotesId is null and _assetnotes_assetUUID is not null) THEN

            insert into asset_notes (assetnotes_assetUUID, assetnotes_note, assetnotes_createdByUUID, assetnotes_updatedByUUID, assetnotes_updatedTS, assetnotes_createdTS)
            values
            (_assetnotes_assetUUID, _assetnote, _userUUID, _userUUID, now(), now());

        ELSE

            update asset_notes set assetnotes_note=_assetnote, assetnotes_updatedByUUID=_userUUID, assetnotes_updatedTS=now()
            where assetnotesId=_assetnotesId;

        END IF;

    ELSEIF (_action = 'DELETE') THEN

        DELETE from asset_notes where assetnotesId=_assetnotesId;

    END IF;

    IF (_DEBUG = 1) THEN
        select _action,_assetnotesId,
               _assetnotes_assetUUID, _assetnote, _userUUID;

    END IF;


END$$

DELIMITER ;


-- ==================================================================

-- call ASSETPART_assetpart(action, _userUUID, _customerUUID, asset_partUUID, asset_part_template_part_sku,asset_part_statusId, asset_part_sku,asset_part_name, asset_part_description, asset_part_userInstruction, asset_part_shortName, asset_part_imageURL, asset_part_imageThumbURL, asset_part_hotSpotJSON, asset_part_isPurchasable, asset_part_diagnosticUUID, asset_part_magentoUUID, asset_part_vendor,_asset_part_fabricId);
-- call ASSETPART_assetpart('GET', '1', '3792f636d9a843d190b8425cc06257f5', null, null,null, null, null, null, null, null, null, null, null, null, null, null, null,null,null);
-- call ASSETPART_assetpart('GET', '1', '3792f636d9a843d190b8425cc06257f5',  '0090d1d3b414471485c5e8b6f390a150', null,null, null, null, null, null, null, null, null, null, null, null, null, null,null);
-- call ASSETPART_assetpart('CREATE', '1', '3792f636d9a843d190b8425cc06257f5',  10, 'asset_part_template_part_sku',1, 'asset_part_sku', 'asset_part_name', 'asset_part_description', 'asset_part_userInstruction', 'asset_part_shortName', 'asset_part_imageURL', 'asset_part_imageThumbURL', 'asset_part_hotSpotJSON', 1, 'asset_part_diagnosticUUID', 'asset_part_magentoUUID', 'asset_part_vendor',null);
-- call ASSETPART_assetpart('UPDATE', '1', '3792f636d9a843d190b8425cc06257f5',   10, 'asset_part_template_part_sku2',1, 'asset_part_sku', 'asset_part_name', 'asset_part_description', 'asset_part_userInstruction', 'asset_part_shortName', 'asset_part_imageURL', 'asset_part_imageThumbURL', 'asset_part_hotSpotJSON', 0, 'asset_part_diagnosticUUID', 'asset_part_magentoUUID', 'asset_part_vendor',null);
-- call ASSETPART_assetpart('UPDATE', '1', '3792f636d9a843d190b8425cc06257f5',   10, null,null,null,null, null, null, null,'img url',null, null,null, null,null, null,'1');
-- call ASSETPART_assetpart('DELETE', '1', '3792f636d9a843d190b8425cc06257f5',  10, null,null, null, null,null,null,null,null,null,null,null,null, null,null,null);
-- call ASSETPART_assetpart('SET_DIGNOSTIC', '1', null,null,'004301AU',null, null, null, null,null, null, null, null, null, 0, 'tesing_updated_dignosticUUID', null, null,null);
-- call ASSETPART_assetpart('REMOVE_DIGNOSTIC', '1', null,null,'004301AU',null, null, null, null,null, null, null, null,null, 0, null, null, null,null);

DROP procedure IF EXISTS `ASSETPART_assetpart`;

DELIMITER $$
CREATE PROCEDURE `ASSETPART_assetpart`(IN _action VARCHAR(100),
                                       IN _userUUID VARCHAR(100),
                                       IN _customerUUID VARCHAR(100),
                                       IN _asset_partUUID VARCHAR(100),
                                       IN _asset_part_template_part_sku VARCHAR(100),
                                       IN _asset_part_statusId INT,
                                       IN _asset_part_sku VARCHAR(100),
                                       IN _asset_part_name VARCHAR(255),
                                       IN _asset_part_description VARCHAR(255),
                                       IN _asset_part_userInstruction VARCHAR(255),
                                       IN _asset_part_shortName VARCHAR(255),
                                       IN _asset_part_imageURL VARCHAR(255),
                                       IN _asset_part_imageThumbURL VARCHAR(255),
                                       IN _asset_part_hotSpotJSON TEXT,
                                       IN _asset_part_isPurchasable VARCHAR(255),
                                       IN _asset_part_diagnosticUUID VARCHAR(255),
                                       IN _asset_part_magentoUUID VARCHAR(255),
                                       IN _asset_part_vendor VARCHAR(255),
                                       IN _asset_part_fabricId CHAR(36))
ASSETPART_assetpart:
BEGIN


    DECLARE DEBUG INT DEFAULT 1;


    IF (_action IS NULL OR _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _action can not be empty';
        LEAVE ASSETPART_assetpart;
    END IF;

    IF (_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _userUUID missing';
        LEAVE ASSETPART_assetpart;
    END IF;



    IF (_action = 'GET') THEN
        IF (_customerUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _customerUUID missing';
            LEAVE ASSETPART_assetpart;
        END IF;

        SET @l_SQL = 'SELECT * FROM asset_part ';

        SET @l_SQL = CONCAT(@l_SQL, '  WHERE asset_part_customerUUID =\'', _customerUUID, '\'');

        IF (_asset_partUUID IS NOT NULL AND _asset_partUUID != '') THEN
            SET @l_SQL = CONCAT(@l_SQL, '  AND asset_partUUID =\'', _asset_partUUID, '\'');
        END IF;

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'GET-LIST') THEN
        select * from asset_part;
    ELSEIF (_action = 'CREATE') THEN

        IF (DEBUG = 1) THEN
            select _action,
                   _userUUID,
                   _customerUUID,
                   _asset_partUUID,
                   _asset_part_template_part_sku,
                   _asset_part_statusId,
                   _asset_part_sku,
                   _asset_part_name,
                   _asset_part_description,
                   _asset_part_userInstruction,
                   _asset_part_shortName,
                   _asset_part_imageURL,
                   _asset_part_imageThumbURL,
                   _asset_part_hotSpotJSON,
                   _asset_part_isPurchasable,
                   _asset_part_diagnosticUUID,
                   _asset_part_magentoUUID,
                   _asset_part_vendor;
        END IF;
        IF (_customerUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _customerUUID missing';
            LEAVE ASSETPART_assetpart;
        END IF;
        IF (_asset_partUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_partUUID missing';
            LEAVE ASSETPART_assetpart;
        END IF;

        if (_asset_part_isPurchasable is null) then set _asset_part_isPurchasable = 0; end if;

        insert into asset_part
        (asset_partUUID, asset_part_template_part_sku, asset_part_customerUUID, asset_part_statusId, asset_part_sku,
         asset_part_name, asset_part_description, asset_part_userInstruction, asset_part_shortName, asset_part_imageURL,
         asset_part_imageThumbURL, asset_part_hotSpotJSON, asset_part_isPurchasable, asset_part_diagnosticUUID,
         asset_part_magentoUUID, asset_part_vendor,
         asset_part_createdByUUID, asset_part_updatedByUUID, asset_part_updatedTS, asset_part_createdTS,
         asset_part_deleteTS)
        values (_asset_partUUID, _asset_part_template_part_sku, _customerUUID, _asset_part_statusId, _asset_part_sku,
                _asset_part_name, _asset_part_description, _asset_part_userInstruction, _asset_part_shortName,
                _asset_part_imageURL, _asset_part_imageThumbURL, _asset_part_hotSpotJSON, _asset_part_isPurchasable,
                _asset_part_diagnosticUUID, _asset_part_magentoUUID, _asset_part_vendor,
                _userUUID, _userUUID, now(), now(), null);

        select * from asset_part where asset_partUUID = _asset_partUUID;

    ELSEIF (_action = 'UPDATE') THEN

        IF (_customerUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _customerUUID missing';
            LEAVE ASSETPART_assetpart;
        END IF;
        IF (_asset_partUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_partUUID missing';
            LEAVE ASSETPART_assetpart;
        END IF;

        set @l_sql = CONCAT('update asset_part set asset_part_updatedTS=now(), asset_part_updatedByUUID=\'', _userUUID,
                            '\'');

        if (_asset_partUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_partUUID = \'', _asset_partUUID, '\'');
        END IF;
        if (_customerUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_customerUUID = \'', _customerUUID, '\'');
        end if;
        if (_asset_part_template_part_sku is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_template_part_sku = \'', _asset_part_template_part_sku, '\'');
        END IF;
        if (_asset_part_sku is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_sku = \'', _asset_part_sku, '\'');
        END IF;
        if (_asset_part_statusId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_statusId = ', _asset_part_statusId);
        END IF;
        if (_asset_part_name is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_name = \'', _asset_part_name, '\'');
        END IF;
        if (_asset_part_description is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_description = \'', _asset_part_description, '\'');
        END IF;
        if (_asset_part_userInstruction is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_userInstruction = \'', _asset_part_userInstruction, '\'');
        END IF;
        if (_asset_part_shortName is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_shortName = \'', _asset_part_shortName, '\'');
        END IF;
        if (_asset_part_imageURL is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_imageURL = \'', _asset_part_imageURL, '\'');
        END IF;
        if (_asset_part_imageThumbURL is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_imageThumbURL = \'', _asset_part_imageThumbURL, '\'');
        END IF;
        if (_asset_part_hotSpotJSON is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_hotSpotJSON = \'', _asset_part_hotSpotJSON, '\'');
        END IF;
        if (_asset_part_diagnosticUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_diagnosticUUID = \'', _asset_part_diagnosticUUID, '\'');
        END IF;
        if (_asset_part_magentoUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_magentoUUID = \'', _asset_part_magentoUUID, '\'');
        END IF;
        if (_asset_part_vendor is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_vendor = \'', _asset_part_vendor, '\'');
        END IF;
        if (_asset_part_isPurchasable is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_isPurchasable = ', _asset_part_isPurchasable);
        END IF;
        if (_asset_part_fabricId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',asset_part_fabricId = \'', _asset_part_fabricId, '\'');
        END IF;


        set @l_sql = CONCAT(@l_sql, ' where asset_partUUID = \'', _asset_partUUID, '\';');

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF (_action = 'SET_DIGNOSTIC') THEN

        IF (_asset_part_template_part_sku IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_part_template_part_sku missing';
            LEAVE ASSETPART_assetpart;

        ELSEIF (_asset_part_diagnosticUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_part_diagnosticUUID missing';
            LEAVE ASSETPART_assetpart;

        ELSE
            update asset_part set asset_part_updatedTS=now(),asset_part_diagnosticUUID = _asset_part_diagnosticUUID where asset_part_template_part_sku = _asset_part_template_part_sku;
            update part_template set part_updatedTS=now(),part_diagnosticUUID = _asset_part_diagnosticUUID where part_sku = _asset_part_template_part_sku;
        END IF;

    ELSEIF (_action = 'REMOVE_DIGNOSTIC') THEN

        IF (_asset_part_template_part_sku IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_part_template_part_sku missing';
            LEAVE ASSETPART_assetpart;

        ELSE
            update asset_part set asset_part_updatedTS=now(),asset_part_diagnosticUUID = null where asset_part_template_part_sku = _asset_part_template_part_sku;
            update part_template set part_updatedTS=now(),part_diagnosticUUID = null where part_sku = _asset_part_template_part_sku;
        END IF;

    ELSEIF (_action = 'DELETE') THEN

        IF (DEBUG = 1) THEN select _action, _asset_partUUID; END IF;

        IF (_asset_partUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _asset_partUUID missing';
            LEAVE ASSETPART_assetpart;
        END IF;

        update asset_part
        set asset_part_deleteTS=now(),
            asset_part_statusId=2,
            asset_part_updatedByUUID=_userUUID
        where asset_partUUID = _asset_partUUID
          and asset_part_customerUUID = _customerUUID;
        -- TBD, figure out what cleanup may be involved

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
-- call ATT_getPicklist('att_priority', null, null);

DROP procedure IF EXISTS `ATT_getPicklist`;

DELIMITER //
CREATE PROCEDURE `ATT_getPicklist`(IN _tables varchar(1000),
                                   IN _customerId CHAR(36),
                                   IN _userId CHAR(36),
                                   IN _assetUUID CHAR(60)
                                   )
getPicklist:
BEGIN

    IF (LOCATE('att_address_type', _tables) > 0) THEN
        select 'att_address_type' as tableName, id as id, name as value, name as name
        from att_address_type
        order by name;
    END IF;

    IF (LOCATE('att_phone', _tables) > 0) THEN
        select 'att_phone' as tableName, id as id, name as value, name as name from att_phone order by name;
    END IF;

    IF (LOCATE('att_status', _tables) > 0) THEN
        select 'att_status' as tableName, id as id, id as value, name as label from att_status order by label;
    END IF;

    IF (LOCATE('customer', _tables) > 0) THEN
        select 'customer' as tableName, customerUUID as id, customer_name as value, customer_name as name
        from customer
        order by customer_name;
    END IF;

    IF (LOCATE('checklist', _tables) > 0) THEN

        if (_customerId is null) Then
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
            LEAVE getPicklist;
        END IF;

        select 'checklist' as tableName, checklistUUID as id, checklist_name as value, checklist_name as name,
        checklist_partRequired as isPartRequire
        from checklist
        where checklist_customerUUID = _customerId AND checklist_deleteTS is NULL
        order by checklist_name;
    END IF;


    IF (LOCATE('group', _tables) > 0) THEN

        if (_customerId is null) Then
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
            LEAVE getPicklist;
        END IF;

        select 'group' as tableName, groupUUID as id, group_name as value, group_name as name
        from user_group
        where group_customerUUID = _customerId
        order by group_name;
    END IF;

    IF (LOCATE('asset', _tables) > 0) THEN

        if (_customerId is null) Then
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
            LEAVE getPicklist;
        END IF;

        select 'group' as tableName, assetUUID as id, asset_name as value, asset_name as name, asset_locationUUID as locationId
        from asset
        where asset_customerUUID = _customerId
        order by asset_name;
    END IF;

    IF (LOCATE('diagnostic_tree', _tables) > 0) THEN
        select 'diagnostic_tree' as tableName, diagnosticUUID as id, diagnosticUUID as value, diagnostic_name as label
        from diagnostic_tree
        order by label;
    end if;

    IF (LOCATE('location', _tables) > 0) THEN

        if (_customerId is null) Then
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
            LEAVE getPicklist;
        END IF;

        set @l_sql = 'select l.locationUUID as id, l.location_name as value, l.location_name as name
        from location l left join asset a on(l.locationUUID = a.asset_locationUUID)';
        set @l_sql = CONCAT(@l_sql,' where l.location_customerUUID =\'',_customerId,'\'');

        IF(_assetUUID is not null)THEN
             set @l_sql = CONCAT(@l_sql,' and a.assetUUID =\'',_assetUUID,'\'');
        END IF;

        set @l_sql = CONCAT(@l_sql,' order by l.location_name;');

        PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

    END IF;
     IF (LOCATE('isPrimary', _tables) > 0) THEN

        if (_customerId is null) Then
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
            LEAVE getPicklist;
        END IF;

        select 'location' as tableName, locationUUID as id, location_name as value, location_name as name
        from location
        where location_customerUUID = _customerId and location_statusId = 1 and location_isPrimary = 1
        order by location_name;
    END IF;

    -- IF (LOCATE('user', _tables) > 0) THEN

    --     if (_customerId is null) Then
    --         SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATT_getPicklist: _customerId can not be empty';
    --         LEAVE getPicklist;
    --     END IF;

    --     select 'user' as tableName, userUUID as id, user_userName as value, user_userName as name
    --     from `user`
    --     where user_customerUUID = _customerId
    --       and user_statusId = 1
    --     order by user_userName;
    -- END IF;

    IF (LOCATE('att_userlevel_predefined', _tables) > 0) THEN
        select 'att_userlevel_predefined' as tableName, description as id, bitwise as value, bitwise as name
        from att_userlevel_predefined
        order by description;
    END IF;

    IF (LOCATE('att_priority', _tables) > 0) THEN
        select * from att_priority;
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
CREATE PROCEDURE SECURITY_bitwise(IN _action VARCHAR(100),
                                  IN _userId CHAR(36),
                                  IN _targetUserId CHAR(36),
                                  IN _att_userlevel_predefined INT,
                                  IN _att_bitwise BIGINT)
SECURITY_bitwise:
BEGIN

    DECLARE _DEBUG INT DEFAULT 1;

    DECLARE _att_userlevel_predefined_bitwise BIGINT DEFAULT 0;
    DECLARE _customer_securityBitwise BIGINT DEFAULT 0;
    DECLARE _brand_securityBitwise BIGINT DEFAULT 0;
    DECLARE _group_securityBitwise BIGINT DEFAULT 0;
    DECLARE _user_individualSecurityBitwise BIGINT DEFAULT 0;

    DECLARE _user_securityBitwise BIGINT DEFAULT 0;

    DECLARE _customerId CHAR(36);
    DECLARE _brandId CHAR(36);

    if (_action = 'ADDUSERSECURITY') THEN

        select user_customerUUID, user_securityBitwise, user_individualSecurityBitwise
        INTO
            _customerId,_user_securityBitwise,_user_individualSecurityBitwise
        from `user`
        where userUUID = _targetUserId;

        select _user_individualSecurityBitwise | _att_bitwise into _user_individualSecurityBitwise;

        update `user` set user_individualSecurityBitwise=_user_individualSecurityBitwise where userUUID = _targetUserId;

        set _action = 'CALCULATE';

    ELSEif (_action = 'REMOVESECURITY') THEN

        select user_customerUUID, user_securityBitwise, user_individualSecurityBitwise
        INTO
            _customerId,_user_securityBitwise,_user_individualSecurityBitwise
        from `user`
        where userUUID = _targetUserId;

        select _user_individualSecurityBitwise ^ _att_bitwise into _user_individualSecurityBitwise;

        update `user` set user_individualSecurityBitwise=_user_individualSecurityBitwise where userUUID = _targetUserId;

        set _action = 'CALCULATE';

    END IF;

    if (_action = 'CALCULATE') THEN

        -- user
        select user_customerUUID, user_securityBitwise, user_individualSecurityBitwise
        INTO
            _customerId,_user_securityBitwise,_user_individualSecurityBitwise
        from `user`
        where _targetUserId = userUUID;

        -- customer
        select customer_securityBitwise into _customer_securityBitwise from customer where customerUUID = _customerId;

        -- brand
        select ifnull(brand_securityBitwise, 0)
        into _brand_securityBitwise
        from customer_brand b
                 left join customer c on (c.customer_brandUUID = b.brandUUID)
        where c.customerUUID = _customerId;

        -- groups
        -- select into _group_securityBitwise where ugj_userUUID = userUUID;

        set _user_securityBitwise = _customer_securityBitwise | _brand_securityBitwise | _group_securityBitwise |
                                    _user_individualSecurityBitwise;

        update `user` set user_securityBitwise=_user_securityBitwise where userUUID = _targetUserId;

    END IF;

    IF (_DEBUG = 1) THEN
        select _action,
               _customerId,
               _user_securityBitwise,
               _customer_securityBitwise,
               _user_individualSecurityBitwise,
               _brand_securityBitwise,
               _group_securityBitwise,
               _targetUserId;
    END IF;

END$$

-- ==================================================================

/*
call NOTIFICATION_notification(
_action,_userUUID,
_notification_templateId,_notificationId,_notificationType,
_notification_toEmail,_notification_toSMS,_notification_toUserUUID,_notification_toGroupUUID,_notification_toAppUUID,
_notification_fromAppUUID,_notification_fromUserUUID,_notification_workorderUUID,
_notification_readyOn,_notification_expireOn,
_notification_content,_notification_subject,_notification_hook,
_notification_assetUUID,_notification_priority,_notification_isClearable
);

call NOTIFICATION_notification(
'CREATE',1,
1,null,'APP',
null,null,1,null,null,
null,2,_notification_workorderUUID,
'22-05-2020T01:25Z','22-05-2021T01:25Z',
'Content','_notification_subject','_notification_hook',
_notification_assetUUID,_notification_priority,_notification_isClearable
);


call NOTIFICATION_notification('GETAPP',1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
call NOTIFICATION_notification('GETSMS',1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
call NOTIFICATION_notification('GETEMAIL',1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);

call NOTIFICATION_notification('ACKNOWLEDGE',null,null,1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
call NOTIFICATION_notification('ACKNOWLEDGE',null,null,null,null,null,null,null,null,1,null,null,null,null,null,null,null,null,null,null,null);

call NOTIFICATION_notification('CLEANUP',null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);

*/

DROP procedure IF EXISTS `NOTIFICATION_notification`;

DELIMITER $$
CREATE PROCEDURE `NOTIFICATION_notification`(IN _action VARCHAR(100),
                                             IN _userUUID CHAR(36),
                                             IN _notification_templateKey varchar(25),
                                             IN _notificationId INT,
                                             IN _notification_type VARCHAR(25),
                                             IN _notification_toEmail VARCHAR(255),
                                             IN _notification_toSMS VARCHAR(100),
                                             IN _notification_toUserUUID CHAR(36),
                                             IN _notification_toGroupUUID CHAR(36),
                                             IN _notification_toAppUUID CHAR(36),
                                             IN _notification_fromAppUUID CHAR(36),
                                             IN _notification_fromUserUUID CHAR(36),
                                             IN _notification_workorderUUID CHAR(36),
                                             IN _notification_readyOn VARCHAR(36),
                                             IN _notification_expireOn VARCHAR(36),
                                             IN _notification_content TEXT,
                                             IN _notification_subject VARCHAR(255),
                                             IN _notification_hook VARCHAR(255),
                                             IN _notification_assetUUID VARCHAR(255),
                                             IN _notification_priority VARCHAR(25),
                                             IN _notification_isClearable INT)
NOTIFICATION_notification:
BEGIN

    DECLARE _DEBUG INT DEFAULT 0;

    DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%YT%h:%iZ';
    DECLARE _notificationFoundId INT;
    DECLARE _commaNeeded INT;

    DECLARE _readyDate datetime;
    DECLARE _expireDate datetime;


    IF (_action = 'GETAPP') THEN

        select *
        from (select *
              from notification_queue
              where notification_type = 'APP'
                and notification_toUserUUID = _userUUID
                and notification_expireOn > now()
                and notification_readyOn < now()
                and notification_statusId < 3
                -- and notification_assetUUID is null
              union all
              select *
              from notification_queue
              where notification_type = 'APP'
                and notification_toGroupUUID in
                    (select ugj_groupUUID from user_group_join where ugj_userUUID = _userUUID)
                and notification_expireOn > now()
                and notification_readyOn < now()
                and notification_statusId < 3
                -- and notification_assetUUID is null
                ) no;
                 -- left join user u on no.notification_fromUserUUID = u.userUUID;

    ELSEIF (_action = 'GETSMS') THEN

        select *
        from notification_queue
        where notification_type = 'SMS'
          and notification_expireOn > now()
          and notification_readyOn < now()
          and notification_statusId < 3;

    ELSEIF (_action = 'GETASSET') THEN

        select *
        from notification_queue
        where notification_type = 'APP'
          and notification_expireOn > now()
          and notification_readyOn < now()
          and notification_statusId < 3
          and notification_assetUUID = _notification_assetUUID;

    ELSEIF (_action = 'GETEMAIL') THEN

        select *
        from notification_queue
        where notification_type = 'EMAIL'
          and notification_expireOn > now()
          and notification_readyOn < now()
          and notification_statusId < 3;

    ELSEIF (_action = 'CREATE') THEN

        if (_notification_readyOn IS NOT NULL) THEN
            set _readyDate = (STR_TO_DATE(_notification_readyOn, _dateFormat));
        ELSE
            set _readyDate = now();
        END IF;

        if (_notification_expireOn IS NOT NULL) THEN
            set _expireDate = (STR_TO_DATE(_notification_expireOn, _dateFormat));
        ELSE
            set _expireDate = DATE_ADD(now(), INTERVAL 2 WEEK);
        END IF;

        -- attempt to find duplicates

        -- select userUUID into _notificationFoundId from `notification_queue`
        -- where notification_subject=_notification_subject;

        IF (_notificationFoundId is null) THEN

            insert into `notification_queue` (notification_type,
                                              notification_toEmail, notification_toSMS, notification_toGroupUUID,
                                              notification_toAppUUID, notification_toUserUUID,
                                              notification_fromAppUUID, notification_fromUserUUID,
                                              notification_readyOn, notification_expireOn,
                                              notification_statusId, notification_content, notification_subject,
                                              notification_hook,notification_priority,notification_isClearable,
                                              notification_assetUUID,notification_createdTS,notification_workorderUUID)
            values (_notification_type,
                    _notification_toEmail, _notification_toSMS, _notification_toGroupUUID, _notification_toAppUUID,
                    _notification_toUserUUID,
                    _notification_fromAppUUID, _notification_fromUserUUID,
                    _readyDate, _expireDate,
                    1, _notification_content, _notification_subject,
                    _notification_hook,_notification_priority,_notification_isClearable,
                    _notification_assetUUID,now(),_notification_workorderUUID);

        END IF;

    ELSEIF (_action = 'DELETE') THEN

        if (_notificationId is not null) then
            DELETE from notification_queue where notificationId = _notificationId;
        elseif (_notification_toUserUUID is not null) then
            DELETE from notification_queue where notification_toUserUUID = _notification_toUserUUID; -- deleted
        elseif (_notification_toGroupUUID is not null) then
            DELETE from notification_queue where notification_toGroupUUID = _notification_toGroupUUID; -- deleted
        END IF;

    ELSEIF (_action = 'CLEANUP') THEN

        DELETE from notification_queue where notification_expireOn < now();
        DELETE from notification_queue where notification_statusId = 3; -- deleted

    ELSEIF (_action = 'READ' and _notificationId is not null) THEN

        update notification_queue set notification_statusId=2 where notificationId = _notificationId;
        -- and notification_isClearable=1;

    ELSEIF (_action = 'ACKNOWLEDGE' and _notificationId is not null) THEN

        update notification_queue set notification_statusId=3 where notificationId = _notificationId;
        -- and notification_isClearable=1;

    ELSEIF (_action = 'ACKNOWLEDGE' and _notification_workorderUUID is not null) THEN

        update notification_queue set notification_statusId=3 where notification_workorderUUID = _notification_workorderUUID;

    ELSE
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call NOTIFICATION_notification: _action is of type invalid';
        LEAVE NOTIFICATION_notification;
    END IF;


    IF (_DEBUG = 1) THEN
        select _action,
               _notification_type,
               _notification_toEmail,
               _notification_toSMS,
               _notification_toGroupUUID,
               _notification_toAppUUID,
               _notification_toUserUUID,
               _notification_fromAppUUID,
               _notification_fromUserUUID,
               _readyDate,
               _expireDate,
               _notification_statusId,
               _notification_content,
               _notification_subject,
               _notification_hook;

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
CREATE PROCEDURE `USER_login`(IN _action VARCHAR(100),
                              IN _userId CHAR(36),
                              IN _entityId CHAR(36),
                              IN _USER_loginEmail VARCHAR(100),
                              IN _USER_loginPW VARCHAR(100),
                              IN _USER_loginEmailValidationCode VARCHAR(100),
                              IN _USER_loginEnabled INT,
                              IN _USER_loginPWReset INT)
USER_login:
BEGIN

    DECLARE _USER_loginLast DATETIME;
    DECLARE _USER_loginFailedAttempts INT;
    DECLARE _USER_loginPWExpire DATETIME;
    DECLARE _userName varchar(100);
    DECLARE _password varchar(100);
    DECLARE _USER_loginEmailVerified DATETIME;
    DECLARE _customerUUID varchar(100);
    DECLARE _securityBitwise varchar(100);
    DECLARE _individualSecurityBitwise varchar(100);


    DECLARE _DISABLE_MFA INT default 1; -- 0 is enable MFA

    DECLARE DEBUG INT DEFAULT 0;


    IF (_action IS NULL) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_login: _action can not be empty';
        LEAVE USER_login;
    END IF;

    IF (_action = 'LOGIN' and _USER_loginEmail is NOT null and _USER_loginPW is not null) THEN


        select userUUID,
               user_customerUUID,
               user_userName,
               user_loginEnabled,
               user_loginPW,
               user_loginEmailVerified,
               user_securityBitwise,
               user_individualSecurityBitwise
        into _entityId, _customerUUID, _userName, _USER_loginEnabled,_password,_USER_loginEmailVerified, _securityBitwise, _individualSecurityBitwise
        from `user`
        where user_loginEmail = _USER_loginEmail;

        if (DEBUG = 1) THEN
            select _action,
                   _USER_loginEmail,
                   _USER_loginPW,
                   _entityId,
                   _USER_loginEnabled,
                   _password,
                   _USER_loginEmailVerified;
        END IF;

        if (_entityId is null) THEN
            SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call USER_login: user not found';
            LEAVE USER_login;
        END IF;

        if (_USER_loginEnabled = 0) THEN
            SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call USER_login: login not enabled';
            LEAVE USER_login;
        END IF;

        if (_USER_loginEmailVerified is null) THEN
            SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call USER_login: email not verified';
            LEAVE USER_login;
        END IF;

        if (_USER_loginPW <> _password) THEN
            SIGNAL SQLSTATE '41007' SET MESSAGE_TEXT = 'call USER_login: password not correct';
            LEAVE USER_login;
        END IF;

        if (_DISABLE_MFA = 0) THEN
            select SESSION_generateAccessCode(4) into _USER_loginEmailValidationCode;


            update `user`
            set user_loginLast=now(),
                user_loginSessionExpire= DATE_ADD(now(), INTERVAL 4 MINUTE),
                user_loginEmailValidationCode=_USER_loginEmailValidationCode,
                user_loginFailedAttempts=0
            where userUUID = _entityId;

            call NOTIFICATION_notification(
                    'CREATE', null,
                    'MFA', null, 'SMS',
                    null, _entityId, null, null, null,
                    null, 2,null,
                    null, null,
                    concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode),
                    concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode), null
                );
            call NOTIFICATION_notification(
                    'CREATE', null,
                    'MFA', null, 'EMAIL',
                    _entityId, null, null, null, null,
                    null, 2,null,
                    null, null,
                    concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode),
                    concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode), null
                );

            select _entityId                      as entityId,
                   _USER_loginEmailValidationCode as accessCode,
                   4                              as expiresInMinutes,
                   _userName                      as userName,
                   _securityBitwise               as securityBitwise,
                   _individualSecurityBitwise     as individualSecurityBitwise,
                   _customerUUID                  as customerUUID;

        ELSE

            -- call ENTITY_session('CREATE', _entityId,null,@accessToken);
            select SESSION_generateSession(25) into _USER_loginEmailValidationCode;

            update `user`
            set user_loginEmailValidationCode=null,
                user_loginSession=_USER_loginEmailValidationCode,
                user_loginLast= now(),
                user_loginSessionExpire=DATE_ADD(now(), INTERVAL 8 HOUR)
            where userUUID = _entityId;

            select _entityId                      as entityId,
                   _USER_loginEmailValidationCode as sessionToken,
                   _userName                      as userName,
                   _securityBitwise               as securityBitwise,
                   _individualSecurityBitwise     as individualSecurityBitwise,
                   _customerUUID                  as customerUUID;

        END IF;


        -- TODO, handle login in attempts and lockout in the future.

    ELSEIF (_action = 'MFA' and _USER_loginEmail is NOT null and _USER_loginEmailValidationCode is not null) THEN

        select userUUID,
               user_customerUUID,
               user_userName,
               user_loginEnabled,
               user_loginPW,
               user_loginEmailVerified,
               user_securityBitwise,
               user_individualSecurityBitwise
        into _entityId, _customerUUID, _userName, _USER_loginEnabled,_password,_USER_loginEmailVerified, _securityBitwise, _individualSecurityBitwise
        from `user`
        where user_loginEmail = _USER_loginEmail
          and user_loginEmailValidationCode = _USER_loginEmailValidationCode
          and now() < user_loginSessionExpire;


        if (DEBUG = 1) THEN
            select _action, _entityId, _USER_loginEnabled, _USER_loginEmailValidationCode, _USER_loginEmail;
        END IF;

        if (_entityId is not null) THEN

            -- call ENTITY_session('CREATE', _entityId,null,@accessToken);
            select SESSION_generateSession(25) into _USER_loginEmailValidationCode;

            update `user`
            set user_loginEmailValidationCode=null,
                user_loginSession=_USER_loginEmailValidationCode,
                user_loginLast= now(),
                user_loginSessionExpire=DATE_ADD(now(), INTERVAL 8 HOUR)
            where userUUID = _entityId;

            select _entityId                      as entityId,
                   _USER_loginEmailValidationCode as sessionToken,
                   _userName                      as userName,
                   _securityBitwise               as securityBitwise,
                   _individualSecurityBitwise     as individualSecurityBitwise,
                   _customerUUID                  as customerUUID;

        else
            SIGNAL SQLSTATE '45004' SET MESSAGE_TEXT = 'Your authentication code has expired or does not match.', MYSQL_ERRNO = 12;
            LEAVE USER_login;

        END IF;

    ELSEIF (_action = 'FORGOTPASSWORD' and _USER_loginEmail is not null) THEN

        -- set _USER_loginEmailValidationCode = SESSION_generateAccessCode(7);
        select userUUID, user_loginEnabled, `user_loginPW`, user_loginEmailVerified
        into _entityId, _USER_loginEnabled,_USER_loginPW,_USER_loginEmailVerified
        from `user`
        where user_loginEmail = _USER_loginEmail
          and user_loginEnabled = 1;

        if (_entityId is not null and _USER_loginEnabled > 0 and _USER_loginEmailVerified is not null) THEN
            -- update contact set password=_USER_loginEmailValidationCode, emailValidationCode=_USER_loginEmailValidationCode where contactId=_entityId;
            -- call updateNotificationQueue('ADD',null,null,'PASSWORD_TEMPORARY','EMAIL',null,_entityId,null,0,null,null);
            call NOTIFICATION_notification(
                    'CREATE', null,
                    'PASSWORD_TEMPORARY', null, 'EMAIL',
                    _entityId, null, null, null, null,
                    null, 2,null,
                    null, null,
                    concat('Your password is: ', _USER_loginPW, ' Please change once you log back in.'),
                    'Password Reminder', null
                );

        END IF;

        if (DEBUG = 1) THEN
            select _action, _entityId, _USER_loginPW, _USER_loginEnabled, _USER_loginEmailVerified;
        END IF;

    ELSEIF (_action = 'RESETPASSWORD' and _entityId is not null and _USER_loginPW is not null) THEN

        select user_loginEnabled, user_loginPW, user_loginEmailVerified
        into _USER_loginEnabled,_password,_USER_loginEmailVerified
        from `user`
        where userUUID = _entityId;

        if (_entityId is not null and _USER_loginEnabled > 0 and _USER_loginEmailVerified is not null) THEN

            update `user`
            set user_loginEmailValidationCode=null,
                `user_loginPW`= _USER_loginPW,
                user_loginFailedAttempts=0
            where userUUID = _entityId;

        end if;
        -- update entity set USER_loginPW=_USER_loginPW, USER_loginPWReset=0  where entityId=_entityId;

        if (DEBUG = 1) THEN
            select _action,
                   _entityId,
                   _password as oldPass,
                   _USER_loginPW,
                   _USER_loginEnabled,
                   _USER_loginEmailVerified;
        END IF;

        -- call updateNotificationQueue('ADD',null,'MFA','EMAIL',null,_entityId,null,0,null,null);

    ELSEIF (_action = 'ACCESS' and _USER_loginEnabled is NOT null and _entityId is not null) THEN

        if (_USER_loginEnabled = 0) THEN

            update `user`
            set user_loginEnabled=0,
                user_loginPWReset=1,
                user_loginPWExpire=now(),
                user_loginEmailValidationCode=null,
                user_loginSession=null
            where userUUID = _entityId;

        ELSE

            if (_USER_loginEmail is not null) then
                update `user` set user_loginEmail=_USER_loginEmail where userUUID = _entityId;
            END IF;

            if (_USER_loginPW is not null) then
                update `user` set user_loginPW=_USER_loginPW where userUUID = _entityId;
            END IF;

            select user_loginEnabled, user_loginPW, user_loginEmail
            into _USER_loginEnabled,_password,_USER_loginEmail
            from `user`
            where userUUID = _entityId;

            if (_password is null) then
                update `user` set user_loginPW=SESSION_generateAccessCode(7) where userUUID = _entityId;
            END IF;


            if (_USER_loginEmail is null) then
                SIGNAL SQLSTATE '45007' SET MESSAGE_TEXT = 'User login can not be enabled if email is not valid.', MYSQL_ERRNO = 12;
                LEAVE USER_login;
            END IF;

            set _USER_loginEmailValidationCode = SESSION_generateAccessCode(7);

            update `user`
            set user_loginEnabled=1,
                user_loginEmailValidationCode=_USER_loginEmailValidationCode
            where userUUID = _entityId;
            -- call updateNotificationQueue('ADD',null,null,'INVITELOGIN','EMAIL',null,_entityId,null,0,null,null);

            call NOTIFICATION_notification(
                    'CREATE', null,
                    'INVITELOGIN', null, 'EMAIL',
                    _entityId, null, null, null, null,
                    null, 2,null,
                    null, null,
                    concat('Please verify your email: http://action=VERIFY'),
                    'Invitatin', null
                );

        END IF;

        if (DEBUG = 1) THEN select _action, _entityId, _USER_loginEnabled, _USER_loginEmailValidationCode; END IF;

    ELSEIF (_action = 'RESENDMFA' and _entityId is not null) THEN

        set _USER_loginEmailValidationCode = SESSION_generateAccessCode(4);

        update `user`
        set user_loginLast=now(),
            user_loginSessionExpire= DATE_ADD(now(), INTERVAL 4 MINUTE),
            user_loginEmailValidationCode=_USER_loginEmailValidationCode,
            user_loginFailedAttempts=0
        where userUUID = _entityId;


        call NOTIFICATION_notification(
                'CREATE', null,
                'MFA', null, 'SMS',
                null, _entityId, null, null, null,
                null, 2,null,
                null, null,
                concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode),
                concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode), null
            );
        call NOTIFICATION_notification(
                'CREATE', null,
                'MFA', null, 'EMAIL',
                _entityId, null, null, null, null,
                null, 2,null,
                null, null,
                concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode),
                concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode), null
            );
        select _entityId as entityId, _USER_loginEmailValidationCode as accessCode, 4 as expiresInMinutes;

        if (DEBUG = 1) THEN select _action, _entityId, _USER_loginEmailValidationCode; END IF;

        -- select _entityId as entityId, _USER_loginEmailValidationCode as validationCode;

    ELSEIF (_action = 'VERIFYEMAIL' and _USER_loginEmailValidationCode is NOT null and
            _USER_loginEmail is not null) THEN

        select userUUID
        into _entityId
        from `user`
        where user_loginEmail = _USER_loginEmail
          and user_loginEmailValidationCode = _USER_loginEmailValidationCode;


        if (DEBUG = 1) THEN select _action, _entityId, _USER_loginEmail, _USER_loginEmailValidationCode; END IF;

        if (_entityId is null) THEN
            SIGNAL SQLSTATE '45006' SET MESSAGE_TEXT = 'Verification code not valid', MYSQL_ERRNO = 12;
            LEAVE USER_login;
        END IF;

        update `user` set user_loginEmailVerified=now(), user_loginEmailValidationCode=null where userUUID = _entityId;

    END IF;

END$$


DELIMITER ;

-- ==================================================================

-- SELECT VAIDATECHECKLISTITEM('6', 'value', '5,9')
-- SELECT VAIDATECHECKLISTITEM('1','boolean', null)
-- SELECT VAIDATECHECKLISTITEM('GOD', 'text', null)
-- SELECT VAIDATECHECKLISTITEM('88', 'value', '5,6')
-- for checklist_history_item_status
-- 	1 -> Pending
-- 	2 -> Failed
-- 	3 -> Passed
-- 	4 -> NA
use jcmi_hms;
DROP FUNCTION IF EXISTS vaidateChecklistItem;

DELIMITER //
CREATE FUNCTION `vaidateChecklistItem`(_value VARCHAR(100), _type CHAR(36), _succRange CHAR(36))
RETURNS varchar(10)
BEGIN
DECLARE _checklistStatus INT default 1;
IF(_type = 'boolean') then -- for the checklist type boolean
IF(_value = _succRange) then
set _checklistStatus = 3;
ELSE
set _checklistStatus = 2;
END IF;
END IF;
IF(_type = 'value') THEN -- for the checklist type
select CAST(SUBSTRING_INDEX(_succRange, ',',-1) AS UNSIGNED INTEGER) into  @maxVal;
select CAST(SUBSTRING_INDEX(_succRange, ',', 1) AS UNSIGNED INTEGER) into  @minVal;
IF(_value <= @maxVal and _value >= @minVal) THEN
set _checklistStatus = 3 ;-- passed
ELSE
set _checklistStatus = 2; -- failed
END IF;
END IF;
IF(_type = 'text') THEN
if(_value is not null and _value != '') THEN
set _checklistStatus = 3;
ELSE
set _checklistStatus = 2;
END IF;

END IF;
return _checklistStatus;
END;

DELIMITER ;
-- ==================================================================
/*
call CHECKLIST_checklist(
_action,_userUUID,_customerUUID,
_checklistUUID, _assetUUID,_historyUUID, _workorderUUID,
_checklist_statusId,_checklist_name, _checklist_recommendedFrequency,_checklist_rulesJSON,
_checklist_itemUUID,_checklist_item_statusId,_checklist_item_sortOrder,
_checklist_item_prompt, _checklist_item_type, _checklist_item_optionSetJSON,
_checklist_item_successPrompt, _checklist_item_successRange,
checklist_history_item_resultFlag,checklist_history_item_resultText, _checklist_history_item_historyUUID, _checklist_partRequired
);

call CHECKLIST_checklist(
'GET_HISTORY','1',null,
'2b61b61eb4d141799a9560cccb109f59', null, null, null,null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);

-- creates a cl and wo
call CHECKLIST_checklist(
'UPDATE_HISTORY','1','a30af0ce5e07474487c39adab6269d5f',
'2b61b61eb4d141799a9560cccb109f59', '00c93791035c44fd98d4f40ff2cdfe0a',uuid(),
null, null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);

-- updates a cl item
call CHECKLIST_checklist(
'UPDATE_HISTORY','1','a30af0ce5e07474487c39adab6269d5f',
'2b61b61eb4d141799a9560cccb109f59', '00c93791035c44fd98d4f40ff2cdfe0a','100',
null, null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);


call CHECKLIST_checklist(
'GET_TEMPLATE','1','a30af0ce5e07474487c39adab6269d5f',
'2b61b61eb4d141799a9560cccb109f59', null, null, null,null, null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);

call CHECKLIST_checklist(
'GET_HISTORY','1','a30af0ce5e07474487c39adab6269d5f',
null, null, '9910d4bb-fd03-11ea-a1a5-4e53d94465b4', null,null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);
-- gets history by workorderUUID
call CHECKLIST_checklist(
'GET_HISTORY','1',null,
null, null, null, '88602c15-3b1c-11eb-a1a5-4e53d94465b4',null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);

call CHECKLIST_checklist(
'PASS_CHECKLIST','1',null,
null, null, 'af103ffe-fdde-11ea-a1a5-4e53d94465b4', null,null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);

call CHECKLIST_checklist(
'FAIL_CHECKLIST_CREATEWO','1','a30af0ce5e07474487c39adab6269d5f',
null, null, 'af103ffe-fdde-11ea-a1a5-4e53d94465b4', null,null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);
call CHECKLIST_checklist(
'GET',null,null,
'2b61b61eb4d141799a9560cccb109f59', null, null, null,null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);

call CHECKLIST_checklist(
'GET_HISTORY',null,null,
null, null, 'f4dcf10d-51b7-11eb-a1a5-4e53d94465b4', 'f4dcfb91-51b7-11eb-a1a5-4e53d94465b4',null,null, null,null,null,null,null, null, null, null, null, null, null, null, null,null
);
*/

DROP procedure IF EXISTS `CHECKLIST_checklist`;

DELIMITER $$
CREATE PROCEDURE `CHECKLIST_checklist`(
IN _action VARCHAR(100),
IN _userUUID char(36),
IN _customerUUID char(36),
IN _checklistUUID char(36),
IN _assetUUID char(36),
IN _historyUUID char(36),
IN _workorderUUID char(36),
IN _checklist_statusId INT,
IN _checklist_name varchar(255),
IN _checklist_recommendedFrequency varchar(25), -- [HOURLY,DAILY,WEEKLY,MONTHLY,YEARLY]
IN _checklist_rulesJSON TEXT,

IN _checklist_itemUUID char(36),
IN _checklist_item_statusId INT, -- 0,1
IN _checklist_item_sortOrder INT,
IN _checklist_item_prompt varchar(255),
IN _checklist_item_type varchar(255),
IN _checklist_item_optionSetJSON TEXT,
IN _checklist_item_successPrompt varchar(255),
IN _checklist_item_successRange varchar(255),

IN _checklist_history_item_resultFlag INT,
IN _checklist_history_item_resultText varchar(255),
IN _checklist_history_item_historyUUID char(36),
IN _checklist_partRequired INT,
IN _checklist_history_comment varchar(255)
)
CHECKLIST_checklist: BEGIN

DECLARE _DEBUG INT DEFAULT 0;

DECLARE _ids varchar(1000);
DECLARE _id varchar(100);
DECLARE SubStrLen INT;
DECLARE strLen INT;

DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%YT%h:%iZ';
DECLARE _foundId char(36);
DECLARE _foundChecklistItemId char(36);
DECLARE _commaNeeded INT;

DECLARE _readyDate datetime;
DECLARE _expireDate datetime;
DECLARE _assetName varchar(255);
DECLARE _workorder_locationUUID char(36);
DECLARE _checklist_itemHistoryIds varchar(1024) DEFAULT '';
DECLARE _checklist_itemIds varchar(1024) DEFAULT '';
DECLARE _checklist_history_resultFlag INT DEFAULT 0;
DECLARE _checklistStatus INT default 1;
DECLARE failedChecklistCount INT default 0;
 DECLARE  _workorder_actions  VARCHAR(1000) default '';
IF(_action='GET')Then

     set  @l_sql = CONCAT('select cl.*,clh.* from checklist cl left join checklist_history clh on
    (cl.checklistUUID = clh.checklist_history_checklistUUID)');

	if(_checklistUUID is not null or _historyUUID is not null ) THEN
			set @l_sql = CONCAT(@l_sql,' where');
		END IF;

    if ( _checklistUUID is not null) THEN
        set @l_sql = CONCAT(@l_sql,' cl.checklistUUID = \'', _checklistUUID,'\'');
    END IF;

	if(_checklistUUID is not null and _historyUUID is not null ) THEN
			set @l_sql = CONCAT(@l_sql,' and');
		END IF;

    if ( _historyUUID is not null) THEN
       set @l_sql = CONCAT(@l_sql,' clh.checklist_historyUUID = \'', _historyUUID,'\'');
     END IF;

     IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

	PREPARE stmt FROM @l_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

ELSEIF(_action ='GET_HISTORY' and (_historyUUID is not null or _checklistUUID is not null or _checklist_itemUUID is not null  or _workorderUUID is not null)) THEN

    set  @l_sql = CONCAT('select c.*,i.* from checklist_history c ');
    set  @l_sql = CONCAT(@l_sql,'left join checklist_item_history i on (i.checklist_history_item_historyUUID = c.checklist_historyUUID) ');
    set  @l_sql = CONCAT(@l_sql,' where ');

    if ( _historyUUID is not null) THEN
        set @l_sql = CONCAT(@l_sql,'c.checklist_historyUUID = \'', _historyUUID,'\'');
        set _commaNeeded=1;
    END IF;
    if ( _checklistUUID is not null) THEN
        set @l_sql = CONCAT(@l_sql,'c.checklist_history_checklistUUID = \'', _checklistUUID,'\'');
        set _commaNeeded=1;
    END IF;
    if ( _checklist_itemUUID is not null) THEN
        if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
        set @l_sql = CONCAT(@l_sql,'i.checklist_history_itemUUID = \'', _checklist_itemUUID,'\'');
        set _commaNeeded=1;
    END IF;
    if ( _workorderUUID is not null) THEN
        if (_commaNeeded=1) THEN set @l_sql = CONCAT(@l_sql,' AND '); END IF;
        set @l_sql = CONCAT(@l_sql,'c.checklist_history_workorderUUID = \'', _workorderUUID,'\'');
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
ELSEIF( _action = 'VALIDATE' or _action= 'COMPLETE') THEN
 -- 	1 -> Incomplete
 -- 	2 -> Complete_Failed
 -- 	3 -> Complete_Passed
	IF(_action = 'VALIDATE') THEN
		 set failedChecklistCount = 0;
		   select count(*)  into failedChecklistCount from checklist_item_history where checklist_history_item_historyUUID= _historyUUID and checklist_history_item_statusId not in ('3', '4'); -- count of not passed checklistHistoryItem
			select failedChecklistCount;
	END IF;
    IF(_action= 'COMPLETE') THEN
          IF(_checklist_statusId is not null) THEN
			update checklist_history set  checklist_history_statusId = _checklist_statusId where checklist_historyUUID = _historyUUID ; -- 3 -> COMPLETE_PASSED
            IF(_checklist_statusId = '3') THEN set @checklistStatus = '(COMPLETE_PASSED)'; ELSE set  @checklistStatus = '(COMPLETE_FAILED)'; END IF;
            set @WorkorderAction = CONCAT(_checklist_name, @checklistStatus);
            select workorder_actions into _workorder_actions from workorder where workorderUUID= _workorderUUID;
            if(_workorder_actions is null) THEN
				set  _workorder_actions = @WorkorderAction;
			else
				set  _workorder_actions = CONCAT(_workorder_actions,',', CHAR(13), @WorkorderAction);
            END IF;
            IF(_checklist_history_comment is not null) THEN
					set _workorder_actions = CONCAT(_workorder_actions, CHAR(13), 'cmt: ', _checklist_history_comment);
            END IF;
           update workorder set  workorder_updatedTS=now(), workorder_actions = _workorder_actions where workorderUUID = _workorderUUID;
            select _workorder_actions, @WorkorderAction;
          END IF;
          if(_checklist_history_comment is not null and _historyUUID is not null) THEN
				update checklist_history set checklist_history_updatedtS = now(), checklist_history_comment = _checklist_history_comment where checklist_historyUUid = _historyUUID;
		 END IF;
	END IF;
ELSEIF( _action ='UPDATE_HISTORY' or _action ='FAIL_CHECKLIST_CREATEWO' ) THEN

    if (_customerUUID is null) THEN
        SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call CHECKLIST_checklist: _customerUUID required';
        LEAVE CHECKLIST_checklist;
    END IF;
    if (_checklistUUID is null) THEN
        SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call CHECKLIST_checklist: _checklistUUID required';
        LEAVE CHECKLIST_checklist;
    END IF;

    if (_historyUUID is null and _action = 'UPDATE_HISTORY') THEN
        set _historyUUID = uuid();
    ELSEIF(_historyUUID is null)then
        SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call CHECKLIST_checklist: _historyUUID required';
        LEAVE CHECKLIST_checklist;
    END IF;

    IF (_action ='FAIL_CHECKLIST_CREATEWO') THEN

        -- consider getting checklist_history_checklistUUID,checklist_history_assetUUID
        -- checklist_history_checklistUUID, checklist_history_customerUUID, checklist_history_workorderUUID,
        -- checklist_history_assetUUID, checklist_history_statusId, checklist_history_resultFlag,
        -- checklist_history_name, checklist_history_rulesJSON

        select checklist_history_workorderUUID,checklist_history_checklistUUID,checklist_history_assetUUID
        into _workorderUUID, _checklistUUID,_assetUUID
        from checklist_history
        where checklist_historyUUID = _historyUUID;

        update  checklist_history set checklist_history_resultFlag=2,checklist_history_updatedTS=now(),
                checklist_history_updatedByUUID=_userUUID
                where checklist_historyUUID = _historyUUID;

        update  workorder set workorder_completeDate=Date(now()), workorder_updatedTS = now(),
                workorder_updatedByUUID = _userUUID, workorder_status = 'Complete'
                where workorderUUID = _workorderUUID;

        set _workorderUUID = null;
        set _historyUUID= UUID();

    END IF;

	-- 1. determine if history aready exists
    select checklist_historyUUID into _foundId from checklist_history where checklist_historyUUID=_historyUUID;

	select asset_locationUUID,asset_name into _workorder_locationUUID, _assetName from asset where assetUUID =_assetUUID;

	select checklist_name,checklist_rulesJSON into _checklist_name,_checklist_rulesJSON from checklist where checklistUUID =_checklistUUID;

	-- need to create a new checklist and workorder
    if (_foundId is null) THEN

        if (_workorderUUID is null) then select UUID() into _workorderUUID; end if;

        insert into checklist_history (
            checklist_historyUUID, checklist_history_checklistUUID, checklist_history_customerUUID,
            checklist_history_workorderUUID, checklist_history_assetUUID, checklist_history_statusId,
            checklist_history_name, checklist_history_rulesJSON,
            checklist_history_resultFlag,
            checklist_history_createdByUUID, checklist_history_updatedByUUID, checklist_history_updatedTS, checklist_history_createdTS
        )
        Values (
            _historyUUID,_checklistUUID,_customerUUID,_workorderUUID,_assetUUID,1,
            _checklist_name,_checklist_rulesJSON,
            0,
            _userUUID,_userUUID,now(),now()
        );

        select group_concat(checklist_itemUUID) into _ids  from checklist_item
        where checklist_item_checklistUUID = _checklistUUID and checklist_item_statusId =1
        order by checklist_item_sortOrder;

		if (_DEBUG=1) THEN select 'CREATE HISTORY ',_workorderUUID,' ',_assetUUID,' ',_workorder_locationUUID,' ',_checklist_name, ' ', _ids;  END IF;
		set _checklist_itemIds = _ids;
        -- reOrder of the stages for old tasktype
        if(_ids is not null) then
            looper: loop
                SET strLen = CHAR_LENGTH(_ids);

                set _id = SUBSTRING_INDEX(_ids, ',', 1);

                select UUID(), checklist_itemUUID, checklist_item_sortOrder, checklist_item_prompt, checklist_item_type, checklist_item_optionSetJSON, checklist_item_successPrompt,
                        checklist_item_successRange
                into  _checklist_history_item_historyUUID, _checklist_itemUUID, _checklist_item_sortOrder, _checklist_item_prompt, _checklist_item_type,
                        _checklist_item_optionSetJSON, _checklist_item_successPrompt, _checklist_item_successRange
                from checklist_item where  checklist_itemUUID= _id;

                insert into checklist_item_history (
                    checklist_history_itemUUID, checklist_history_item_historyUUID, checklist_history_item_itemUUID, checklist_history_item_statusId,
                    checklist_history_item_sortOrder, checklist_history_item_prompt, checklist_history_item_type,
                    checklist_history_item_optionSetJSON, checklist_history_item_successPrompt, checklist_history_item_successRange,
                    checklist_history_item_resultFlag,
                    checklist_history_item_createdByUUID, checklist_history_item_updatedByUUID, checklist_history_item_updatedTS, checklist_history_item_createdTS
                )
                values (
                    _checklist_history_item_historyUUID, _historyUUID, _checklist_itemUUID, 1,
                    _checklist_item_sortOrder, _checklist_item_prompt, _checklist_item_type,
                    _checklist_item_optionSetJSON, _checklist_item_successPrompt, _checklist_item_successRange,
                    null,
                    _userUUID,_userUUID,now(),now()
                );

                set _checklist_itemHistoryIds = concat(_checklist_itemHistoryIds, _checklist_history_item_historyUUID, ',');

                -- select
                -- _checklist_itemUUID, _historyUUID, checklist_item_statusId, checklist_item_sortOrder, checklist_item_prompt, checklist_item_type, checklist_item_optionSetJSON, checklist_item_successPrompt, checklist_item_successRange, _userUUID, _userUUID, now(), now(), null
                -- into table checklist_item_history
                -- from checklist_item where  checklist_itemUUID= _id;

                SET SubStrLen = CHAR_LENGTH(SUBSTRING_INDEX(_ids, ',', 1))+2;
                SET _ids = MID(_ids, SubStrLen, strLen);

                if(_ids = '') then
                    leave looper;
                end if;
            end loop;
        end if;

        -- create WO if it does not exist, but make sure to update the historyUUID
        set _foundId = null;

        select workorderUUID into _foundId from workorder where workorderUUID=_workorderUUID;

        if (_foundId is null) THEN
            if (_DEBUG=1) THEN select '_workorderUUID',_workorderUUID; END IF;
            if (_DEBUG=1) THEN select 'CREATE WO ',_workorderUUID,' ',_assetUUID,' ',_workorder_locationUUID,' ',_checklist_name; END IF;

                -- call WORKORDER_create(_action, _customerId,_userUUID
                -- _workorderUUID,_workorder_locationUUID,_workorder_userUUID,_workorder_groupUUID,_workorder_assetUUID,
                -- _workorder_checklistUUID,_workorder_checklistHistoryUUID,_workorder_status,_workorder_type,_workorder_name,_workorder_number,_workorder_details,
                -- _workorder_actions,_workorder_priority,_workorder_dueDate,_workorder_completeDate,
                -- _workorder_scheduleDate,_workorder_rescheduleDate,_workorder_frequency,_workorder_frequencyScope,_wapj_asset_partUUID,
                -- _wapj_quantity
                -- );

                    call WORKORDER_create('CREATE', _customerUUID,_userUUID,
                        _workorderUUID,_workorder_locationUUID,_userUUID,null,_assetUUID, _checklistUUID,
                        _historyUUID,null,'CHECKLIST',CONCAT('Checklist - ',_checklist_name),null,_assetName,
                        _assetName,null,null,null,null,
                        null,null,null,null,
                        null,null,null,null
                    );

                    -- 	 		ELSE

                                    -- this will replace the checklistUUID for the historyUUID version of it.
                                    -- update workorder set workorder_checklistUUID = _historyUUID where workorderUUID=_workorderUUID;
                    /*
                                    call WORKORDER_workOrder('UPDATE', _customerUUID,_userUUID,
                                    _workorderUUID,_workorder_locationUUID,_userUUID,null,_assetUUID,
                                    _historyUUID,1,'CHECKLIST',null,null,_workorder_details,
                                    _workorder_actions,null,null,null,
                                    null,1,'DAILY',null,
                                    null
                                    );
                    */
       ELSE
				update workorder set workorder_checklistHistoryUUID = _historyUUID, workorder_status='IN_PROGRESS' where workorderUUID = _workorderUUID;
       END IF;

    ELSE -- history found, so update records

		if ( _checklist_statusId is not null or _checklist_name is not null) THEN

			set  @l_sql = CONCAT('update checklist_history set checklist_history_updatedTS=now(), checklist_history_updatedByUUID=\'', _userUUID,'\'');

			if (_checklist_name is not null) THEN
				set @l_sql = CONCAT(@l_sql,', checklist_history_name= \'', _checklist_name,'\'');
			END IF;
			if (_checklist_statusId is not null) THEN
				set @l_sql = CONCAT(@l_sql,', checklist_history_statusId= ', _checklist_statusId);
			END IF;


			set @l_sql = CONCAT(@l_sql,' where checklist_historyUUID = \'', _historyUUID,'\';');

			IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

			PREPARE stmt FROM @l_sql;
			EXECUTE stmt;
			DEALLOCATE PREPARE stmt;

        END IF;

		if ( _checklist_item_statusId is not null or _checklist_name is not null and _checklist_history_item_historyUUID is not null) THEN

		IF(_checklist_item_statusId > 3) THEN
			set _checklistStatus = 4;
		ELSE
			if(_checklist_item_type  = 'boolean') THEN
					select vaidateChecklistItem(_checklist_history_item_resultFlag,_checklist_item_type, _checklist_item_successRange) into _checklistStatus;
            ELSE
					  select vaidateChecklistItem(_checklist_history_item_resultText, _checklist_item_type, _checklist_item_successRange) into _checklistStatus;
			END IF;
		END IF;
			set  @l_sql = CONCAT('update checklist_item_history set checklist_history_item_updatedTS=now(), checklist_history_item_updatedByUUID=\'', _userUUID,'\'');

			if (_checklist_history_item_resultText is not null) THEN
				set @l_sql = CONCAT(@l_sql,', checklist_history_item_resultText= \'', _checklist_history_item_resultText,'\'');
			END IF;
			if (_checklist_history_item_resultFlag is not null) THEN
				set @l_sql = CONCAT(@l_sql,', checklist_history_item_resultFlag= ', _checklist_history_item_resultFlag);
			END IF;
			if (_checklistStatus is not null) THEN
				set @l_sql = CONCAT(@l_sql,', checklist_history_item_statusId= ', _checklistStatus);
			END IF;

			set @l_sql = CONCAT(@l_sql,' where  checklist_history_itemUUID= \'', _checklist_history_item_historyUUID,'\';');

			IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

			PREPARE stmt FROM @l_sql;
			EXECUTE stmt;
			DEALLOCATE PREPARE stmt;

		END IF;

    END IF;

    -- 1b. determine if workorder aready exists
		-- (note, this can be called from WO create as well.  Depends on from who the caller is
			-- from workorder create
            -- from start checklist

    -- 2. if not, then copy a checklistUUID into a new history instance.

    -- 3. else update history.
		-- update mastor record if noted
        -- update item record if noted

    -- 4. if all items on the checklist are completed, then close the WO
		 select workorder_name, workorder_number into @workorderName, @workorderNumber  from workorder where workorderUUID = _workorderUUID ;
		select _historyUUID as 'historyUUID',_workorderUUID as 'workorderUUID', _checklist_itemIds as 'checklistItemUUIDs', _checklist_itemHistoryIds as 'historyItemUUIDs',@workorderName as workorderName, @workorderNumber as  workOrderNumber;
ELSEIF (_action = 'CREATE_CHECKLIST') THEN
    if (_customerUUID is null) THEN
		SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call CHECKLIST_checklist: _customerUUID required';
		LEAVE CHECKLIST_checklist;
	END IF;
    set _checklistUUID =  UUID();
    if(_checklist_recommendedFrequency is null) THEN set _checklist_recommendedFrequency = 'WEEKLY'; END IF;
    insert into checklist (
                    checklistUUID, checklist_customerUUID, checklist_statusId, checklist_name, checklist_recommendedFrequency,
                    checklist_rulesJSON,
                    checklist_createdByUUID, checklist_updatedByUUID, checklist_updatedTS, checklist_createdTS,checklist_partRequired
                ) values (
                    _checklistUUID, _customerUUID, 1, _checklist_name, _checklist_recommendedFrequency,
                    _checklist_rulesJSON,
                    _userUUID, _userUUID, now(), now(), _checklist_partRequired
                );
        select _checklistUUID;

ELSEIF(_action ='UPDATE_TEMPLATE' and _checklistUUID is not null) THEN

	-- 1. update template

	if (_customerUUID is null) THEN
		SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call CHECKLIST_checklist: _customerUUID required';
		LEAVE CHECKLIST_checklist;
	END IF;

	-- 1. determine if history aready exists
    select checklistUUID into _foundId from checklist where checklistUUID=_checklistUUID;

            if (_foundId is null) THEN

                if (_checklist_recommendedFrequency is null) THEN set _checklist_recommendedFrequency='WEEKLY'; END IF;

                insert into checklist (
                    checklistUUID, checklist_customerUUID, checklist_statusId, checklist_name, checklist_recommendedFrequency,
                    checklist_rulesJSON,
                    checklist_createdByUUID, checklist_updatedByUUID, checklist_updatedTS, checklist_createdTS
                ) values (
                    _checklistUUID, _customerUUID, 1, _checklist_name, _checklist_recommendedFrequency,
                    _checklist_rulesJSON,
                    _userUUID, _userUUID, now(), now()
                );

            ELSE

                set  @l_sql = CONCAT('update checklist set checklist_updatedTS=now(), checklist_updatedByUUID=\'', _userUUID,'\'');

                if (_checklist_rulesJSON is not null) THEN
                    set @l_sql = CONCAT(@l_sql,',checklist_rulesJSON = \'', _checklist_rulesJSON,'\'');
                END IF;
                if (_checklist_recommendedFrequency is not null) THEN
                    set @l_sql = CONCAT(@l_sql,',checklist_recommendedFrequency = \'', _checklist_recommendedFrequency,'\'');
                END IF;
                if (_checklist_name is not null) THEN
                    set @l_sql = CONCAT(@l_sql,',checklist_name = \'', _checklist_name,'\'');
                END IF;
                if (_checklist_statusId is not null) THEN
                    set @l_sql = CONCAT(@l_sql,',checklist_statusId = ', _checklist_statusId);
                END IF;


                set @l_sql = CONCAT(@l_sql,' where checklistUUID = \'', _checklistUUID,'\';');

                IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

                PREPARE stmt FROM @l_sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;


            END IF;

		if(_checklist_itemUUID is null) THEN
			set _checklist_itemUUID = UUID();
		END IF;

    select checklist_itemUUID into _foundChecklistItemId from checklist_item where checklist_itemUUID=_checklist_itemUUID;

    if (_foundChecklistItemId is null and _checklist_itemUUID is not null) THEN

		insert into checklist_item (
            checklist_itemUUID, checklist_item_checklistUUID, checklist_item_customerUUID, checklist_item_statusId,
            checklist_item_sortOrder, checklist_item_prompt, checklist_item_type, checklist_item_optionSetJSON,
            checklist_item_successPrompt, checklist_item_successRange,
            checklist_item_createdByUUID, checklist_item_updatedByUUID, checklist_item_updatedTS, checklist_item_createdTS
        ) values (
            _checklist_itemUUID, _checklistUUID, _customerUUID, 1,
            _checklist_item_sortOrder, _checklist_item_prompt, _checklist_item_type, _checklist_item_optionSetJSON,
            _checklist_item_successPrompt, _checklist_item_successRange,
            _userUUID, _userUUID, now(), now()
         );
		select _checklist_itemUUID;
    ELSE

		set  @l_sql = CONCAT('update checklist_item set checklist_item_updatedTS=now(), checklist_item_updatedByUUID=\'', _userUUID,'\'');

        if (_checklist_item_successRange is not null) THEN
			set @l_sql = CONCAT(@l_sql,',checklist_item_successRange = \'', _checklist_item_successRange,'\'');
        END IF;
        if (_checklist_item_successPrompt is not null) THEN
			set @l_sql = CONCAT(@l_sql,',checklist_item_successPrompt = \'', _checklist_item_successPrompt,'\'');
        END IF;
        if (_checklist_item_optionSetJSON is not null) THEN
			set @l_sql = CONCAT(@l_sql,',checklist_item_optionSetJSON = \'', _checklist_item_optionSetJSON,'\'');
        END IF;
        if (_checklist_item_type is not null) THEN
			set @l_sql = CONCAT(@l_sql,',checklist_item_type = \'', _checklist_item_type,'\'');
        END IF;
        if (_checklist_item_prompt is not null) THEN
			set @l_sql = CONCAT(@l_sql,',checklist_item_prompt = \'', _checklist_item_prompt,'\'');
        END IF;
        if (_checklist_item_statusId is not null) THEN
			set @l_sql = CONCAT(@l_sql,',checklist_item_statusId = ', _checklist_item_statusId);
        END IF;
        if (_checklist_item_sortOrder is not null) THEN
			set @l_sql = CONCAT(@l_sql,',checklist_item_sortOrder = ', _checklist_item_sortOrder);
        END IF;

		set @l_sql = CONCAT(@l_sql,' where checklist_itemUUID = \'', _checklist_itemUUID,'\';');

        IF (_DEBUG=1) THEN select _action,@l_SQL; END IF;

		PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

    END IF;
ELSEIF(_action = 'DELETE_CHECKLISTITEM' and _checklist_itemUUID is not null) THEN
		delete from checklist_item where checklist_itemUUID = _checklist_itemUUID;
ELSEIF(_action = 'UPDATE_CHECKLIST') THEN
        IF(_checklistUUID is null) THEN
             SIGNAL SQLSTATE '41002' SET MESSAGE_TEXT = 'call CHECKLIST_checklist: _checklistUUID required';
        LEAVE CHECKLIST_checklist;
        END IF;
        IF(_userUUID is null) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ASSETPART_assetpart: _userUUID missing';
            LEAVE CHECKLIST_checklist;
        END IF;

	 set  @l_sql = CONCAT('update checklist set checklist_updatedTS=now(), checklist_updatedByUUID=\'', _userUUID,'\'');
		 if (_checklist_name is not null) THEN
                      set @l_sql = CONCAT(@l_sql,',checklist_name = \'', _checklist_name,'\'');
		 END IF;
     set @l_sql = CONCAT( @l_sql ,' where checklistUUID = \'', _checklistUUID,'\';');
     IF (_DEBUG=1) THEN select _action, @l_sql ; END IF;
     select _checklist_name as checklistTitle;
     PREPARE stmt FROM @l_sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
ELSEIF(_action = 'COMPLETE' or _action = 'RESET') THEN
	select checklist_history_workorderUUID into _workorderUUID from checklist_history
			where checklist_historyUUID = _historyUUID;

    select group_concat(checklist_history_item_resultFlag),
            group_concat(COALESCE(checklist_history_item_resultText, 'NULL'))
    into _checklist_history_item_resultFlag, _checklist_history_item_resultText
    from checklist_item_history
        where checklist_history_item_historyUUID = '50279b80-3ba9-11eb-a1a5-4e53d94465b4' and checklist_history_item_statusId =1
        order by checklist_history_item_sortOrder;

    IF (LOCATE('0', _checklist_history_item_resultFlag) > 0 OR LOCATE('NULL', _checklist_history_item_resultText) > 0) THEN
        SET _checklist_history_resultFlag = 2;
    ELSE
        SET _checklist_history_resultFlag = 1;
    END IF;

	update  checklist_history set checklist_history_resultFlag = _checklist_history_resultFlag,checklist_history_updatedTS=now(),
	checklist_history_updatedByUUID=_userUUID
	where checklist_historyUUID = _historyUUID;

	update  workorder set workorder_completeDate=Date(now()), workorder_updatedTS = now(),
		workorder_updatedByUUID = _userUUID, workorder_status = 'Complete'
		where workorderUUID = _workorderUUID;

    select _checklist_history_resultFlag as checklistStatus; -- 0 is not started 1 is success and 2 is failed

ELSEIF(_action = 'RESET') THEN
	select checklist_history_workorderUUID into _workorderUUID from checklist_history
			where checklist_historyUUID = _historyUUID;

	update  checklist_history set checklist_history_resultFlag = 0,checklist_history_updatedTS=now(),
	checklist_history_updatedByUUID=_userUUID
	where checklist_historyUUID = _historyUUID;

	update  workorder set workorder_completeDate=Date(now()), workorder_updatedTS = now(),
		workorder_updatedByUUID = _userUUID, workorder_status = 'IN_PROGRESS'
		where workorderUUID = _workorderUUID;
ELSEIF(_action ='PASS_CHECKLIST') THEN


	select checklist_history_workorderUUID into _workorderUUID from checklist_history
		where checklist_historyUUID = _historyUUID;

	update  checklist_history set checklist_history_resultFlag=1,checklist_history_updatedTS=now(),
		checklist_history_updatedByUUID=_userUUID
		where checklist_historyUUID = _historyUUID;

    update  workorder set workorder_completeDate=Date(now()), workorder_updatedTS = now(),
		workorder_updatedByUUID = _userUUID, workorder_status = 'Complete'
		where workorderUUID = _workorderUUID;

		if (_DEBUG=1) THEN select _action, _workorderUUID,' ',_historyUUID;  END IF;

ELSEIF(_action ='FAIL_CHECKLIST') THEN

	select checklist_history_workorderUUID into _workorderUUID from checklist_history
		where checklist_historyUUID = _historyUUID;

	update  checklist_history set checklist_history_resultFlag=2,checklist_history_updatedTS=now(),
		checklist_history_updatedByUUID=_userUUID
		where checklist_historyUUID = _historyUUID;

    update  workorder set workorder_completeDate=Date(now()), workorder_updatedTS = now(),
		workorder_updatedByUUID = _userUUID, workorder_status = 'Complete'
		where workorderUUID = _workorderUUID;

ELSEIF(_action ='DELETE') THEN

	-- 1. if delete of a checklist history, then make sure wo is deleted.

    select _action;
ELSEIF(_action ='DELETE_CLI') THEN
IF(_checklistUUID is not null) THEN
    update checklist set checklist_deleteTS = date(now()) where checklistUUID = _checklistUUID;
    END IF;

ELSEIF(_action ='COUNT_CLWO') THEN
    IF(_checklistUUID is not null) THEN
    select count(*) into @WOCount from workorder where workorder_checklistUUID=_checklistUUID
        and workorder_status not like '%complete%' ;
	END IF;
    select @WOCount as activeWorkorders;
ELSE
	SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call CHECKLIST_checklist: _action is of type invalid';
	LEAVE CHECKLIST_checklist;
END IF;


IF (_DEBUG=1) THEN
	select _action;
END IF;


END$$

DELIMITER ;

DROP procedure IF EXISTS `PARTTEMPLATE_parttemplate`;

DELIMITER $$
CREATE PROCEDURE `PARTTEMPLATE_parttemplate`(IN _action VARCHAR(100),
                                       IN _userUUID VARCHAR(100),

                                       IN _part_sku VARCHAR(100),
                                       IN _part_statusId INT,
                                       IN _part_name VARCHAR(255),
                                       IN _part_shortName VARCHAR(255),
                                       IN _part_brandId VARCHAR(255),
                                       IN _part_imageURL VARCHAR(255),
                                       IN _part_imageThumbURL VARCHAR(255),
                                       IN _part_hotSpotJSON TEXT,
                                       IN _part_isPurchasable BOOLEAN,
                                       IN _part_diagnosticUUID VARCHAR(255),
                                       IN _part_magentoUUID VARCHAR(255),
                                       IN _part_vendor VARCHAR(255))
PARTTEMPLATE_parttemplate:
BEGIN


    DECLARE DEBUG INT DEFAULT 0;
    IF (_action IS NULL OR _action = '') THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call PARTTEMPLATE_parttemplate: _action can not be empty';
        LEAVE PARTTEMPLATE_parttemplate;
    END IF;

    IF (_userUUID IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PARTTEMPLATE_parttemplate: _userUUID missing';
        LEAVE PARTTEMPLATE_parttemplate;
    END IF;

    IF (_action = 'GET') THEN
        IF (_part_sku IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PARTTEMPLATE_parttemplate: _part_sku missing';
            LEAVE PARTTEMPLATE_parttemplate;
        END IF;
        select * from part_template where part_sku = _part_sku;
    ELSEIF (_action = 'GET-LIST') THEN
        SELECT * from part_template;
    ELSEIF (_action = 'CREATE') THEN
        IF (DEBUG = 1) THEN
            select _action,
                   _userUUID,
                 _part_sku,
                 _part_statusId,
                 _part_name,
                 _part_shortName,
                 _part_brandId,
                 _part_imageURL,
                 _part_imageThumbURL,
                 _part_hotSpotJSON,
                 _part_isPurchasable,
                 _part_diagnosticUUID,
                 _part_magentoUUID,
                 _part_vendor;
        END IF;

        IF (_part_sku IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PARTTEMPLATE_parttemplate: _part_sku missing';
            LEAVE PARTTEMPLATE_parttemplate;
        END IF;

        if (_part_isPurchasable is null) then set _part_isPurchasable = 0; end if;

        insert into part_template
        (part_sku, part_statusId, part_name, part_shortName, part_brandId,
         part_imageURL, part_imageThumbURL, part_hotSpotJSON, part_isPurchasable, part_diagnosticUUID,
         part_magentoUUID, part_vendor,
         part_createdByUUID, part_updatedByUUID, part_updatedTS, part_createdTS,
         part_deleteTS)
        values (_part_sku,
                _part_statusId,
                _part_name,
                _part_shortName,
                _part_brandId,
                _part_imageURL,
                _part_imageThumbURL,
                _part_hotSpotJSON,
                _part_isPurchasable,
                _part_diagnosticUUID,
                _part_magentoUUID,
                _part_vendor,
                _userUUID, _userUUID, now(), now(), null);

        select * from part_template where part_sku = _part_sku;

    ELSEIF (_action = 'UPDATE') THEN

        IF (_part_sku IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PARTTEMPLATE_parttemplate: _part_sku missing';
            LEAVE PARTTEMPLATE_parttemplate;
        END IF;

        set @l_sql = CONCAT('update part_template set part_updatedTS=now(), part_updatedByUUID=\'', _userUUID,
                            '\'');

        if (_part_sku is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_sku = \'', _part_sku, '\'');
        END IF;
        if (_part_statusId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_statusId = ', _part_statusId);
        END IF;
        if (_part_name is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_name = \'', _part_name, '\'');
        END IF;
        if (_part_shortName is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_shortName = \'', _part_shortName, '\'');
        END IF;
        if (_part_brandId is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_brandId = \'', _part_brandId, '\'');
        END IF;
        if (_part_imageURL is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_imageURL = \'', _part_imageURL, '\'');
        END IF;
        if (_part_imageThumbURL is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_imageThumbURL = \'', _part_imageThumbURL, '\'');
        END IF;
        if (_part_hotSpotJSON is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_hotSpotJSON = \'', _part_hotSpotJSON, '\'');
        END IF;
        if (_part_isPurchasable is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_isPurchasable = \'', _part_isPurchasable, '\'');
        END IF;
        if (_part_diagnosticUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_diagnosticUUID = \'', _part_diagnosticUUID, '\'');
        END IF;
        if (_part_magentoUUID is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_magentoUUID = \'', _part_magentoUUID, '\'');
        END IF;
        if (_part_vendor is not null) THEN
            set @l_sql = CONCAT(@l_sql, ',part_vendor = \'', _part_vendor, '\'');
        END IF;



        set @l_sql = CONCAT(@l_sql, ' where part_sku = \'', _part_sku, '\';');

        IF (DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF (_action = 'REMOVE') THEN
        delete from part_template where part_sku=_part_sku;

    ELSEIF (_action = 'DELETE') THEN

        IF (DEBUG = 1) THEN select _action, _part_sku; END IF;

        IF (_part_sku IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call PARTTEMPLATE_parttemplate: _part_sku missing';
            LEAVE PARTTEMPLATE_parttemplate;
        END IF;

        update part_template
        set part_deleteTS=now(),
            part_statusId=2
        where part_sku = _part_sku;

    END IF;

END$$


DELIMITER ;

-- ==================================================================

-- call ATTACHMENT_attachment(null,'5eb71fddbe04419bb7fda53fb0ef31ae','ASSET-PART', null,null, null, null, null, null, null)
-- call ATTACHMENT_attachment(null, '4e64ea9a159f45308019edcfd9dd9cd8','ASSET', null, null, null, null, null, null, null)
-- call ATTACHMENT_attachment('UPDATE_ATTACHMENT','2efb73617c614b1e8d686da738a3ed91', 'ASSET', '85a9fc657d60484eb35009250b50f9c7', 'HVAC Unit', null, null, null, null, null)
-- call ATTACHMENT_attachment('CREATE_ATTACHMENT','2efb73617c614b1e8d686da738a3ed91' , 'ASSET', null,'newly added features', 'HVAC Unit', '1',
-- 'https://jcmi.sfo2.digitaloceanspaces.com/attachment-temp/87c7f772-8d9c-4cb2-b5f5-ed4fe03f9ee3_1614244345251.jpeg', 'a30af0ce5e07474487c39adab6269d5f',
-- '2')

DROP procedure IF EXISTS `ATTACHMENT_attachment`;

DELIMITER $$
CREATE PROCEDURE `ATTACHMENT_attachment`( IN _action char(32), IN _partId char(36),IN _partType char(36), IN _attachmentuuid CHAR(36), IN _attachment_description varchar(1000),
											IN _attachment_shortName varchar(100), IN _attachmentStatus int, IN _attachment_fileURL varchar(255), IN _attachment_customerUUid varchar(36),
                                            IN _attachment_createdByUUID varchar(36), IN _attachment_mineType varchar(50))
ATTACHMENT_attachment:
BEGIN

    DECLARE DEBUG INT DEFAULT 0;
    DECLARE asset_part_id char(60);
	IF(_action = 'UPDATE_ATTACHMENT') THEN
		IF(_attachmentuuid is null) THEN
			SIGNAL SQLSTATE '45003' SET message_text = 'call ATTACHMENT_attachment: _attachmentuuid can not be empty';
            LEAVE ATTACHMENT_attachment;
        END IF;
        IF(_attachment_description is NULL) THEN
			SIGNAL SQLSTATE '45003' SET message_text = 'call ATTACHMENT_attachment: _attachment_description can not be empty';
             LEAVE ATTACHMENT_attachment;
		END IF;
        set @l_sql = CONCAT('update attachment set attachment_updatedts = now()');
        IF(_attachment_description is not null) THEN
		set @l_sql = CONCAT(@l_sql, ',attachment_description =\'', _attachment_description, '\'');
        END IF;
        IF(_attachment_fileURL is not null) THEN
        set @l_sql = CONCAT(@l_sql, ', attachment_fileURL=\'', _attachment_fileURL,'\'');
        END IF;
         IF(_attachment_mineType is not null and _attachment_mineType != '' ) THEN
        set @l_sql = CONCAT(@l_sql, ', attachment_mimeType =\'', _attachment_mineType,'\'');
        END IF;
		 set @l_sql = CONCAT(@l_sql, ' where attachmentuuid =\'', _attachmentuuid,'\';');
        if(DEBUG =1) THEN select @l_sql, _action; END IF;
        PREPARE stmt from @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
	ELSEIF(_action = 'DELETE_ATTACHMENT') THEN
		IF(_attachmentuuid is null) THEN
			SIGNAL SQLSTATE '45003' SET message_text = 'call ATTACHMENT_attachment: _attachmentuuid can not be empty';
            LEAVE ATTACHMENT_attachment;
        END IF;
       update attachment set attachment_deleteTS = now() where  attachmentuuid= _attachmentuuid;
    ELSEIF(_action = 'CREATE_ATTACHMENT') THEN
        IF(_attachment_description is NULL) THEN
			SIGNAL SQLSTATE '45003' SET message_text = 'call ATTACHMENT_attachment: _attachment_description can not be empty';
             LEAVE ATTACHMENT_attachment;
		END IF;
         IF(_attachment_fileURL is NULL) THEN
			SIGNAL SQLSTATE '45003' SET message_text = 'call ATTACHMENT_attachment: _attachment_fileURL can not be empty';
             LEAVE ATTACHMENT_attachment;
		END IF;
          IF(_attachment_customerUUID is NULL) THEN
			SIGNAL SQLSTATE '45003' SET message_text = 'call ATTACHMENT_attachment: attachment_customerUUID can not be empty';
             LEAVE ATTACHMENT_attachment;
		END IF;
           set _attachmentuuid = uuid();
        insert INTO attachment(`attachmentUUID`,`attachment_statusId`,`attachment_fileURL`,`attachment_shortName`,`attachment_description`,`attachment_mimeType`,
				`attachment_customerUUID`,`attachment_createdByUUID`,`attachment_acknowledgedByUUID`,`attachment_updatedTS`,`attachment_createdTS`,`attachment_deleteTS`)
				values(_attachmentuuid, _attachmentStatus, _attachment_fileURL, _attachment_shortName
                , _attachment_description,_attachment_mineType, _attachment_customerUUid , _attachment_createdByUUID, null, now(), now(), null);
-- DEAL WITH INSERTING INTO RIGHT TABLE
        IF(_partType = 'ASSET') THEN
            insert into asset_attachment_join(`aaj_asset_assetUUID`, `aaj_attachmentUUID`, `aaj_createdTS`)
            values(_partId, _attachmentuuid, now());
#             SELECT asset_partUUID into asset_part_id FROM asset WHERE assetUUID = _partId;
        ELSEIF(_partType = 'ASSET-PART') THEN
            insert into asset_part_attachment_join(`apaj_asset_partUUID`, `apaj_attachmentUUID`, `apaj_createdTS`)
            values(_partId, _attachmentuuid, now());
        ELSEIF(_partType = 'PART-TEMPLATE') THEN
            insert into part_attachment_join(`paj_part_sku`, `paj_attachmentUUID`, `paj_createdTS`)
            values(_partId, _attachmentuuid, now());
        END IF;
        #         insert into asset_part_attachment_join(`apaj_asset_partUUID`, `apaj_attachmentUUID`, `apaj_createdTS`)
# 			values(asset_part_id, _attachmentuuid, now());
    ELSE
		IF (_partId IS NULL) THEN
         SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call ATTACHMENT_attachment: _partId can not be empty';
         LEAVE ATTACHMENT_attachment;
         END IF;

		IF (_partType IS NULL) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call ATTACHMENT_attachment: _partType can not be empty';
        LEAVE ATTACHMENT_attachment;
		END IF;
	END IF;
-- FOR _partType of ASSET, return records for ASSETS UNION ASSET_PART UNION PART_TEMPLATE
-- FOR _partType of ASSET-PART, return records for ASSET-PART UNION PART_TEMPLATE
-- FOR _partType of PART_TEMPLATE, return recors for PART_TEMPLATE
    IF(_partType = 'ASSET') THEN
        SELECT asset_partUUID into asset_part_id FROM asset WHERE assetUUID = _partId;
        SELECT asset_part_template_part_sku into template_part_id FROM asset_part where asset_partUUID = asset_part_id;
        SELECT a.*, 'ASSET' as partType FROM attachment a LEFT JOIN asset_attachment_join aaj ON (a.attachmentUUID = aaj.aaj_attachmentUUID)
        WHERE aaj.aaj_asset_assetUUID = _partId and a.attachment_deleteTS is null
        UNION
        SELECT b.*, 'PART' as partType FROM attachment b LEFT JOIN asset_part_attachment_join apj ON (b.attachmentUUID = apj.apaj_attachmentUUID)
        WHERE apj.apaj_asset_partUUID = asset_part_id and b.attachment_deleteTS is null
        UNION
        SELECT c.*, 'FACTORY' as partType FROM attachment c LEFT JOIN part_attachment_join paj ON (c.attachmentUUID = paj.paj_attachmentUUID)
        WHERE paj.paj_part_sku = template_part_id and c.attachment_deleteTS is null ;
    ELSEIF(_partType = 'ASSET-PART') THEN
        SELECT asset_part_template_part_sku into template_part_id FROM asset_part where asset_partUUID = _partId;
        SELECT b.*, 'PART' as partType FROM attachment b LEFT JOIN asset_part_attachment_join apj ON (b.attachmentUUID = apj.apaj_attachmentUUID)
        WHERE apj.apaj_asset_partUUID = _partId and b.attachment_deleteTS is null
        UNION
        SELECT c.*, 'FACTORY' as partType FROM attachment c LEFT JOIN part_attachment_join paj ON (c.attachmentUUID = paj.paj_attachmentUUID)
        WHERE paj.paj_part_sku = template_part_id and c.attachment_deleteTS is null ;
    ELSEIF(_partType = 'PART-TEMPLATE') THEN
        SELECT c.*, 'FACTORY' as partType FROM attachment c LEFT JOIN part_attachment_join paj ON (c.attachmentUUID = paj.paj_attachmentUUID)
        WHERE paj.paj_part_sku = _partId and c.attachment_deleteTS is null ;
#     END IF;
#     IF(_partType = 'ASSET' or _partType = 'ASSET-PART') THEN
#
#         IF(_partType = 'ASSET') THEN
#             SELECT asset_partUUID into asset_part_id FROM asset WHERE assetUUID = _partId;
#         ELSE
#            set asset_part_id = _partId;
#         END IF;
#
#         SELECT a.*, 'ASSET' as partType FROM attachment a LEFT JOIN asset_part_attachment_join apj ON (a.attachmentUUID = apj.apaj_attachmentUUID)
#         WHERE apj.apaj_asset_partUUID = asset_part_id and attachment_deleteTS is null ;

    ELSE
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'call ATTACHMENT_attachment: _partType not matching with conditions';
         LEAVE ATTACHMENT_attachment;
    END IF;

END$$

DELIMITER ;


-- ==================================================================
-->call Fabric_fabric('ADD',null,null,null,'<name>','<img url>','<img json>')
-->call Fabric_fabric('GET','<_partId>',<_partType>,null,null,null,null)
--call Fabric_fabric('GET','e0a6967bf19e47ddab7c2a6147da1e98','LOCATION',null,null,null,null)
--call Fabric_fabric('GET','4c2d6b13a0f647b08bf11d37ab78b211','ASSET-PART',null,null,null,null)
--call Fabric_fabric('GET','1611765382204','DIAGNOSTIC-NODE',null,null,null,null)
-->call Fabric_fabric('GET_JSON',null,null,<_id:fabric_img id>,null,null,null)
--call Fabric_fabric('GET_JSON',null,null,'00207fbc-6d26-11eb-a1a5-4e53d94465b4',null,null,null)
-->call Fabric_fabric('UPDATE',null,null,<_id:fabric_img id>,'<name>','<img url>','<img json>')
--call Fabric_fabric('UPDATE',null,null,'00207fbc-6d26-11eb-a1a5-4e53d94465b4','kl','updated-text','{}')
--call Fabric_fabric('LIST',null,null,null,null,null,null)

DROP procedure IF EXISTS `Fabric_fabric`;

DELIMITER $$
CREATE PROCEDURE `Fabric_fabric`(IN _action char(32),IN _partId char(36),IN _partType char(36),IN _id char(36),IN _name char(36),IN _img_url varchar(225),_img_json TEXT)
Fabric_fabric:
BEGIN

    DECLARE DEBUG INT DEFAULT 0;

    IF (_action IS NULL) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: _action can not be empty';
        LEAVE Fabric_fabric;
    END IF;

    IF(_action = 'ADD') THEN
        IF (_img_url IS NULL) THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: _img_url can not be empty';
            LEAVE Fabric_fabric;
        END IF;
        IF (_img_json IS NULL) THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: _img_json can not be empty';
            LEAVE Fabric_fabric;
        END IF;
        IF (_name IS NULL) THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: _name can not be empty';
            LEAVE Fabric_fabric;
        END IF;

        SET @_uniqueId = uuid();
        INSERT INTO fabric_img (id,img_name,img_url,img_json) VALUES (@_uniqueId,_name,_img_url,_img_json);

        SELECT @_uniqueId as 'id' ;
    ELSEIF (_action = 'UPDATE') THEN
        IF (_id IS NULL) THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: _id can not be empty';
            LEAVE Fabric_fabric;
		END IF;
        IF(_name IS NULL and _img_url IS NULL and _img_json IS NULL )THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: no parameter to update';
            LEAVE Fabric_fabric;
		END IF;
        set @l_SQL = 'update fabric_img set ' ;
        set @comma_flag = 0;
        IF(_name IS NOT NULL)THEN
            set @comma_flag = 1;
            set @l_SQL=	CONCAT(@l_SQL,'img_name = \'',_name,'\'');
		END IF;
        IF(_img_url IS NOT NULL)THEN
            set @comma_flag = 1;
            if(@comma_flag = 1)then
                set @l_SQL=	CONCAT(@l_SQL,',');
            end if;
            set @l_SQL=	CONCAT(@l_SQL,'img_url = \'',_img_url,'\'');
		END IF;
        IF(_img_json IS NOT NULL)THEN
            if(@comma_flag = 1)then
                set @l_SQL=	CONCAT(@l_SQL,',');
            end if;
            set @l_SQL=	CONCAT(@l_SQL,'img_json = \'',_img_json,'\'');
        END IF;

         set @l_SQL=CONCAT(@l_SQL,' WHERE id = \'',_id,'\'');

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        select 'updated';

    ELSEIF (_action = 'GET') THEN
        IF (_partId IS NULL) THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: _partId can not be empty';
            LEAVE Fabric_fabric;
        END IF;

        set @l_SQL = 'select fi.id as id,fi.img_name as name,fi.img_url as url,fi.img_json as fabJSON from fabric_img fi left join ' ;

        IF(_partType = 'LOCATION')THEN
        	set @l_SQL=	CONCAT(@l_SQL, 'location l on (fi.id = l.location_fabricId) where l.locationUUID = \'',_partId,'\'');
        ELSEIF(_partType = 'ASSET-PART')THEN
        	set @l_SQL=	CONCAT(@l_SQL, 'asset_part ap on (fi.id = ap.asset_part_fabricId) where ap.asset_partUUID = \'',_partId,'\'');
        ELSEIF(_partType = 'DIAGNOSTIC-NODE')THEN
        	set @l_SQL=	CONCAT(@l_SQL, 'diagnostic_node dn on (fi.id = dn.diagnostic_node_fabricId) where dn.diagnostic_nodeUUID = \'',_partId,'\'');
        ELSE
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: _partType not matching';
            LEAVE Fabric_fabric;
        END IF;

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'GET_JSON') THEN
        IF (_id IS NULL) THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call Fabric_fabric: _id can not be empty';
            LEAVE Fabric_fabric;
        END IF;
        select img_json as fabJSON from fabric_img where id = _id;
    ELSEIF (_action = 'LIST') THEN
        SELECT id,img_url as 'url',img_name as 'name' FROM fabric_img where img_name IS NOT NULL;
	END IF;
END$$

DELIMITER ;

-- ==================================================================
-- > call GROUP_group('GET-LIST',<targetedUserId_id>,<group_id>,<group_name>,<customer_id>,<user_id>)
-- call GROUP_group('GET-LIST',1,null,null,null,null)
-- call GROUP_group('GET-LIST',1,1,null,null,null)
-- call GROUP_group('GET-LIST',1,null,null,'a30af0ce5e07474487c39adab6269d5f',null)
-- > call GROUP_group('GET-USER-LIST',<targetedUserId_id>,<group_id>,null,null,null)
-- call GROUP_group('GET-USER-LIST',1,1,null,null,null)
-- > call GROUP_group('ADD-USER',<targetedUserId_id>,<group_id>,null,null,<user_id>);
-- call GROUP_group('ADD-USER',6,3,null,null,1);
-- > call GROUP_group('REMOVE-USER',<targetedUserId_id>,<group_id>,null,null,null);
-- call GROUP_group('REMOVE-USER',6,3,null,null,null);
-- > call GROUP_group('ADD-GROUP',<targetedUserId_id>,null,<group_name>,<customer_id>,<user_id>);
-- call GROUP_group('ADD-GROUP',1,null,'new grp','a30af0ce5e07474487c39adab6269d5f',1);

DROP procedure IF EXISTS `GROUP_group`;

DELIMITER $$
CREATE PROCEDURE `GROUP_group`(
    IN _action char(32),
    IN _targetedUserId char(36),
    IN _groupid char(36),
    IN _groupName char(36),
    IN _customerId char(36),
    IN _userid char(36)
    )
GROUP_group:
BEGIN

    DECLARE DEBUG INT DEFAULT 0;

    IF (_action IS NULL) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call GROUP_group: _action can not be empty';
        LEAVE GROUP_group;
    END IF;

      IF (_targetedUserId IS NULL) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call GROUP_group: _targetedUserId can not be empty';
        LEAVE GROUP_group;
    END IF;

    IF(_action = 'GET-LIST') THEN
        SET @l_SQL = 'SELECT * FROM user_group';

        IF(_groupid IS NOT NULL)THEN
            -- filter group by _groupid
            SET @l_SQL = CONCAT(@l_SQL,' where groupUUID = \'',_groupid,'\';');
        ELSEIF(_customerId IS NOT NULL)THEN
            -- filter group by _customerId
            SET @l_SQL = CONCAT(@l_SQL,' where group_customerUUID = \'',_customerId,'\';');
        END IF;

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF(_action = 'GET-USER-LIST') THEN
        SET @l_SQL = 'SELECT * FROM user_group';

        IF(_groupid IS NULL)THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call GROUP_group: _groupid can not be empty';
            LEAVE GROUP_group;
        END IF;

        -- left join user_group_join
        SET @l_SQL = CONCAT(@l_SQL,' ug left join user_group_join ugj on (ug.groupUUID = ugj.ugj_groupUUID)');
        -- filter users of group by _groupid
        SET @l_SQL = CONCAT(@l_SQL,' where ug.groupUUID = \'',_groupid,'\';');

        PREPARE stmt FROM @l_SQL;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF(_action='ADD-GROUP')THEN

        IF(_groupName IS NULL)THEN
         SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call GROUP_group:  _groupName can not be empty';
         LEAVE GROUP_group;
        END IF;
        IF(_customerId IS NULL)THEN
         SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call GROUP_group:  _customerId can not be empty';
         LEAVE GROUP_group;
        END IF;
        IF(_userid IS NULL)THEN
         SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call GROUP_group:  _userid can not be empty';
         LEAVE GROUP_group;
        END IF;

        set @nxtGUUID = null;
        select UUID() into @nxtGUUID;
        insert into user_group values(@nxtGUUID,_customerId,_groupName,_userid,null,null,now(),null,0);

        select @nxtGUUID as 'id',_groupName as 'name';

    ELSEIF(_action = 'ADD-USER')THEN

        IF(_groupid IS NULL)THEN
         SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call GROUP_group:  _groupid can not be empty';
         LEAVE GROUP_group;
        END IF;

        INSERT INTO user_group_join (ugj_groupUUID,ugj_userUUID,ugj_createdByUUID,ugj_createdTS)
        VALUES(_groupid,_targetedUserId,_userid,now());

    ELSEIF(_action = 'REMOVE-USER')THEN

        IF(_groupid IS NULL)THEN
         SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call GROUP_group:  _groupid can not be empty';
         LEAVE GROUP_group;
        END IF;

        Delete FROM user_group_join WHERE ugj_groupUUID = _groupid and ugj_userUUID = _targetedUserId;

    END IF;

END$$

DELIMITER ;
-- ==================================================================
DROP procedure IF EXISTS `STATS_stats`;

DELIMITER $$
CREATE PROCEDURE STATS_stats(IN _action VARCHAR(100),
                                IN _customerId CHAR(36))
STATS_stats:
BEGIN
    IF (_action = 'WORKORDER') THEN
        select
            (select count(workorderUUID) from workorder where workorder_customerUUID = _customerId and
                                                              workorder_status='Complete' and
                    workorder_completeDate > (curdate() - INTERVAL DAYOFWEEK(curdate())+7 DAY)) as last_7_days_wo,
            (select count(workorderUUID) from workorder where workorder_customerUUID = _customerId and
                                                              workorder_status='Complete' and
                    workorder_completeDate > (curdate() - INTERVAL DAYOFWEEK(curdate())+14 DAY)and
                    workorder_completeDate < (curdate() - INTERVAL DAYOFWEEK(curdate())+7 DAY)) as lastweek_7_days_wo,
            (select count(workorderUUID) from workorder where workorder_customerUUID = _customerId and
                                                              workorder_status<=>'Complete') as open_wo,
            (select count(workorderUUID) from workorder w left join checklist_history ch on w.workorder_checklistHistoryUUID=ch.checklist_historyUUID
             where ch.checklist_history_statusId =2
                and workorder_customerUUID = _customerId
               and ch.checklist_history_updatedTS > (curdate() - INTERVAL DAYOFWEEK(curdate())+7 DAY)) as failed_cl,
            (select count(workorderUUID) from workorder w left join checklist_history ch on w.workorder_checklistHistoryUUID=ch.checklist_historyUUID
             where ch.checklist_history_statusId =2
               and workorder_customerUUID = _customerId
               and ch.checklist_history_updatedTS > (curdate() - INTERVAL DAYOFWEEK(curdate())+14 DAY)
                and ch.checklist_history_updatedTS < (curdate() - INTERVAL DAYOFWEEK(curdate())+7 DAY) ) as failed_cl_lastweek;
    END IF;
END$$
-- ==================================================================
-- > call PRIVILAGE_privilage('GET-LIST',<user_id>)
-- call PRIVILAGE_privilage('GET-LIST',1);
DROP procedure IF EXISTS `PRIVILAGE_privilage`;

DELIMITER $$
CREATE PROCEDURE `PRIVILAGE_privilage`(
    IN _action char(32),
    IN _userid char(36),
    )
GROUP_group:
BEGIN

    DECLARE DEBUG INT DEFAULT 0;

    IF (_action IS NULL) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call PRIVILAGE_privilage: _action can not be empty';
        LEAVE GROUP_group;
    END IF;

      IF (_userid IS NULL) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call PRIVILAGE_privilage: _userid can not be empty';
        LEAVE GROUP_group;
    END IF;

    IF(_action = 'GET-LIST') THEN
        SET @l_SQL = 'SELECT * FROM PRIVILAGE_privilage';
    END IF;

    PREPARE stmt FROM @l_SQL;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END$$

DELIMITER ;
-- ==================================================================
DROP procedure IF EXISTS `SECURITY_bitwise3`;
/*
call SECURITY_bitwise3(_action,_userId,_hierarchyId,_hierarchyType,_att_bitwise);
> call SECURITY_bitwise3('ADD',_userId,_hierarchyId,_hierarchyType,_att_bitwise);
call SECURITY_bitwise3('ADD','1','10f15063ba49451baf43e750c0be4805','BRAND',2);
> call SECURITY_bitwise3('REMOVE',_userId,_hierarchyId,_hierarchyType,_att_bitwise);
call SECURITY_bitwise3('REMOVE','1','10f15063ba49451baf43e750c0be4805','BRAND',4);
*/
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
CREATE PROCEDURE SECURITY_bitwise3(IN _action VARCHAR(100),
                                  IN _userId CHAR(36),
                                  IN _hierarchyId CHAR(36),
                                  IN _hierarchyType CHAR(36),
                                  IN _att_bitwise BIGINT)
SECURITY_bitwise3:
BEGIN

    DECLARE _DEBUG INT DEFAULT 1;
    
    IF(_action IS NULL)THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise3: _action can not be empty';
        LEAVE SECURITY_bitwise3;
    END IF;
    IF(_userId IS NULL)THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise3: _userId can not be empty';
        LEAVE SECURITY_bitwise3;
    END IF;
    IF(_hierarchyType IS NULL)THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise3: _hierarchyType can not be empty';
        LEAVE SECURITY_bitwise3;
    END IF;
    IF(_hierarchyId IS NULL)THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise3: _hierarchyId can not be empty';
        LEAVE SECURITY_bitwise3;
    END IF;

    -- GET CURRENT BITWISE
    SET @CUR_BITWISE = null;

    IF(_hierarchyType = 'GROUP')THEN
        select group_securityBitwise into @CUR_BITWISE from user_group where groupUUID = _hierarchyId;
    ELSEIF(_hierarchyType = 'USER')THEN
        -- in hold for now.
        SELECT 'in hold for now';
    ELSE
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise3: _hierarchyType did not match any.';
        LEAVE SECURITY_bitwise3;
    END IF;

    IF(@CUR_BITWISE IS NULL)THEN
        SET @CUR_BITWISE = 0;
    END IF;

    -- BITWISE UPDATE OPERATION
    SET @UPDATED_BITWISE = null;

    IF(_action = 'ADD')THEN
        SELECT @CUR_BITWISE|_att_bitwise into @UPDATED_BITWISE;
    ELSEIF(_action = 'REMOVE')THEN
        SELECT @CUR_BITWISE^_att_bitwise into @UPDATED_BITWISE;
    ELSE
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise3: _action did not match any.';
        LEAVE SECURITY_bitwise3;
    END IF;
    
    -- SET UPDATED BITWISE
    IF(_hierarchyType = 'GROUP')THEN
        update user_group SET group_securityBitwise = @UPDATED_BITWISE where groupUUID = _hierarchyId;
    ELSEIF(_hierarchyType = 'USER')THEN
       -- in hold for now.
        SELECT 'in hold for now';
    END IF;
    
END$$
DELIMITER ;