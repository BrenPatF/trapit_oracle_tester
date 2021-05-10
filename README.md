# Trapit
<img src="mountains.png">
Oracle PL/SQL unit testing module.

:detective:

TRansactional API Testing (TRAPIT) framework for Oracle SQL and PL/SQL unit testing.

This is a lightweight framework for unit testing SQL and PL/SQL based on the 'Math Function Unit Testing design pattern'. I explained the concepts involved in a presentation at the Oracle User Group Ireland Conference in March 2018:

- [The Database API Viewed As A Mathematical Function: Insights into Testing](https://www.slideshare.net/brendanfurey7/database-api-viewed-as-a-mathematical-function-insights-into-testing)

I later named the approach 'The Math Function Unit Testing design pattern':
- [The Math Function Unit Testing design pattern, implemented in nodejs](https://github.com/BrenPatF/trapit_nodejs_tester)

The main features of the design pattern:

- The 'unit under test' (UUT) is viewed from the perspective of a mathematical function having an 'extended signature', comprising any actual parameters and return value, together with other inputs and outputs of any kind
- A wrapper function is constructed based on this conceptual function, and this wrapper function is 'externally pure', in the sense that any data changes made are rolled back before returning
- The wrapper function performs the steps necessary to test the UUT in a single scenario
- It takes all inputs of the extended signature as a parameter, creates any test data needed from them, effects a transaction with the UUT, and returns all outputs as a return value
- Any test data, and any data changes made by the UUT, are reverted before return
- The wrapper function has a fixed signature with input as a set of input groups containing arrays of records, and return value a set of output groups containing arrays of records
- The wrapper function specific to the UUT is called within a loop over scenarios by a library test driver module
- The library test driver module reads data for all scenarios in JSON format, with both inputs to the UUT and the expected outputs, and metadata records describing the specific data structure
- The module takes the actual outputs from the wrapper function and merges them in alongside the expected outputs to create a JSON output results file
- This JSON file is processed by a nodejs program that produces reports in plain text and HTML, with a summary page, and pages per scenario showing inputs and actual outputs, highlighting any differences from expected

Advantages include:

- Once the unit test program is written for one scenario no further programming is required to handle additional scenarios
- The complexity of the unit test code (the wrapper function) depends only on the API interface of the UUT, and not on its internal complexity (unlike, say, microtesting approaches)
- The outputs from the unit testing program show exactly what the program actually does in terms of data inputs and outputs
- All unit test programs in any language can follow a single, straightforward pattern

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
- [Usage - General](https://github.com/BrenPatF/trapit_oracle_tester#usage---general)
- [Usage - Example](https://github.com/BrenPatF/trapit_oracle_tester#usage---example)

### Usage - General
- [Usage](https://github.com/BrenPatF/trapit_oracle_tester#usage)

In order to use the framework for unit testing, the following preliminary steps are required, after installation: 
- Create a JSON file containing the input test data including expected return values in the required format. The input JSON file essentially consists of two objects: 
  - `meta`: inp and out objects each containing group objects with arrays of field names
  - `scenarios`: scenario objects containing inp and out objects, with inp and out objects containing, for each group defined in meta, an array of input records and an array of expected output records, respectively, records being in delimited fields format
- Place the JSON file in the Oracle directory, INPUT_DIR, created as part of this module's installation
- Create a unit test PL/SQL wrapper function in a package, which should call the unit under test passing the appropriate parameters and return its outputs, with the following signature:

  - Input parameter: 3-level list (type L3_chr_arr) with test inputs as group/record/field
  - Return Value:    2-level list (type L2_chr_arr) with test outputs as group/record (with record as delimited fields string)

This wrapper function may need to write inputs to, and read outputs from, tables, but should be 'externally pure' in the sense that any changes made are rolled back before returning, including any made by the unit under test.
- Insert a record into the tt_units table using the Trapit.Add_Ttu procedure, passing names of package, function and JSON file, and a unit test group name

Once the preliminary steps are executed, the following steps run the unit test programs in the group (say UT_GROUP): 
- Run script from slqplus:

```
SQL> @r_tests
```
where the script r_tests.sql constains a single PL/SQL statement within a PL/SQL block:

```
BEGIN
  Trapit_Run.Run_Tests(p_group_nm => 'UT_GROUP');
END;
```
This writes JSON output files both to the tt_units table and to the Oracle directory, INPUT_DIR, for all programs in the unit test group.
- Open a DOS or Powershell window in the trapit npm package folder (`see Install 3: Install npm trapit package below`) after placing the output JSON files in the subfolder ./examples/externals and run:

```
$ node ./examples/externals/test-externals
```

The nodejs program produces listings of the results in HTML and/or text format in a subfolder with name derived from the unit test title in the input JSON file. The unit test steps can easily be automated in Powershell (or in a Unix script).

### Usage - Example
- [Usage](https://github.com/BrenPatF/trapit_oracle_tester#usage)
- [Input JSON File](https://github.com/BrenPatF/trapit_oracle_tester#input-json-file)
- [Unit Test PL/SQL Wrapper Function](https://github.com/BrenPatF/trapit_oracle_tester#unit-test-plsql-wrapper-function)
- [Unit Test Formatted Results](https://github.com/BrenPatF/trapit_oracle_tester#unit-test-formatted-results)

The example comes from [Oracle PL/SQL network analysis module](https://github.com/BrenPatF/plsql_network)

#### Input JSON File
- [Usage - Example](https://github.com/BrenPatF/trapit_oracle_tester#usage-example)

The JSON input file contains `meta` and `scenarios` properties, as mentioned above, with structure reflecting the (extended) inputs and outputs of the unit under test. An easy way to generate a starting point for this is to use a powershell utility [Powershell Utilites module](https://github.com/BrenPatF/powershell_utils) to generate a template file, with a single scenario with placeholder records. This can be done by opening a powershell window from the folder test_data within the example module, and running:

```
.\purely_wrap_all_nets
```

The script imports the powershell module and calls the utility function Write-UT_Template:

```
Write-UT_Template 'purely_wrap_all_nets' '|'
```

It takes inputs of file name stem and delimiter, and reads from two files, the first, `purely_wrap_all_nets_inp.csv`, containing input group, field pairs:
##### purely_wrap_all_nets_inp.csv
```
group,field
Link,Link Id
Link,Node Id From
Link,Node Id To
```

and the second, `purely_wrap_all_nets_out.csv`, containing output group, field pairs:
##### purely_wrap_all_nets_out.csv
```
group,field
Network,Root Node Id
Network,Direction
Network,Node Id
Network,Link Id
Network,Node Level
Network,Loop Flag
Network,Line Number
```
The template file, purely_wrap_all_nets_temp.json, has the lines:

##### purely_wrap_all_nets_temp.json
```
{
  "meta": {
         "title": "title",
         "delimiter": "|",
         "inp": {
               "Link": [
                     "Link Id",
                     "Node Id From",
                     "Node Id To"
                   ]
             },
         "out": {
               "Network": [
                       "Root Node Id",
                       "Direction",
                       "Node Id",
                       "Link Id",
                       "Node Level",
                       "Loop Flag",
                       "Line Number"
                     ]
             }
       },
  "scenarios": {
           "scenario 1": {
                     "active_yn": "Y",
                     "inp": {
                           "Link": [
                                 "||"
                               ]
                         },
                     "out": {
                           "Network": [
                                   "||||||"
                                 ]
                         }
                   }
         }
}
```
The template is then updated with test data for 3 scenarios:
##### tt_net_pipe.purely_wrap_all_nets_inp.json
<div style="overflow: auto; max-height: 700px;">
<pre>
{  
   "meta":{  
      "title":"Oracle PL/SQL Network Analysis",
      "delimiter":"|",
      "inp":{  
         "Link":[  
            "Link Id",
            "Node Id From",
            "Node Id To"
         ]
      },
      "out":{  
         "Network":[  
            "Root Node Id",
            "Direction",
            "Node Id",
            "Link Id",
            "Node Level",
            "Loop Flag",
            "Line Number"
         ]
      }
   },
   "scenarios":{  
      "1 link":{  
         "active_yn":"Y",
         "inp":{  
            "Link":[  
               "Link 1|Node 1|Node 2"
            ]
         },
         "out":{  
            "Network":[  
               "Node 1| |Node 1|ROOT|0||1",
               "Node 1|>|Node 2|Link 1|1||2"
            ]
         }
      },
      "1 loop, 100ch names":{  
         "active_yn":"Y",
         "inp":{  
            "Link":[  
               "Link 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890|Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890|Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
            ]
         },
         "out":{  
            "Network":[  
               "Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890| |Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890|ROOT|0||1",
               "Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890|=|Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890|Link 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890|1|*|2"
            ]
         }
      },
      "4 subnetworks, looped and tree":{  
         "active_yn":"Y",
         "inp":{  
            "Link":[  
               "Link 1-1|Node 1-1|Node 2-1",
               "Link 2-1|Node 2-1|Node 3-1",
               "Link 1-2|Node 1-2|Node 2-2",
               "Link 2-2|Node 2-2|Node 3-2",
               "Link 3-2|Node 2-2|Node 4-2",
               "Link 1-3|Node 1-3|Node 2-3",
               "Link 2-3|Node 2-3|Node 1-3",
               "Link 1-4|Node 1-4|Node 2-4",
               "Link 2-4|Node 2-4|Node 3-4",
               "Link 3-4|Node 3-4|Node 1-4"
            ]
         },
         "out":{  
            "Network":[  
               "Node 1-1| |Node 1-1|ROOT|0||1",
               "Node 1-1|>|Node 2-1|Link 1-1|1||2",
               "Node 1-1|>|Node 3-1|Link 2-1|2||3",
               "Node 1-2| |Node 1-2|ROOT|0||4",
               "Node 1-2|>|Node 2-2|Link 1-2|1||5",
               "Node 1-2|>|Node 3-2|Link 2-2|2||6",
               "Node 1-2|>|Node 4-2|Link 3-2|2||7",
               "Node 1-3| |Node 1-3|ROOT|0||8",
               "Node 1-3|>|Node 2-3|Link 1-3|1||9",
               "Node 1-3|>|Node 1-3|Link 2-3|2|*|10",
               "Node 1-4| |Node 1-4|ROOT|0||11",
               "Node 1-4|>|Node 2-4|Link 1-4|1||12",
               "Node 1-4|>|Node 3-4|Link 2-4|2||13",
               "Node 1-4|>|Node 1-4|Link 3-4|3|*|14"
            ]
         }
      }
   }
}
</pre>
</div>

#### Unit Test PL/SQL Wrapper Function
- [Usage - Example](https://github.com/BrenPatF/trapit_oracle_tester#usage-example)

The text box below shows the entire body code for the unit test package containing the pure wrapper function, Purely_Wrap_All_Nets. The function calls a local procedure to add the test data, then calls another local function that calls the unit under test and returns the output data in the required format. The test data are rolled back before return.
```
CREATE OR REPLACE PACKAGE BODY TT_Net_Pipe AS
PROCEDURE add_Links(
            p_link_2lis                    L2_chr_arr) IS -- list of (from node, to node, link id) triples
BEGIN

  FOR i IN 1..p_link_2lis.COUNT LOOP
    INSERT INTO network_links VALUES (p_link_2lis(i)(1), p_link_2lis(i)(2), p_link_2lis(i)(3));
  END LOOP;

END add_Links;

FUNCTION cursor_To_List(
            p_cursor_text                  VARCHAR2)     -- cursor text
            RETURN                         L1_chr_arr IS -- list of delimited records
  l_csr             SYS_REFCURSOR;
BEGIN

  OPEN l_csr FOR p_cursor_text;
  RETURN Utils.Cursor_To_List(x_csr    => l_csr,
                              p_delim  => '|');
END cursor_To_List;

FUNCTION Purely_Wrap_All_Nets(
            p_inp_3lis                     L3_chr_arr)   -- input list of lists (record, field)
            RETURN                         L2_chr_arr IS -- output list of lists (group, record)

  l_act_2lis                     L2_chr_arr := L2_chr_arr();
BEGIN

  add_Links(p_link_2lis => p_inp_3lis(1));
  l_act_2lis.EXTEND;
  l_act_2lis(1) := cursor_To_List(p_cursor_text => 'SELECT * FROM TABLE(Net_Pipe.All_Nets)');
  ROLLBACK;
  RETURN l_act_2lis;

END Purely_Wrap_All_Nets;
END TT_Net_Pipe;
```
Notice the simplicity of this code, which reflects the level of complexity of input and output structure, not that of the base network analysis code.

#### Unit Test Formatted Results
- [Usage - Example](https://github.com/BrenPatF/trapit_oracle_tester#usage-example)

The nodejs program produces listings of the results in HTML and/or text format, with a summary of the scenario results and detailed listings for each scenario. 

<div style="overflow: auto; max-height: 700px;">

<pre>
Unit Test Report: Oracle PL/SQL Network Analysis
================================================

      #    Scenario                        Fails (of 1)  Status 
      ---  ------------------------------  ------------  -------
      1    1 link                          0             SUCCESS
      2    1 loop, 100ch names             0             SUCCESS
      3    4 subnetworks, looped and tree  0             SUCCESS

Test scenarios: 0 failed of 3: SUCCESS
======================================

SCENARIO 1: 1 link {
====================

   INPUTS
   ======

      GROUP 1: Link {
      ===============

            #  Link Id  Node Id From  Node Id To
            -  -------  ------------  ----------
            1  Link 1   Node 1        Node 2    

      }
      =

   OUTPUTS
   =======

      GROUP 1: Network {
      ==================

            #  Root Node Id  Direction  Node Id  Link Id  Node Level  Loop Flag  Line Number
            -  ------------  ---------  -------  -------  ----------  ---------  -----------
            1  Node 1                   Node 1   ROOT     0                      1          
            2  Node 1        >          Node 2   Link 1   1                      2          

      } 0 failed of 2: SUCCESS
      ========================

} 0 failed of 1: SUCCESS
========================

SCENARIO 2: 1 loop, 100ch names {
=================================

   INPUTS
   ======

      GROUP 1: Link {
      ===============

            #  Link Id                                                                                               Node Id From                                                                                          Node Id To                                                                                          
            -  ----------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------------------------------
            1  Link 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890  Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890  Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890

      }
      =

   OUTPUTS
   =======

      GROUP 1: Network {
      ==================

            #  Root Node Id                                                                                          Direction  Node Id                                                                                               Link Id                                                                                               Node Level  Loop Flag  Line Number
            -  ----------------------------------------------------------------------------------------------------  ---------  ----------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------------------------------  ----------  ---------  -----------
            1  Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890             Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890  ROOT                                                                                                  0                      1          
            2  Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890  =          Node 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890  Link 17890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890  1           *          2          

      } 0 failed of 2: SUCCESS
      ========================

} 0 failed of 1: SUCCESS
========================

SCENARIO 3: 4 subnetworks, looped and tree {
============================================

   INPUTS
   ======

      GROUP 1: Link {
      ===============

            #   Link Id   Node Id From  Node Id To
            --  --------  ------------  ----------
            1   Link 1-1  Node 1-1      Node 2-1  
            2   Link 2-1  Node 2-1      Node 3-1  
            3   Link 1-2  Node 1-2      Node 2-2  
            4   Link 2-2  Node 2-2      Node 3-2  
            5   Link 3-2  Node 2-2      Node 4-2  
            6   Link 1-3  Node 1-3      Node 2-3  
            7   Link 2-3  Node 2-3      Node 1-3  
            8   Link 1-4  Node 1-4      Node 2-4  
            9   Link 2-4  Node 2-4      Node 3-4  
            10  Link 3-4  Node 3-4      Node 1-4  

      }
      =

   OUTPUTS
   =======

      GROUP 1: Network {
      ==================

            #   Root Node Id  Direction  Node Id   Link Id   Node Level  Loop Flag  Line Number
            --  ------------  ---------  --------  --------  ----------  ---------  -----------
            1   Node 1-1                 Node 1-1  ROOT      0                      1          
            2   Node 1-1      >          Node 2-1  Link 1-1  1                      2          
            3   Node 1-1      >          Node 3-1  Link 2-1  2                      3          
            4   Node 1-2                 Node 1-2  ROOT      0                      4          
            5   Node 1-2      >          Node 2-2  Link 1-2  1                      5          
            6   Node 1-2      >          Node 3-2  Link 2-2  2                      6          
            7   Node 1-2      >          Node 4-2  Link 3-2  2                      7          
            8   Node 1-3                 Node 1-3  ROOT      0                      8          
            9   Node 1-3      >          Node 2-3  Link 1-3  1                      9          
            10  Node 1-3      >          Node 1-3  Link 2-3  2           *          10         
            11  Node 1-4                 Node 1-4  ROOT      0                      11         
            12  Node 1-4      >          Node 2-4  Link 1-4  1                      12         
            13  Node 1-4      >          Node 3-4  Link 2-4  2                      13         
            14  Node 1-4      >          Node 1-4  Link 3-4  3           *          14         

      } 0 failed of 14: SUCCESS
      =========================

} 0 failed of 1: SUCCESS
========================
</pre>
</div>


## API - Trapit
- [In this README...](https://github.com/BrenPatF/trapit_oracle_tester#in-this-readme)
- [Add_Ttu(p_unit_test_package_nm, p_purely_wrap_api_function_nm, p_group_nm, p_active_yn, p_input_file)](https://github.com/BrenPatF/trapit_oracle_tester#trapitadd_ttup_unit_test_package_nm-p_purely_wrap_api_function_nm-p_group_nm-p_active_yn-p_input_file)

This section excludes public program units that are only used by the package Trapit_Run.

### Trapit.Add_Ttu(p_unit_test_package_nm, p_purely_wrap_api_function_nm, p_group_nm, p_active_yn, p_input_file)
Adds a record to tt_units table, with parameters as follows:

- `p_unit_test_package_nm`: unit test package name
- `p_purely_wrap_api_function_nm`: wrapper function name
- `p_group_nm`: test group name
- `p_active_yn`: active Y/N flag
- `p_input_file`: name of input file, which has to exist in Oracle directory `input_dir`

## API - Trapit_Run
- [In this README...](https://github.com/BrenPatF/trapit_oracle_tester#in-this-readme)
- [Run_Tests(p_group_nm)](https://github.com/BrenPatF/trapit_oracle_tester#trapitrun_testsp_group_nm)

This package runs with Invoker rights, not the default Definer rights, so that dynamic SQL calls to the test packages in the calling schema do not require execute privilege to be granted to owning schema (if different from caller).

### Trapit.Run_Tests(p_group_nm)
Runs the unit test program for each package procedure set to active in tt_units table for a given test group, with parameters as follows:

- `p_group_nm`: test group name

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
Open a DOS or Powershell window in the folder where you want to install npm packages, and, with [nodejs](https://nodejs.org/en/download/) installed, run:

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