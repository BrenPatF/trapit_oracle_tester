CREATE OR REPLACE PACKAGE UT_Utils AS
/***************************************************************************************************
Description: This package contains procedures for Brendan's database unit testing framework .

             It was published initially with two other utility packages for the articles linked in
             the link below:

                 Utils:     General utilities
                 Timer_Set: Code timing utility

Further details: 'Brendan's Database Unit Testing Framework'
                 http://aprogrammerwrites.eu/?p=1723


Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        08-May-2016 1.0   Initial
Brendan Furey        21-May-2016 1.1   Replaced SYS.ODCI types with custom types L1_chr_arr etc.
Brendan Furey        25-Jun-2016 1.2   Refactored the output formatting; removed utPLSQL calls and
                                       replaced Run_Suite with new version that loops over array
                                       making its own calls
Brendan Furey        09-Jul-2016 1.3   Check_UT_Results: Write_Inp_Group added to body write inputs
                                       per scenario, with extra parameters for the inputs
Brendan Furey        09-Sep-2016 1.4   Cursor_to_Array added

***************************************************************************************************/
c_date_fmt              CONSTANT VARCHAR2(11) := 'DD-MON-YYYY';
c_past_date             CONSTANT DATE := To_Date ('01-JAN-2010', c_date_fmt);
c_past_date_chr         CONSTANT VARCHAR2(11) := To_Char (c_past_date, c_date_fmt);
c_call_timer            CONSTANT VARCHAR2(30) := 'Caller';
c_setup_timer           CONSTANT VARCHAR2(30) := 'Setup';
c_empty_list            CONSTANT L1_chr_arr := L1_chr_arr ('EMPTY');
c_ut_suite_bren         CONSTANT PLS_INTEGER := 1;

FUNCTION Init (p_proc_name VARCHAR2) RETURN PLS_INTEGER;
PROCEDURE Run_Suite (p_suite_id PLS_INTEGER);

PROCEDURE Check_UT_Results (p_proc_name                 VARCHAR2,
                            p_test_lis                  L1_chr_arr,
                            p_inp_3lis                  L3_chr_arr,
                            p_act_3lis                  L3_chr_arr,
                            p_exp_3lis                  L3_chr_arr,
                            p_timer_set                 PLS_INTEGER,
                            p_ms_limit                  PLS_INTEGER,
                            p_inp_group_lis             L1_chr_arr,
                            p_inp_fields_2lis           L2_chr_arr,
                            p_out_group_lis             L1_chr_arr,
                            p_fields_2lis               L2_chr_arr);

PROCEDURE Check_UT_Results (p_proc_name                 VARCHAR2,
                            p_test_lis                  L1_chr_arr,
                            p_inp_3lis                  L3_chr_arr,
                            p_act_2lis                  L2_chr_arr,
                            p_exp_2lis                  L2_chr_arr,
                            p_timer_set                 PLS_INTEGER,
                            p_ms_limit                  PLS_INTEGER,
                            p_inp_group_lis             L1_chr_arr,
                            p_inp_fields_2lis           L2_chr_arr,
                            p_out_group_lis             L1_chr_arr,
                            p_fields_2lis               L2_chr_arr);

PROCEDURE Check_UT_Results (p_proc_name                 VARCHAR2,
                            p_test_lis                  L1_chr_arr,
                            p_inp_3lis                  L3_chr_arr,
                            p_act_lis                   L1_chr_arr,
                            p_exp_lis                   L1_chr_arr,
                            p_timer_set                 PLS_INTEGER,
                            p_ms_limit                  PLS_INTEGER,
                            p_inp_group_lis             L1_chr_arr,
                            p_inp_fields_2lis           L2_chr_arr,
                            p_out_group_lis             L1_chr_arr,
                            p_fields_2lis               L2_chr_arr);

FUNCTION List_or_Empty (p_list L1_chr_arr) RETURN L1_chr_arr;
FUNCTION Get_View (    p_view_name         VARCHAR2,
                       p_sel_field_lis     L1_chr_arr,
                       p_where             VARCHAR2 DEFAULT NULL,
                       p_timer_set         PLS_INTEGER) RETURN L1_chr_arr;
FUNCTION Cursor_to_Array (x_csr IN OUT SYS_REFCURSOR, p_filter VARCHAR2 DEFAULT NULL) RETURN L1_chr_arr;

END UT_Utils;
/
SHOW ERROR
CREATE OR REPLACE PUBLIC SYNONYM UT_Utils FOR UT_Utils
/
GRANT EXECUTE ON UT_Utils TO PUBLIC
/
