use cm_hms_auth;
use jcmi_core;
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
