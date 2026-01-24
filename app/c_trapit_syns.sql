DEFINE lib=&1
/***************************************************************************************************
Name: c_trapit_syns.sql                Author: Brendan Furey                       Date: 08-Jun-2019

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
| *c_trapit_syns.sql*       |  Creates synonyms for Trapit components in app schema to lib schema  |
|---------------------------|----------------------------------------------------------------------|
|  l_objects.sql            |  Lists recently created objects for a schema                         |
|---------------------------|----------------------------------------------------------------------|
|  install_trapit_tt.sql    |  Creates unit test components for testing the generic unit test API, |
|                           |  Trapit_Run.Run_A_Test                                               |
====================================================================================================

Creates synonyms for Trapit components in app schema to lib schema.

Synonyms created:

    Synonym             Object Type
    ==================  ============================================================================
    L2_chr_arr          Array (VARRAY)
    L3_chr_arr          Array (VARRAY)
    L4_chr_arr          Array (VARRAY)
    Trapit              Package
    Trapit_Run          Package

***************************************************************************************************/
PROMPT Creating synonyms for &lib Trapit components...
CREATE OR REPLACE SYNONYM L2_chr_arr FOR &lib..L2_chr_arr
/
CREATE OR REPLACE SYNONYM L3_chr_arr FOR &lib..L3_chr_arr
/
CREATE OR REPLACE SYNONYM L4_chr_arr FOR &lib..L4_chr_arr
/
CREATE OR REPLACE SYNONYM Trapit FOR &lib..Trapit
/
CREATE OR REPLACE SYNONYM Trapit_Run FOR &lib..Trapit_Run
/
exit