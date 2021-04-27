use jcmi_core;
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

---------------------------------------------------------------------------------
-- to get user permissions of user
DROP FUNCTION IF EXISTS fetchUserPermissions;

DELIMITER //

CREATE FUNCTION fetchUserPermissions (
_bitwise VARCHAR(100))
RETURNS varchar(2000)
fetchUserPermissions:
BEGIN
DECLARE biwiseArray varchar(2000) DEFAULT '';
set @cnt  = 0;
IF(_bitwise is null ) THEN 
set biwiseArray = 0;
return biwiseArray;
leave fetchUserPermissions;
END IF;
do_this:
loop
	set @num = POWER(2, @cnt);
    IF(@num & _bitwise != 0) THEN
		IF(biwiseArray= '') THEN
			set biwiseArray =  @num;
		ELSE
			set biwiseArray = CONCAT(biwiseArray , ',' , @num);
		END IF;
	END IF;
   set @cnt = @cnt + 1;
    if(POWER(2, @cnt) > _bitwise) THEN
		leave do_this;
    END IF;
END loop do_this ;
 return biwiseArray;
END; //

DELIMITER ;