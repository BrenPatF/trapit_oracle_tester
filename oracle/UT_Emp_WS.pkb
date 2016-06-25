CREATE OR REPLACE PACKAGE BODY UT_Emp_WS AS
/***************************************************************************************************
Description: Unit testing for HR demo web service code (Emp_WS) using Brendan's database unit
             testing framework.

             It was published initially with three utility packages and the base package for the
             articles linked in the link below:

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
Brendan Furey        21-May-2016 1.1   Re-factored: setup at procedure level; new type names;
                                       Write_Session_Results moved to Check_UT_Results; etc.
Brendan Furey        25-Jun-2016 1.2   Removed ut_Setup and ut_Teardown following removal of uPLSQL

***************************************************************************************************/

c_n                     CONSTANT VARCHAR2(1) := 'N';

/***************************************************************************************************

Write_Log: Local procedure calls utility logging procedure to write a line

***************************************************************************************************/
PROCEDURE Write_Log (p_line VARCHAR2) IS -- line to write
BEGIN
  Utils.Write_Log (p_line);
END Write_Log;

/***************************************************************************************************

ut_AIP_Save_Emps: Main procedure for unit testing Emp_WS.AIP_Save_Emps procedure

***************************************************************************************************/
PROCEDURE ut_AIP_Save_Emps IS

  c_proc_name CONSTANT  VARCHAR2(61) := 'UT_Emp_WS.ut_AIP_Save_Emps';

  c_ln_prefix             CONSTANT VARCHAR2(20) := 'LN ';
  c_em_prefix             CONSTANT VARCHAR2(20) := 'EM ';

  c_ln                    CONSTANT L1_chr_arr := L1_chr_arr (
        c_ln_prefix || '1', c_ln_prefix || '2', c_ln_prefix || '3', c_ln_prefix || '4', c_ln_prefix || '5', c_ln_prefix || '6');
  c_em                    CONSTANT L1_chr_arr := L1_chr_arr (
        c_em_prefix || '1', c_em_prefix || '2', c_em_prefix || '3', c_em_prefix || '4', c_em_prefix || '5', c_em_prefix || '6');
  c_job_id                CONSTANT VARCHAR2(20) := 'IT_PROG';
  c_job_id_invalid        CONSTANT VARCHAR2(20) := 'NON_JOB';

  c_salary                CONSTANT L1_chr_arr := L1_chr_arr ('1000', '1500', '2000x', '3000', '4000', '5000');

  c_params_3lis           CONSTANT L3_chr_arr := L3_chr_arr (
          L2_chr_arr (L1_chr_arr (c_ln (1),    c_em (1),        c_job_id,         c_salary (1))), -- valid
          L2_chr_arr (L1_chr_arr (c_ln (2),    c_em (2),        c_job_id_invalid, c_salary (2))), -- invalid
          L2_chr_arr (L1_chr_arr (c_ln (3),    c_em (3),        c_job_id,         c_salary (3))), -- invalid salary, nan
          L2_chr_arr (L1_chr_arr (c_ln (4),    c_em (4),        c_job_id,         c_salary (4)),  -- valid
                      L1_chr_arr (c_ln (5),    c_em (5),        c_job_id_invalid, c_salary (5)),  -- invalid job id
                      L1_chr_arr (c_ln (6),    c_em (6),        c_job_id,         c_salary (6)))  -- valid
  );
  g_ws_exp_3lis                   L3_chr_arr;

  c_ws_ms_limit           CONSTANT PLS_INTEGER := 2;
  c_scenario_lis         CONSTANT L1_chr_arr := L1_chr_arr (
                               '1 valid record',
                               '1 invalid job id',
                               '1 invalid number',
                               '2 valid records, 1 invalid job id'
  );
  c_out_group_lis         CONSTANT L1_chr_arr := L1_chr_arr ('Employee', 'Output array', 'Exception');
  c_fields_2lis           CONSTANT L2_chr_arr :=  L2_chr_arr (
                                      L1_chr_arr ('*Employee id', 'Name', 'Email', 'Job', '*Salary'),
                                      L1_chr_arr ('*Employee id', 'Description'),
                                      L1_chr_arr ('Error message')
  );
  l_timer_set             PLS_INTEGER;
  l_ws_act_3lis           L3_chr_arr := L3_chr_arr ();

  /***************************************************************************************************

  Setup: Setup procedure for unit testing Emp_WS.AIP_Save_Emps package. Sets the expected output
          nested array after determining where the primary key generating sequence is at

  ***************************************************************************************************/
  PROCEDURE Setup IS
    l_last_seq_val         PLS_INTEGER;
  BEGIN

    SELECT employees_seq.NEXTVAL
      INTO l_last_seq_val
      FROM DUAL;

    g_ws_exp_3lis := L3_chr_arr ( -- each call results in a list of 2 output lists: first is the table records; second is the out array
                        L2_chr_arr (L1_chr_arr (Utils.List_Delim (To_Char(l_last_seq_val+1), c_ln (1), c_em (1), c_job_id, c_salary (1))), -- valid char, num pair
                                    L1_chr_arr (Utils.List_Delim (To_Char(l_last_seq_val+1), To_Char(To_Date(l_last_seq_val+1,'J'),'JSP'))),
                                    UT_Utils.c_empty_list
                        ),
                        L2_chr_arr (UT_Utils.c_empty_list,
                                    L1_chr_arr (Utils.List_Delim (0, 'ORA-02291: integrity constraint (.) violated - parent key not found')),
                                    L1_chr_arr (Utils.List_Delim (0, 'ORA-02291: integrity constraint (.) violated - parent key not found'))
                        ),
                        L2_chr_arr (UT_Utils.c_empty_list,
                                    UT_Utils.c_empty_list,
                                    L1_chr_arr ('ORA-06502: PL/SQL: numeric or value error: character to number conversion error')
                        ),
                        L2_chr_arr (L1_chr_arr (Utils.List_Delim (To_Char(l_last_seq_val+3), c_ln (4), c_em (4), c_job_id, c_salary (1)),  -- Deliberate mistake: c_salary (1), 4 --> 1
                                                Utils.List_Delim (To_Char(l_last_seq_val+5), c_ln (6), c_em (6), c_job_id, c_salary (6)),
                                                Utils.List_Delim (To_Char(l_last_seq_val+5), c_ln (6), c_em (6), c_job_id, c_salary (6))), -- Deliberate mistake: duplicate record
                                    L1_chr_arr (Utils.List_Delim (To_Char(l_last_seq_val+3), To_Char(To_Date(l_last_seq_val+3,'J'),'JSP')),
                                                Utils.List_Delim (0, 'ORA-02291: integrity constraint (.) violated - parent key not found'),
                                                Utils.List_Delim (To_Char(l_last_seq_val+5), To_Char(To_Date(l_last_seq_val+5,'J'),'JSP'))),
                                    UT_Utils.c_empty_list
                        )
                     );

  END Setup;

  /***************************************************************************************************

  Call_WS: Takes input list of lists for single call to web service procedure, calls the procedure
           with the specific array type list as input, converts the specific array type output list
           to our generic list of lists format allowing for error cases. Procedure call is timed

  ***************************************************************************************************/
  PROCEDURE Call_WS (p_ws_inp_2lis        L2_chr_arr,       -- input list of lists (record, field)
                     x_ws_out_2lis    OUT L2_chr_arr) IS    -- output list of lists (group, record)

    l_emp_out_lis       emp_out_arr;
    l_tab_lis           L1_chr_arr;
    l_arr_lis           L1_chr_arr;
    l_err_lis           L1_chr_arr;

    -- Do_Save makes the ws call and returns o/p array
    PROCEDURE Do_Save (x_emp_out_lis OUT emp_out_arr) IS
      l_emp_in_lis        emp_in_arr := emp_in_arr();
    BEGIN

      FOR i IN 1..p_ws_inp_2lis.COUNT LOOP
        l_emp_in_lis.EXTEND;
        l_emp_in_lis (l_emp_in_lis.COUNT) := emp_in_rec (p_ws_inp_2lis(i)(1), p_ws_inp_2lis(i)(2), p_ws_inp_2lis(i)(3), p_ws_inp_2lis(i)(4));
      END LOOP;

      Timer_Set.Init_Time (p_timer_set_ind => l_timer_set);
      Emp_WS.AIP_Save_Emps (
                p_emp_in_lis        => l_emp_in_lis,
                x_emp_out_lis       => x_emp_out_lis);
      Timer_Set.Increment_Time (p_timer_set_ind => l_timer_set, p_timer_name => UT_Utils.c_call_timer);

    END Do_Save;

    -- Get_Tab_Lis: gets the database records inserted into a generic list of strings
    PROCEDURE Get_Tab_Lis (x_tab_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (employee_id, last_name, email, job_id, salary)
        BULK COLLECT INTO x_tab_lis
        FROM employees
       WHERE utid = Utils.c_session_id_if_UT
       ORDER BY employee_id;
      Timer_Set.Increment_Time (p_timer_set_ind => l_timer_set, p_timer_name => 'SELECT');

    EXCEPTION
      WHEN NO_DATA_FOUND THEN NULL;
    END Get_Tab_Lis;

    -- Get_Arr_Lis converts the ws output array into a generic list of strings
    PROCEDURE Get_Arr_Lis (p_emp_out_lis emp_out_arr, x_arr_lis OUT L1_chr_arr) IS
    BEGIN

      IF p_emp_out_lis IS NOT NULL THEN

        x_arr_lis := L1_chr_arr();
        x_arr_lis.EXTEND (p_emp_out_lis.COUNT);
        FOR i IN 1..p_emp_out_lis.COUNT LOOP

          x_arr_lis (i) := Utils.List_Delim (p_emp_out_lis(i).employee_id, p_emp_out_lis(i).description);

        END LOOP;

      END IF;

    END Get_Arr_Lis;

  BEGIN

    BEGIN

      Do_Save (x_emp_out_lis => l_emp_out_lis);
      Get_Tab_Lis (x_tab_lis => l_tab_lis);
      Get_Arr_Lis (p_emp_out_lis => l_emp_out_lis, x_arr_lis => l_arr_lis);

    EXCEPTION
      WHEN OTHERS THEN
        l_err_lis := L1_chr_arr (SQLERRM);
    END;

    x_ws_out_2lis := L2_chr_arr (UT_Utils.List_or_Empty (l_tab_lis), UT_Utils.List_or_Empty (l_arr_lis), UT_Utils.List_or_Empty (l_err_lis));

  END Call_WS;

BEGIN

  l_timer_set := UT_Utils.Init (c_proc_name);
  Setup;
  Timer_Set.Increment_Time (l_timer_set, 'Setup');
  l_ws_act_3lis.EXTEND (c_params_3lis.COUNT);

  FOR i IN 1..c_params_3lis.COUNT LOOP

    Call_WS (c_params_3lis(i), l_ws_act_3lis(i));
    ROLLBACK;

  END LOOP;

  UT_Utils.Check_UT_Results (c_proc_name, c_scenario_lis, l_ws_act_3lis, g_ws_exp_3lis, l_timer_set, c_ws_ms_limit,
                             c_out_group_lis, c_fields_2lis);

EXCEPTION
  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;
END ut_AIP_Save_Emps;

END UT_Emp_WS;
/
SHO ERR
