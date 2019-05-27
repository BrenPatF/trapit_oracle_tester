@..\initspool install_trapit
/***************************************************************************************************
Name: install_trapit.sql               Author: Brendan Furey                       Date: 19-May-2019

Installation script for the unit test utility components in the trapit_oracle_tester module. It 
requires a minimum Oracle database version of 12.2, owing to the use of v12.2 PL/SQL JSON features.

This module facilitates unit testing following 'The Math Function Unit Testing design pattern'.

    GitHub: https://github.com/BrenPatF/trapit_oracle_tester

Pre-requisite: Installation of the oracle_plsql_utils module (base install):

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

The lib schema refers to the schema in which oracle_plsql_utils was installed.
====================================================================================================
|  Script              |  Notes                                                                    |
|===================================================================================================
| *install_trapit.sql* |  Creates base components, including Trapit package, in lib schema         |
====================================================================================================

This file has the install script for the lib schema.

Components created, with NO synonyms or grants - only accessible within lib schema:

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
    package_nm                   VARCHAR2(30) NOT NULL,
    procedure_nm                 VARCHAR2(30) NOT NULL,
    description                  VARCHAR2(500),
    active_yn                    VARCHAR2(1),
    input_json                   CLOB,
    output_json                  CLOB,
    CONSTRAINT uni_pk            PRIMARY KEY (package_nm, procedure_nm),
    CONSTRAINT uni_js1           CHECK (input_json IS JSON),
    CONSTRAINT uni_js2           CHECK (output_json IS JSON))
/
COMMENT ON TABLE tt_units IS 'Unit test metadata'
/
PROMPT Create package Trapit
@trapit.pks
@trapit.pkb
@..\endspool