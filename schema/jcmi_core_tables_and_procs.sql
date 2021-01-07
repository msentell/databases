
-- use cm_hms_auth;
use jcmi_core;

-- =====================================
-- CUSTOMER AND USERS
-- todo: create user/customer in their own space
-- =====================================

DROP TABLE IF EXISTS customer_brand;

CREATE TABLE `customer_brand` (
    brandUUID CHAR(32)  NOT NULL,
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
    customer_brandUUID CHAR(36)   NULL,
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







DROP FUNCTION IF EXISTS SESSION_generateAccessCode;

DELIMITER //
CREATE FUNCTION `SESSION_generateAccessCode`(_limit int) RETURNS varchar(45) CHARSET utf8mb4
    DETERMINISTIC
BEGIN


DECLARE _code VARCHAR(45) default '';
-- DECLARE _possible VARCHAR(100) DEFAULT  "23456789ABCDEFGHKMNPQRTUVWXY";
DECLARE _possible VARCHAR(100) DEFAULT  '1234567890';
DECLARE x INT DEFAULT 1;

    SET x=1;
    WHILE x <= _limit DO
        SET _code = CONCAT(_code, substring(_possible, FLOOR(RAND() * LENGTH(_possible) + 1), 1));
        SET x= x+1;
    END WHILE;

RETURN _code;
END //
DELIMITER ;


DROP FUNCTION IF EXISTS SESSION_generateSession;

DELIMITER //
CREATE FUNCTION `SESSION_generateSession`(_limit int) RETURNS varchar(45) CHARSET utf8mb4
    DETERMINISTIC
BEGIN


DECLARE _code VARCHAR(45) default '';
DECLARE _possible VARCHAR(100) DEFAULT  '23456789ABCDEFGHKMNPQRTUVWXYabcdefghijklmnopqrstuvwxyz';
-- DECLARE _possible VARCHAR(100) DEFAULT  '1234567890';
DECLARE x INT DEFAULT 1;

    SET x=1;
    WHILE x <= _limit DO
        SET _code = CONCAT(_code, substring(_possible, FLOOR(RAND() * LENGTH(_possible) + 1), 1));
        SET x= x+1;
    END WHILE;

RETURN _code;
END //
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
    DECLARE _startLocationUUID varchar(100);
    DECLARE _securityBitwise varchar(100);
    DECLARE _individualSecurityBitwise varchar(100);
    DECLARE _brand_preferenceJSON text;

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
        
         select brand_preferenceJSON into _brand_preferenceJSON  from customer_brand left join customer on (customer_brand.brandUUID = customer.customer_brandUUID)
        where customer.customerUUID = _customerUUID;

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
                    null, 2,
                    null, null,
                    concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode),
                    concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode), null
                );
            call NOTIFICATION_notification(
                    'CREATE', null,
                    'MFA', null, 'EMAIL',
                    _entityId, null, null, null, null,
                    null, 2,
                    null, null,
                    concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode),
                    concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode), null
                );

            select user_profile_locationUUID
            into _startLocationUUID
            from user_profile
            where user_profile_userUUID = _entityId;
            IF (_startLocationUUID is null) THEN
                select locationUUID
                into _startLocationUUID
                from location
                where location_customerUUID = _customerUUID
                  and location_isPrimary = 1
                LIMIT 1;
            END IF;
            select _entityId                      as entityId,
                   _USER_loginEmailValidationCode as accessCode,
                   4                              as expiresInMinutes,
                   _startLocationUUID             as startLocationUUID,
                   _userName                      as userName,
                   _securityBitwise               as securityBitwise,
                   _individualSecurityBitwise     as individualSecurityBitwise,
                   _brand_preferenceJSON         as brandpreferenceJSON,
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



            select user_profile_locationUUID
            into _startLocationUUID
            from user_profile
            where user_profile_userUUID = _entityId;
            IF (_startLocationUUID is null) THEN
                select locationUUID
                into _startLocationUUID
                from location
                where location_customerUUID = _customerUUID
                  and location_isPrimary = 1
                LIMIT 1;
            END IF;
            select _entityId                      as entityId,
                   _USER_loginEmailValidationCode as sessionToken,
                   _startLocationUUID             as startLocationUUID,
                   _userName                      as userName,
                   _securityBitwise               as securityBitwise,
                   _individualSecurityBitwise     as individualSecurityBitwise,
                   _brand_preferenceJSON          as brandpreferenceJSON,
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

            select user_profile_locationUUID
            into _startLocationUUID
            from user_profile
            where user_profile_userUUID = _entityId;
            IF (_startLocationUUID is null) THEN
                select locationUUID
                into _startLocationUUID
                from location
                where location_customerUUID = _customerUUID
                  and location_isPrimary = 1
                LIMIT 1;
            END IF;

            select _entityId                      as entityId,
                   _USER_loginEmailValidationCode as sessionToken,
                   _startLocationUUID             as startLocationUUID,
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
                    null, 2,
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
                    null, 2,
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
                null, 2,
                null, null,
                concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode),
                concat('You have 4 minutes to enter this access code: ', _USER_loginEmailValidationCode), null
            );
        call NOTIFICATION_notification(
                'CREATE', null,
                'MFA', null, 'EMAIL',
                _entityId, null, null, null, null,
                null, 2,
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

call USER_user('GETALLUSERS', 'a30af0ce5e07474487c39adab6269d5f',1,null,null,null,null,null,null,null,null,null,null,null);

call USER_user('GET_LIST_OF_USER', null, null,'1\',\'2',null,null,null, null,null,null,null,null, null,null);

*/

DROP procedure IF EXISTS `USER_user`;

DELIMITER $$
CREATE PROCEDURE `USER_user`(IN _action VARCHAR(100),
                             IN _customerId VARCHAR(100),
                             IN _userUUID CHAR(36), -- user making the request
                             IN _user_userUUID CHAR(36), -- target user
                             IN _user_userName VARCHAR(100),
                             IN _user_loginEmail VARCHAR(255),
                             IN _user_loginPW VARCHAR(100),
                             IN _user_statusId INT,
                             IN _user_securityBitwise BIGINT,
                             IN _user_profile_locationUUID CHAR(36),
                             IN _user_profile_phone VARCHAR(100),
                             IN _user_profile_preferenceJSON VARCHAR(1000),
                             IN _user_profile_avatarSrc varchar(255),
                             IN _groupUUID CHAR(36))
USER_user:
BEGIN

    DECLARE _DEBUG INT DEFAULT 0;

    DECLARE _dateFormat varchar(100) DEFAULT '%d-%m-%Y';
    DECLARE _userFoundUUID CHAR(36);
    DECLARE _commaNeeded INT;

    IF (_action = 'GET-LIST') THEN

        set @l_sql = CONCAT(
                'select c.customer_name, c.customerUUID, u.*,p.user_profile_phone,p.user_profile_preferenceJSON,p.user_profile_avatarSrc ');


        -- if (_groupUUID is not null) THEN
        --     set @l_sql = CONCAT(@l_sql, ',g.group_name, g.groupUUID ');
        -- end if;

        set @l_sql = CONCAT(@l_sql, ' from `user` u');
        set @l_sql = CONCAT(@l_sql, ' left join customer c on (c.customerUUID=u.user_customerUUID)');
        set @l_sql = CONCAT(@l_sql, ' left join user_profile p on (p.user_profile_userUUID = u.userUUID)');
        -- set @l_sql = CONCAT(@l_sql, ' left join location l on (l.locationUUID = p.user_profile_locationUUID)');

        -- if (_groupUUID is not null) THEN
        --     set @l_sql = CONCAT(@l_sql, ' left join user_group_join gj on (gj.ugj_userUUID = u.userUUID)');
        --     set @l_sql = CONCAT(@l_sql, ' left join user_group g on (g.groupUUID = gj.ugj_groupUUID)');
        -- end if;

        if (_customerId is not null) THEN
            set @l_sql = CONCAT(@l_sql, 'where u.user_customerUUID = \'', _customerId, '\'');
            set _commaNeeded = 1;
        END IF;
        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSEIF (_action = 'GET') THEN

        IF (_customerId IS NULL or _customerId = '') THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_user: _customerId can not be empty';
            LEAVE USER_user;
        END IF;

        set @l_sql = CONCAT(
                'select c.customer_name, c.customerUUID, u.*,p.user_profile_phone,p.user_profile_preferenceJSON,p.user_profile_avatarSrc,p.user_profile_locationUUID ');


        -- if (_groupUUID is not null) THEN
        --     set @l_sql = CONCAT(@l_sql, ',g.group_name, g.groupUUID ');
        -- end if;

        set @l_sql = CONCAT(@l_sql, ' from `user` u');
        set @l_sql = CONCAT(@l_sql, ' left join customer c on (c.customerUUID=u.user_customerUUID)');
        set @l_sql = CONCAT(@l_sql, ' left join user_profile p on (p.user_profile_userUUID = u.userUUID)');
        -- set @l_sql = CONCAT(@l_sql, ' left join location l on (l.locationUUID = p.user_profile_locationUUID)');

        -- if (_groupUUID is not null) THEN
        --     set @l_sql = CONCAT(@l_sql, ' left join user_group_join gj on (gj.ugj_userUUID = u.userUUID)');
        --     set @l_sql = CONCAT(@l_sql, ' left join user_group g on (g.groupUUID = gj.ugj_groupUUID)');
        -- end if;

        set @l_sql = CONCAT(@l_sql, ' where ');

        if (_customerId is not null) THEN
            set @l_sql = CONCAT(@l_sql, 'u.user_customerUUID = \'', _customerId, '\'');
            set _commaNeeded = 1;
        END IF;
        if (_user_userUUID is not null) THEN
            if (_commaNeeded = 1) THEN set @l_sql = CONCAT(@l_sql, ' AND '); END IF;
            set @l_sql = CONCAT(@l_sql, 'u.userUUID = \'', _user_userUUID, '\'');
            set _commaNeeded = 1;
        END IF;
        -- if (_groupUUID is not null) THEN
        --     if (_commaNeeded = 1) THEN set @l_sql = CONCAT(@l_sql, ' AND '); END IF;
        --     set @l_sql = CONCAT(@l_sql, 'g.groupUUID = \'', _groupUUID, '\'');
        --     set _commaNeeded = 1;
        -- END IF;

        set @l_sql = CONCAT(@l_sql, ';');

        IF (_DEBUG = 1) THEN select _action, @l_SQL; END IF;

        PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSEIF (_action = 'UPDATE' and _user_userUUID is not null) THEN

        IF (_customerId IS NULL or _customerId = '') THEN
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_user: _customerId can not be empty';
            LEAVE USER_user;
        END IF;

        -- RULES and CONVERSIONS

        select userUUID into _userFoundUUID from `user` where userUUID = _user_userUUID;

        IF (_userFoundUUID is null) THEN

            insert into `user` (userUUID, user_customerUUID, user_userName, user_loginEmail,
                                user_loginPW, user_statusId,
                                user_securityBitwise,
                                user_createdByUUID, user_updatedByUUID, user_updatedTS, user_createdTS, user_deleteTS)
            values (_user_userUUID, _customerId, _user_userName, _user_loginEmail,
                    _user_loginPW, 1,
                    _user_securityBitwise,
                    _userUUID, _userUUID, now(), now(), null);

            -- handle creating the profile record;

            replace into user_profile (user_profile_userUUID, user_profile_avatarSrc, user_profile_phoneTypeId,
                                       user_profile_phone, user_profile_addressTypeId, user_profile_locationUUID,
                                       user_profile_preferenceJSON,
                                       user_profile_createdByUUID, user_profile_updatedByUUID, user_profile_updatedTS,
                                       user_profile_createdTS, user_profile_deleteTS)
            values (_user_userUUID, _user_profile_avatarSrc, 3, _user_profile_phone, 2, _user_profile_locationUUID,
                    _user_profile_preferenceJSON,
                    _userUUID, _userUUID, now(), now(), null);

        ELSE -- update

            set @l_sql = CONCAT('update user set user_updatedTS =now(), user_updatedByUUID =', _userUUID);

            if (_user_userName is not null) THEN
                set @l_sql = CONCAT(@l_sql, ',user_userName = \'', _user_userName, '\'');
            END IF;
            if (_user_loginEmail is not null) THEN
                set @l_sql = CONCAT(@l_sql, ',user_loginEmail = \'', _user_loginEmail, '\'');
            END IF;
            if (_user_statusId is not null) THEN
                set @l_sql = CONCAT(@l_sql, ',user_statusId = ', _user_statusId);
            END IF;
            if (_user_securityBitwise is not null) THEN
                set @l_sql = CONCAT(@l_sql, ',user_securityBitwise = ', _user_securityBitwise);
            END IF;

               set @l_sql = CONCAT(@l_sql, ' where userUUID = \'', _user_userUUID, '\';');

            IF (_DEBUG = 1) THEN select _action, @l_SQL; END IF;

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

                set @l_sql = null;

                set @l_sql =
                        CONCAT('update user_profile set user_profile_updatedTS =now(), user_profile_updatedByUUID =',
                               _userUUID);

                if (_user_profile_locationUUID is not null) THEN
                    set @l_sql = CONCAT(@l_sql, ',user_profile_locationUUID = \'', _user_profile_locationUUID, '\'');
                END IF;
                if (_user_profile_phone is not null) THEN
                    set @l_sql = CONCAT(@l_sql, ',user_profile_phone = \'', _user_profile_phone, '\'');
                END IF;
                if (_user_profile_preferenceJSON is not null) THEN
                    set @l_sql =
                            CONCAT(@l_sql, ',user_profile_preferenceJSON = \'', _user_profile_preferenceJSON, '\'');
                END IF;
                if (_user_profile_avatarSrc is not null) THEN
                    set @l_sql = CONCAT(@l_sql, ',user_profile_avatarSrc = \'', _user_profile_avatarSrc, '\'');
                END IF;


                set @l_sql = CONCAT(@l_sql, ' where user_profile_userUUID = \'', _user_userUUID, '\';');

                IF (_DEBUG = 1) THEN select _action, @l_SQL; END IF;

                PREPARE stmt FROM @l_sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;

            END IF;

        END IF;

    ELSEIF (_action = 'REMOVE') THEN

        -- if (_groupUUID is not null) THEN

        --     delete
        --     from user_group_join
        --     where ugj_groupUUID = _groupUUID
        --       and ugj_userUUID = _user_userUUID;

        -- END IF;

        if (_user_userUUID is not null) THEN
            update `user`
            set user_deleteTS=now(),
                user_updatedByUUID=_userUUID,
                user_updatedTS=now()
            where userUUID = _user_userUUID;
        END IF;


    -- ELSEIF (_action = 'ADDGROUP' and _user_userUUID is not null and _groupUUID is not null) THEN

    --     insert ignore into user_group_join
    --         (ugj_groupUUID, ugj_userUUID, ugj_createdByUUID, ugj_createdTS)
    --     values (_groupUUID, _user_userUUID, _userUUID, now());

    ELSEIF (_action = 'CHANGEPASSWORD' and _user_userUUID is not null and _user_loginPW is not null) THEN

        update `user`
        set user_loginPW=_user_loginPW,
            user_updatedByUUID=_userUUID,
            user_updatedTS=now()
        where userUUID = _user_userUUID;

    ELSEIF (_action = 'LOGOUT') THEN

        update `user`
        set user_loginSessionExpire = now()
        where userUUID = _user_userUUID;

    ELSEIF (_action = 'GETALLUSERS') THEN

        if (_customerId is null) Then
            SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_user: _customerId can not be empty';
            LEAVE USER_user;
        END IF;

        select 'user' as tableName, userUUID as id, user_userName as value, user_userName as name
        from `user`
        where user_customerUUID = _customerId
          and user_statusId = 1
        order by user_userName;

    ELSEIF (_action = 'GET_LIST_OF_USER') THEN
		set @l_sql = CONCAT('SELECT userUUID, user_userName FROM `user` where userUUID IN (\'',_user_userUUID,'\')');
		PREPARE stmt FROM @l_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSE
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call USER_user: _action is of type invalid';
        LEAVE USER_user;
    END IF;


    IF (_DEBUG = 1) THEN
        select _action,
               _user_userUUID,
               _customerId,
               _user_userName,
               _user_loginEmail,
               _user_loginPW,
               _user_securityBitwise,
               _userUUID,
               _groupUUID;

    END IF;


END$$

DELIMITER ;

DROP procedure IF EXISTS `ATT_getPicklist`;

DELIMITER //
CREATE PROCEDURE `ATT_getPicklist`(IN _tables varchar(1000),
                                   _customerId CHAR(36),
                                   _userId CHAR(36))
getPicklist:
BEGIN

    IF (LOCATE('customer_brand', _tables) > 0) THEN
        select 'customer_brand' as tableName, brandUUID as id, brandUUID as value, brand_name as label
        from customer_brand
        order by label;
    END IF;

     IF (LOCATE('customer', _tables) > 0) THEN
        select 'customer' as tableName, customerUUID as id, customerUUID as value, customer_name as name
        from customer
        order by customer_name;
    END IF;
END //

DELIMITER ;










END //
DELIMITER ;
-- ==================================================================
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

use cm_hms_auth;
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

