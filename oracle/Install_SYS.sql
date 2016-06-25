SET SERVEROUTPUT ON
SET TRIMSPOOL ON
SET PAGES 1000
SET LINES 500
SPOOL Install_SYS.log
REM
REM Run this script from sys schema to create new schema for Brendan's utPLSQL web service demo
REM

DEFINE DEMO_USER=&1

CREATE USER &DEMO_USER IDENTIFIED BY &DEMO_USER
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";

-- SYSTEM PRIVILEGES
GRANT CREATE SESSION TO &DEMO_USER ;
GRANT ALTER SESSION TO &DEMO_USER ;
GRANT CREATE TABLE TO &DEMO_USER ;
GRANT CREATE TYPE TO &DEMO_USER ;
GRANT CREATE PUBLIC SYNONYM TO &DEMO_USER ;
GRANT CREATE SYNONYM TO &DEMO_USER ;
GRANT CREATE SEQUENCE TO &DEMO_USER ;
GRANT CREATE VIEW TO &DEMO_USER ;
GRANT UNLIMITED TABLESPACE TO &DEMO_USER ;
GRANT CREATE PROCEDURE TO &DEMO_USER ;

SPOOL OFF