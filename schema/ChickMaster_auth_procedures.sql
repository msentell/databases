-- DEPRECATED...moved into jcmi_core_tables_and_procs
use cm_hms_auth;
use jcmi_core;
DELIMITER ;
-- ==================================================================
/*
-- > call CUSTOMER_customer(
--    <_action>,<user_id>,<_customerUUID>,<_customerBrandUUID>,<_customerStatusId>,
--    <_customerName>,<_customerLogo>,<_customerSecurityBitwise>,<_customerPreferenceJSON>,
--    <_xRefName>,<_xRefId>,<_customer_externalName>)
-- > call CUSTOMER_customer('ASSIGN-BRAND',<_user_id>,<_customerUUID>,<_customerBrandUUID>,null,null,null,null,null,null,null);
-- call CUSTOMER_customer('ASSIGN-BRAND',1,'a30af0ce5e07474487c39adab6269d5g','3',null,null,null,null,null,null,null,null);
-- > call CUSTOMER_customer('REMOVE-BRAND',<_user_id>,<_customerUUID>,<_customerBrandUUID>,null,null,null,null,null,null,null);
-- call CUSTOMER_customer('REMOVE-BRAND',1,'a30af0ce5e07474487c39adab6269d5g','3',null,null,null,null,null,null,null,null);
-- > call CUSTOMER_customer('GET',<user_id>,<_customerUUID>,null,null,null,null,null,null,null,null,null);
-- call CUSTOMER_customer('GET',1,'059cfac3b0e3440fb4d499f85036b4ba',null,null,null,null,null,null,null,null,null);
- >call CUSTOMER_customer('CREATE',_userUUID,null,_customerBrandUUID,null,_customerName,null,null,null,null,null,null);
-  call CUSTOMER_customer('CREATE','1',null,'1',null,'cus-5',null,null,null,null,null,null);
*/
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
                                     IN _xRefId VARCHAR(255),
									 IN _customer_externalName VARCHAR(50))
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
        SELECT * FROM customer c LEFT JOIN customer_brand cb on (c.customer_brandUUID = cb.brandUUID) WHERE customerUUID = _customerUUID;
       ELSEIF (_action = 'CREATE') THEN
        -- _customerName is required
        IF (_customerName IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerName missing';
        END IF;
        -- _customerBrandUUID is required
        IF (_customerBrandUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerBrandUUID missing';
        END IF;
		
        SET @New_Customer_id = uuid();
        
        INSERT INTO customer (customerUUID, customer_brandUUID,customer_name,customer_updatedTS,customer_updatedByUUID,customer_createdByUUID)
        VALUES (@New_Customer_id,_customerBrandUUID,_customerName,now(),_userUUID,_userUUID);
        
        SELECT @New_Customer_id as 'customerId';
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
    ELSEIF (_action ='ASSIGN-BRAND')THEN
        
        IF (_customerBrandUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customer_brandUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;
        IF (_customerUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;

        update customer set customer_brandUUID = _customerBrandUUID, customer_updatedByUUID = _userUUID, customer_updatedTS = now()   where  customerUUID = _customerUUID;
    ELSEIF (_action ='REMOVE-BRAND')THEN
        
        IF (_customerUUID IS NULL) THEN
            SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'call CUSTOMER_customer: _customerUUID missing';
            LEAVE CUSTOMER_customer;
        END IF;

        update customer set customer_brandUUID = null, customer_updatedByUUID = _userUUID, customer_updatedTS = now()   where  customerUUID = _customerUUID;   
    END IF;
    
END$$

Delimiter ;
-- ==================================================================

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
-- ==================================================================
DROP procedure IF EXISTS `SECURITY_bitwise2`;
/*
call SECURITY_bitwise2(_action,_userId,_hierarchyId,_hierarchyType,_att_bitwise);
call SECURITY_bitwise2('ADD','1','10f15063ba49451baf43e750c0be4805','BRAND',2);
call SECURITY_bitwise2('REMOVE','1','10f15063ba49451baf43e750c0be4805','BRAND',4);
call SECURITY_bitwise2('ADD','1','059cfac3b0e3440fb4d499f85036b4ba','CUSTOMER',4);
call SECURITY_bitwise2('REMOVE','1','059cfac3b0e3440fb4d499f85036b4ba','CUSTOMER',4);
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
CREATE PROCEDURE SECURITY_bitwise2(IN _action VARCHAR(100),
                                  IN _userId CHAR(36),
                                  IN _hierarchyId CHAR(36),
                                  IN _hierarchyType CHAR(36),
                                  IN _att_bitwise BIGINT)
SECURITY_bitwise2:
BEGIN

    DECLARE _DEBUG INT DEFAULT 1;
    
    IF(_action IS NULL)THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise2: _action can not be empty';
        LEAVE SECURITY_bitwise2;
    END IF;
    IF(_userId IS NULL)THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise2: _userId can not be empty';
        LEAVE SECURITY_bitwise2;
    END IF;
    IF(_hierarchyType IS NULL)THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise2: _hierarchyType can not be empty';
        LEAVE SECURITY_bitwise2;
    END IF;
    IF(_hierarchyId IS NULL)THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise2: _hierarchyId can not be empty';
        LEAVE SECURITY_bitwise2;
    END IF;

    -- GET CURRENT BITWISE
    SET @CUR_BITWISE = null;

    IF(_hierarchyType = 'BRAND')THEN
        select brand_securityBitwise into @CUR_BITWISE from customer_brand where brandUUID = _hierarchyId;
    ELSEIF(_hierarchyType = 'CUSTOMER')THEN
        select customer_securityBitwise into @CUR_BITWISE from customer where customerUUID = _hierarchyId;
    ELSE
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise2: _hierarchyType did not match any.';
        LEAVE SECURITY_bitwise2;
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
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'call SECURITY_bitwise2: _action did not match any.';
        LEAVE SECURITY_bitwise2;
    END IF;
    
    -- SET UPDATED BITWISE
    IF(_hierarchyType = 'BRAND')THEN
        update customer_brand SET brand_securityBitwise = @UPDATED_BITWISE where brandUUID = _hierarchyId;
    ELSEIF(_hierarchyType = 'CUSTOMER')THEN
         update customer SET customer_securityBitwise = @UPDATED_BITWISE where customerUUID = _hierarchyId;
    END IF;
    
END$$
DELIMITER ;