# Trapit
<img src="mountains.png">
Oracle PL/SQL unit testing module.

:detective:

TRansactional API Testing (TRAPIT) framework for Oracle PL/SQL unit testing.

This is a lightweight PL/SQL-based framework for API testing that can be considered as an alternative to utPLSQL. The framework is based on the idea that all API testing programs can follow a universal design pattern for testing APIs, using the concept of a ‘pure’ function as a wrapper to manage the ‘impurity’ inherent in database APIs. In this approach, a 'pure' wrapper function is constructed that takes input parameters and returns a value, and is tested within a loop over scenario records read from a JSON file. I explained the concepts involved in a presentation at the Oracle User Group Ireland Conference in March 2018:

- [The Database API Viewed As A Mathematical Function: Insights into Testing](https://www.slideshare.net/brendanfurey7/database-api-viewed-as-a-mathematical-function-insights-into-testing)

I later named the approach 'The Math Function Unit Testing design pattern':
- [The Math Function Unit Testing design pattern, implemented in nodejs](https://github.com/BrenPatF/trapit_nodejs_tester)

This module is a pre-requisite for the unit testing parts of these other Oracle GitHub modules:
- [Utils - Oracle PL/SQL general utilities module](https://github.com/BrenPatF/oracle_plsql_utils)
- [Log_Set - Oracle logging module](https://github.com/BrenPatF/log_set_oracle)
- [Timer_Set - Oracle PL/SQL code timing module](https://github.com/BrenPatF/timer_set_oracle)
- [Net_Pipe - Oracle PL/SQL network analysis module](https://github.com/BrenPatF/plsql_network)

Examples of its use in testing four demo PL/SQL APIs can be seen here:
- [Oracle PL/SQL API Demos - demonstrating instrumentation and logging, code timing and unit testing of Oracle PL/SQL APIs](https://github.com/BrenPatF/oracle_plsql_api_demos)

## In this README...
- [Usage](https://github.com/BrenPatF/trapit_oracle_tester#usage)
- [API - Trapit](https://github.com/BrenPatF/trapit_oracle_tester#api---trapit)
- [API - Trapit_Run](https://github.com/BrenPatF/trapit_oracle_tester#api---trapit_run)
- [Installation](https://github.com/BrenPatF/trapit_oracle_tester#installation)
- [Operating System/Oracle Versions](https://github.com/BrenPatF/trapit_oracle_tester#operating-systemoracle-versions)

## Usage
- [In this README...](https://github.com/BrenPatF/trapit_oracle_tester#in-this-readme)

In order to use the framework for unit testing, the following preliminary steps are required: 
* A JSON file is created containing the input test data including expected return values in the required format. The input JSON file essentially consists of two objects: 
  * `meta`: inp and out objects each containing group objects with arrays of field names
  * `scenarios`: scenario objects containing inp and out objects, with inp and out objects containing, for each group defined in meta, an array of input records and an array of expected output records, respectively, records being in delimited fields format
* A unit test PL/SQL program is created as a public procedure in a package (see example below). The program calls:
  * Trapit.Get_Inputs to get the JSON data and translate into PL/SQL arrays
  * Trapit.Set_Outputs to convert actual results in PL/SQL arrays into JSON, and write the output JSON file
* A record is inserted into the tt_units table using the Trapit.Add_Ttu procedure, passing names of package, procedure, JSON file (which should be placed in an Oracle directory, INPUT_DIR) and an active Y/N flag

Once the preliminary steps are executed, the following steps run the unit test program: 
* The procedure Trapit.Run_Tests is called to run active test programs, writing JSON output files both to the tt_units table and to the Oracle directory, INPUT_DIR
* Open a DOS or Powershell window in the trapit npm package folder (`see Install 3: Install npm trapit package below`) after placing the output JSON file in the subfolder ./examples/externals and run:
```
$ node ./examples/externals/test-externals
```
The nodejs program produces listings of the results in HTML and/or text format. The unit test steps can easily be automated in Powershell (or in a Unix script).

### Example test program main procedure from Utils module
```
PROCEDURE Test_API IS

  PROC_NM                        CONSTANT VARCHAR2(30) := 'Test_API';
  l_act_3lis                     L3_chr_arr := L3_chr_arr();
  l_sces_4lis                    L4_chr_arr;
  l_scenarios                    Trapit.scenarios_rec;
  l_delim                        VARCHAR2(10);
BEGIN

  l_scenarios := Trapit.Get_Inputs(p_package_nm  => $$PLSQL_UNIT,
                                   p_procedure_nm => PROC_NM);
  l_sces_4lis := l_scenarios.scenarios_4lis;
  l_delim := l_scenarios.delim;
  l_act_3lis.EXTEND(l_sces_4lis.COUNT);
  FOR i IN 1..l_sces_4lis.COUNT LOOP
    l_act_3lis(i) := purely_Wrap_API(p_delim    => l_delim,
                                     p_inp_3lis => l_sces_4lis(i));
  END LOOP;

  Trapit.Set_Outputs(p_package_nm   => $$PLSQL_UNIT,
                     p_procedure_nm => PROC_NM,
                     p_act_3lis     => l_act_3lis);
END Test_API;
```

There is also a separate [module](https://github.com/BrenPatF/oracle_plsql_api_demos) demonstrating instrumentation and logging, code timing and unit testing of Oracle PL/SQL APIs.

## API - Trapit
- [In this README...](https://github.com/BrenPatF/trapit_oracle_tester#in-this-readme)
- [Get_Inputs(p_package_nm, p_procedure_nm)](https://github.com/BrenPatF/trapit_oracle_tester#l_scenarios-trapitscenarios_rec--trapitget_inputsp_package_nm-p_procedure_nm)
- [Set_Outputs(p_package_nm, p_procedure_nm, p_act_3lis)](https://github.com/BrenPatF/trapit_oracle_tester#trapitset_outputsp_package_nm-p_procedure_nm-p_act_3lis)
- [Add_Ttu(p_package_nm, p_procedure_nm, p_group_nm, p_active_yn, p_input_file)](https://github.com/BrenPatF/trapit_oracle_tester#trapitadd_ttup_package_nm-p_procedure_nm-p_group_nm-p_active_yn-p_input_file)
### l_scenarios Trapit.scenarios_rec := Trapit.Get_Inputs(p_package_nm, p_procedure_nm)
- [API - Trapit](https://github.com/BrenPatF/trapit_oracle_tester#api---trapit)

Returns a record containing a delimiter and 4-level list of scenario metadata for testing the given package procedure, with parameters as follows:

* `p_package_nm`: package name
* `p_procedure_nm`: procedure name

Return Value
* `scenarios_rec`: record type with two fields:
  * `delim`: record delimiter
  * `scenarios_4lis`: 4-level list of scenario input values - (scenario, group, record, field)

### Trapit.Set_Outputs(p_package_nm, p_procedure_nm, p_act_3lis)
- [API - Trapit](https://github.com/BrenPatF/trapit_oracle_tester#api---trapit)

Adds the actual results data into the JSON input object for testing the given package procedure and writes it to file, and to a column in tt_units table, with parameters as follows:

* `p_package_nm`: package name
* `p_procedure_nm`: procedure name
* `p_act_3lis`: 3-level list of actual values as delimited records, by scenario and group

### Trapit.Add_Ttu(p_package_nm, p_procedure_nm, p_group_nm, p_active_yn, p_input_file)
- [API - Trapit](https://github.com/BrenPatF/trapit_oracle_tester#api---trapit)

Adds a record to tt_units table, with parameters as follows:

* `p_package_nm`: package name
* `p_procedure_nm`: procedure name
* `p_group_nm`: test group name
* `p_active_yn`: active Y/N flag
* `p_input_file`: name of input file, which has to exist in Oracle directory `input_dir`

## API - Trapit_Run
- [In this README...](https://github.com/BrenPatF/trapit_oracle_tester#in-this-readme)
- [Run_Tests(p_group_nm)](https://github.com/BrenPatF/trapit_oracle_tester#trapitrun_testsp_group_nm)

This package runs with Invoker rights, not the default Definer rights, so that dynamic SQL calls to the test packages in the calling schema do not require execute privilege to be granted to owning schema (if different from caller).

### Trapit.Run_Tests(p_group_nm)
Runs the unit test program for each package procedure set to active in tt_units table for a given test group, with parameters as follows:

* `p_group_nm`: test group name

Normally the test packages in a group will be within a single schema from where the tests would be run.

## Installation
- [In this README...](https://github.com/BrenPatF/trapit_oracle_tester#in-this-readme)
- [Install 1: Install pre-requisite module](https://github.com/BrenPatF/trapit_oracle_tester#install-1-install-pre-requisite-module)
- [Install 2: Install Oracle Trapit module](https://github.com/BrenPatF/trapit_oracle_tester#install-2-install-oracle-trapit-module)
- [Install 3: Create synonyms to lib](https://github.com/BrenPatF/trapit_oracle_tester#install-3-create-synonyms-to-lib)
- [Install 4: Install npm trapit package](https://github.com/BrenPatF/trapit_oracle_tester#install-4-install-npm-trapit-package)

The install depends on the pre-requisite module Utils, and `lib` schema refers to the schema in which Utils is installed.

### Install 1: Install pre-requisite module
- [Installation](https://github.com/BrenPatF/trapit_oracle_tester#installation)

The pre-requisite module can be installed by following the instructions at [Utils on GitHub](https://github.com/BrenPatF/oracle_plsql_utils). This allows inclusion of the examples and unit tests for the module. Alternatively, the next section shows how to install the module directly without its examples or unit tests here.

#### [Schema: sys; Folder: install_prereq] Create lib and app schemas and Oracle directory
- install_sys.sql creates an Oracle directory, `input_dir`, pointing to 'c:\input'. Update this if necessary to a folder on the database server with read/write access for the Oracle OS user
- Run script from slqplus:
```
SQL> @install_sys
```

#### [Schema: lib; Folder: install_prereq\lib] Create lib components
- Run script from slqplus:
```
SQL> @install_lib_all
```
#### [Schema: app; Folder: install_prereq\app] Create app synonyms
- Run script from slqplus:
```
SQL> @c_syns_all
```

### Install 2: Install Oracle Trapit module
- [Installation](https://github.com/BrenPatF/trapit_oracle_tester#installation)
#### [Schema: lib; Folder: lib]
- Run script from slqplus:
```
SQL> @install_trapit app
```
This creates the required components for the base install along with grants for them to the app schema (passing none instead of app will bypass the grants). It requires a minimum Oracle database version of 12.2. To grant privileges to another `schema`, run the grants script directly, passing `schema`:
```
SQL> @grant_trapit_to_app schema
```

### Install 3: Create synonyms to lib
- [Installation](https://github.com/BrenPatF/trapit_oracle_tester#installation)
#### [Schema: app; Folder: app]
- Run script from slqplus:
```
SQL> @c_trapit_syns lib
```
This install creates private synonyms to the lib schema. To create synonyms within another schema, run the synonyms script directly from that schema, passing lib schema.

### Install 4: Install npm trapit package
- [Installation](https://github.com/BrenPatF/trapit_oracle_tester#installation)
#### [Folder: (npm root)]
Open a DOS or Powershell window in the folder where you want to install npm packages, and, with [nodejs](https://nodejs.org/en/download/) installed, run
```
$ npm install trapit
```
This should install the trapit nodejs package in a subfolder .\node_modules\trapit

## Operating System/Oracle Versions
- [In this README...](https://github.com/BrenPatF/trapit_oracle_tester#in-this-readme)
### Windows
Tested on Windows 10, should be OS-independent
### Oracle
- Tested on Oracle Database Version 18.3.0.0.0
- Minimum version 12.2

## See also
- [Utils - Oracle PL/SQL general utilities module](https://github.com/BrenPatF/oracle_plsql_utils)
- [Log_Set - Oracle logging module](https://github.com/BrenPatF/log_set_oracle)
- [Timer_Set - Oracle PL/SQL code timing module](https://github.com/BrenPatF/timer_set_oracle)
- [Net_Pipe - Oracle PL/SQL network analysis module](https://github.com/BrenPatF/plsql_network)
- [Trapit - nodejs unit test processing package](https://github.com/BrenPatF/trapit_nodejs_tester)
- [Oracle PL/SQL API Demos - demonstrating instrumentation and logging, code timing and unit testing of Oracle PL/SQL APIs](https://github.com/BrenPatF/oracle_plsql_api_demos)

## License
MIT