# trapit_oracle_tester
TRansactional API Test (TRAPIT) utility packages for Oracle plus demo base and test programs for Oracle's HR demo schema.

The test utility packages and types are designed as a lightweight PL/SQL-based framework for API testing that can be considered as an alternative to utPLSQL.

This article provides example output and links to articles describing design patterns the framework is designed to facilitate, as well as anti-patterns it is designed to discourage:

<a href="http://aprogrammerwrites.eu/?p=1723" target="_blank">TRAPIT - TRansactional API Testing in Oracle</a>
    

Pre-requisites
==============
In order to run the demo unit test suite, you must have installed Oracle's HR demo schema on your Oracle instance:

<a href="https://docs.oracle.com/cd/E11882_01/server.112/e10831/installation.htm#COMSC001" target="_blank">Oracle Database Sample Schemas</a>
    
There are no other dependencies outside this project.

Output logging
==============
The testing utility packages use my own simple logging framework, installed as part of the installation scripts. To replace this with your own preferred logging framework, simply edit the procedure Utils.Write_Log to output using your own logging procedure, and optionally drop the log_headers and log_lines tables, along with the three Utils.*_Log methods.

As far as I know the code should work on any recent-ish version - I have tested on 11.2 and 12.1.

Install steps
=============
 	Extract all the files into a directory
        Update Install_SYS.sql to ensure Oracle directory points to a writable directory on the database sever (in repo now is set to 'C:\input')
 	Run Install_SYS.sql as a DBA passing new library schema name as parameter (eg @Install_SYS trapit)
 	Run Install_HR.sql from the HR schema passing library utilities schema name as parameter  (eg @Install_HR trapit)
 	Run Install_Bren.sql from the schema for the library utilities (@Install_Bren)
 	Check log files for any errors

Running the demo test suite
===========================
Run R_Suite_br.sql from the schema for the library utilities in the installation directory.

Java driver
===========
I have included a java program that can be used to call the web service base procedure. This is not required for the Oracle code, but I thought it might make a useful template for JDBC integration testing:

<a href="http://aprogrammerwrites.eu/?p=1676" target="_blank">A Template Script for JDBC Integration Testing of Oracle Procedures</a>