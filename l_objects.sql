DEFINE SCHEMA=&1
@initspool l_objects_&SCHEMA
/***************************************************************************************************
Name: l_objects.sql                    Author: Brendan Furey                       Date: 31-Dec-2025

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
| *l_objects.sql*           |  Lists recently created objects for a schema                         |
|---------------------------|----------------------------------------------------------------------|
|  install_trapit_tt.sql    |  Creates unit test components for testing the generic unit test API, |
|                           |  Trapit_Run.Run_A_Test                                               |
====================================================================================================

This file has the script to list recently created objects for a schema.

***************************************************************************************************/
COLUMN object_name FORMAT A30
PROMPT Objects in schema &SCHEMA created within last minute
SELECT object_type, object_name, status
  FROM user_objects
 WHERE last_ddl_time > SYSDATE - 1 / 24 / 60
ORDER BY 1, 2
/
@endspool
exit