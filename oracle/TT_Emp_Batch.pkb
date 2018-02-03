CREATE OR REPLACE PACKAGE BODY TT_Emp_Batch AS
/***************************************************************************************************
Description: Transactional API testing for HR demo batch code

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        11-Sep-2016 1.0   Created
Brendan Furey        22-Oct-2016 1.1   TRAPIT name changes, UT->TT etc.
Brendan Furey        27-Jan-2018 1.2   Re-factor to emphasise single underlying design pattern

***************************************************************************************************/
c_n                     CONSTANT VARCHAR2(1) := 'N';
c_date_fmt              CONSTANT VARCHAR2(30) := Utils_TT.c_date_fmt;
c_today_chr             CONSTANT VARCHAR2(30) := To_Char (SYSDATE, c_date_fmt);
/***************************************************************************************************

Write_Log: Local procedure calls utility logging procedure to write a line

***************************************************************************************************/
PROCEDURE Write_Log (p_line VARCHAR2) IS -- line to write
BEGIN
  Utils.Write_Log (p_line);
END Write_Log;

/***************************************************************************************************

tt_AIP_Load_Emps: Main procedure for testing Emp_Batch.AIP_Load_Emps procedure

***************************************************************************************************/
PROCEDURE tt_AIP_Load_Emps IS

  c_proc_name             CONSTANT VARCHAR2(61) := 'TT_Emp_Batch.tt_AIP_Load_Emps';
  c_batch_job_id          CONSTANT VARCHAR2(61) := 'LOAD_EMPS';
  c_offset_1              CONSTANT VARCHAR2(20) := '1_OFFSET';
  c_offset_2              CONSTANT VARCHAR2(20) := '2_OFFSET';
  c_past_date_chr         CONSTANT VARCHAR2(61) := Utils_TT.c_past_date_chr;
  c_ln_prefix             CONSTANT VARCHAR2(20) := 'LN ';
  c_em_prefix             CONSTANT VARCHAR2(20) := 'EM ';
  c_fn_prefix             CONSTANT VARCHAR2(20) := 'FN_';

  c_fn_lis                CONSTANT L1_chr_arr := L1_chr_arr (c_fn_prefix || '1');
  c_ln_lis                CONSTANT L1_chr_arr := L1_chr_arr (
        c_ln_prefix || '1', c_ln_prefix || '2', c_ln_prefix || '3', c_ln_prefix || '4', c_ln_prefix || '5', c_ln_prefix || '6');
  c_em_lis                CONSTANT L1_chr_arr := L1_chr_arr (
        c_em_prefix || '1', c_em_prefix || '2', c_em_prefix || '3', c_em_prefix || '4', c_em_prefix || '5', c_em_prefix || '6');
  c_sal_lis               CONSTANT L1_chr_arr := L1_chr_arr (
        '10000', '20000', '30000');

  c_status_s              CONSTANT VARCHAR2(1) := 'S';
  c_status_f              CONSTANT VARCHAR2(1) := 'F';
  c_job_id                CONSTANT VARCHAR2(20) := 'IT_PROG';
  c_job_id_invalid        CONSTANT VARCHAR2(20) := 'NON_JOB';
  c_hd_lis                CONSTANT L1_chr_arr := L1_chr_arr (c_past_date_chr, c_past_date_chr, c_past_date_chr);
  c_jb_lis                CONSTANT L1_chr_arr := L1_chr_arr (c_job_id, c_job_id, c_job_id);

  c_dat_name              CONSTANT VARCHAR2(20) := 'employees.dat';
  c_dat_name_0            CONSTANT VARCHAR2(30) := 'employees_20160101.dat';
  c_dat_name_1            CONSTANT VARCHAR2(30) := 'employees_20160801.dat';
  c_emp_id_invalid        CONSTANT VARCHAR2(20) := '99';
  c_30_chars              CONSTANT VARCHAR2(30) := '123456789012345678901234567890';
  c_1000_chars            CONSTANT VARCHAR2(1000) := '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
-- To avoid: 'SP2-0027: Input is too long (> 2499 characters) - line ignored'
  c_ms_limit              CONSTANT PLS_INTEGER := 2;

  c_file_3lis             CONSTANT L3_chr_arr := L3_chr_arr (
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr ('', c_ln_lis(1),  c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1)), ','))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr ('', c_ln_lis(1),  c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1)), ','),
                                                    Utils.List_Delim (L1_chr_arr (c_offset_1 || '1', c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2)), ','),
                                                    Utils.List_Delim (L1_chr_arr (c_offset_1 || '2', c_ln_lis(3) || 'U',  c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3)), ','))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr (c_emp_id_invalid, c_ln_lis(1),  c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1)), ','))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr ('', c_ln_lis(1),  c_em_lis(1) || c_30_chars, c_hd_lis(1), c_jb_lis(1), c_sal_lis(1)), ','))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr (c_offset_1 || '1', c_ln_lis(1) || c_30_chars,  c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1)), ','),
                                                    Utils.List_Delim (L1_chr_arr ('', c_ln_lis(3),  c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3)), ','))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr ('', c_ln_lis(1),  c_em_lis(1), c_hd_lis(1), c_job_id_invalid, c_sal_lis(1)), ','))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr ('', c_ln_lis(1),  c_em_lis(1), c_hd_lis(1), c_job_id_invalid, c_sal_lis(1)), ','),
                                                    Utils.List_Delim (L1_chr_arr (c_offset_1 || '1', c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_job_id_invalid, c_sal_lis(2)), ','),
                                                    Utils.List_Delim (L1_chr_arr (c_offset_1 || '2', c_ln_lis(3) || 'U',  c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3)), ','))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr ('', c_1000_chars || c_1000_chars || c_1000_chars || c_1000_chars || 'x',  c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1)), ','),
                                                    Utils.List_Delim (L1_chr_arr (c_offset_1 || '2', c_ln_lis(3) || 'U',  c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3)), ','))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_dat_name_1),
                                        L1_chr_arr (Utils.List_Delim (L1_chr_arr ('', c_ln_lis(1),  c_em_lis(1), c_hd_lis(1), c_job_id_invalid, c_sal_lis(1)), ','))
                                                )
);
  c_emp_3lis              CONSTANT L3_chr_arr := L3_chr_arr (
                                                NULL,
                                                L2_chr_arr (
                                        L1_chr_arr (c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2)),
                                        L1_chr_arr (c_ln_lis(3),  c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2)),
                                        L1_chr_arr (c_ln_lis(3),  c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2)),
                                        L1_chr_arr (c_ln_lis(3),  c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3))
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_ln_lis(2),  c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2))
                                                )
);
  c_jbs_3lis              CONSTANT L3_chr_arr := L3_chr_arr (
                                                NULL,
                                                L2_chr_arr (
                                        L1_chr_arr (c_batch_job_id, c_dat_name_0, '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s)
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_batch_job_id, c_dat_name_0, '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s)
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_batch_job_id, c_dat_name_0, '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s)
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_batch_job_id, c_dat_name_0, '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s)
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_batch_job_id, c_dat_name_0, '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s)
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_batch_job_id, c_dat_name_0, '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s)
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_batch_job_id, c_dat_name_1, '0', '0', '2', c_past_date_chr, c_past_date_chr, c_status_f)
                                                ),
                                                L2_chr_arr (
                                        L1_chr_arr (c_batch_job_id, c_dat_name_1, '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s)
                                                )
);
  c_exp_emp_2lis          CONSTANT L2_chr_arr := L2_chr_arr (
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(1), c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1), c_today_chr)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2), c_past_date_chr),
                                                    Utils.List_Delim (c_offset_1 || '2', c_ln_lis(3) || 'U', c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3), c_today_chr),
                                                    Utils.List_Delim (c_offset_1 || '3', c_ln_lis(1), c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1), c_today_chr)
                                        ),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2), c_past_date_chr)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2), c_past_date_chr)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2), c_past_date_chr),
                                                    Utils.List_Delim (c_offset_1 || '2', c_ln_lis(3), c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3), c_today_chr)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2), c_past_date_chr)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2), c_past_date_chr),
                                                    Utils.List_Delim (c_offset_1 || '2', c_ln_lis(3) || 'U', c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3), c_today_chr)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2), c_past_date_chr),
                                                    Utils.List_Delim (c_offset_1 || '2', c_ln_lis(3) || 'U', c_em_lis(3), c_hd_lis(3), c_jb_lis(3), c_sal_lis(3), c_today_chr)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_jb_lis(2), c_sal_lis(2), c_past_date_chr))
);

  c_exp_jbs_2lis           CONSTANT L2_chr_arr := L2_chr_arr (
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_1, '1', '0', '0', c_today_chr, c_today_chr, c_status_s)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_0,  '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s),
                                                    Utils.List_Delim (c_offset_1 || '2', c_batch_job_id, c_dat_name_1, '2', '0', '0', c_today_chr, c_today_chr, c_status_s)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_0,  '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s),
                                                    Utils.List_Delim (c_offset_1 || '2', c_batch_job_id, c_dat_name_1, '0', '0', '1', c_today_chr, c_today_chr, c_status_f)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_0,  '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s),
                                                    Utils.List_Delim (c_offset_1 || '2', c_batch_job_id, c_dat_name_1, '0', '0', '1', c_today_chr, c_today_chr, c_status_f)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_0,  '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s),
                                                    Utils.List_Delim (c_offset_1 || '2', c_batch_job_id, c_dat_name_1, '1', '0', '1', c_today_chr, c_today_chr, c_status_s)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_0,  '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s),
                                                    Utils.List_Delim (c_offset_1 || '2', c_batch_job_id, c_dat_name_1, '0', '0', '1', c_today_chr, c_today_chr, c_status_f)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_0,  '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s),
                                                    Utils.List_Delim (c_offset_1 || '2', c_batch_job_id, c_dat_name_1, '1', '0', '2', c_today_chr, c_today_chr, c_status_s)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_1,  '0', '0', '2', c_past_date_chr, c_past_date_chr, c_status_f),
                                                    Utils.List_Delim (c_offset_1 || '2', c_batch_job_id, c_dat_name_1, '1', '1', '0', c_today_chr, c_today_chr, c_status_s)),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '1', c_batch_job_id, c_dat_name_1,  '10', '0', '2', c_past_date_chr, c_past_date_chr, c_status_s))
  );
  c_exp_err_2lis           CONSTANT L2_chr_arr := L2_chr_arr (
                                        Utils_TT.c_empty_list,
                                        Utils_TT.c_empty_list,
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '2', '', 'Employee not found', 'PK', c_emp_id_invalid, c_ln_lis(1), c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1))),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '2', '', 'ORA-12899: value too large for column "HR"."EMPLOYEES"."EMAIL" (actual: 34, maximum: 25)', 'I', c_offset_2 || '2', c_ln_lis(1), c_em_lis(1) || c_30_chars, c_hd_lis(1), c_jb_lis(1), c_sal_lis(1))),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '2', '', 'ORA-12899: value too large for column "HR"."EMPLOYEES"."LAST_NAME" (actual: 34, maximum: 25)', 'U', c_offset_2 || '1', c_ln_lis(1) || c_30_chars, c_em_lis(1), c_hd_lis(1), c_jb_lis(1), c_sal_lis(1))),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '2', '', 'ORA-02291: integrity constraint (HR.EMP_JOB_FK) violated - parent key not found', 'I', c_offset_2 || '2', c_ln_lis(1), c_em_lis(1), c_hd_lis(1), c_job_id_invalid, c_sal_lis(1))),
                                        L1_chr_arr (Utils.List_Delim (c_offset_1 || '2', '', 'ORA-02291: integrity constraint (HR.EMP_JOB_FK) violated - parent key not found', 'U', c_offset_2 || '1', c_ln_lis(2), c_em_lis(2), c_hd_lis(2), c_job_id_invalid, c_sal_lis(2)),
                                                    Utils.List_Delim (c_offset_1 || '2', '', 'ORA-02291: integrity constraint (HR.EMP_JOB_FK) violated - parent key not found', 'I', c_offset_2 || '3', c_ln_lis(1), c_em_lis(1), c_hd_lis(1), c_job_id_invalid, c_sal_lis(1))),
                                        Utils_TT.c_empty_list,
                                        Utils_TT.c_empty_list
  );
  c_exp_exc_2lis           CONSTANT L2_chr_arr := L2_chr_arr (
                                        Utils_TT.c_empty_list,
                                        Utils_TT.c_empty_list,
                                        L1_chr_arr ('ORA-20001: Batch failed with too many invalid records!'),
                                        L1_chr_arr ('ORA-20001: Batch failed with too many invalid records!'),
                                        Utils_TT.c_empty_list,
                                        L1_chr_arr ('ORA-20001: Batch failed with too many invalid records!'),
                                        Utils_TT.c_empty_list,
                                        Utils_TT.c_empty_list,
                                        L1_chr_arr ('ORA-20002: File has already been processed successfully!')
  );

  c_scenario_lis          CONSTANT L1_chr_arr := L1_chr_arr (
                                'NV/OV/OU/NI/OI/EI: 1/0/0/0/0/0. Existing J/E: 0/0. [1 valid new record from scratch]',
                                'NV/OV/OU/NI/OI/EI: 1/1/1/0/0/0. Existing J/E: 1/0. [3 valid records of each kind]',
                                'NV/OV/OU/NI/OI/EI: 0/0/0/0/1/0. Existing J/E: 1/1. Uid not found [1 invalid old - exception]',
                                'NV/OV/OU/NI/OI/EI: 0/0/0/1/0/0. Existing J/E: 1/1. Email too long [1 invalid new - exception]',
                                'NV/OV/OU/NI/OI/EI: 1/0/0/0/1/0. Existing J/E: 1/1. Name too long [1 valid new, 1 invalid old - no exception]',
                                'NV/OV/OU/NI/OI/EI: 0/0/0/1/0/0. Existing J/E: 1/1. Invalid job [1 invalid new - exception]',
                                'NV/OV/OU/NI/OI/EI: 0/1/0/1/1/0. Existing J/E: 1/2. 2 invalid jobs [1 valid old, 2 invalid: old and new - no exception]',
                                'NV/OV/OU/NI/OI/EI: 0/1/0/0/0/1. Existing J/E: 1/2. Name 4001ch [1 valid old, 1 invalid new for external table - no exception; also file had previously failed]',
                                'NV/OV/OU/NI/OI/EI: 0/0/0/1/0/0. Existing J/E: 1/1. [File already processed - exception]');
  c_inp_group_lis         CONSTANT L1_chr_arr := L1_chr_arr ('Parameter', 'File', 'Batch Job Table', 'Statistics Table', 'Employees Table');
  c_inp_field_2lis        CONSTANT L2_chr_arr := L2_chr_arr (
                                                        L1_chr_arr ('File Name', '*Count'),
                                                        L1_chr_arr ('Line'),
                                                        L1_chr_arr ('Name', '*Fail Percent'),
                                                        L1_chr_arr ('*Job Statistic Id', 'Batch job Id', 'File Name', '*Records Loaded', '*Records Failed ET', '*Records Failed DB', 'Start Time', 'End Time', 'Status'),
                                                        L1_chr_arr ('*Employee Id', 'Name', 'Email', 'Hired', 'Job', '*Salary', '*Manager Id', '*Department Id', 'Updated')
  );
  c_out_group_lis         CONSTANT L1_chr_arr := L1_chr_arr ('Employee', 'Error', 'Job Statistic', 'Exception');
  c_out_field_2lis        CONSTANT L2_chr_arr := L2_chr_arr (
                                                        L1_chr_arr ('*Employee Id', 'Name', 'Email', 'Hired', 'Job', 'Salary', 'Updated'),
                                                        L1_chr_arr ('*Job Statistic Id', 'ORA_ERR_TAG$', 'ORA_ERR_MESG$', 'ORA_ERR_OPTYP$', '*Employee Id', 'Name', 'Email', 'Hired', 'Job', 'Salary'),
                                                        L1_chr_arr ('*Job Statistic Id', 'Batch job Id', 'File Name', '*Records Loaded', '*Records Failed ET', '*Records Failed DB', 'Start Time', 'End Time', 'Status'),
                                                        L1_chr_arr ('Message')
  );
  l_timer_set                      PLS_INTEGER;
  l_inp_3lis                       L3_chr_arr := L3_chr_arr();

  l_act_3lis                       L3_chr_arr := L3_chr_arr();
  l_exp_3lis                       L3_chr_arr := L3_chr_arr();

  /***************************************************************************************************

  Setup_Array: Array setup procedure

  ***************************************************************************************************/
  PROCEDURE Setup_Array IS
  BEGIN

    l_act_3lis.EXTEND (c_file_3lis.COUNT);
    l_inp_3lis.EXTEND (c_file_3lis.COUNT);
    l_exp_3lis.EXTEND (c_file_3lis.COUNT);

  END Setup_Array;

  /***************************************************************************************************

  Setup_DB: Database setup procedure for testing AIP_Load_Emps

  ***************************************************************************************************/
  PROCEDURE Setup_DB (p_exp_emp_lis          L1_chr_arr,    -- expected values for emplyees
                      p_exp_jbs_lis          L1_chr_arr,    -- expected values for job statistics
                      p_exp_err_lis          L1_chr_arr,    -- expected values for errors table
                      p_exp_exc_lis          L1_chr_arr,    -- expected values for exceptions
                      p_dat_2lis             L2_chr_arr,    -- data file inputs
                      p_emp_2lis             L2_chr_arr,    -- employees inputs
                      p_jbs_2lis             L2_chr_arr,    -- job statistics inputs
                      x_inp_2lis         OUT L2_chr_arr,    -- generic inputs list
                      x_exp_2lis         OUT L2_chr_arr) IS -- generic expected values list

    l_last_seq_emp      PLS_INTEGER;
    l_last_seq_jbs      PLS_INTEGER;
    l_emp_lis           L1_chr_arr := L1_chr_arr();
    l_exp_lis           L1_chr_arr := L1_chr_arr();
    l_jbs_lis           L1_chr_arr := L1_chr_arr();
    l_exp_jbs_lis       L1_chr_arr := L1_chr_arr();
    l_exp_err_lis       L1_chr_arr := L1_chr_arr();
    l_batch_job         VARCHAR2(60);
    l_dat_lis           L1_chr_arr := L1_chr_arr();
    FUNCTION Replace_Seq_Offset (p_str VARCHAR2, p_seq PLS_INTEGER, p_offset VARCHAR2) RETURN VARCHAR2 IS
      l_offset            PLS_INTEGER;
      l_seq               VARCHAR2(10);
    BEGIN
      l_offset := Instr (p_str, p_offset, 1, 1);
      IF l_offset > 0 THEN

        l_seq := p_seq + To_Number (Substr (p_str, l_offset + 8, 1));
        RETURN Regexp_Replace (p_str, p_offset || '(.)', To_Char (l_seq));

      ELSE

        RETURN p_str;

      END IF;

    END Replace_Seq_Offset;

  BEGIN

    DELETE hr.err$_employees WHERE ttid IS NOT NULL; -- DML logging does auto transaction
    DELETE job_statistics WHERE ttid IS NOT NULL; -- job statistics done via auto transaction
    COMMIT;

    SELECT Utils.List_Delim (batch_job_id, fail_threshold_perc)
      INTO l_batch_job
      FROM batch_jobs
     WHERE batch_job_id = c_batch_job_id;

    SELECT employees_seq.NEXTVAL
      INTO l_last_seq_emp
      FROM DUAL;

    l_exp_lis.EXTEND (p_exp_emp_lis.COUNT);
    FOR i IN 1..p_exp_emp_lis.COUNT LOOP

      l_exp_lis(i) := Replace_Seq_Offset (p_exp_emp_lis(i), l_last_seq_emp, c_offset_1);

    END LOOP;

    l_dat_lis.EXTEND (p_dat_2lis(2).COUNT);
    FOR i IN 1..p_dat_2lis(2).COUNT LOOP

      l_dat_lis(i) := Replace_Seq_Offset (p_dat_2lis(2)(i), l_last_seq_emp, c_offset_1);

    END LOOP;

    SELECT job_statistics_seq.NEXTVAL
      INTO l_last_seq_jbs
      FROM DUAL;

    l_exp_jbs_lis.EXTEND (p_exp_jbs_lis.COUNT);
    FOR i IN 1..p_exp_jbs_lis.COUNT LOOP

      l_exp_jbs_lis(i) := Replace_Seq_Offset (p_exp_jbs_lis(i), l_last_seq_jbs, c_offset_1);

    END LOOP;

    l_exp_err_lis.EXTEND (p_exp_err_lis.COUNT);
    FOR i IN 1..p_exp_err_lis.COUNT LOOP

      l_exp_err_lis(i) := Replace_Seq_Offset (Replace_Seq_Offset (p_exp_err_lis(i), l_last_seq_jbs, c_offset_1), l_last_seq_emp, c_offset_2);

    END LOOP;

    IF p_jbs_2lis IS NOT NULL THEN

      l_jbs_lis.EXTEND (p_jbs_2lis.COUNT);
      FOR i IN 1..p_jbs_2lis.COUNT LOOP

        DML_API_TT_Bren.Ins_jbs (
                            p_batch_job_id      => p_jbs_2lis(i)(1),
                            p_file_name         => p_jbs_2lis(i)(2),
                            p_records_loaded    => p_jbs_2lis(i)(3),
                            p_records_failed_et => p_jbs_2lis(i)(4),
                            p_records_failed_db => p_jbs_2lis(i)(5),
                            p_start_time        => p_jbs_2lis(i)(6),
                            p_end_time          => p_jbs_2lis(i)(7),
                            p_job_status        => p_jbs_2lis(i)(8),
                            x_rec               => l_jbs_lis(i));
      END LOOP;

    END IF;

    IF p_emp_2lis IS NOT NULL THEN

      l_emp_lis.EXTEND (p_emp_2lis.COUNT);
      FOR i IN 1..p_emp_2lis.COUNT LOOP

        l_last_seq_emp := DML_API_TT_HR.Ins_Emp (
                            p_emp_ind     => i,
                            p_dep_id      => NULL,
                            p_mgr_id      => NULL,
                            p_job_id      => p_emp_2lis(i)(4),
                            p_salary      => p_emp_2lis(i)(5),
                            p_last_name   => p_emp_2lis(i)(1),
                            p_email       => p_emp_2lis(i)(2),
                            p_hire_date   => p_emp_2lis(i)(3),
                            p_update_date => p_emp_2lis(i)(3),
                            x_rec         => l_emp_lis(i));
      END LOOP;

    END IF;

    Utils.Delete_File (c_dat_name);

    Utils.Write_File (c_dat_name, l_dat_lis);

    x_inp_2lis := L2_chr_arr (L1_chr_arr (Utils.List_Delim (p_dat_2lis(1)(1), p_dat_2lis(2).COUNT)),
                              l_dat_lis,
                              L1_chr_arr (l_batch_job),
                              l_jbs_lis,
                              l_emp_lis
                  );

    x_exp_2lis := L2_chr_arr (l_exp_lis, -- valid char, num pair
                              l_exp_err_lis,
                              l_exp_jbs_lis,
                              p_exp_exc_lis
                  );
  END Setup_DB;

  /***************************************************************************************************

  Purely_Wrap_API: Design pattern has the API call wrapped in a 'pure' procedure, called once per 
                   scenario, with the output 'actuals' array including everything affected by the API,
                   whether as output parameters, or on database tables, etc. The inputs are also
                   extended from the API parameters to include any other effective inputs. Assertion 
                   takes place after all scenarios and is against the extended outputs, with extended
                   inputs also listed. The API call is timed

  ***************************************************************************************************/
  PROCEDURE Purely_Wrap_API (p_file_name            VARCHAR2,      -- original file name
                             p_file_count           PLS_INTEGER,   -- number of lines in file
                             p_exp_emp_lis          L1_chr_arr,    -- expected values for employees
                             p_exp_jbs_lis          L1_chr_arr,    -- expected values for job statistics
                             p_exp_err_lis          L1_chr_arr,    -- expected values for errors table
                             p_exp_exc_lis          L1_chr_arr,    -- expected values for exceptions
                             p_dat_2lis             L2_chr_arr,    -- data file inputs
                             p_emp_2lis             L2_chr_arr,    -- employees inputs
                             p_jbs_2lis             L2_chr_arr,    -- job statistics inputs
                             x_inp_2lis         OUT L2_chr_arr,    -- generic inputs list (for scenario)
                             x_exp_2lis         OUT L2_chr_arr,    -- generic expected values list (for scenario)
                             x_act_2lis         OUT L2_chr_arr) IS -- generic actual values list (for scenario)

    l_tab_lis           L1_chr_arr;
    l_err_lis           L1_chr_arr;
    l_jbs_lis           L1_chr_arr;
    l_exc_lis           L1_chr_arr;

    -- Get_Tab_Lis: gets the database records inserted into a generic list of strings
    PROCEDURE Get_Tab_Lis (x_tab_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (
                 employee_id,
                 last_name,
                 email,
                 To_Char (hire_date, c_date_fmt),
                 job_id,
                 salary,
                 To_Char (update_date, c_date_fmt))
        BULK COLLECT INTO x_tab_lis
        FROM employees
       ORDER BY employee_id;

    END Get_Tab_Lis;

    -- Get_Err_Lis: gets the database error records inserted into a generic list of strings
    PROCEDURE Get_Err_Lis (x_err_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (
                job_statistic_id,
                ORA_ERR_TAG$,
                Replace (ORA_ERR_MESG$, Chr(10)),
                ORA_ERR_OPTYP$,
                employee_id,
                last_name,
                email,
                hire_date,
                job_id,
                salary)
      BULK COLLECT INTO x_err_lis
      FROM err$_employees;

    END Get_Err_Lis;

    -- Get_Jbs_Lis: gets the job_statistics_v records inserted into a generic list of strings
    PROCEDURE Get_Jbs_Lis (x_jbs_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (
                 job_statistic_id,
                 batch_job_id,
                 file_name,
                 records_loaded,
                 records_failed_et,
                 records_failed_db,
                 To_Char (start_time, c_date_fmt),
                 To_Char (end_time, c_date_fmt),
                 job_status)
        BULK COLLECT INTO x_jbs_lis
        FROM job_statistics_v
       ORDER BY job_statistic_id;

    END Get_Jbs_Lis;

  BEGIN

    Setup_DB (p_exp_emp_lis        => p_exp_emp_lis,
              p_exp_jbs_lis        => p_exp_jbs_lis,
              p_exp_err_lis        => p_exp_err_lis,
              p_exp_exc_lis        => p_exp_exc_lis,
              p_dat_2lis           => p_dat_2lis,
              p_emp_2lis           => p_emp_2lis,
              p_jbs_2lis           => p_jbs_2lis,
              x_inp_2lis           => x_inp_2lis,
              x_exp_2lis           => x_exp_2lis);
   Timer_Set.Increment_Time (l_timer_set, 'Setup_DB');

   BEGIN

      Emp_Batch.AIP_Load_Emps (p_file_name => p_file_name, p_file_count => p_file_count);
      Timer_Set.Increment_Time (l_timer_set, Utils_TT.c_call_timer);

    EXCEPTION
      WHEN OTHERS THEN
        l_exc_lis := L1_chr_arr (SQLERRM);
    END;


    Get_Tab_Lis (x_tab_lis => l_tab_lis); Timer_Set.Increment_Time (l_timer_set, 'Get_Tab_Lis');
    Get_Err_Lis (x_err_lis => l_err_lis); Timer_Set.Increment_Time (l_timer_set, 'Get_Err_Lis');
    Get_Jbs_Lis (x_jbs_lis => l_jbs_lis); Timer_Set.Increment_Time (l_timer_set, 'Get_Jbs_Lis');

    x_act_2lis := L2_chr_arr (Utils_TT.List_or_Empty (l_tab_lis),
                              Utils_TT.List_or_Empty (l_err_lis),
                              Utils_TT.List_or_Empty (l_jbs_lis),
                              Utils_TT.List_or_Empty (l_exc_lis));
    ROLLBACK;

  END Purely_Wrap_API;

BEGIN
--
-- Every testing main section should be similar to this, with array setup, then loop over scenarios
-- making a 'pure'(-ish) call to specific, local Purely_Wrap_API, with single assertion call outside
-- the loop
--
  l_timer_set := Utils_TT.Init (c_proc_name);
  Setup_Array;

  FOR i IN 1..c_file_3lis.COUNT LOOP

    Purely_Wrap_API (p_file_name          => c_file_3lis(i)(1)(1),
                     p_file_count         => c_file_3lis(i)(2).COUNT,
                     p_exp_emp_lis        => c_exp_emp_2lis(i),
                     p_exp_jbs_lis        => c_exp_jbs_2lis(i),
                     p_exp_err_lis        => c_exp_err_2lis(i),
                     p_exp_exc_lis        => c_exp_exc_2lis(i),
                     p_dat_2lis           => c_file_3lis(i),
                     p_emp_2lis           => c_emp_3lis(i),
                     p_jbs_2lis           => c_jbs_3lis(i),
                     x_inp_2lis           => l_inp_3lis(i),
                     x_exp_2lis           => l_exp_3lis(i),
                     x_act_2lis           => l_act_3lis(i));

  END LOOP;

  Utils_TT.Is_Deeply (c_proc_name, c_scenario_lis, l_inp_3lis, l_act_3lis, l_exp_3lis, l_timer_set, c_ms_limit,
                      c_inp_group_lis, c_inp_field_2lis, c_out_group_lis, c_out_field_2lis);

EXCEPTION
  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;
END tt_AIP_Load_Emps;

END TT_Emp_Batch;
/
SHO ERR
