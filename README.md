# db_unit_test
Unit test utility packages for Oracle plus demo base and test programs for Oracle's HR demo schema.

The test utility packages and types are designed as a lightweight PL/SQL-based framework for unit testing that can be considered as an alternative to utPLSQL.

This article provides example output and links to articles describing design patterns the framework is designed to facilitate, as well as anti-patterns it is designed to discourage:

Brendan's Database Unit Testing Framework
    http://aprogrammerwrites.eu/?p=1723

Pre-requisites
==============
In order to run the demo unit test suite, you must have installed Oracle's HR demo schema on your Oracle instance:

Oracle Database Sample Schemas
    https://docs.oracle.com/cd/E11882_01/server.112/e10831/installation.htm#COMSC001

There are no other dependencies outside this project.

Output logging
==============
The testing utility packages use my own simple logging framework, installed as part of the installation scripts. To replace this with your own preferred logging framework, simply edit the procedure Utils.Write_Log to output using your own logging procedure, and optionally drop the log_headers and log_lines tables, along with the three Utils.*_Log methods.

As far as I know the code should work on any recent-ish version - I have tested on 11.2 and 12.1. See these links for more information.<a href=</a>

Install steps
=============
 	Extract all the files into a directory
 	If a new schema for library utilities is required, then run Install_SYS.sql as a DBA passing schema name as parameter
 	Run Install_HR.sql from the HR schema passing library utilities schema name as parameter
 	Run Install_Bren.sql from the schema for the library utilities
 	Check log files for any errors

Running the demo test suite
===========================
Run R_Suite_br.sql from the schema for the library utilities in the installation directory.

Java driver
===========
I have included a java program that can be used to call the web service base procedure. This is not required for the Oracle code, but I thought it might make a useful template for JDBC integration testing:

A Template Script for JDBC Integration Testing of Oracle Procedures
    http://aprogrammerwrites.eu/?p=1676
