DEFINE app=&1
/***************************************************************************************************
Name: grant_trapit_to_app.sql          Author: Brendan Furey                       Date: 08-Jun-2019

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
| *grant_trapit_to_app.sql* |  Grants privileges on Trapit components from lib to app schema       |
|---------------------------|----------------------------------------------------------------------|
|  c_trapit_syns.sql        |  Creates synonyms for Trapit components in app schema to lib schema  |
|---------------------------|----------------------------------------------------------------------|
|  l_objects.sql            |  Lists recently created objects for a schema                         |
|---------------------------|----------------------------------------------------------------------|
|  install_trapit_tt.sql    |  Creates unit test components for testing the generic unit test API, |
|                           |  Trapit_Run.Run_A_Test                                               |
====================================================================================================

This file grants privileges on Trapit components from lib to app schema.

Grants applied:

    Privilege           Object                   Object Type
    ==================  =======================  ===================================================
    Execute             L2_chr_arr               Array (VARRAY)
    Execute             L3_chr_arr               Array (VARRAY)
    Execute             L4_chr_arr               Array (VARRAY)
    Execute             Trapit                   Package
    Execute             Trapit_Run               Package

***************************************************************************************************/
PROMPT Granting Trapit components to &app...
GRANT EXECUTE ON L2_chr_arr TO &app
/
GRANT EXECUTE ON L3_chr_arr TO &app
/
GRANT EXECUTE ON L4_chr_arr TO &app
/
GRANT EXECUTE ON Trapit TO &app
/
GRANT EXECUTE ON Trapit_Run TO &app
/
