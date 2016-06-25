CREATE OR REPLACE PACKAGE DML_API_UT_HR AS
/***************************************************************************************************
Description: This package contains HR DML procedures for Brendan's database unit testing
             framework demo test data

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        10-May-2016 1.0   Initial

***************************************************************************************************/

c_ln_pre        CONSTANT VARCHAR2(10) := 'LN_';
c_em_pre        CONSTANT VARCHAR2(10) := 'EM_';

FUNCTION Ins_Emp (      p_emp_ind        PLS_INTEGER,
                            p_dep_id        PLS_INTEGER,
                            p_mgr_id        PLS_INTEGER,
                            p_job_id        VARCHAR2,
                            p_salary        PLS_INTEGER) RETURN PLS_INTEGER;

END DML_API_UT_HR ;
/
SHO ERR
/
