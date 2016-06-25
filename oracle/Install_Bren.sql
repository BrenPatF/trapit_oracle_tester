SET SERVEROUTPUT ON
SET TRIMSPOOL ON
SET PAGES 1000
SET LINES 500
SPOOL Install_Bren.log

REM Run this script from schema for Brendan's unit testing design patterns demo to create the common objects

PROMPT Common types creation
PROMPT =====================

PROMPT Drop type L3_chr_arr
DROP TYPE L3_chr_arr
/
PROMPT Drop type L2_chr_arr
DROP TYPE L2_chr_arr
/
PROMPT Create type L1_chr_arr
CREATE OR REPLACE TYPE L1_chr_arr IS VARRAY(32767) OF VARCHAR2(4000)
/
PROMPT Create type L2_chr_arr
CREATE OR REPLACE TYPE L2_chr_arr IS VARRAY(32767) OF L1_chr_arr
/
PROMPT Create type L3_chr_arr
CREATE OR REPLACE TYPE L3_chr_arr IS VARRAY(32767) OF L2_chr_arr
/
CREATE OR REPLACE PUBLIC SYNONYM L1_chr_arr FOR L1_chr_arr
/
GRANT EXECUTE ON L1_chr_arr TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM L2_chr_arr FOR L2_chr_arr
/
GRANT EXECUTE ON L2_chr_arr TO PUBLIC
/
CREATE OR REPLACE PUBLIC SYNONYM L3_chr_arr FOR L3_chr_arr
/
GRANT EXECUTE ON L3_chr_arr TO PUBLIC
/
PROMPT Create type L1_num_arr
CREATE OR REPLACE TYPE L1_num_arr IS VARRAY(32767) OF NUMBER
/
CREATE OR REPLACE PUBLIC SYNONYM L1_num_arr FOR L1_num_arr
/
GRANT EXECUTE ON L1_num_arr TO PUBLIC
/

PROMPT Common tables creation
PROMPT ======================

PROMPT Create table log_headers
DROP TABLE log_lines
/
DROP TABLE log_headers
/
CREATE TABLE log_headers (
        id                      INTEGER NOT NULL,
        description             VARCHAR2(500),
        creation_date           TIMESTAMP,
        CONSTRAINT hdr_pk       PRIMARY KEY (id)
)
/
PROMPT Insert the default log header
INSERT INTO log_headers VALUES (0, 'Miscellaneous output', SYSTIMESTAMP)
/
CREATE OR REPLACE PUBLIC SYNONYM log_headers FOR log_headers
/
GRANT ALL ON log_headers TO PUBLIC
/
DROP SEQUENCE log_headers_s
/
CREATE SEQUENCE log_headers_s START WITH 1
/
CREATE OR REPLACE PUBLIC SYNONYM log_headers_s FOR log_headers_s
/
GRANT SELECT ON log_headers_s TO PUBLIC
/
PROMPT Create table log_lines
CREATE TABLE log_lines (
        id                      INTEGER NOT NULL,
        log_header_id           INTEGER NOT NULL,
        group_text              VARCHAR2(100),
        line_text               VARCHAR2(4000),
        creation_date           TIMESTAMP,
        CONSTRAINT lin_pk       PRIMARY KEY (id, log_header_id),
        CONSTRAINT lin_hdr_fk   FOREIGN KEY (log_header_id) REFERENCES log_headers (id)
)
/
CREATE OR REPLACE PUBLIC SYNONYM log_lines FOR log_lines
/
GRANT ALL ON log_lines TO PUBLIC
/
DROP SEQUENCE log_lines_s
/
CREATE SEQUENCE log_lines_s START WITH 1
/
CREATE OR REPLACE PUBLIC SYNONYM log_lines_s FOR log_lines_s
/
GRANT SELECT ON log_lines_s TO PUBLIC
/

PROMPT Packages creation
PROMPT =================

PROMPT Create package Utils
@Utils.pks
@Utils.pkb

PROMPT Create package Timer_Set
@Timer_Set.pks
@Timer_Set.pkb

PROMPT Create package UT_Utils
@UT_Utils.pks
@UT_Utils.pkb

PROMPT HR Types creation
PROMPT =================

PROMPT Input types creation
DROP TYPE emp_in_arr
/
CREATE OR REPLACE TYPE emp_in_rec AS OBJECT (
        last_name       VARCHAR2(25),
        email           VARCHAR2(25),
        job_id          VARCHAR2(10),
        salary          NUMBER
)
/
CREATE TYPE emp_in_arr AS TABLE OF emp_in_rec
/
PROMPT Output types creation
DROP TYPE emp_out_arr
/
CREATE OR REPLACE TYPE emp_out_rec AS OBJECT (
        employee_id     NUMBER,
        description     VARCHAR2(500)
)
/
CREATE TYPE emp_out_arr AS TABLE OF emp_out_rec
/
PROMPT HR synonyms AND views creation
PROMPT ==============================
CREATE SYNONYM departments FOR hr.departments
/
CREATE SYNONYM employees_seq FOR hr.employees_seq
/
PROMPT employees view
CREATE OR REPLACE VIEW employees AS
SELECT
        employee_id,
	first_name,
	last_name,
	email,
	phone_number,
	hire_date,
	job_id,
	salary,
	commission_pct,
	manager_id,
	department_id,
	utid
  FROM  hr.employees
 WHERE (utid = SYS_Context ('userenv', 'sessionid') OR
        Substr (Nvl (SYS_Context ('userenv', 'client_info'), 'XX'), 1, 2) != 'UT')
/
PROMPT hr_test_view_v view
CREATE OR REPLACE VIEW hr_test_view_v AS
WITH all_emps AS (
        SELECT Avg (salary) avg_sal, SUM (salary) sal_tot_g
          FROM employees e
)
SELECT e.last_name, d.department_name, m.last_name manager, e.salary,
       Round (e.salary / Avg (e.salary) OVER (PARTITION BY e.department_id), 2) sal_rat,
       Round (e.salary / a.avg_sal, 2) sal_rat_g
  FROM all_emps a
 CROSS JOIN employees e
  JOIN departments d
    ON d.department_id = e.department_id
  LEFT JOIN employees m
    ON m.employee_id = e.manager_id
 WHERE e.job_id != 'AD_ASST'
   AND a.sal_tot_g >= 1600
/
PROMPT HR Packages creation
PROMPT ====================

PROMPT Create package DML_API_UT_HR
@DML_API_UT_HR.pks
@DML_API_UT_HR.pkb

PROMPT Create package Emp_WS
@Emp_WS.pks
@Emp_WS.pkb

PROMPT Create package UT_Emp_WS
@UT_Emp_WS.pks
@UT_Emp_WS.pkb

PROMPT View_drivers packages
PROMPT =====================

PROMPT Create package UT_View_Drivers
@UT_View_Drivers.pks
@UT_View_Drivers.pkb

SPOOL OFF