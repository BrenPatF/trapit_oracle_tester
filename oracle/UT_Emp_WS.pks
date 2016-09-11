CREATE OR REPLACE PACKAGE UT_Emp_WS AS
/***************************************************************************************************
Description: Unit testing for HR demo web service code (Emp_WS) using Brendan's database unit
             testing framework.

                 UT_Utils:  Utility procedures for Brendan's database unit testing framework
                 Utils:     General utilities
                 Timer_Set: Code timing utility
                 Emp_WS:    HR demo web service base code

Further details: 'Brendan's Database Unit Testing Framework'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        08-May-2016 1.0   Initial
Brendan Furey        25-Jun-2016 1.1   Removed ut_Setup and ut_Teardown following removal of uPLSQL
Brendan Furey        11-Sep-2016 1.2   ut_AIP_Get_Dept_Emps added

***************************************************************************************************/

PROCEDURE ut_AIP_Save_Emps;
PROCEDURE ut_AIP_Get_Dept_Emps;

END UT_Emp_WS;
/
