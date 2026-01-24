@..\initspool install_trapit_tt
/***************************************************************************************************
Name: install_trapit_tt.sql            Author: Brendan Furey                       Date: 31-Dec-2025

Installation script in the 'Trapit - Oracle PL/SQL Unit Testing' module, which facilitates unit
testing in Oracle PL/SQL following 'The Math Function Unit Testing design pattern', as described
here: 

    https://brenpatf.github.io/2023/06/05/the-math-function-unit-testing-design-pattern.html

GitHub project for Oracle PL/SQL:

    https://github.com/BrenPatF/trapit_oracle_tester

====================================================================================================
|  Script                   |  Notes                                                               |
|==================================================================================================|
|  install_trapit.sql       |  Creates base components, including Trapit package, in lib schema    |
|---------------------------|----------------------------------------------------------------------|
|  grant_trapit_to_app.sql  |  Grants privileges on Trapit components from lib to app schema       |
|---------------------------|----------------------------------------------------------------------|
|  c_trapit_syns.sql        |  Creates synonyms for Trapit components in app schema to lib schema  |
|---------------------------|----------------------------------------------------------------------|
|  l_objects.sql            |  Lists recently created objects for a schema                         |
|---------------------------|----------------------------------------------------------------------|
| *install_trapit_tt.sql*   |  Creates unit test components for testing the generic unit test API, |
|                           |  Trapit_Run.Run_A_Test                                               |
====================================================================================================

This file has the install script for the lib schema for testing the generic unit test API, 
Trapit_Run.Run_A_Test.

Components created:

    Metadata      Description
    ============  ==================================================================================
    tt_units      Unit test metadata  for testing the generic unit test API, Trapit_Run.Run_A_Test 

    Packages      Description
    ============  ==================================================================================
    TT_Trapit     Unit test functions for testing the generic unit test API, Trapit_Run.Run_A_Test        

***************************************************************************************************/

PROMPT Create package TT_Trapit
@tt_trapit.pks
@tt_trapit.pkb

PROMPT Add the tt_units record, reading in JSON file from INPUT_DIR
DECLARE
BEGIN

  Trapit.Add_Ttu(
          p_unit_test_package_nm         => 'TT_TRAPIT',
          p_purely_wrap_api_function_nm  => 'PURELY_WRAP_OUTER', 
          p_group_nm                     => 'trapit',
          p_active_yn                    => 'Y', 
          p_input_file                   => 'tt_trapit.purely_wrap_outer_inp.json',
          p_title                        => 'Trapit Oracle Tester'
  );
END;
/
@..\endspool
exit