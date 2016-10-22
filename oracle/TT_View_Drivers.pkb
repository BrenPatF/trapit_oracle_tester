CREATE OR REPLACE PACKAGE BODY TT_View_Drivers AS
/***************************************************************************************************
Description: This package contains testing procedures corresponding to SQL views, which allows
             testing of SQL statements with Brendan's TRAPIT API testing framework.

             For tt_View_X, no package is required as this test package actually calls a generic
             packaged procedure in Utils_TT to execute the SQL for the job.

             It was published initially with three other utility packages for the articles linked in
             the link below:

                 Utils_TT:  Utility procedures for Brendan's TRAPIT API testing framework
                 Utils:     General utilities
                 Timer_Set: Code timing utility

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        21-May-2016 1.0   Created
Brendan Furey        25-Jun-2016 1.1   Removed tt_Setup and ut_Teardown following removal of uPLSQL
Brendan Furey        09-Jul-2016 1.2   Passing new input arrays to Check_TT_Results for printing per
                                       scenario
Brendan Furey        22-Oct-2016 1.3   TRAPIT name changes, UT->TT etc.

***************************************************************************************************/
c_out_group_lis       CONSTANT L1_chr_arr := L1_chr_arr ('Select results');

/***************************************************************************************************

tt_HR_Test_View_V: TRAPIT procedure to test view HR_Test_View_V

***************************************************************************************************/
PROCEDURE tt_HR_Test_View_V IS

  c_view_name           CONSTANT VARCHAR2(61) := 'HR_Test_View_V';
  c_proc_name           CONSTANT VARCHAR2(61) := 'TT_View_Drivers.tt_' || c_view_name;
  c_dep_id_1            CONSTANT PLS_INTEGER := 10;
  c_dep_id_2            CONSTANT PLS_INTEGER := 20;
  c_dep_nm_1            CONSTANT VARCHAR2(100) := 'Administration';
  c_dep_nm_2            CONSTANT VARCHAR2(100) := 'Marketing';
  c_job_bad             CONSTANT VARCHAR2(100) := 'AD_ASST';
  c_job_good            CONSTANT VARCHAR2(100) := 'IT_PROG';
  c_base_sal            CONSTANT PLS_INTEGER := 1000;

  c_ln_pre              CONSTANT VARCHAR2(10) := DML_API_TT_HR.c_ln_pre;

  c_sel_lis             CONSTANT L1_chr_arr := L1_chr_arr ('last_name', 'department_name', 'manager', 'salary', 'sal_rat', 'sal_rat_g');
  c_where_lis           CONSTANT L1_chr_arr := L1_chr_arr (NULL, NULL, 'department_name=''Administration''', NULL);

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
                                       Utils.List_Delim (c_ln_pre || '2',   c_dep_nm_1, c_ln_pre || '1', '2000',  '1.33', '.67'),
                                       Utils.List_Delim (c_ln_pre || '5',   c_dep_nm_2, c_ln_pre || '1', '5000',  '1',    '1.67')
                                               ),
                                               L1_chr_arr (
                                       Utils.List_Delim (c_ln_pre || '1',   c_dep_nm_1, NULL,            '1000', '.67',   '.33'),
                                       Utils.List_Delim (c_ln_pre || '2',   c_dep_nm_1, c_ln_pre || '1', '2000',  '1.33', '.67')
                                               ),
                                               Utils_TT.c_empty_list
                        );

  c_scenario_ds_lis     CONSTANT L1_num_arr := L1_num_arr (1, 2, 2, 3);
  c_scenario_lis        CONSTANT L1_chr_arr := L1_chr_arr (
                               'DS-1, testing inner, outer joins, analytic over dep, and global ratios with 1 dep',
                               'DS-2, testing same as 1 but with extra emp in another dep',
                               'DS-2, passing ''WHERE dep=10''',
                               'DS-3, Salaries total 1500 (< threshold of 1600, so return nothing)');

  c_inp_group_lis       CONSTANT L1_chr_arr := L1_chr_arr ('Employee', 'Where');
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
                                                                'Where')
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
/***************************************************************************************************

Setup: Local procedure to create test records for a given scenario; rolled back after query executed

***************************************************************************************************/
  PROCEDURE Setup (p_call_ind           PLS_INTEGER,   -- scenario index
                   x_inp_lis        OUT L1_chr_arr) IS -- input list

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

  END Setup;

BEGIN

  l_timer_set := Utils_TT.Init (c_proc_name);
  l_act_2lis.EXTEND (c_exp_2lis.COUNT);
  l_inp_3lis.EXTEND (c_exp_2lis.COUNT);

  FOR i IN 1..c_exp_2lis.COUNT LOOP

    l_inp_3lis (i) := L2_chr_arr();
    l_inp_3lis (i).EXTEND(2);

    Setup (c_scenario_ds_lis (i), l_inp_3lis (i)(1));

    l_inp_3lis (i)(2) := L1_chr_arr (c_where_lis(i));
    Timer_Set.Increment_Time (l_timer_set, Utils_TT.c_setup_timer);
    l_act_2lis(i) := Utils_TT.Get_View (
                            p_view_name         => c_view_name,
                            p_sel_field_lis     => c_sel_lis,
                            p_where             => c_where_lis(i),
                            p_timer_set         => l_timer_set);

  END LOOP;

  Utils_TT.Check_TT_Results (c_proc_name, c_scenario_lis, l_inp_3lis, l_act_2lis, c_exp_2lis, l_timer_set, c_ms_limit,
                             c_inp_group_lis, c_inp_field_2lis, c_out_group_lis, c_out_field_2lis);

EXCEPTION

  WHEN OTHERS THEN
    Utils.Write_Other_Error;
    RAISE;

END tt_HR_Test_View_V;

END TT_View_Drivers;
/
