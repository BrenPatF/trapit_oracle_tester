CREATE OR REPLACE PACKAGE DML_API_UT_Bren AS
/***************************************************************************************************
Description: This package contains Bren (i.e. demo schema) UT DML procedures for  Brendan's
             database unit testing framework demo test data

Further details: 'Brendan's Database Unit Testing Framework'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan              11-Sep-2016 1.0   Initial

***************************************************************************************************/

PROCEDURE Ins_Jbs (p_batch_job_id        VARCHAR2,
                   p_file_name           VARCHAR2,
                   p_records_loaded      PLS_INTEGER,
                   p_records_failed_et   PLS_INTEGER,
                   p_records_failed_db   PLS_INTEGER,
                   p_start_time          DATE,
                   p_end_time            DATE,
                   p_job_status          VARCHAR2,
                   x_rec             OUT VARCHAR2);

END DML_API_UT_Bren;
/
SHO ERR
