-- use cm_hms;
use jcmi_hms;
-- =====================================
-- ATTRIBUTES
-- =====================================
DROP TABLE IF EXISTS att_status;

CREATE TABLE `att_status` (
   id INT NOT NULL,
   name varchar(25) NOT NULL,
   PRIMARY KEY (id))
ENGINE = InnoDB;

insert into att_status(id,name) values (1,'ACTIVE');
insert into att_status(id,name) values (2,'InACTIVE');
insert into att_status(id,name) values (3,'Deleted');

DROP TABLE IF EXISTS att_phone;

CREATE TABLE `att_phone` (
   id INT NOT NULL,
   name varchar(25) NOT NULL,
   PRIMARY KEY (id))
ENGINE = InnoDB;

insert into att_phone(id,name) values (1,'MOBILE');
insert into att_phone(id,name) values (2,'LAN');
insert into att_phone(id,name) values (3,'WORK');
insert into att_phone(id,name) values (4,'PERSONAL');

DROP TABLE IF EXISTS att_address_type;

CREATE TABLE `att_address_type` (
   id INT NOT NULL,
   name varchar(25) NOT NULL,
   PRIMARY KEY (id))
ENGINE = InnoDB;

insert into att_address_type(id,name) values (1,'HOME');
insert into att_address_type(id,name) values (2,'WORK');



DROP TABLE IF EXISTS att_privilege;

CREATE TABLE `att_privilege` (
   category varchar(50) NOT NULL,
   `key` varchar(50) NOT NULL,
   pos int NOT NULL,
   bitwise BIGINT NOT NULL,
   PRIMARY KEY (bitwise))
ENGINE = InnoDB;

insert into att_privilege(category,`key`,pos,bitwise) values ('No','NONE',0,0);
insert into att_privilege(category,`key`,pos,bitwise) values ('workorder','CANAPPROVECHECKLISTS',1,1);
insert into att_privilege(category,`key`,pos,bitwise) values ('workorder','CANAPPROVEORDER',2,2);
insert into att_privilege(category,`key`,pos,bitwise) values ('license','CANACCESSHMS',3,4);
insert into att_privilege(category,`key`,pos,bitwise) values ('license','ADDUSERS',4,8);


DROP TABLE IF EXISTS att_userlevel_predefined;

CREATE TABLE `att_userlevel_predefined` (
   description varchar(50) NOT NULL,
   bitwise BIGINT NOT NULL,
   PRIMARY KEY (description))
ENGINE = InnoDB;

insert into att_userlevel_predefined(description,bitwise) values ('CM Admin',1);
insert into att_userlevel_predefined(description,bitwise) values ('Site Admin',2);
insert into att_userlevel_predefined(description,bitwise) values ('Site Manager',4);
insert into att_userlevel_predefined(description,bitwise) values ('Maintenance',8);
insert into att_userlevel_predefined(description,bitwise) values ('Operator',16);

/*
-- =====================================
-- CUSTOMER AND USERS
-- todo: create user/customer in their own space
-- =====================================

DROP TABLE IF EXISTS customer_brand;

CREATE TABLE `customer_brand` (
    brandId INT  NOT NULL,
    brand_name varchar(50)  NULL,
    brand_logo varchar(255)  NULL,
    brand_securityBitwise BIGINT  NULL,
    brand_preferenceJSON text  NULL, -- JSON PAYLOAD
    brand_createdByUUID CHAR(36)  NULL,
   	brand_created datetime  NULL default now(),
   	PRIMARY KEY (brandId))
ENGINE = InnoDB;


DROP TABLE IF EXISTS customer;

CREATE TABLE `customer` (
    customerUUID CHAR(36)  NOT NULL,
    customer_externalName varchar(50)   NULL,
    -- customer_brandId INT   NULL,
    customer_statusId INT   NULL DEFAULT 1,
    customer_name varchar(50)  NULL,
    customer_logo varchar(255)  NULL,
    customer_securityBitwise BIGINT  NULL,
    customer_preferenceJSON text  NULL, -- JSON PAYLOAD
    customer_createdByUUID CHAR(36)  NULL,
    customer_updatedByUUID CHAR(36)  NULL,
   	customer_updatedTS datetime  NULL,
  	customer_createdTS datetime  NULL default now(),
   	customer_deleteTS datetime  NULL,
   	PRIMARY KEY (customerUUID))
ENGINE = InnoDB;

DROP TABLE IF EXISTS customer_xref;

CREATE TABLE `customer_xref` (
    customerXrefId INT  NOT NULL   AUTO_INCREMENT,
    customerUUID CHAR(36)  NOT NULL,
    customerx_externalName varchar(255)   NULL,
    customerx_externalId varchar(255)   NULL,
    customerx_createdByUUID CHAR(36)  NULL,
    customerx_updatedByUUID CHAR(36)  NULL,
   	customerx_updatedTS datetime  NULL,
  	customerx_createdTS datetime  NULL default now(),
   	customerx_deleteTS datetime  NULL,
   	PRIMARY KEY (customerXrefId),
   	INDEX customerId_idx (customerUUID))
ENGINE = InnoDB   AUTO_INCREMENT=1000;
*/

DROP TABLE IF EXISTS customer_attachment_join;

CREATE TABLE `customer_attachment_join` (
    caj_customerUUID CHAR(36)  NOT NULL,
    caj_attachmentUUID CHAR(36)  NOT NULL,
    caj_createdTS datetime  NULL default now(),

    PRIMARY KEY (caj_customerUUID,caj_attachmentUUID))
ENGINE = InnoDB ;

/*
DROP TABLE IF EXISTS user;

CREATE TABLE `user` (
    userUUID CHAR(36)  NOT NULL,
    user_customerUUID CHAR(36)  NOT NULL,
    user_userName varchar(255)   NULL,

    user_loginEmail varchar(255) NULL,
    user_loginEmailValidationCode varchar(25) NULL,
    user_loginEmailVerified datetime NULL,
    user_loginEnabled SMALLINT NOT NULL DEFAULT 0,
    user_loginPW varchar(25) NULL,
    user_loginPWExpire datetime NULL,
    user_loginPWReset SMALLINT not NULL default 1,
    user_loginLast datetime null,
    user_loginSession varchar(255) null,
    user_loginSessionExpire datetime null,
    user_loginFailedAttempts SMALLINT NOT NULL DEFAULT 0,

    user_statusId INT   NULL DEFAULT 1,
    user_securityBitwise BIGINT  NULL,
    user_individualSecurityBitwise BIGINT  NULL,

    user_createdByUUID CHAR(36)  NULL,
    user_updatedByUUID CHAR(36)  NULL,
   	user_updatedTS datetime  NULL,
  	user_createdTS datetime  NULL default now(),
   	user_deleteTS datetime  NULL,
   	PRIMARY KEY (userUUID))
ENGINE = InnoDB;

DROP TABLE IF EXISTS user_xref;

CREATE TABLE `user_xref` (
    userXrefId INT  NOT NULL   AUTO_INCREMENT,
    userUUID CHAR(36)  NOT NULL,
    userx_externalName varchar(255)   NULL,
    userx_externalId INT   NULL,
    userx_createdByUUID CHAR(36)  NULL,
    userx_updatedByUUID CHAR(36)  NULL,
   	userx_updatedTS datetime  NULL,
  	userx_createdTS datetime  NULL default now(),
   	userx_deleteTS datetime  NULL,
  	PRIMARY KEY (userXrefId),
   	INDEX userId_idx (userUUID))
ENGINE = InnoDB   AUTO_INCREMENT=1000;
*/

DROP TABLE IF EXISTS user_profile;

CREATE TABLE `user_profile` (
    -- user_profileId INT  NOT NULL   AUTO_INCREMENT,
    user_profile_userUUID CHAR(36)  NOT NULL,

    user_profile_avatarSrc varchar(255)   NULL,
    user_profile_phoneTypeId INT NULL DEFAULT 1,
    user_profile_phone varchar(255)   NULL,
    user_profile_addressTypeId INT NULL DEFAULT 1,

    user_profile_locationUUID CHAR(36),

    user_profile_preferenceJSON text  NULL, -- JSON PAYLOAD

    user_profile_createdByUUID CHAR(36)  NULL,
    user_profile_updatedByUUID CHAR(36)  NULL,
   	user_profile_updatedTS datetime  NULL,
  	user_profile_createdTS datetime  NULL default now(),
   	user_profile_deleteTS datetime  NULL,
  	PRIMARY KEY (user_profile_userUUID))
ENGINE = InnoDB   AUTO_INCREMENT=1000;


DROP TABLE IF EXISTS user_group;

CREATE TABLE `user_group` (
    groupUUID CHAR(36)  NOT NULL,
    group_customerUUID CHAR(36)  NOT NULL,
    group_name varchar(50)  NOT NULL,
    group_createdByUUID CHAR(36)  NULL,
    group_updatedByUUID CHAR(36)  NULL,
    group_securityBitwise bigint  NOT NULL DEFAULT 0,
   	group_updatedTS datetime  NULL,
  	group_createdTS datetime  NULL default now(),
   	group_deleteTS datetime  NULL,
   	PRIMARY KEY (groupUUID),
   	UNIQUE INDEX customerGroup_unique (group_customerUUID,groupUUID))
ENGINE = InnoDB ;

DROP TABLE IF EXISTS user_group_join;

CREATE TABLE `user_group_join` (
    ugj_groupUUID CHAR(36)  NOT NULL,
    ugj_userUUID CHAR(36)  NOT NULL,
    ugj_createdByUUID CHAR(36)  NULL,
  	ugj_createdTS datetime  NULL default now(),
   	PRIMARY KEY (ugj_groupUUID,ugj_userUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS plan;

CREATE TABLE `plan` (
    planUUID CHAR(36)  NOT NULL,
    plan_name varchar(50)  NOT NULL,
    plan_securityBitwise BIGINT  NULL,
    plan_maxUsers BIGINT  NULL,
   	plan_createdByUUID CHAR(36)  NULL,
    plan_updatedByUUID CHAR(36)  NULL,
   	plan_updatedTS datetime  NULL,
  	plan_createdTS datetime  NULL default now(),
   	plan_deleteTS datetime  NULL,
   	PRIMARY KEY (planUUID))
ENGINE = InnoDB ;

DROP TABLE IF EXISTS customer_plan_join;

CREATE TABLE `customer_plan_join` (
    cpj_planUUID CHAR(36)  NOT NULL,
    cpj_customerUUID CHAR(36)  NOT NULL,
    cpj_createdByUUID CHAR(36)  NULL,
  	cpj_createdTS datetime  NULL default now(),
   	PRIMARY KEY  (cpj_planUUID,cpj_customerUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS user_session;

CREATE TABLE `user_session` (
   	-- sessionId INT  NOT NULL   AUTO_INCREMENT,
    session_userUUID CHAR(36)  NOT NULL,
    session_token varchar(255)   NULL,
   	session_expireTS datetime  NULL,
   	PRIMARY KEY (session_userUUID))
ENGINE = InnoDB;


-- =====================================
-- NOTIFICATION
-- notes: this is not meant to be a email/attachment. only basic notifications with formated HTML.
-- =====================================
DROP TABLE IF EXISTS notification_queue;

CREATE TABLE `notification_queue` (
   	notificationId INT NOT NULL AUTO_INCREMENT,
   	notification_type varchar(25) NOT NULL, -- [SMS,EMAIL,APP]
   	notification_toEmail varchar(100) NULL,
   	notification_toSMS varchar(25) NULL,
    notification_toGroupUUID CHAR(25) NULL,
    notification_toAppUUID CHAR(36) NULL,
    notification_toAssetUUID CHAR(36) NULL,
    notification_priority varchar(25) NULL DEFAULT 'LOW', -- LOW, MEDIUM, HIGH
   	notification_toUserUUID CHAR(36) NULL,
    notification_fromAppUUID CHAR(36) NULL,
    notification_fromUserUUID CHAR(36) NOT NULL,
    notification_workorderUUID CHAR(36) NULL,
   	notification_readyOn timestamp NOT NULL,
    notification_expireOn timestamp NOT NULL,
    notification_isClearable INT NULL DEFAULT 1,
   	notification_statusId INT NOT NULL DEFAULT 0, -- 0 not processed, 1+ processed
   	notification_content TEXT NULL, -- email payload
   	notification_subject varchar(255) NULL, -- email,SMS payload
   	notification_hook varchar(255) NULL, -- agnostic value understood by calling/receiving entity.
  	notification_createdTS datetime  NULL default now(),
   	PRIMARY KEY (notificationId))
ENGINE = InnoDB ;

DROP TABLE IF EXISTS notification_template;

CREATE TABLE `notification_template` (
  `notification_templateId` INT NOT NULL AUTO_INCREMENT,
   notification_customerUUID CHAR(36) NULL,
  `notification_key` VARCHAR(100) NOT NULL default '', -- well known key, and short description
  `notification_category` VARCHAR(100) NULL default '', -- used for easy maintenance searches
  `notification_templateType` VARCHAR(10) NOT NULL default 'EMAIL', -- [SMS,EMAIL,APP]
  `notification_templateSubject` VARCHAR(255) NOT NULL,
  `notification_templateBody` text NULL,
  PRIMARY KEY (`notification_templateId`),
  INDEX `notification_idx` (notification_key))
 ENGINE = InnoDB
AUTO_INCREMENT = 1000;


DROP TABLE IF EXISTS user_activity_log;

CREATE TABLE `user_activity_log` (
  	activityId INT NOT NULL AUTO_INCREMENT,
    activity_userUUID CHAR(36)  NOT NULL,
    activity_customerUUID CHAR(36) NULL,
  	activity_action VARCHAR(150) NOT NULL, -- well known activities [LOGIN,LOGOUT]
   	activity_detail varchar(255) NULL,
   	activity_error INT NULL,
  	activity_createdTS datetime  NULL default now(),
  	PRIMARY KEY (activityId))
ENGINE = InnoDB ;

-- =====================================
--  INTERNATIONALIZATION
-- =====================================


-- =====================================
-- ASSETS
-- =====================================

DROP TABLE IF EXISTS location;

-- INSERT INTO `location` (`location_coordinate`) VALUES (POINT(40.71727401 -74.00898606));

CREATE TABLE `location` (
    locationUUID CHAR(60)  NOT NULL,
    location_customerUUID CHAR(36)  NOT NULL,
    location_statusId INT   NULL DEFAULT 1,

    location_type varchar(255) NULL, -- [user defined types,]
    location_name varchar(255) NULL,
    location_description varchar(1000) NULL,
    location_isPrimary SMALLINT NOT NULL DEFAULT 0,
    location_imageUrl varchar(255) NULL,
    location_hotSpotJSON text NULL, -- JSON payload

    -- location_coordinate	POINT not null, -- can't have default
    location_addressTypeId INT NULL DEFAULT 1,
    location_address varchar(255) NULL,
    location_address_city varchar(255) NULL,
    location_address_state varchar(25) NULL,
    location_address_zip varchar(25) NULL,
    location_country varchar(25) NULL,

    location_contact_name varchar(100) NULL,
    location_contact_email varchar(100) NULL,
    location_contact_phone varchar(50) NULL,

    location_createdByUUID CHAR(36)  NULL,
    location_updatedByUUID CHAR(36)  NULL,
   	location_updatedTS datetime  NULL,
  	location_createdTS datetime  NULL default now(),
   	location_deleteTS datetime  NULL,

  	PRIMARY KEY (locationUUID)
  	-- ,SPATIAL INDEX coordinate_idx (location_coordinate)
    )
ENGINE = InnoDB ;


-- add location join to understand true topology.


DROP TABLE IF EXISTS asset;

CREATE TABLE `asset` (
    assetUUID CHAR(60)  NOT NULL,
    asset_locationUUID CHAR(36)  NULL,
    asset_partUUID CHAR(60)  NULL,
    asset_customerUUID CHAR(36)  NOT NULL,
    asset_statusId INT   NULL DEFAULT 1,

    asset_name varchar(255) NULL,
    asset_shortName varchar(255) NULL,

    asset_installDate DATE  NULL,

    asset_metaDataJSON TEXT NULL,

    asset_createdByUUID CHAR(36)  NULL,
    asset_updatedByUUID CHAR(36)  NULL,
   	asset_updatedTS datetime  NULL,
  	asset_createdTS datetime  NULL default now(),
   	asset_deleteTS datetime  NULL,
   	asset_externalId CHAR(36) NULL,

  	PRIMARY KEY (assetUUID),
  	INDEX location_idx (asset_customerUUID,asset_locationUUID,assetUUID,asset_partUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS asset_notes;

CREATE TABLE `asset_notes` (
    assetnotesId INT NOT NULL AUTO_INCREMENT,
    assetnotes_assetUUID CHAR(36) NULL,
    assetnotes_note text NULL,
    assetnotes_createdByUUID CHAR(36)  NULL,
    assetnotes_updatedByUUID CHAR(36)  NULL,
    assetnotes_updatedTS datetime  NULL,
    assetnotes_createdTS datetime  NULL default now(),
    PRIMARY KEY (assetnotesId),
    -- UNIQUE INDEX assetnotes_assetUUID_unique (assetnotes_assetUUID))
ENGINE = InnoDB AUTO_INCREMENT=1000;


DROP TABLE IF EXISTS asset_alert;

CREATE TABLE `asset_alert` (
    alertId INT  NOT NULL AUTO_INCREMENT,
    alert_assetUUID CHAR(36)  NOT NULL,
   	alert_statusId INT   NULL DEFAULT 1,

    asset_description varchar(1000) NULL,

    alert_createdByUUID CHAR(36)  NULL,
    alert_acknowledgedByUUID CHAR(36)  NULL,
   	alert_updatedTS datetime  NULL,
  	alert_createdTS datetime  NULL default now(),
   	alert_deleteTS datetime  NULL,

  	PRIMARY KEY (alertId),
  	INDEX alert_idx (alert_assetUUID))
ENGINE = InnoDB ;

DROP TABLE IF EXISTS asset_attachment_join;

CREATE TABLE `asset_attachment_join` (
                                         aaj_asset_assetUUID CHAR(36)  NOT NULL,
                                         aaj_attachmentUUID CHAR(36)  NOT NULL,
                                         aaj_createdTS datetime  NULL default now(),

                                         PRIMARY KEY (aaj_asset_assetUUID,aaj_attachmentUUID))
    ENGINE = InnoDB ;

DROP TABLE IF EXISTS attachment;

CREATE TABLE `attachment` (
    attachmentUUID CHAR(36)  NOT NULL,
   	attachment_statusId INT   NULL DEFAULT 1,
    attachment_fileURL varchar(255) NULL,
    attachment_shortName varchar(100) NULL,
    attachment_description varchar(1000)  NULL,
    attachment_mimeType varchar(25) NULL,
    attachment_customerUUID CHAR(36)  NOT NULL,

    attachment_createdByUUID CHAR(36)  NULL,
    attachment_acknowledgedByUUID CHAR(36)  NULL,
    attachment_updatedByUUID CHAR(36)  NULL,
   	attachment_updatedTS datetime  NULL,
  	attachment_createdTS datetime  NULL default now(),
   	attachment_deleteTS datetime  NULL,

  	PRIMARY KEY (attachmentUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS part_attachment_join;

CREATE TABLE `part_attachment_join` (
    paj_part_sku varchar(100) NOT NULL,
    paj_attachmentUUID CHAR(36)  NOT NULL,
  	paj_createdTS datetime  NULL default now(),

  	PRIMARY KEY (paj_part_sku,paj_attachmentUUID))
ENGINE = InnoDB ;



DROP TABLE IF EXISTS part_template;

CREATE TABLE `part_template` (
    -- part_partUUID CHAR(36)  NOT NULL,
    part_sku varchar(100) NOT NULL,
    part_brandId varchar(36) NULL,
   	part_statusId INT NULL DEFAULT 1,

    part_name varchar(255) NOT NULL,
    part_shortName varchar(100) NULL,
    part_description varchar(1000) NULL,
    part_userInstruction varchar(255) NULL,
    part_imageURL varchar(255) NULL,
    part_imageThumbURL varchar(255) NULL,
    part_hotSpotJSON text NULL, -- JSON payload
    part_isPurchasable SMALLINT NULL DEFAULT 1,

    -- part_knowledgeBaseUUID CHAR(36)   NULL, -- turned into a join
    part_diagnosticUUID CHAR(36)   NULL,
    part_magentoUUID CHAR(36)   NULL,
    part_vendor varchar(255)   NULL,

    part_createdByUUID CHAR(36)  NULL,
    part_updatedByUUID CHAR(36)  NULL,
   	part_updatedTS datetime  NULL,
  	part_createdTS datetime  NULL default now(),
   	part_deleteTS datetime  NULL,
    part_tags varchar(255) NULL,
    part_metaDataJSON TEXT NULL,

    -- PRIMARY KEY (part_partUUID),
    PRIMARY KEY (part_sku))
    -- UNIQUE index part_sku_unique (part_sku))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS part_join_template;

CREATE TABLE `part_join_template` (
    -- pj_parent_partUUID CHAR(36)  NOT NULL,
    -- pj_child_partUUID CHAR(36)  NOT NULL,
    pj_parent_part_sku varchar(100)  NOT NULL,
    pj_child_part_sku varchar(100)  NOT NULL,
    pj_createdTS datetime  NULL default now(),

  	PRIMARY KEY (pj_parent_partUUID,pj_child_partUUID))
ENGINE = InnoDB ;

-- TODO revisit
DROP TABLE IF EXISTS part_knowledge_join;

CREATE TABLE `part_knowledge_join` (
    pkj_part_partUUID CHAR(36)  NOT NULL,
    pkj_part_knowledgeUUID CHAR(36)  NOT NULL,
  	pkj_createdTS datetime  NULL default now(),
  	PRIMARY KEY (pkj_part_partUUID,pkj_part_knowledgeUUID))
ENGINE = InnoDB ;




DROP TABLE IF EXISTS asset_part;

CREATE TABLE `asset_part` (
    asset_partUUID CHAR(60)  NOT NULL, -- this is a new id and not = to template part
--    asset_template_partUUID CHAR(36)  NULL, -- reference back to a part in a template if needed.
    asset_part_template_part_sku varchar(100)  NULL, -- reference back to a part in a template if needed.
    asset_part_customerUUID CHAR(36)  NOT NULL,
   	asset_part_statusId INT NULL DEFAULT 1,

    asset_part_sku varchar(100) NULL,  -- can be null if their own part, but will take the original
    asset_part_name varchar(255) NOT NULL,
    asset_part_description varchar(1000) NULL,
    asset_part_userInstruction varchar(255) NULL,
    asset_part_shortName varchar(100) NULL,
    asset_part_imageURL varchar(255) NULL,
    asset_part_imageThumbURL varchar(255) NULL,
    asset_part_hotSpotJSON text NULL, -- JSON payload
    asset_part_isPurchasable SMALLINT NULL DEFAULT 1,

    -- asset_part_knowledgeBaseUUID CHAR(36)   NULL,
    asset_part_diagnosticUUID CHAR(36)   NULL,
    asset_part_magentoUUID CHAR(36)   NULL,
    asset_part_vendor varchar(255)   NULL,

    asset_part_createdByUUID CHAR(36)  NULL,
    asset_part_updatedByUUID CHAR(36)  NULL,
   	asset_part_updatedTS datetime  NULL,
  	asset_part_createdTS datetime  NULL default now(),
   	asset_part_deleteTS datetime  NULL,
    asset_part_tags varchar(255) NULL,
    asset_part_metaDataJSON TEXT NULL,

  	PRIMARY KEY (asset_partUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS asset_part_join;

CREATE TABLE `asset_part_join` (
    apj_parent_asset_partUUID CHAR(36)  NOT NULL,
    apj_child_asset_partUUID CHAR(36)  NOT NULL,
  	apj_createdTS datetime  NULL default now(),

  	PRIMARY KEY (apj_parent_asset_partUUID,apj_child_asset_partUUID))
ENGINE = InnoDB ;



DROP TABLE IF EXISTS asset_part_attachment_join;

CREATE TABLE `asset_part_attachment_join` (
    apaj_asset_partUUID CHAR(36)  NOT NULL,
    apaj_attachmentUUID CHAR(36)  NOT NULL,
  	apaj_createdTS datetime  NULL default now(),

  	PRIMARY KEY (apaj_asset_partUUID,apaj_attachmentUUID))
ENGINE = InnoDB ;



DROP TABLE IF EXISTS knowledge_base;

CREATE TABLE `knowledge_base` (
    knowledgeUUID CHAR(36)  NOT NULL,
   	knowledge_statusId INT   NULL DEFAULT 1,
    knowledge_imageURL varchar(255) NULL,
    knowledge_tags varchar(500) NULL, -- comma seperated tags
    knowledge_categories varchar(500) NULL, -- comma seperated tags
    knowledge_title varchar(100) NULL,
    knowledge_content varchar(1000)  NULL,
    knowledge_customerUUID CHAR(36)  NULL,
    knowledge_likes int NULL DEFAULT 0,
    knowledge_dislikes int NULL DEFAULT 0,
	  knowledge_relatedArticles TEXT NULL, -- json
    knowledge_createdByUUID CHAR(32)  NULL,
    knowledge_acknowledgedByUUID CHAR(32)  NULL,
    knowledge_updatedByUUID CHAR(32)  NULL,
   	knowledge_updatedTS datetime  NULL,
  	knowledge_createdTS datetime  NULL default now(),
   	knowledge_deleteTS datetime  NULL,
    knowledge_attachment varchar(100) NULL.

  	PRIMARY KEY (knowledgeUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS asset_part_knowledge_join;

CREATE TABLE `asset_part_knowledge_join` (
    apkj_asset_partUUID CHAR(36)  NOT NULL,
    apkj_asset_knowledgeUUID CHAR(36)  NOT NULL,
  	apkj_createdTS datetime  NULL default now(),

  	PRIMARY KEY (apkj_asset_partUUID,apkj_asset_knowledgeUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS diagnostic_tree;

CREATE TABLE `diagnostic_tree` (
    diagnosticUUID CHAR(36)  NOT NULL,
   	diagnostic_statusId INT   NULL DEFAULT 1,
    diagnostic_name varchar(100) NULL,
    diagnostic_description text  NULL,
    diagnostic_startNodeUUID CHAR(36) NULL,

    diagnostic_createdByUUID CHAR(36)  NULL,
    diagnostic_updatedByUUID CHAR(36)  NULL,
   	diagnostic_updatedTS datetime  NULL,
  	diagnostic_createdTS datetime  NULL default now(),
   	diagnostic_deleteTS datetime  NULL,

  	PRIMARY KEY (diagnosticUUID))
ENGINE = InnoDB ;

DROP TABLE IF EXISTS diagnostic_node;

CREATE TABLE `diagnostic_node` (
    diagnostic_nodeUUID CHAR(36)  NOT NULL,
    diagnostic_node_diagnosticUUID CHAR(36)  NOT NULL,
   	diagnostic_node_statusId INT   NULL DEFAULT 1,
    diagnostic_node_title varchar(100) NULL,
    diagnostic_node_warning varchar(255) NULL,
    diagnostic_node_prompt varchar(255) NULL,
    diagnostic_node_optionPrompt varchar(255) NULL,
    diagnostic_node_hotSpotJSON text NULL, -- JSON payload
    diagnostic_node_imageSetJSON text NULL, -- JSON payload
    diagnostic_node_optionSetJSON text NULL, -- JSON payload

    diagnostic_node_createdByUUID CHAR(36)  NULL,
    diagnostic_node_updatedByUUID CHAR(36)  NULL,
   	diagnostic_node_updatedTS datetime  NULL,
  	diagnostic_node_createdTS datetime  NULL default now(),
   	diagnostic_node_deleteTS datetime  NULL,

  	PRIMARY KEY (diagnostic_nodeUUID),
	INDEX diagnostic_node_idx (diagnostic_node_diagnosticUUID,diagnostic_nodeUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS workorder;

CREATE TABLE `workorder` (
    workorderUUID CHAR(36)  NOT NULL,
    workorder_customerUUID CHAR(36)  NOT NULL,
    workorder_locationUUID CHAR(36)  NULL,
    workorder_userUUID CHAR(36)  NULL,
    workorder_groupUUID CHAR(36)  NULL,
    workorder_assetUUID CHAR(36)  NULL,
    workorder_checklistUUID CHAR(36)  NULL,
    workorder_checklistHistoryUUID CHAR(36)  NULL,
    workorder_tag varchar(100)  NULL, -- used to help group WO's for actions.
   	workorder_status varchar(25)   NULL DEFAULT 'PENDING', -- PENDING,ASSIGNED,COMPLETE
   	workorder_type varchar(25)  NULL, -- user defined

    workorder_number varchar(100) NULL,
    workorder_name varchar(100) NULL,
    workorder_details text NULL,
    workorder_actions text NULL,
    workorder_priority varchar(25) NULL DEFAULT 'LOW', -- LOW, MEDIUM, HIGH

   	workorder_dueDate date  NULL,
    workorder_scheduleDate date  NULL,
    workorder_rescheduleDate date  NULL,
   	workorder_completeDate date  NULL,
   	workorder_frequency int  NULL DEFAULT 1,
   	workorder_frequencyScope varchar(25)  NULL DEFAULT 'DAILY', -- DAILY, WEEKLY, MONTHLY

    workorder_createdByUUID CHAR(36)  NULL,
    workorder_updatedByUUID CHAR(36)  NULL,
   	workorder_updatedTS datetime  NULL,
  	workorder_createdTS datetime  NULL default now(),
   	workorder_deleteTS datetime  NULL,

  	PRIMARY KEY (workorderUUID),
	INDEX workorder_user_idx (workorder_userUUID,workorder_dueDate),
	INDEX workorder_group_idx (workorder_groupUUID,workorder_dueDate)
	)
ENGINE = InnoDB ;


DROP TABLE IF EXISTS workorder_asset_part_join;

CREATE TABLE `workorder_asset_part_join` (
    wapj_workorderUUID CHAR(36)  NOT NULL,
    wapj_asset_partUUID CHAR(36)  NOT NULL,
    wapj_quantity INT  NOT NULL DEFAULT 1,
  	wapj_createdTS datetime  NULL default now(),

  	PRIMARY KEY (wapj_workorderUUID,wapj_asset_partUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS workorder_template;

CREATE TABLE `workorder_template` (
    workorder_templateUUID CHAR(36)  NOT NULL,
    workorder_template_customerUUID CHAR(36)  NOT NULL,
    workorder_template_locationUUID CHAR(36)  NULL,
    workorder_template_userUUID CHAR(36)  NULL,
    workorder_template_groupUUID CHAR(36)  NULL,
    workorder_template_assetUUID CHAR(36)  NULL,
    workorder_template_checklistUUID CHAR(36)  NULL,
   	workorder_type varchar(25)  NULL, -- user defined

    workorder_template_name varchar(100) NULL,
    workorder_template_details text NULL,
    workorder_template_actions text NULL,
    workorder_template_priority varchar(25) NULL DEFAULT 'LOW', -- LOW, MEDIUM, HIGH

   	workorder_template_frequency int  NULL DEFAULT 1,
   	workorder_template_frequencyScope varchar(25)  NULL DEFAULT 'SINGLE', -- DAILY, WEEKLY, MONTHLY, SINGLE

    workorder_createdByUUID CHAR(36)  NULL,
    workorder_updatedByUUID CHAR(36)  NULL,
   	workorder_updatedTS datetime  NULL,
  	workorder_createdTS datetime  NULL default now(),
   	workorder_deleteTS datetime  NULL,

  	PRIMARY KEY (workorder_templateUUID)
	)
ENGINE = InnoDB ;


DROP TABLE IF EXISTS checklist;

CREATE TABLE `checklist` (
    checklistUUID CHAR(36)  NOT NULL,
    checklist_customerUUID CHAR(36) NULL,
   	checklist_statusId INT   NULL DEFAULT 1,
    checklist_name varchar(100) NULL,
    checklist_recommendedFrequency varchar(255)  NULL,
    checklist_rulesJSON text  NULL,

    checklist_createdByUUID CHAR(36)  NULL,
    checklist_updatedByUUID CHAR(36)  NULL,
   	checklist_updatedTS datetime  NULL,
  	checklist_createdTS datetime  NULL default now(),
   	checklist_deleteTS datetime  NULL,

  	PRIMARY KEY (checklistUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS checklist_item;

CREATE TABLE `checklist_item` (
    checklist_itemUUID CHAR(36)  NOT NULL,
    checklist_item_checklistUUID CHAR(36)  NOT NULL,
    checklist_item_customerUUID CHAR(36)  NULL,
   	checklist_item_statusId INT   NULL DEFAULT 1,

    checklist_item_sortOrder INT  NOT NULL DEFAULT 1,
    checklist_item_prompt varchar(255) NULL,
    checklist_item_type varchar(255) NULL DEFAULT 'TEXT', -- DECIMAL,TEXT,BOOLEAN
    checklist_item_optionSetJSON text NULL, -- JSON payload
    checklist_item_successPrompt varchar(255) NULL,
    checklist_item_successRange varchar(255) NULL,

    checklist_item_createdByUUID CHAR(36)  NULL,
    checklist_item_updatedByUUID CHAR(36)  NULL,
   	checklist_item_updatedTS datetime  NULL,
  	checklist_item_createdTS datetime  NULL default now(),
   	checklist_item_deleteTS datetime  NULL,

  	PRIMARY KEY (checklist_itemUUID),
	INDEX checklist_item_idx (checklist_item_checklistUUID,checklist_itemUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS maestro_event;

CREATE TABLE `maestro_event` (
    maestro_eventUUID CHAR(36)  NOT NULL,
    maestro_event_customerUUID CHAR(36) NULL,
   	maestro_event_statusId INT   NULL DEFAULT 1,
    maestro_event_type varchar(25) NULL DEFAULT 'SYSTEM', -- ALARM, SYSTEM
    maestro_event_description varchar(255)  NULL,

    maestro_event_createdByUUID CHAR(36)  NULL,
    maestro_event_acknowledgedByUUID CHAR(36)  NULL,
   	maestro_event_acknowledgedTS datetime  NULL,
  	maestro_event_createdTS datetime  NULL default now(),
   	maestro_event_deleteTS datetime  NULL,

  	PRIMARY KEY (maestro_eventUUID),
    INDEX maestro_idx (maestro_eventUUID,maestro_event_createdTS)
    )
ENGINE = InnoDB ;


DROP TABLE IF EXISTS checklist_history;

CREATE TABLE `checklist_history` (
    checklist_historyUUID CHAR(36)  NOT NULL,
    checklist_history_checklistUUID CHAR(36)  NOT NULL,
    checklist_history_customerUUID CHAR(36) NOT NULL,
    checklist_history_workorderUUID CHAR(36) NULL,
    checklist_history_assetUUID CHAR(36) NULL,
    checklist_history_statusId INT   NULL DEFAULT 1,
    checklist_history_resultFlag INT   NULL DEFAULT 0, -- 0=open, 1=success, 2=fail
    checklist_history_name varchar(100) NULL,
    checklist_history_rulesJSON text  NULL,

    checklist_history_createdByUUID CHAR(36)  NULL,
    checklist_history_updatedByUUID CHAR(36)  NULL,
    checklist_history_updatedTS datetime  NULL,
    checklist_history_createdTS datetime  NULL default now(),
    checklist_history_deleteTS datetime  NULL,
    checklist_history_comment VARCHAR(255) NULL

    PRIMARY KEY (checklist_historyUUID))
ENGINE = InnoDB ;


DROP TABLE IF EXISTS checklist_item_history;

CREATE TABLE `checklist_item_history` (
    checklist_history_itemUUID CHAR(36)  NOT NULL,
    checklist_history_item_historyUUID CHAR(36)  NOT NULL,
    checklist_history_item_itemUUID CHAR(36) NOT NULL,
    checklist_history_item_statusId INT   NULL DEFAULT 1,
    checklist_history_item_resultFlag INT   NULL DEFAULT 0, -- 0=open, 1=success, 2=fail
    checklist_history_item_resultText varchar(255),

    checklist_history_item_sortOrder INT  NOT NULL DEFAULT 1,
    checklist_history_item_prompt varchar(255) NULL,
    checklist_history_item_type varchar(255) NULL DEFAULT 'TEXT', -- DECIMAL,TEXT,BOOLEAN
    checklist_history_item_optionSetJSON text NULL, -- JSON payload
    checklist_history_item_successPrompt varchar(255) NULL,
    checklist_history_item_successRange varchar(255) NULL,

    checklist_history_item_createdByUUID CHAR(36)  NULL,
    checklist_history_item_updatedByUUID CHAR(36)  NULL,
    checklist_history_item_updatedTS datetime  NULL,
    checklist_history_item_createdTS datetime  NULL default now(),
    checklist_history_item_deleteTS datetime  NULL,

    PRIMARY KEY (checklist_history_itemUUID),
  INDEX checklist_item_idx (checklist_history_item_historyUUID,checklist_history_itemUUID))
ENGINE = InnoDB ;



-- maestro_data - do this later.

DROP TABLE IF EXISTS privilege_bitwise;

CREATE TABLE `privilege_bitwise` (
   	privilege_key varchar(25)   NOT NULL,
    privilege_category varchar(25) NULL DEFAULT 'SYSTEM', -- ALARM, SYSTEM
    privilege_description varchar(255) NULL,
    privilege_bitWise bigint  NULL,
  	PRIMARY KEY (privilege_key)
    )
ENGINE = InnoDB ;


DROP TABLE IF EXISTS barcode;

CREATE TABLE `barcode` (
    barcodeId INT NOT NULL AUTO_INCREMENT,
    barcode_uuid CHAR(36) NOT NULL,
    barcode_type CHAR(100)  NULL,
    barcode_destinationURL VARCHAR(255) NULL,
    barcode_status CHAR(100) NULL DEFAULT 'ACTIVE',
    barcode_isRegistered BOOLEAN DEFAULT false,
    barcode_partSKU VARCHAR(255) NULL,
    barcode_assetUUID VARCHAR(36) NULL,
    barcode_customerUUID VARCHAR(36) NULL,
    barcode_locationUUID VARCHAR(36) NULL,
    barcode_createdByUUID CHAR(36)  NULL,
    barcode_updatedByUUID CHAR(36)  NULL,
   	barcode_updatedTS datetime  NULL,
  	barcode_createdTS datetime  NULL default now(),
   	barcode_deleteTS datetime  NULL,
   	PRIMARY KEY (barcodeId),
   	INDEX barcodeUUID_idx (barcode_uuid)
);

DROP TRIGGER IF EXISTS before_insert_on_barcode_set_uuids
DELIMITER //
CREATE TRIGGER before_insert_on_barcode_set_uuids
  BEFORE INSERT ON barcode
  FOR EACH ROW
    BEGIN
      SET new.barcode_uuid = replace(uuid(),'-','');
    END ;  //
DELIMITER ;


DROP TABLE IF EXISTS translations;

CREATE TABLE `translations` (
    translationId INT   NOT NULL   AUTO_INCREMENT,
    translation_languageCode varchar(10) NOT NULL,
    translation_uuid CHAR(36) NOT NULL,
    translation_field varchar(50) NOT NULL,
    translation_text text  NULL,
    PRIMARY KEY (translationId),
    index uuid_idx (translation_uuid,translation_field,translation_languageCode)
    )
ENGINE = InnoDB   AUTO_INCREMENT=1000;

DROP TABLE IF EXISTS languages;

CREATE TABLE `languages` (
    languageCode varchar(10) NOT NULL,
    PRIMARY KEY (languageCode)
    )
ENGINE = InnoDB ;

insert into languages (languageCode) values ('en-IN');
insert into languages (languageCode) values ('fr-FR');
insert into languages (languageCode) values ('de-DE');

TRUNCATE jcmi_hms.privilege_bitwise;
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_CREATEBRAND', 'ACCT', 2199023255552, 'ACCT-Can create brands');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_CREATECUSTOMER', 'ACCT', 4398046511104, 'ACCT-Can create customers');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_CREATEUSERS', 'ACCT', 549755813888, 'ACCT-Can create users');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_UPDATEUSERS', 'ACCT', 1099511627776, 'ACCT-Can update users');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_UPDATESECURITY', 'ACCT', 8796093022208, 'ACCT-Can update secuirty');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('APP_LOGIN', 'APP', 1, 'ADMIN-Can login');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('APP_SUPERUSER', 'APP', 2, 'ADMIN-Has JCMI Super User Rights');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CL_CREATE', 'CL', 4096, 'CHECKLIST-Can create checklists');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CL_DELETE', 'CL', 16384, 'CHECKLIST-Can delete checklists');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CL_READ', 'CL', 2048, 'CHECKLIST-Can read checklists');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CL_UPDATE', 'CL', 8192, 'CHECKLIST-Can edit checklists');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CLT_CREATE', 'CLT', 1048576, 'CHECKLIST TEMPLATE-Can create checklist templates');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CLT_DELETE', 'CLT', 4194304, 'CHECKLIST TEMPLATE-Can delete checklist templates');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CLT_READ', 'CLT', 524288, 'CHECKLIST TEMPLATE-Can read checklist templates');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CLT_UPDATE', 'CLT', 2097152, 'CHECKLIST TEMPLATE-Can update checklist templates');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('DIAG_CREATE', 'DIAG', 36028797018964000, 'DIAGNOSTICS-Can create diagnostics');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('DIAG_DELETE', 'DIAG', 144115188075856000, 'DIAGNOSTICS-Can create diagnostics');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('DIAG_READ', 'DIAG', 18014398509482000, 'DIAGNOSTICS-Can create diagnostics');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('DIAG_UPDATE', 'DIAG', 72057594037927900, 'DIAGNOSTICS-Can create diagnostics');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('GRP_CREATE', 'GRP', 35184372088832, 'GROUP-Can create groups');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('GRP_DELETE', 'GRP', 70368744177664, 'GROUP-Can delete groups');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('GRP_UPDATE', 'GRP', 140737488355328, 'GROUP-Can update groups');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('KB_CREATE', 'KB', 8589934592, 'KB-Can create articles');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('KB_DELETE', 'KB', 34359738368, 'KB-Can delete articles');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('KB_READ', 'KB', 4294967296, 'KB-Can read articles');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('KB_UPDATE', 'KB', 17179869184, 'KB-Can update articles');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('MAESTRO_CONTROL', 'MAESTRO', 134217728, 'MAESTRO-Can control Maestro');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('MAESTRO_READ', 'MAESTRO', 67108864, 'MAESTRO-Can view Maestro');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('SEARCH_SEARCH', 'SEARCH', 8, 'SEARCH-Can Search');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_ASSIGN', 'WO', 256, 'WORKORDER-Can assign workorders');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_CREATE', 'WO', 32, 'WORKORDER-Can create workorders');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_DELETE', 'WO', 128, 'WORKORDER-Can delete workorders');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_READ', 'WO', 16, 'WORKORDER-Can read workorders');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_UPDATE', 'WO', 64, 'WORKORDER-Can update workorders');
