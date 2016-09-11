CREATE OR REPLACE PACKAGE UT_Emp_Batch AS
/***************************************************************************************************
Description: Unit testing for HR demo batch code

Further details: 'Brendan's Database Unit Testing Framework'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        11-Sep-2016 1.0   Created

***************************************************************************************************/
PROCEDURE ut_AIP_Load_Emps;

END UT_Emp_Batch;
/
SHO ERR
