CREATE OR REPLACE PACKAGE UT_View_Drivers AS
/***************************************************************************************************
Description: This package contains unit testing procedures corresponding to SQL views, which allows
             testing of SQL statements with Brendan's database unit testing framework.

             For ut_View_X, no package is required as this test package actually calls a generic
             packaged procedure in UT_Utils to execute the SQL for the job.

             It was published initially with three other utility packages for the articles linked in
             the link below:

                 UT_Utils:  Utility procedures for Brendan's database unit testing framework
                 Utils:     General utilities
                 Timer_Set: Code timing utility

Further details: 'Brendan's Database Unit Testing Framework'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        21-May-2016 1.0   Created
Brendan Furey        25-Jun-2016 1.1   Removed ut_Setup and ut_Teardown following removal of uPLSQL

***************************************************************************************************/

PROCEDURE ut_HR_Test_View_V;

END UT_View_Drivers;
/
