CREATE OR REPLACE PACKAGE BODY DML_API_UT_Bren AS
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

/***************************************************************************************************

Ins_Emp: Inserts a record in job_statistics table for unit testing, setting the new utid column to
         session id

***************************************************************************************************/
PROCEDURE Ins_Jbs (p_batch_job_id        VARCHAR2,    -- batch job id
                   p_file_name           VARCHAR2,    -- original input file name
                   p_records_loaded      PLS_INTEGER, -- records loaded to table
                   p_records_failed_et   PLS_INTEGER, -- records that failed to load via external table
                   p_records_failed_db   PLS_INTEGER, -- records that failed validation in the database
                   p_start_time          DATE,        -- job start time
                   p_end_time            DATE,        -- job end time
                   p_job_status          VARCHAR2,    -- job status
                   x_rec             OUT VARCHAR2) IS -- output record
BEGIN

  INSERT INTO job_statistics (
        job_statistic_id,
        batch_job_id,
        file_name,
        records_loaded,
        records_failed_et,
        records_failed_db,
        start_time,
        end_time,
        job_status,
        utid
  ) VALUES (
        job_statistics_seq.NEXTVAL,
        p_batch_job_id,
        p_file_name,
        p_records_loaded,
        p_records_failed_et,
        p_records_failed_db,
        p_start_time,
        p_end_time,
        p_job_status,
        SYS_Context ('userenv', 'sessionid')
  ) RETURNING Utils.List_Delim (
                job_statistic_id,
                batch_job_id,
                file_name,
                records_loaded,
                records_failed_et,
                records_failed_db,
                To_Char (start_time, UT_Utils.c_date_fmt),
                To_Char (end_time, UT_Utils.c_date_fmt),
                job_status)
         INTO x_rec;

END Ins_Jbs;

END DML_API_UT_Bren;
/
SHO ERR