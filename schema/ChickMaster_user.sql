
use cm_hms_auth;

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



