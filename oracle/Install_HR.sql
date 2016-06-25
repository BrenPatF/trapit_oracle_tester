SET SERVEROUTPUT ON
SET TRIMSPOOL ON
SET PAGES 1000
SET LINES 500
SPOOL Install_HR.log
DEFINE DEMO_USER=&1
REM
REM Run this script from HR schema to add utid column TO employees for Brendan's utPLSQL web service demo
REM

PROMPT ADD utid TO employees
ALTER TABLE employees ADD (utid VARCHAR2(30))
/
PROMPT Grant all on employees to &DEMO_USER
GRANT ALL ON employees TO &DEMO_USER
/
PROMPT Grant all on departments to &DEMO_USER
GRANT ALL ON departments TO &DEMO_USER
/
PROMPT Grant all on employees_seq to &DEMO_USER
GRANT ALL ON employees_seq TO &DEMO_USER
/
SPOOL OFF