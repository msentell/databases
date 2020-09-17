
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