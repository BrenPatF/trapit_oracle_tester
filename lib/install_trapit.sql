WHENEVER SQLERROR CONTINUE
DEFINE app=&1
@..\initspool install_trapit
/***************************************************************************************************
Name: install_trapit.sql               Author: Brendan Furey                       Date: 19-May-2019

Installation script in the 'Trapit - Oracle PL/SQL Unit Testing' module, which facilitates unit
testing in Oracle PL/SQL following 'The Math Function Unit Testing design pattern', as described
here: 

    https://brenpatf.github.io/2023/06/05/the-math-function-unit-testing-design-pattern.html

GitHub project for Oracle PL/SQL:

    https://github.com/BrenPatF/trapit_oracle_tester

====================================================================================================
|  Script                   |  Notes                                                               |
|==================================================================================================|
| *install_trapit.sql*      |  Creates base components, including Trapit package, in lib schema    |
|---------------------------|----------------------------------------------------------------------|
|  grant_trapit_to_app.sql  |  Grants privileges on Trapit components from lib to app schema       |
|---------------------------|----------------------------------------------------------------------|
|  c_trapit_syns.sql        |  Creates synonyms for Trapit components in app schema to lib schema  |
|---------------------------|----------------------------------------------------------------------|
|  l_objects.sql            |  Lists recently created objects for a schema                         |
|---------------------------|----------------------------------------------------------------------|
|  install_trapit_tt.sql    |  Creates unit test components for testing the generic unit test API, |
|                           |  Trapit_Run.Run_A_Test                                               |
====================================================================================================

This file has the install script for the lib schema (base components).

Components created, with grants to app schema (if passed) via grant_trapit_to_app.sql:

    Types         Description
    ============  ==================================================================================
    L2_chr_arr    Generic array of L1_chr_arr
    L3_chr_arr    Generic array of L2_chr_arr
    L4_chr_arr    Generic array of L3_chr_arr

    Tables        Description
    ============  ==================================================================================
    tt_units      Stores unit test metadata, including input and output JSON CLOBs

    Packages      Description
    ============  ==================================================================================
    Trapit        Unit test utility functions and procedures
    Trapit_Run    Unit test driver package with Invoker rights

***************************************************************************************************/
PROMPT Drop table tt_units
DROP TABLE tt_units
/
PROMPT Common type creation
PROMPT ====================

DROP TYPE L4_chr_arr
/
DROP TYPE L3_chr_arr
/
PROMPT Create type L2_chr_arr
CREATE OR REPLACE TYPE L2_chr_arr IS VARRAY(32767) OF L1_chr_arr
/
PROMPT Create type L3_chr_arr
CREATE OR REPLACE TYPE L3_chr_arr IS VARRAY(32767) OF L2_chr_arr
/
PROMPT Create type L4_chr_arr
CREATE OR REPLACE TYPE L4_chr_arr IS VARRAY(32767) OF L3_chr_arr
/
PROMPT Table creation
PROMPT ==============

PROMPT Create table tt_units
PROMPT tt_units
CREATE TABLE tt_units (
    unit_test_package_nm         VARCHAR2(30) NOT NULL,
    purely_wrap_api_function_nm  VARCHAR2(30) NOT NULL,
    group_nm                     VARCHAR2(30),
    description                  VARCHAR2(500),
    title                        VARCHAR2(100),
    active_yn                    VARCHAR2(1),
    input_json                   CLOB,
    output_json                  CLOB,
    CONSTRAINT uni_pk            PRIMARY KEY (unit_test_package_nm, purely_wrap_api_function_nm),
    CONSTRAINT uni_js1           CHECK (input_json IS JSON),
    CONSTRAINT uni_js2           CHECK (output_json IS JSON))
/
COMMENT ON TABLE tt_units IS 'Unit test metadata'
/
CREATE OR REPLACE CONTEXT Trapit_Ctx USING Trapit
/
PROMPT Create package Trapit
@trapit.pks
@trapit.pkb
PROMPT Create package Trapit_Run
@trapit_run.pks
@trapit_run.pkb

PROMPT Grant access to &app (skip if none passed)
WHENEVER SQLERROR EXIT
EXEC IF '&app' = 'none' THEN RAISE_APPLICATION_ERROR(-20000, 'Skipping schema grants'); END IF;
@grant_trapit_to_app &app

@..\endspool
exit