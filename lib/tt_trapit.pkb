CREATE OR REPLACE PACKAGE BODY TT_Trapit AS
/***************************************************************************************************
Name: tt_trapit.pkb                    Author: Brendan Furey                       Date: 31-Dec-2025

Package body component in the 'Trapit - Oracle PL/SQL Unit Testing' module, which facilitates unit
testing in Oracle PL/SQL following 'The Math Function Unit Testing design pattern', as described
here: 

    https://brenpatf.github.io/2023/06/05/the-math-function-unit-testing-design-pattern.html

GitHub project for Oracle PL/SQL:

    https://github.com/BrenPatF/trapit_oracle_tester

At the heart of the design pattern there is a language-specific unit testing driver function. This
function reads an input JSON scenarios file, then loops over the scenarios making calls to a
function passed in as a parameter from the calling script. The passed function acts as a 'pure'
wrapper around calls to the unit under test. It is 'externally pure' in the sense that it is
deterministic, and interacts externally only via parameters and return value. Where the unit under
test reads inputs from file the wrapper writes them based on its parameters, and where the unit
under test writes outputs to file the wrapper reads them and passes them out in its return value.
Any file writing is reverted before exit.

The driver function accumulates the output scenarios containing both expected and actual results
in an object, from which a JavaScript function writes the results in HTML and text formats.

In testing of non-JavaScript programs, the results object is written to a JSON file to be passed
to the JavaScript formatter. In Oracle PL/SQL, a PowerShell utility is used to automate the running
of the PL/SQL function, Trapit_Run.Test_Output_Files to write the JSON files for a unit test group,
then call the JavaScript formatter, format-external-file.js. The Oracle implementation differs from
those for scripting languages in two other ways:

1. Dynamic SQL replaces the passing of a function as a parameter
2. A database table is used to store the function names by unit test group

====================================================================================================
|  Package     |  Notes                                                                            |
|==================================================================================================|
|  Trapit      |  Unit test utility package (Definer rights)                                       |
|--------------|-----------------------------------------------------------------------------------|
|  Trapit_Run  |  Unit test driver package (Invoker rights)                                        |
|--------------|-----------------------------------------------------------------------------------|
| *TT_Trapit*  |  Unit test package for testing the generic unit test API, Trapit_Run.Run_A_Test   |
====================================================================================================

This file has the package body for TT_Trapit, the unit test package for testing the generic unit 
test API, Trapit_Run.Run_A_Test. See README for API specification, and the other modules mentioned
there for examples of use

***************************************************************************************************/
UNIT_TEST_PACKAGE_NM          CONSTANT VARCHAR2(10) := 'TT_TRAPIT';
UNIT_TEST_FUNCTION_INN_NM     CONSTANT VARCHAR2(30) := 'PURELY_WRAP_INNER';
META                          CONSTANT VARCHAR2(10) := 'meta';
TITLE                         CONSTANT VARCHAR2(10) := 'title';
DELIMITER                     CONSTANT VARCHAR2(10) := 'delimiter';
SCENARIOS                     CONSTANT VARCHAR2(10) := 'scenarios';
INP                           CONSTANT VARCHAR2(3) := 'inp';
OUT                           CONSTANT VARCHAR2(3) := 'out';
EXP                           CONSTANT VARCHAR2(3) := 'exp';
ACT                           CONSTANT VARCHAR2(3) := 'act';
EXCEPTION_GROUP               CONSTANT VARCHAR2(30) := 'Unhandled Exception';
ACTIVE_YN                     CONSTANT VARCHAR2(10) := 'active_yn';
CAT_SET                       CONSTANT VARCHAR2(20) := 'category_set';
DELIM                         CONSTANT VARCHAR2(1) := '|';
g_out_group_lis               L1_chr_arr;
g_sce_inp_lis                 L1_chr_arr;
g_sce_inp_ind                 PLS_INTEGER;
g_act_value_3lis              L3_chr_arr;

/***************************************************************************************************

groups_List_From_GF: Returns a list of groups, given a flattened list containing a 2-element list
                     for each row:
                     1 = group; 2 = delimited values

***************************************************************************************************/
FUNCTION groups_List_From_GF(
            p_group_field_2lis             L2_chr_arr)   -- group/csv pairs list
            RETURN                         L1_chr_arr IS -- groups list
  l_last_group            VARCHAR2(100) := '*NULL*';
  l_group_lis             L1_chr_arr := L1_chr_arr();
BEGIN
--
-- loop over input array, on new group add previous group to list
--
  FOR i IN 1..p_group_field_2lis.COUNT LOOP

    IF p_group_field_2lis(i)(1) != l_last_group THEN
      IF i != 1 THEN
        l_group_lis.EXTEND;
        l_group_lis(l_group_lis.COUNT) := l_last_group;
      END IF;
      l_last_group := p_group_field_2lis(i)(1);
    END IF;

  END LOOP;
  l_group_lis.EXTEND;
  l_group_lis(l_group_lis.COUNT) := l_last_group;
  RETURN l_group_lis;

END groups_List_From_GF;

/***************************************************************************************************

groups_Obj_From_GF: Returns a JSON groups object, given a list of groups, and a flattened list
                    containing a 2-element list for each row:
                    1 = group; 2 = delimited values

***************************************************************************************************/
FUNCTION groups_Obj_From_GF(
            p_group_field_2lis             L2_chr_arr,      -- group/csv pairs list
            p_group_lis                    L1_chr_arr)      -- groups list
            RETURN                         JSON_Object_T IS -- JSON groups object
  l_groups_obj            JSON_Object_T := JSON_Object_T();
  l_group                 VARCHAR2(100);
  l_field_lis             JSON_Array_T;
BEGIN
--
-- loop over input array, on new group start array of fields
--
  FOR i IN 1..p_group_lis.COUNT LOOP

    l_group := p_group_lis(i);
    l_field_lis := JSON_Array_T();
    FOR j IN 1..p_group_field_2lis.COUNT LOOP
  
      IF p_group_field_2lis(j)(1) = l_group THEN
        l_field_lis.Append(p_group_field_2lis(j)(2));
      END IF;
  
    END LOOP;
    l_groups_obj.put(l_group, l_field_lis);

  END LOOP;
  RETURN l_groups_obj;

END groups_Obj_From_GF;

/***************************************************************************************************

groups_Obj_From_SGF: Returns a JSON groups object for a single scenario, given a list of groups,
                     and a flattened list containing a 3-element list for each row:
                     1 = scenario; 2 = group; 3 = delimited values

***************************************************************************************************/
FUNCTION groups_Obj_From_SGF(
            p_sce                          VARCHAR2,        -- scenario
            p_group_lis                    L1_chr_arr,      -- groups list
            p_sgf_2lis                     L2_chr_arr)      -- scenario/group/csv triples list
            RETURN                         JSON_Object_T IS -- JSON groups object
   l_gf_2lis               L2_chr_arr := L2_chr_arr();
BEGIN
--
-- loop over input group list, for each obtain the list of csv strings for that sce and group
--
  FOR i IN 1..p_sgf_2lis.COUNT LOOP

    IF p_sgf_2lis(i)(1) = p_sce THEN
      l_gf_2lis.EXTEND;
      l_gf_2lis(l_gf_2lis.COUNT) := L1_chr_arr(p_sgf_2lis(i)(2), p_sgf_2lis(i)(3));
    END IF;

  END LOOP;

  RETURN groups_Obj_From_GF(p_group_field_2lis  => l_gf_2lis,
                            p_group_lis         => p_group_lis);

END groups_Obj_From_SGF;

/***************************************************************************************************

write_Input_JSON: Writes input JSON object to tt_units table, based on input 3-level list
                  (scenario/group/record list)

***************************************************************************************************/
PROCEDURE write_Input_JSON(
            p_inp_3lis                     L3_chr_arr) IS -- input 3-level list
  l_json_obj              JSON_Object_T := JSON_Object_T();
  l_out_obj               JSON_Object_T := JSON_Object_T();
  l_met_obj               JSON_Object_T := JSON_Object_T();
  l_met_out_obj           JSON_Object_T := JSON_Object_T();
  l_sce_obj               JSON_Object_T := JSON_Object_T();
  l_sce_inp_obj           JSON_Object_T;
  l_sce_out_obj           JSON_Object_T;
  l_sce_act_obj           JSON_Object_T;
  l_scenarios_obj         JSON_Object_T := JSON_Object_T();
  l_group_keys            JSON_Key_List;
  l_rec_list              JSON_Array_T;
  l_ut_2lis               L2_chr_arr := p_inp_3lis(1);
  l_inp_group_field_2lis  L2_chr_arr := p_inp_3lis(2);
  l_out_group_field_2lis  L2_chr_arr := p_inp_3lis(3);
  l_sce_2lis              L2_chr_arr := p_inp_3lis(4);
  l_inp_2lis              L2_chr_arr := p_inp_3lis(5);
  l_exp_2lis              L2_chr_arr := p_inp_3lis(6);
  l_act_2lis              L2_chr_arr := p_inp_3lis(7);
  l_inp_group_lis         L1_chr_arr;
  l_act_group             L2_chr_arr;
  l_act_value_lis         L1_chr_arr;
  l_sce                   VARCHAR2(4000);
  l_active_yn             VARCHAR2(1);
  l_cat_set               VARCHAR2(4000);
  l_exception_yn          VARCHAR2(1);
  l_inp_clob              CLOB;
  l_i_act                 PLS_INTEGER := 0;
BEGIN
  l_inp_group_lis := groups_List_From_GF(p_group_field_2lis => l_inp_group_field_2lis);
  g_out_group_lis := groups_List_From_GF(p_group_field_2lis => l_out_group_field_2lis);

  l_met_obj.put(TITLE, l_ut_2lis(1)(1));
  l_met_obj.put(DELIMITER, l_ut_2lis(1)(2));
  l_met_obj.put(INP, groups_Obj_From_GF(l_inp_group_field_2lis, l_inp_group_lis));
  l_met_obj.put(OUT, groups_Obj_From_GF(l_out_group_field_2lis, g_out_group_lis));
  g_sce_inp_lis := L1_chr_arr();
  l_json_obj.put(META, l_met_obj);
  g_act_value_3lis := L3_chr_arr();
  FOR i IN 1..l_sce_2lis.COUNT LOOP

    l_sce          := l_sce_2lis(i)(1);
    l_active_yn    := l_sce_2lis(i)(2); 
    l_cat_set      := l_sce_2lis(i)(3); 
    l_exception_yn := l_sce_2lis(i)(4); 
    IF l_active_yn = 'Y' THEN
       l_i_act := l_i_act + 1;
       g_sce_inp_lis.EXTEND;
       g_sce_inp_lis(g_sce_inp_lis.COUNT) := l_exception_yn;
    END IF;
    l_sce_inp_obj := groups_Obj_From_SGF(l_sce, l_inp_group_lis, l_inp_2lis);
    l_sce_out_obj := groups_Obj_From_SGF(l_sce, g_out_group_lis, l_exp_2lis);
    l_sce_act_obj := groups_Obj_From_SGF(l_sce, g_out_group_lis, l_act_2lis);

    l_act_group := L2_chr_arr();
    l_act_group.EXTEND(g_out_group_lis.COUNT);
    FOR j IN 1..g_out_group_lis.COUNT LOOP

      l_rec_list := l_sce_act_obj.get_Array(g_out_group_lis(j));
      l_act_value_lis := L1_chr_arr();
      l_act_value_lis.EXTEND(l_rec_list.get_Size);
  
      FOR k IN 0..l_rec_list.get_Size-1 LOOP
        l_act_value_lis(k + 1) := l_rec_list.get_String(k);
      END LOOP;
      l_act_group(j) := l_act_value_lis;
    END LOOP;
    IF l_active_yn = 'Y' THEN
      g_act_value_3lis.EXTEND;
      g_act_value_3lis(l_i_act) := l_act_group;
    END IF;

    l_sce_obj.put(ACTIVE_YN, l_active_yn);
    l_sce_obj.put(CAT_SET, l_cat_set);
    l_sce_obj.put(INP, l_sce_inp_obj);
    l_sce_obj.put(OUT, l_sce_out_obj);
    l_scenarios_obj.put(l_sce, l_sce_obj);

  END LOOP;
  l_json_obj.put(SCENARIOS, l_scenarios_obj);
  l_inp_clob := l_json_obj.to_clob();

  INSERT INTO tt_units (
      unit_test_package_nm,
      purely_wrap_api_function_nm,
      input_json
  ) VALUES (
      UNIT_TEST_PACKAGE_NM,
      UNIT_TEST_FUNCTION_INN_NM,
      l_inp_clob
  );

END write_Input_JSON;

/***************************************************************************************************

get_JSON_Obj: Gets output JSON object from tt_units table

***************************************************************************************************/
FUNCTION get_JSON_Obj
            RETURN                         JSON_Object_T IS -- JSON object
  l_output_json           CLOB;
  l_json_elt              JSON_Element_T;
  l_json_obj              JSON_Object_T;
BEGIN

  SELECT output_json
    INTO l_output_json
    FROM tt_units
   WHERE unit_test_package_nm        = UNIT_TEST_PACKAGE_NM
     AND purely_wrap_api_function_nm = UNIT_TEST_FUNCTION_INN_NM;

  l_json_elt := JSON_Element_T.parse(l_output_json);
  IF NOT l_json_elt.is_Object THEN
    Utils.Raise_Error('Invalid JSON');
  END IF;

  RETURN treat(l_json_elt AS JSON_Object_T);

END get_JSON_Obj;

/***************************************************************************************************

JSON_Array_To_List: Converts a JSON array to a list with prefix applied

***************************************************************************************************/
PROCEDURE JSON_Array_To_List(
            p_prefix                       VARCHAR2,      -- prefix
            p_json_array                   JSON_Array_T,  -- JSON array
            x_fld_ind               IN OUT PLS_INTEGER,   -- field index
            x_value_lis             IN OUT L1_chr_arr) IS -- list of values
BEGIN
  x_value_lis.EXTEND(p_json_array.get_Size);
  FOR k IN 0..p_json_array.get_Size-1 LOOP
    x_fld_ind := x_fld_ind + 1;
    x_value_lis(x_fld_ind) := p_prefix || p_json_array.get_String(k);
  END LOOP;
END JSON_Array_To_List;

/***************************************************************************************************

met_List: Creates a metadata list of input or output fields based on input JSON object

***************************************************************************************************/
FUNCTION met_List(
            p_obj                          JSON_Object_T) -- JSON object
            RETURN                         L1_chr_arr IS  -- list of input or output fields
  l_field_lis             L1_chr_arr := L1_chr_arr();
  l_fld_ind               PLS_INTEGER := 0;
  l_keys                  JSON_Key_List;
  l_group                 VARCHAR2(100);
BEGIN
  l_keys := p_obj.get_Keys;
  FOR i IN 1..l_keys.COUNT LOOP

    l_group := l_keys(i);
    JSON_Array_To_List(p_prefix     => l_group || DELIM,
                       p_json_array => p_obj.get_Array(l_group),
                       x_fld_ind    => l_fld_ind,
                       x_value_lis  => l_field_lis);
  END LOOP;
  RETURN l_field_lis;

END met_List;

/***************************************************************************************************

get_Actuals: Returns actuals as 2-level list of lists (group/record list), based on output JSON 
             object in tt_units table

***************************************************************************************************/
FUNCTION get_Actuals
            RETURN                         L2_chr_arr IS -- actuals as 2-level list of lists
  l_json_obj              JSON_Object_T;
  l_inp_obj               JSON_Object_T;
  l_out_obj               JSON_Object_T;
  l_met_obj               JSON_Object_T;
  l_met_out_obj           JSON_Object_T;
  l_sce_obj               JSON_Object_T;
  l_scenarios_obj         JSON_Object_T;
  l_sce_inp_obj           JSON_Object_T;
  l_sce_out_obj           JSON_Object_T;
  l_keys                  JSON_Key_List;
  l_group_keys            JSON_Key_List;
  l_rec_list              JSON_Array_T;
  l_unit_test_lis         L1_chr_arr;
  l_inp_field_lis         L1_chr_arr;
  l_out_field_lis         L1_chr_arr;
  l_out_sce_lis           L1_chr_arr := L1_chr_arr();
  l_inp_value_lis         L1_chr_arr := L1_chr_arr();
  l_exp_value_lis         L1_chr_arr := L1_chr_arr();
  l_act_value_lis         L1_chr_arr := L1_chr_arr();
  l_group                 VARCHAR2(100);
  l_sce                   VARCHAR2(100);
  l_fld_ind               PLS_INTEGER;
  l_fld_exp_ind           PLS_INTEGER;
  l_fld_act_ind           PLS_INTEGER;

BEGIN
  l_json_obj := get_JSON_Obj;
  l_met_obj := l_json_obj.get_Object(META);
  l_unit_test_lis := L1_chr_arr(l_met_obj.get_String(TITLE) || DELIM || l_met_obj.get_String(DELIMITER));
  l_inp_obj := l_met_obj.get_Object(INP);
  l_out_obj := l_met_obj.get_Object(OUT);

  l_inp_field_lis := met_List(l_inp_obj);
  l_out_field_lis := met_List(l_out_obj);

  l_scenarios_obj := l_json_obj.get_Object(SCENARIOS);
  l_keys := l_scenarios_obj.get_Keys;
  l_out_sce_lis.EXTEND(l_keys.COUNT);
  l_fld_ind := 0;
  l_fld_exp_ind := 0;
  l_fld_act_ind := 0;
  FOR i IN 1..l_keys.COUNT LOOP

    l_sce := l_keys(i);
    l_sce_obj := l_scenarios_obj.get_Object(l_sce);
    l_out_sce_lis(i) := l_sce || DELIM || l_sce_obj.get_String(CAT_SET);
    l_inp_obj := l_sce_obj.get_Object(INP);-- need to get current sce
    l_group_keys := l_inp_obj.get_Keys;
    FOR j IN 1..l_group_keys.COUNT LOOP

      l_group := l_group_keys(j);
      JSON_Array_To_List(p_prefix     => l_sce || DELIM || l_group || DELIM,
                         p_json_array => l_inp_obj.get_Array(l_group),
                         x_fld_ind    => l_fld_ind,
                         x_value_lis  => l_inp_value_lis);
    END LOOP;

    l_out_obj := l_sce_obj.get_Object(OUT);
    l_group_keys := l_out_obj.get_Keys;
    FOR j IN 1..l_group_keys.COUNT LOOP
  
      l_group := l_group_keys(j);
      JSON_Array_To_List(p_prefix     => l_sce || DELIM || l_group || DELIM,
                         p_json_array => l_out_obj.get_Object(l_group).get_Array(EXP),
                         x_fld_ind    => l_fld_exp_ind,
                         x_value_lis  => l_exp_value_lis);

      JSON_Array_To_List(p_prefix     => l_sce || DELIM || l_group || DELIM,
                         p_json_array => l_out_obj.get_Object(l_group).get_Array(ACT),
                         x_fld_ind    => l_fld_act_ind,
                         x_value_lis  => l_act_value_lis);
    END LOOP;

  END LOOP;

  RETURN L2_chr_arr(
            l_unit_test_lis,
            l_inp_field_lis,
            l_out_field_lis,
            l_out_sce_lis,
            l_inp_value_lis,
            l_exp_value_lis,
            l_act_value_lis
  );

END get_Actuals;

/***************************************************************************************************

Purely_Wrap_Inner: Unit test wrapper function at inner level

    Returns the 'actual' outputs, given the inputs for a scenario, with the signature expected for
    the Math Function Unit Testing design pattern, namely:

      Input parameter: 3-level list (type L3_chr_arr) with test inputs as group/record/field
      Return Value: 2-level list (type L2_chr_arr) with test outputs as group/record (with record as
                   delimited fields string)

    In the special case where the unit testing framework is used to test its own main API, this 
    inner wrapper function ignores the input parameter, and returns actual values based on the outer
    level input data for the current scenario, using globals stored by the outer level function

***************************************************************************************************/
FUNCTION Purely_Wrap_Inner(
            p_inp_3lis                     L3_chr_arr)   -- inputs as 3-level list of lists
            RETURN                         L2_chr_arr IS -- actuals as 2-level list of lists
BEGIN
  g_sce_inp_ind := g_sce_inp_ind + 1;
  IF g_sce_inp_lis(g_sce_inp_ind) = 'Y' THEN
    Utils.Raise_Error('Exception thrown');
  END IF;
  RETURN g_act_value_3lis(g_sce_inp_ind);

END Purely_Wrap_Inner;

/***************************************************************************************************

Purely_Wrap_Outer: Unit test wrapper function at outer level

    Returns the 'actual' outputs, given the inputs for a scenario, with the signature expected for
    the Math Function Unit Testing design pattern, namely:

      Input parameter: 3-level list (type L3_chr_arr) with test inputs as group/record/field
      Return Value: 2-level list (type L2_chr_arr) with test outputs as group/record (with record as
                   delimited fields string)

    In the special case where the unit testing framework is used to test its own main API, the inner
    wrapper function ignores the input parameter, and returns actual values based on the outer level
    input data for the current scenario, using globals stored by this outer level function

***************************************************************************************************/
FUNCTION Purely_Wrap_Outer(
            p_inp_3lis                     L3_chr_arr)   -- inputs as 3-level list of lists
            RETURN                         L2_chr_arr IS -- actuals as 2-level list of lists
  l_act_2lis        L2_chr_arr := L2_chr_arr();
BEGIN

  g_sce_inp_ind := 0;
  write_Input_JSON(p_inp_3lis => p_inp_3lis);
  Trapit_Run.Run_A_Test(p_package_function => UNIT_TEST_PACKAGE_NM || '.' || UNIT_TEST_FUNCTION_INN_NM,
                        p_title            => 'Inner Unit Test');
  l_act_2lis := get_Actuals;
  ROLLBACK;
  RETURN l_act_2lis;

END Purely_Wrap_Outer;

END TT_Trapit;
/
SHO ERR 