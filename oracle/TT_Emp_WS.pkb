CREATE OR REPLACE PACKAGE BODY TT_Emp_WS AS
/***************************************************************************************************
Description: Transactional API testing for HR demo web service code (Emp_WS) using Brendan's TRAPIT
             API testing framework.

             It was published initially with three utility packages and the base package for the
             articles linked in the link below:

                 Utils_TT:  Utility procedures for Brendan's TRAPIT API testing framework
                 Utils:     General utilities
                 Timer_Set: Code timing utility
                 Emp_WS:    HR demo web service base code

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        08-May-2016 1.0   Initial
Brendan Furey        21-May-2016 1.1   Re-factored: setup at procedure level; new type names;
                                       Write_Session_Results moved to Check_TT_Results; etc.
Brendan Furey        25-Jun-2016 1.2   Removed tt_Setup and ut_Teardown following removal of uPLSQL
Brendan Furey        09-Jul-2016 1.3   Passing new input arrays to Check_TT_Results for printing per
                                       scenario
Brendan Furey        11-Sep-2016 1.4   tt_AIP_Get_Dept_Emps added
Brendan Furey        01-Oct-2016 1.5   tt_AIP_Get_Dept_Emps: Call timing added; also, null dept
                                       scenario added
Brendan Furey        22-Oct-2016 1.6   TRAPIT name changes, UT->TT etc.
Brendan Furey        27-Jan-2018 1.7   Re-factor to emphasise single underlying design pattern

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

tt_AIP_Save_Emps: Main procedure for testing Emp_WS.AIP_Save_Emps procedure

***************************************************************************************************/
PROCEDURE tt_AIP_Save_Emps IS

  c_proc_name CONSTANT  VARCHAR2(61) := 'TT_Emp_WS.tt_AIP_Save_Emps';

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
  g_exp_3lis                   L3_chr_arr;

  c_ws_ms_limit          CONSTANT PLS_INTEGER := 2;
  c_scenario_lis         CONSTANT L1_chr_arr := L1_chr_arr (
                               '1 valid record',
                               '1 invalid job id',
                               '1 invalid number',
                               '2 valid records, 1 invalid job id (2 deliberate errors)'
  );
  c_inp_group_lis       CONSTANT L1_chr_arr := L1_chr_arr ('Employee');
  c_inp_field_2lis      CONSTANT L2_chr_arr := L2_chr_arr (
                                                        L1_chr_arr (
                                                                'Name',
                                                                'Email',
                                                                'Job',
                                                                '*Salary')
  );
  c_out_group_lis       CONSTANT L1_chr_arr := L1_chr_arr ('Employee', 'Output array', 'Exception');
  c_out_field_2lis      CONSTANT L2_chr_arr :=  L2_chr_arr (
                                    L1_chr_arr ('*Employee id', 'Name', 'Email', 'Job', '*Salary'),
                                    L1_chr_arr ('*Employee id', 'Description'),
                                    L1_chr_arr ('Error message')
  );
  l_timer_set           PLS_INTEGER;
  l_inp_3lis            L3_chr_arr := L3_chr_arr();

  l_act_3lis         L3_chr_arr := L3_chr_arr();

  /***************************************************************************************************

  Setup_Array: Array setup procedure for testing AIP_Save_Emps. Sets the expected 
               output nested array after determining where the primary key generating sequence is at

  ***************************************************************************************************/
  PROCEDURE Setup_Array IS
    l_last_seq_val         PLS_INTEGER;
  BEGIN

    SELECT employees_seq.NEXTVAL
      INTO l_last_seq_val
      FROM DUAL;

    g_exp_3lis := L3_chr_arr ( -- each call results in a list of 2 output lists: first is the table records; second is the out array
                        L2_chr_arr (L1_chr_arr (Utils.List_Delim (To_Char(l_last_seq_val+1), c_ln (1), c_em (1), c_job_id, c_salary (1))), -- valid char, num pair
                                    L1_chr_arr (Utils.List_Delim (To_Char(l_last_seq_val+1), To_Char(To_Date(l_last_seq_val+1,'J'),'JSP'))),
                                    Utils_TT.c_empty_list
                        ),
                        L2_chr_arr (Utils_TT.c_empty_list,
                                    L1_chr_arr (Utils.List_Delim (0, 'ORA-02291: integrity constraint (.) violated - parent key not found')),
                                    Utils_TT.c_empty_list
                        ),
                        L2_chr_arr (Utils_TT.c_empty_list,
                                    Utils_TT.c_empty_list,
                                    L1_chr_arr ('ORA-06502: PL/SQL: numeric or value error: character to number conversion error')
                        ),
                        L2_chr_arr (L1_chr_arr (Utils.List_Delim (To_Char(l_last_seq_val+3), c_ln (4), c_em (4), c_job_id, c_salary (1)), -- c_salary (1) should be c_salary (4)
                                                Utils.List_Delim (To_Char(l_last_seq_val+5), c_ln (6), c_em (6), c_job_id, c_salary (6)),
                                                Utils.List_Delim (To_Char(l_last_seq_val+5), c_ln (6), c_em (6), c_job_id, c_salary (6))), -- duplicate record to generate error
                                    L1_chr_arr (Utils.List_Delim (To_Char(l_last_seq_val+3), To_Char(To_Date(l_last_seq_val+3,'J'),'JSP')),
                                                Utils.List_Delim (0, 'ORA-02291: integrity constraint (.) violated - parent key not found'),
                                                Utils.List_Delim (To_Char(l_last_seq_val+5), To_Char(To_Date(l_last_seq_val+5,'J'),'JSP'))),
                                    Utils_TT.c_empty_list
                        )
                     );

    l_act_3lis.EXTEND (c_params_3lis.COUNT);
    l_inp_3lis.EXTEND (c_params_3lis.COUNT);

    FOR i IN 1..c_params_3lis.COUNT LOOP

      l_inp_3lis(i) := L2_chr_arr();
      l_inp_3lis(i).EXTEND(1);
      l_inp_3lis(i)(1) := L1_chr_arr();
      l_inp_3lis(i)(1).EXTEND(c_params_3lis(i).COUNT);
      FOR j IN 1..c_params_3lis(i).COUNT LOOP

        l_inp_3lis(i)(1)(j) := Utils.List_Delim (c_params_3lis(i)(j)(1), c_params_3lis(i)(j)(2), c_params_3lis(i)(j)(3), c_params_3lis(i)(j)(4));

      END LOOP;

    END LOOP;

  END Setup_Array;

  /***************************************************************************************************

  Purely_Wrap_API: Design pattern has the API call wrapped in a 'pure' procedure, called once per 
                   scenario, with the output 'actuals' array including everything affected by the API,
                   whether as output parameters, or on database tables, etc. The inputs are also
                   extended from the API parameters to include any other effective inputs. Assertion 
                   takes place after all scenarios and is against the extended outputs, with extended
                   inputs also listed. The API call is timed

                   Here, input is list of lists for single call to web service procedure, the specific
                   array type output list is converted to our generic list of lists format allowing 
                   for error cases. 

  ***************************************************************************************************/
  PROCEDURE Purely_Wrap_API (p_inp_2lis        L2_chr_arr,       -- input list of lists (record, field)
                             x_act_2lis    OUT L2_chr_arr) IS    -- output list of lists (group, record)

    l_emp_out_lis       emp_out_arr;
    l_tab_lis           L1_chr_arr;
    l_arr_lis           L1_chr_arr;
    l_err_lis           L1_chr_arr;

    -- Do_Save makes the ws call and returns o/p array
    PROCEDURE Do_Save (x_emp_out_lis OUT emp_out_arr) IS
      l_emp_in_lis        emp_in_arr := emp_in_arr();
    BEGIN

      FOR i IN 1..p_inp_2lis.COUNT LOOP
        l_emp_in_lis.EXTEND;
        l_emp_in_lis (l_emp_in_lis.COUNT) := emp_in_rec (p_inp_2lis(i)(1), p_inp_2lis(i)(2), p_inp_2lis(i)(3), p_inp_2lis(i)(4));
      END LOOP;

      Timer_Set.Init_Time (p_timer_set_ind => l_timer_set);
      Emp_WS.AIP_Save_Emps (
                p_emp_in_lis        => l_emp_in_lis,
                x_emp_out_lis       => x_emp_out_lis);
      Timer_Set.Increment_Time (p_timer_set_ind => l_timer_set, p_timer_name => Utils_TT.c_call_timer);

    END Do_Save;

    -- Get_Tab_Lis: gets the database records inserted into a generic list of strings
    PROCEDURE Get_Tab_Lis (x_tab_lis OUT L1_chr_arr) IS
    BEGIN

      SELECT Utils.List_Delim (employee_id, last_name, email, job_id, salary)
        BULK COLLECT INTO x_tab_lis
        FROM employees
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

    x_act_2lis := L2_chr_arr (Utils_TT.List_or_Empty (l_tab_lis), Utils_TT.List_or_Empty (l_arr_lis), Utils_TT.List_or_Empty (l_err_lis));
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
  Timer_Set.Increment_Time (l_timer_set, 'Setup_Array');

  FOR i IN 1..c_params_3lis.COUNT LOOP

    Purely_Wrap_API (c_params_3lis(i), l_act_3lis(i));

  END LOOP;

  Utils_TT.Is_Deeply (c_proc_name, c_scenario_lis, l_inp_3lis, l_act_3lis, g_exp_3lis, l_timer_set, c_ws_ms_limit,
                      c_inp_group_lis, c_inp_field_2lis, c_out_group_lis, c_out_field_2lis);

EXCEPTION
  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;
END tt_AIP_Save_Emps;

/***************************************************************************************************

tt_AIP_Get_Dept_Emps: Main procedure for testing Emp_WS.AIP_Get_Dept_Emps procedure

***************************************************************************************************/
PROCEDURE tt_AIP_Get_Dept_Emps IS

  c_proc_name           CONSTANT VARCHAR2(61) := 'TT_Emp_WS.tt_AIP_Get_Dept_Emps';
  c_dep_id_1            CONSTANT PLS_INTEGER := 10;
  c_dep_id_2            CONSTANT PLS_INTEGER := 20;
  c_dep_nm_1            CONSTANT VARCHAR2(100) := 'Administration';
  c_dep_nm_2            CONSTANT VARCHAR2(100) := 'Marketing';
  c_job_bad             CONSTANT VARCHAR2(100) := 'AD_ASST';
  c_job_good            CONSTANT VARCHAR2(100) := 'IT_PROG';
  c_base_sal            CONSTANT PLS_INTEGER := 1000;
  c_out_group_lis       CONSTANT L1_chr_arr := L1_chr_arr ('Select results');

  c_ln_pre              CONSTANT VARCHAR2(10) := DML_API_TT_HR.c_ln_pre;

  c_dep_lis             CONSTANT L1_chr_arr := L1_chr_arr (c_dep_id_1, c_dep_id_1, c_dep_id_2, NULL, c_dep_id_1);

  c_dataset_3lis        CONSTANT L3_chr_arr := L3_chr_arr (
                             L2_chr_arr (L1_chr_arr ('4 emps, 1 dep (10), emp-3 has no dep, emp-4 has bad job'),
--                                         dep           job          salary
                               L1_chr_arr (c_dep_id_1,   c_job_good,  '1000'),
                               L1_chr_arr (c_dep_id_1,   c_job_good,  '2000'),
                               L1_chr_arr (NULL,         c_job_good,  '3000'),
                               L1_chr_arr (c_dep_id_1,   c_job_bad,   '4000')
                                             ),
                             L2_chr_arr (L1_chr_arr ('As dataset 1 but with extra emp-5, in second dep (20)'),
                               L1_chr_arr (c_dep_id_1,   c_job_good,  '1000'),
                               L1_chr_arr (c_dep_id_1,   c_job_good,  '2000'),
                               L1_chr_arr (NULL,         c_job_good,  '3000'),
                               L1_chr_arr (c_dep_id_1,   c_job_bad,   '4000'),
                               L1_chr_arr (c_dep_id_2,   c_job_good,  '5000')
                                             ),
                             L2_chr_arr (L1_chr_arr ('As dataset 2 but with salaries * 0.1, total below reporting threshold of 1600'),
                               L1_chr_arr (c_dep_id_1,   c_job_good,  '100'),
                               L1_chr_arr (c_dep_id_1,   c_job_good,  '200'),
                               L1_chr_arr (NULL,         c_job_good,  '300'),
                               L1_chr_arr (c_dep_id_1,   c_job_bad,   '400'),
                               L1_chr_arr (c_dep_id_2,   c_job_good,  '500')
                                             )
                        );

  c_exp_2lis            CONSTANT L2_chr_arr := L2_chr_arr (
                                               L1_chr_arr (
                                       Utils.List_Delim (c_ln_pre || '1',   c_dep_nm_1, NULL,            '1000', '.67',   '.4'),
                                       Utils.List_Delim (c_ln_pre || '2',   c_dep_nm_1, c_ln_pre || '1', '2000',  '1.33', '.8')
                                               ),
                                               L1_chr_arr (
                                       Utils.List_Delim (c_ln_pre || '1',   c_dep_nm_1, NULL,            '1000', '.67',  '.33'),
                                       Utils.List_Delim (c_ln_pre || '2',   c_dep_nm_1, c_ln_pre || '1', '2000',  '1.33', '.67')
                                               ),
                                               L1_chr_arr (
                                       Utils.List_Delim (c_ln_pre || '5',   c_dep_nm_2, c_ln_pre || '1', '5000',  '1',    '1.67')
                                               ),
                                               Utils_TT.c_empty_list,
                                               Utils_TT.c_empty_list
                        );

  c_scenario_ds_lis     CONSTANT L1_num_arr := L1_num_arr (1, 2, 2, 2, 3);
  c_scenario_lis        CONSTANT L1_chr_arr := L1_chr_arr (
                               'DS-1, testing inner, outer joins, analytic over dep, and global ratios with 1 dep (10) - pass dep 10',
                               'DS-2, testing same as 1 but with extra emp in another dep (20) - pass dep 10',
                               'DS-2, as second scenario, but - pass dep 20',
                               'DS-2, as second scenario, but - pass null dep',
                               'DS-3, Salaries total 1500 (< threshold of 1600, so return nothing) - pass dep 10');

  c_inp_group_lis       CONSTANT L1_chr_arr := L1_chr_arr ('Employee', 'Department Parameter');
  c_inp_field_2lis      CONSTANT L2_chr_arr := L2_chr_arr (
                                                        L1_chr_arr (
                                                                '*Employee Id',
                                                                'Last Name',
                                                                'Email',
                                                                'Hire Date',
                                                                'Job',
                                                                '*Salary',
                                                                '*Manager Id',
                                                                '*Department Id',
                                                                'Updated'),
                                                        L1_chr_arr (
                                                                '*Department Id')
  );
  c_out_field_2lis      CONSTANT L2_chr_arr :=  L2_chr_arr ( L1_chr_arr (
                                'Name',
                                'Department',
                                'Manager',
                                '*Salary',
                                '*Salary Ratio (dep)',
                                '*Salary Ratio (overall)'));

  l_act_2lis                      L2_chr_arr := L2_chr_arr();
  c_ms_limit            CONSTANT PLS_INTEGER := 1;
  l_timer_set                    PLS_INTEGER;
  l_inp_3lis                     L3_chr_arr := L3_chr_arr();
  l_emp_csr                      SYS_REFCURSOR;

  /***************************************************************************************************

  Setup_Array: Array setup procedure for testing AIP_Get_Dept_Emps

  ***************************************************************************************************/
  PROCEDURE Setup_Array IS
  BEGIN

    l_act_2lis.EXTEND (c_exp_2lis.COUNT);
    l_inp_3lis.EXTEND (c_exp_2lis.COUNT);

    FOR i IN 1..c_exp_2lis.COUNT LOOP

      l_inp_3lis (i) := L2_chr_arr();
      l_inp_3lis (i).EXTEND(2);
      l_inp_3lis (i)(2) := L1_chr_arr (c_dep_lis(i));

    END LOOP;

  END Setup_Array;

  /***************************************************************************************************

  Setup_DB: Create test records for a given scenario for testing AIP_Get_Dept_Emps

  ***************************************************************************************************/
  PROCEDURE Setup_DB (p_call_ind           PLS_INTEGER,   -- index of input dataset
                      x_inp_lis        OUT L1_chr_arr) IS -- input list, employees

    l_emp_id            PLS_INTEGER;
    l_mgr_id            PLS_INTEGER;
    l_len_lis           L1_num_arr := L1_num_arr (1, -11, -13, -10, 10, -10);

  BEGIN

    Utils.Heading ('Employees created in setup: DS-' || p_call_ind || ' - ' || c_dataset_3lis (p_call_ind)(1)(1));
    Utils.Col_Headers (L1_chr_arr ('#', 'Employee id', 'Department id', 'Manager', 'Job id', 'Salary'), l_len_lis);
    x_inp_lis := L1_chr_arr();
    x_inp_lis.EXTEND (c_dataset_3lis (p_call_ind).COUNT - 1);
    FOR i IN 2..c_dataset_3lis (p_call_ind).COUNT LOOP

      l_emp_id := DML_API_TT_HR.Ins_Emp (
                            p_emp_ind  => i - 1,
                            p_dep_id   => c_dataset_3lis (p_call_ind)(i)(1),
                            p_mgr_id   => l_mgr_id,
                            p_job_id   => c_dataset_3lis (p_call_ind)(i)(2),
                            p_salary   => c_dataset_3lis (p_call_ind)(i)(3),
                            x_rec      => x_inp_lis(i - 1));
      Utils.Pr_List_As_Line (L1_chr_arr ((i-1), l_emp_id, Nvl (c_dataset_3lis (p_call_ind)(i)(1), ' '), Nvl (To_Char(l_mgr_id), ' '), c_dataset_3lis (p_call_ind)(i)(2), c_dataset_3lis (p_call_ind)(i)(3)), l_len_lis);
      IF i = 2 THEN
        l_mgr_id := l_emp_id;
      END IF;

    END LOOP;

  END Setup_DB;

  /***************************************************************************************************

  Purely_Wrap_API: Design pattern has the API call wrapped in a 'pure' procedure, called once per 
                   scenario, with the output 'actuals' array including everything affected by the API,
                   whether as output parameters, or on database tables, etc. The inputs are also
                   extended from the API parameters to include any other effective inputs. Assertion 
                   takes place after all scenarios and is against the extended outputs, with extended
                   inputs also listed. The API call is timed

  ***************************************************************************************************/
  PROCEDURE Purely_Wrap_API (p_scenario_ds      PLS_INTEGER,   -- index of input dataset
                             p_dep_id           PLS_INTEGER,   -- input department id
                             x_inp_lis      OUT L1_chr_arr,    -- generic inputs list (for scenario)
                             x_act_lis      OUT L1_chr_arr) IS -- generic actual values list (for scenario)
  BEGIN

    Setup_DB (p_scenario_ds, x_inp_lis);
    Timer_Set.Increment_Time (l_timer_set, Utils_TT.c_setup_timer);

    Emp_WS.AIP_Get_Dept_Emps (p_dep_id  => p_dep_id,
                              x_emp_csr => l_emp_csr);
    x_act_lis := Utils_TT.List_or_Empty (Utils_TT.Cursor_to_Array (x_csr => l_emp_csr));
    Timer_Set.Increment_Time (l_timer_set, Utils_TT.c_call_timer);
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

  FOR i IN 1..c_exp_2lis.COUNT LOOP

    Purely_Wrap_API (c_scenario_ds_lis(i), c_dep_lis(i), l_inp_3lis(i)(1), l_act_2lis(i));

  END LOOP;

  Utils_TT.Is_Deeply (c_proc_name, c_scenario_lis, l_inp_3lis, l_act_2lis, c_exp_2lis, l_timer_set, c_ms_limit,
                      c_inp_group_lis, c_inp_field_2lis, c_out_group_lis, c_out_field_2lis);

EXCEPTION

  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;

END tt_AIP_Get_Dept_Emps;

END TT_Emp_WS;
/
SHO ERR

