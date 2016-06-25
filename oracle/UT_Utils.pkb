CREATE OR REPLACE PACKAGE BODY UT_Utils AS
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
                                       Check_UT_Results: Renamed from WS; overloaded versions added
                                       Other re-factoring for formatting etc.
Brendan Furey        10-Jun-2016 1.2   Check_UT_Results: Handle missing records better
Brendan Furey        25-Jun-2016 1.3   Refactored the output formatting; removed utPLSQL calls and
                                       replaced Run_Suite with new version that loops over array
                                       making its own calls

***************************************************************************************************/
c_status_f              CONSTANT VARCHAR2(10) := 'F';
c_status_s              CONSTANT VARCHAR2(10) := 'S';
c_status_word_f         CONSTANT VARCHAR2(10) := 'FAILURE';
c_status_word_s         CONSTANT VARCHAR2(10) := 'SUCCESS';
c_null                  CONSTANT VARCHAR2(30) := 'NULL';
c_time_not_ok           CONSTANT VARCHAR2(60) := 'Average call time: #1, exceeds limit: #2';
c_ut_prefix             CONSTANT VARCHAR2(10) := 'UT_';
c_ut_suites_3lis        CONSTANT L3_chr_arr := L3_chr_arr (
                                    L2_chr_arr (L1_chr_arr ('UT_Emp_WS',           'ut_AIP_Save_Emps'),
                                                L1_chr_arr ('UT_View_Drivers',     'ut_HR_Test_View_V'))
                                 );
c_ut_suite_names_lis    CONSTANT L1_chr_arr := L1_chr_arr ('BRENDAN');

TYPE test_set_rec  IS RECORD (
        test_set_name   VARCHAR2(100),
        n_tests         PLS_INTEGER := 0,
        n_fails         PLS_INTEGER := 0,
        ela_secs        NUMBER := 0,
        cpu_secs        NUMBER := 0);
TYPE test_set_arr IS VARRAY(1000) OF test_set_rec;

g_test_set_lis          test_set_arr := test_set_arr();

g_now_date_threshold    DATE := SYSDATE - 0.01;
g_log_sequence_id       PLS_INTEGER;

/***************************************************************************************************

Write_Log: Local procedure calls utility logging procedure to write a line

***************************************************************************************************/
PROCEDURE Write_Log (p_line VARCHAR2) IS -- line to write
BEGIN
  Utils.Write_Log (p_line);
END Write_Log;

/***************************************************************************************************

Init: ut initialise for a procedure by constructing timer set, then calling local Init procedure,
      and returning the timer set id

***************************************************************************************************/
FUNCTION Init (p_proc_name      VARCHAR2)      -- calling procedure name
               RETURN           PLS_INTEGER IS -- timer set id

  l_timer_set   PLS_INTEGER := Timer_Set.Construct (p_proc_name);

BEGIN

  Utils.Heading ('UNIT TEST for ' || p_proc_name);
  RETURN l_timer_set;

END Init;

/***************************************************************************************************

Write_Suite_Results: Write out the results for a ut suite

***************************************************************************************************/
PROCEDURE Write_Suite_Results (p_suite VARCHAR2) IS -- ut suite name
  l_test_set_rec        test_set_rec;
  l_test_set_tot_rec    test_set_rec;
  l_test_name_lis       L1_chr_arr := L1_chr_arr ('Module');
  l_max_len             PLS_INTEGER;
  l_len_lis             L1_num_arr;
  l_suite_status        VARCHAR2(30) := c_status_word_s;

  /***************************************************************************************************

  Write_Test_Set: Write out the results for a ut suite, set of tests - summary line

  ***************************************************************************************************/
  PROCEDURE Write_Test_Set (p_test_set_rec test_set_rec) IS -- test set record
  BEGIN
    Utils.Pr_List_As_Line (L1_chr_arr (p_test_set_rec.test_set_name, p_test_set_rec.n_tests, p_test_set_rec.n_fails,
                                           To_Char (p_test_set_rec.ela_secs, '99,990.00'), To_Char (p_test_set_rec.cpu_secs, '99,990.00')),
                   l_len_lis);
  END Write_Test_Set;

BEGIN

  Utils.Heading ('Suite Summary');
  FOR i IN 1..g_test_set_lis.COUNT LOOP

    l_test_name_lis.EXTEND;
    l_test_name_lis(l_test_name_lis.COUNT) := g_test_set_lis(i).test_set_name;

  END LOOP;
  l_max_len := Utils.Max_Len (l_test_name_lis);
  l_len_lis := L1_num_arr (l_max_len, -5, -5, -10, -10);
  Utils.Col_Headers (L1_chr_arr ('Package.Procedure', 'Tests', 'Fails', 'ELA', 'CPU'),
               l_len_lis
              );

  FOR i IN 1..g_test_set_lis.COUNT LOOP

    l_test_set_rec := g_test_set_lis (i);
    Write_Test_Set (l_test_set_rec);

    l_test_set_tot_rec.n_tests := l_test_set_tot_rec.n_tests + l_test_set_rec.n_tests ;
    l_test_set_tot_rec.n_fails := l_test_set_tot_rec.n_fails + l_test_set_rec.n_fails ;
    l_test_set_tot_rec.ela_secs := l_test_set_tot_rec.ela_secs + l_test_set_rec.ela_secs ;
    l_test_set_tot_rec.cpu_secs := l_test_set_tot_rec.cpu_secs + l_test_set_rec.cpu_secs ;
    IF l_test_set_rec.n_fails > 0 THEN
      l_suite_status := c_status_word_f;
    END IF;

  END LOOP;
  l_test_set_tot_rec.test_set_name := 'Total';

  Utils.Reprint_Line;
  Write_Test_Set (l_test_set_tot_rec);
  Utils.Reprint_Line;

  IF l_suite_status = c_status_word_f THEN
    RAISE_APPLICATION_ERROR (-20001, 'Suite ' || p_suite || ' returned error status');
  END IF;

END Write_Suite_Results;

/***************************************************************************************************

Check_UT_Results: ut utility to check results from testing, L3_chr_arr version

***************************************************************************************************/
PROCEDURE Check_UT_Results (p_proc_name                 VARCHAR2,      -- calling procedure
                            p_test_lis                  L1_chr_arr,    -- test descriptions
                            p_act_3lis                  L3_chr_arr,    -- actual result strings
                            p_exp_3lis                  L3_chr_arr,    -- expected result strings
                            p_timer_set                 PLS_INTEGER,   -- timer set index
                            p_ms_limit                  PLS_INTEGER,   -- call time limit in ms
                            p_out_group_lis             L1_chr_arr,    -- output group names
                            p_fields_2lis               L2_chr_arr) IS -- test fields descriptions

  l_num_fails_sce                L1_num_arr :=  L1_num_arr();
  l_num_tests_sce                L1_num_arr :=  L1_num_arr();
  l_tot_fails                    PLS_INTEGER := 0;
  l_tot_tests                    PLS_INTEGER := 0;

  /***************************************************************************************************

  Write_Group: Writes the test results for a given scenario and output group in tabluar format within
               block header and trailer lines

  ***************************************************************************************************/
  PROCEDURE Write_Group (p_out_group            VARCHAR2,       -- output group name
                         p_fields_lis           L1_chr_arr,     -- column names array
                         p_act_lis              L1_chr_arr,     -- actual result strings for scenario/ group
                         p_exp_lis              L1_chr_arr,     -- expected result strings for scenario/ group
                         x_num_fails     IN OUT PLS_INTEGER,    -- total number of failed tests
                         x_num_tests     IN OUT PLS_INTEGER) IS -- total number of tests

    l_max_len                    PLS_INTEGER := Greatest (6, Utils.Max_Len (p_act_lis), Utils.Max_Len (p_exp_lis));
    l_res_2lis                   L2_chr_arr := L2_chr_arr();
    l_just_sign                  L1_num_arr := L1_num_arr(1);
    l_missing_rec                VARCHAR2(4000) := RegExp_Replace (Utils.List_Delim (p_fields_lis), '[^' || Utils.g_list_delimiter || ']', ''); --? use global delimiter
    l_num_fails                  PLS_INTEGER := 0;
    /***************************************************************************************************

    Set_Result_Row: Assign a first value scalar, then a list of values to a single row of the output
                    array

    ***************************************************************************************************/
    PROCEDURE Set_Result_Row (p_first_value         VARCHAR2,      -- first element in the results array record
                              p_value_lis           L1_chr_arr,    -- array for rest of the results record
                              x_res_lis         OUT L1_chr_arr) IS -- full results record array
      l_value   VARCHAR2(4000);
    BEGIN

      x_res_lis := L1_chr_arr();
      x_res_lis.EXTEND (1 + p_value_lis.COUNT);
      x_res_lis (1) := p_first_value;

      FOR i IN 1..p_value_lis.COUNT LOOP

        l_value := p_value_lis(i);
        x_res_lis(i+1) := l_value;

      END LOOP;

    END Set_Result_Row;

    /***************************************************************************************************

    Print_Group_Header: Prints the output group header allowing for case where the group has no body

    ***************************************************************************************************/
    FUNCTION Print_Group_Header (p_out_group            VARCHAR2,    -- output group name
                                 p_fields_lis           L1_chr_arr,  -- column names array
                                 p_act_count            PLS_INTEGER, -- number of actual strings
                                 p_exp_count            PLS_INTEGER, -- number of expected strings
                                 p_act_lis_1            VARCHAR2,    -- first element in the actuals array
                                 x_just_sign     IN OUT L1_num_arr,  -- column justification sign array
                                 x_res_lis          OUT L1_chr_arr)  -- first record of results array = headers
                                 RETURN BOOLEAN IS                   -- TRUE if there is a body for the group

      l_not_null_case   BOOLEAN := NOT (p_act_count = p_exp_count AND p_act_count = 1 AND p_act_lis_1 = c_empty_list(1)); --?
      l_group_header    VARCHAR2(300) := ': Actual = 0, Expected = 0: ' || c_status_word_s;
      l_value_lis       L1_chr_arr := p_fields_lis;

    BEGIN

      IF l_not_null_case THEN

        FOR i IN 1..l_value_lis.COUNT LOOP

          x_just_sign.EXTEND;
          x_just_sign(i+1) := 1;
          IF Substr (l_value_lis(i), 1, 1) = '*' THEN
            l_value_lis(i) := Substr (l_value_lis(i), 2);
            x_just_sign(i+1) := -1;
          END IF;

        END LOOP;
        Set_Result_Row ('F?', l_value_lis, x_res_lis);
        l_group_header := ': Actual = ' || p_act_count || ', Expected = ' || p_exp_count || ' {';

      END IF;

      Utils.Heading ('GROUP ' || p_out_group || l_group_header, 1);
      RETURN l_not_null_case;

    END Print_Group_Header;

    /***************************************************************************************************

    Set_Result_Array: Populates the results array for subsequent printing, using actual and expected
                      value input arrays for given scenario and output group

    ***************************************************************************************************/
    PROCEDURE Set_Result_Array (p_missing_rec          VARCHAR2,       -- string to print for a missing record
                                p_act_lis              L1_chr_arr,     -- actual value string array
                                p_exp_lis              L1_chr_arr,     -- expected value string array
                                x_res_2lis      IN OUT L2_chr_arr,     -- results array
                                x_num_fails     IN OUT PLS_INTEGER,    -- total number of failed tests
                                x_num_tests     IN OUT PLS_INTEGER) IS -- total number of tests

      l_row_ind                    PLS_INTEGER := 1;
      l_act                        VARCHAR2(4000);
      l_exp                        VARCHAR2(4000);
      l_value_lis                  L1_chr_arr;

      PROCEDURE Add_Result_Row (p_first_value VARCHAR2, p_value_lis L1_chr_arr, x_row_ind IN OUT PLS_INTEGER) IS
      BEGIN

        x_row_ind := x_row_ind + 1;
        x_res_2lis.EXTEND;
        Set_Result_Row (p_first_value, p_value_lis, x_res_2lis (x_row_ind));

      END Add_Result_Row;

    BEGIN

      FOR i IN 1..Greatest (p_act_lis.COUNT, p_exp_lis.COUNT) LOOP

        x_num_tests := x_num_tests + 1;
        l_act := p_missing_rec;
        l_exp := p_missing_rec;
        IF i <= p_act_lis.COUNT THEN
          l_act := p_act_lis(i);
       END IF;

        IF i <= p_exp_lis.COUNT THEN
          l_exp := p_exp_lis(i);
        END IF;

        l_value_lis := Utils.Row_To_List (l_act);

        IF l_act = l_exp THEN

          Add_Result_Row (' ', l_value_lis, l_row_ind);

        ELSE

          Add_Result_Row ('F', l_value_lis, l_row_ind);
          l_value_lis := Utils.Row_To_List (l_exp);
          Add_Result_Row ('>', l_value_lis, l_row_ind);
          x_num_fails := x_num_fails + 1;

        END IF;

      END LOOP;

    END Set_Result_Array;

    /***************************************************************************************************

    Print_Result_Array: Prints the result array

    ***************************************************************************************************/
    PROCEDURE Print_Result_Array (p_num_fails   PLS_INTEGER,   -- total number of failed tests
                                  p_just_sign   L1_num_arr,    -- column justification sign array
                                  p_res_2lis    L2_chr_arr) IS -- results array

      l_status                     VARCHAR2(100) := c_status_word_s;
      l_len_lis                    L1_num_arr := Utils.Max_Len_2lis (l_res_2lis);

    BEGIN

      FOR i IN 1..l_len_lis.COUNT LOOP
        l_len_lis(i) := p_just_sign(i) * l_len_lis(i);
      END LOOP;

      Utils.Col_Headers (l_res_2lis(1), l_len_lis, 2);
      FOR i IN 2..l_res_2lis.COUNT LOOP

        Utils.Pr_List_As_Line (l_res_2lis(i), l_len_lis, 2);

      END LOOP;

      IF p_num_fails > 0 THEN
        l_status := c_status_word_f;
      END IF;

      Utils.Heading ('} ' || p_num_fails || ' failed, of ' || (p_res_2lis.COUNT-1-p_num_fails) || ': ' || l_status, 1);

    END Print_Result_Array;

  BEGIN

    l_res_2lis.EXTEND;
    IF Print_Group_Header (p_out_group, p_fields_lis, p_act_lis.COUNT, p_exp_lis.COUNT, p_act_lis(1), l_just_sign, l_res_2lis(1)) THEN

      Set_Result_Array (l_missing_rec, p_act_lis, p_exp_lis, l_res_2lis, l_num_fails, x_num_tests);
      Print_Result_Array (l_num_fails, l_just_sign, l_res_2lis);
      x_num_fails := x_num_fails + l_num_fails;

    ELSE

        x_num_tests := x_num_tests + 1;

    END IF;

  END Write_Group;

  /***************************************************************************************************

  Detail_Section: Print the detailed test report returning scenario statistics for the summary

  ***************************************************************************************************/
  PROCEDURE Detail_Section  (x_num_fails_sce       IN OUT L1_num_arr,    -- number of failed tests by scenario
                             x_num_tests_sce       IN OUT L1_num_arr) IS -- total failed tests by scenario
  BEGIN

    x_num_fails_sce.EXTEND (p_act_3lis.COUNT);
    x_num_tests_sce.EXTEND (p_act_3lis.COUNT);

    FOR i IN 1..p_act_3lis.COUNT LOOP -- scenario/call loop

      Utils.Heading ('SCENARIO ' || i || ': ' || p_test_lis(i) || ' {');
      x_num_fails_sce(i) := 0;
      x_num_tests_sce(i) := 0;
      FOR j IN 1..p_act_3lis(i).COUNT LOOP -- group loop (group instance means table or array normally)

        Write_Group (p_out_group_lis(j), p_fields_2lis(j), p_act_3lis(i)(j), p_exp_3lis(i)(j), x_num_fails_sce(i), x_num_tests_sce(i));

      END LOOP;
      Utils.Heading ('} ' || x_num_fails_sce(i) || ' failed, of ' || x_num_tests_sce(i) || ': ' || CASE WHEN x_num_fails_sce(i) = 0 THEN c_status_word_s ELSE c_status_word_f END);

    END LOOP;

  END Detail_Section;

  /***************************************************************************************************

  Summary_Section: Print the summary test report using scenario statistics from the  detailed section

  ***************************************************************************************************/
  PROCEDURE Summary_Section (p_num_fails_sce        L1_num_arr,     -- number of failed tests by scenario
                             p_num_tests_sce        L1_num_arr,     -- total failed tests by scenario
                             x_tot_fails     IN OUT PLS_INTEGER,    -- total number of failed tests
                             x_tot_tests     IN OUT PLS_INTEGER) IS -- total number of tests

    l_tot_status                   VARCHAR2(10);
    l_timing_status                VARCHAR2(10);
    l_max_len_sce                  PLS_INTEGER := Utils.Max_Len (p_test_lis);
    l_ms                           PLS_INTEGER;
    l_timing_fail                  PLS_INTEGER;

  BEGIN

    l_ms := Timer_Set.Timer_Avg_Ela_MS (p_timer_set_ind => p_timer_set, p_timer_name => c_call_timer);
    l_timing_status := CASE WHEN l_ms <= p_ms_limit THEN c_status_word_s ELSE c_status_word_f END;
    Utils.Heading ('TIMING: Actual = ' || l_ms || ', Expected <= ' || p_ms_limit || ': ' || l_timing_status);
    l_timing_fail := CASE WHEN l_ms <= p_ms_limit THEN 0 ELSE 1 END;

    Utils.Heading ('SUMMARY for ' || p_proc_name);
    Utils.Col_Headers (L1_chr_arr ('Scenario', '# Failed', '# Tests', 'Status'), L1_num_arr (l_max_len_sce, -8, -7, 7));
    FOR i IN 1..p_act_3lis.COUNT LOOP

      Utils.Pr_List_As_Line (L1_chr_arr (p_test_lis(i), p_num_fails_sce(i), p_num_tests_sce(i), CASE WHEN p_num_fails_sce(i) = 0 THEN c_status_word_s ELSE c_status_word_f END),
                             L1_num_arr (l_max_len_sce, -8, -7, 7));
      x_tot_fails := x_tot_fails + p_num_fails_sce(i);
      x_tot_tests := x_tot_tests + p_num_tests_sce(i);

    END LOOP;

    x_tot_fails := x_tot_fails + l_timing_fail;
    Utils.Pr_List_As_Line (L1_chr_arr ('Timing', l_timing_fail, 1, l_timing_status),
                           L1_num_arr (l_max_len_sce, -8, -7, 7));
    Utils.Reprint_Line;
    l_tot_status := CASE WHEN x_tot_fails = 0 THEN c_status_word_s ELSE c_status_word_f END;
    Utils.Pr_List_As_Line (L1_chr_arr ('Total', x_tot_fails, (x_tot_tests+1), l_tot_status),
                           L1_num_arr (l_max_len_sce, -8, -7, 7));
    Utils.Reprint_Line;

  END Summary_Section;

  /***************************************************************************************************

  Set_Global_Summary: Assign statistics to a new record in the global suite array for printing at the
                      end

  ***************************************************************************************************/
  PROCEDURE Set_Global_Summary (p_tot_fails     PLS_INTEGER,    -- total number of failed tests
                                p_tot_tests     PLS_INTEGER) IS -- total number of tests

    l_timer_stat_rec               Timer_Set.timer_stat_rec;
    l_test_set_rec                 test_set_rec;

  BEGIN

    Timer_Set.Write_Times (p_timer_set);
    l_timer_stat_rec := Timer_Set.Get_Timer_Stats (p_timer_set_ind => p_timer_set);
    l_test_set_rec.test_set_name := p_proc_name;
    l_test_set_rec.n_tests := p_tot_tests;
    l_test_set_rec.n_fails := p_tot_fails;
    l_test_set_rec.ela_secs := l_timer_stat_rec.ela_secs;
    l_test_set_rec.cpu_secs := l_timer_stat_rec.cpu_secs;

    g_test_set_lis.EXTEND;
    g_test_set_lis (g_test_set_lis.COUNT) := l_test_set_rec;

  END Set_Global_Summary;

BEGIN

  Detail_Section (l_num_fails_sce, l_num_tests_sce);
  Summary_Section (l_num_fails_sce, l_num_tests_sce, l_tot_fails, l_tot_tests);
  Set_Global_Summary (l_tot_fails, l_tot_tests + 1);

END Check_UT_Results;

/***************************************************************************************************

Check_UT_Results: ut utility to check results from testing, L2_chr_arr version just calls L3_chr_arr
                  version

***************************************************************************************************/
PROCEDURE Check_UT_Results (p_proc_name                 VARCHAR2,      -- calling procedure
                            p_test_lis                  L1_chr_arr,    -- test descriptions
                            p_act_2lis                  L2_chr_arr,    -- actual result strings
                            p_exp_2lis                  L2_chr_arr,    -- expected result strings
                            p_timer_set                 PLS_INTEGER,   -- timer set index
                            p_ms_limit                  PLS_INTEGER,   -- call time limit in ms
                            p_out_group_lis             L1_chr_arr,    -- output group names
                            p_fields_2lis               L2_chr_arr) IS -- test fields descriptions

  l_act_3lis               L3_chr_arr := L3_chr_arr ();
  l_exp_3lis               L3_chr_arr := L3_chr_arr ();

BEGIN

  l_act_3lis.EXTEND (p_act_2lis.COUNT);
  l_exp_3lis.EXTEND (p_exp_2lis.COUNT);
  FOR i IN 1..p_act_2lis.COUNT LOOP

    l_act_3lis(i) := L2_chr_arr(NULL);
    l_act_3lis(i)(1) := p_act_2lis(i);
    l_exp_3lis(i) := L2_chr_arr(NULL);
    l_exp_3lis(i)(1) := p_exp_2lis(i);

  END LOOP;

  Check_UT_Results (        p_proc_name       => p_proc_name,
                            p_test_lis        => p_test_lis,
                            p_act_3lis        => l_act_3lis,
                            p_exp_3lis        => l_exp_3lis,
                            p_timer_set       => p_timer_set,
                            p_ms_limit        => p_ms_limit,
                            p_out_group_lis   => p_out_group_lis,
                            p_fields_2lis     => p_fields_2lis);

END Check_UT_Results;

/***************************************************************************************************

Check_UT_Results: ut utility to check results from testing, L1_chr_arr version just calls L3_chr_arr
                  version

***************************************************************************************************/
PROCEDURE Check_UT_Results (p_proc_name                 VARCHAR2,      -- calling procedure
                            p_test_lis                  L1_chr_arr,    -- test descriptions
                            p_act_lis                   L1_chr_arr,    -- actual result strings
                            p_exp_lis                   L1_chr_arr,    -- expected result strings
                            p_timer_set                 PLS_INTEGER,   -- timer set index
                            p_ms_limit                  PLS_INTEGER,   -- call time limit in ms
                            p_out_group_lis             L1_chr_arr,    -- output group names
                            p_fields_2lis               L2_chr_arr) IS -- test fields descriptions

  l_act_3lis               L3_chr_arr := L3_chr_arr (L2_chr_arr (p_act_lis));
  l_exp_3lis               L3_chr_arr := L3_chr_arr (L2_chr_arr (p_exp_lis));

BEGIN

  Check_UT_Results (        p_proc_name       => p_proc_name,
                            p_test_lis        => p_test_lis,
                            p_act_3lis        => l_act_3lis,
                            p_exp_3lis        => l_exp_3lis,
                            p_timer_set       => p_timer_set,
                            p_ms_limit        => p_ms_limit,
                            p_out_group_lis   => p_out_group_lis,
                            p_fields_2lis     => p_fields_2lis);

END Check_UT_Results;

/***************************************************************************************************

List_or_Empty: Takes a list and just returns it unless it's empty, when it returns a 1-record list
               with string EMPTY

***************************************************************************************************/
FUNCTION List_or_Empty (p_list          L1_chr_arr)   -- list of strings
                        RETURN          L1_chr_arr IS -- input list or 1-record EMPTY list
BEGIN
  IF p_list IS NULL THEN
    RETURN c_empty_list;
  ELSE
    IF p_list.COUNT = 0 THEN
      RETURN c_empty_list;
    ELSE
      RETURN p_list;
    END IF;
  END IF;
END List_or_Empty;

/***************************************************************************************************

Get_View: ut utility to run a query dynamically on a view and return result set as array of strings

***************************************************************************************************/
FUNCTION Get_View (p_view_name         VARCHAR2,               -- name of view
                   p_sel_field_lis     L1_chr_arr,             -- list of fields to select
                   p_where             VARCHAR2 DEFAULT NULL,  -- optional where clause
                   p_timer_set         PLS_INTEGER)            -- timer set handle
                   RETURN              L1_chr_arr IS           -- list of delimited result records

  l_cur            SYS_REFCURSOR;
  l_sql_txt        VARCHAR2(32767) := 'SELECT Utils.List_Delim (L1_chr_arr (';
  l_result_lis     L1_chr_arr;
  l_len            PLS_INTEGER;

BEGIN

  FOR i IN 1..p_sel_field_lis.COUNT LOOP

    l_sql_txt := l_sql_txt || p_sel_field_lis(i) || ',';

  END LOOP;

  l_sql_txt := RTrim (l_sql_txt, ',') || ')) FROM ' || p_view_name || ' WHERE ' || Nvl (p_where, '1=1 ') || 'ORDER BY 1';

  OPEN l_cur FOR l_sql_txt;

  FETCH l_cur BULK COLLECT -- ut, small result set, hence no need for limit clause
   INTO l_result_lis;

  CLOSE l_cur;

  Timer_Set.Increment_Time (p_timer_set, c_call_timer);
  ROLLBACK;
  RETURN List_or_Empty (l_result_lis);

END Get_View;

/***************************************************************************************************

Run_Suite: Run a ut suite

***************************************************************************************************/
PROCEDURE Run_Suite (p_suite_id PLS_INTEGER) IS -- suite id, must be one of the named constants in the spec

  PROCEDURE Run_UT_Package (p_package_lis L1_chr_arr) IS
  BEGIN

    FOR i IN 2..p_package_lis.COUNT LOOP

      EXECUTE IMMEDIATE 'BEGIN ' || p_package_lis(1) || '.' || p_package_lis(i) || '; END;';

    END LOOP;

  END Run_UT_Package;

BEGIN

  FOR i IN 1..c_ut_suites_3lis (p_suite_id).COUNT LOOP

    Run_UT_Package (c_ut_suites_3lis (p_suite_id)(i));

  END LOOP;
  Write_Suite_Results (c_ut_suite_names_lis (p_suite_id));

END Run_Suite;

BEGIN

  DBMS_Application_Info.Set_Client_Info (client_info => 'UT');
  Utils.c_session_id_if_UT := SYS_Context ('userenv', 'sessionid');

END UT_Utils;
/
SHO ERR
