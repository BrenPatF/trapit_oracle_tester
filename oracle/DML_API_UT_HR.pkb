CREATE OR REPLACE PACKAGE BODY DML_API_UT_HR AS
/***************************************************************************************************
Description: This package contains HR DML procedures for Brendan's database unit testing
             framework demo test data

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        10-May-2016 1.0   Initial
Brendan Furey        09-Jul-2016 1.1   Added output parameter x_rec for new printing of inputs

***************************************************************************************************/

/***************************************************************************************************

Ins_Emp: Inserts a record in employees table for unit testing, setting the new utid column to
         session id

***************************************************************************************************/
FUNCTION Ins_Emp (p_emp_ind       PLS_INTEGER, -- employee index
                  p_dep_id        PLS_INTEGER, -- department id
                  p_mgr_id        PLS_INTEGER, -- manager id
                  p_job_id        VARCHAR2,    -- job id
                  p_salary        PLS_INTEGER, -- salary
                  x_rec       OUT VARCHAR2)    -- output record
                  RETURN PLS_INTEGER IS        -- employee id created
  l_emp_id PLS_INTEGER;
BEGIN

  INSERT INTO employees (
        employee_id,
        last_name,
        email,
        hire_date,
        job_id,
        salary,
        manager_id,
        department_id,
        utid
  ) VALUES (
        employees_seq.NEXTVAL,
        c_ln_pre || p_emp_ind,
        c_em_pre || p_emp_ind,
        SYSDATE,
        p_job_id,
        p_salary,
        p_mgr_id,
        p_dep_id,
        SYS_Context ('userenv', 'sessionid')
  ) RETURNING employee_id, Utils.List_Delim (   employee_id,
                                                last_name,
                                                email,
                                                hire_date,
                                                job_id,
                                                salary,
                                                manager_id,
                                                department_id)
         INTO l_emp_id, x_rec;

  RETURN l_emp_id;

END Ins_Emp;

END DML_API_UT_HR;
/
SHO ERR
/
