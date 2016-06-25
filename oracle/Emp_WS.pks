CREATE OR REPLACE PACKAGE Emp_WS AS
/***************************************************************************************************
Name:        Emp_WS
Description: HR demo web service code. Procedure saves new employees list and returns primary key
             plus same in words, or zero plus error message in output list
                                                                               
Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        04-May-2016 1.0   Created

***************************************************************************************************/

PROCEDURE AIP_Save_Emps (p_emp_in_lis emp_in_arr, x_emp_out_lis OUT emp_out_arr);

END Emp_WS;
/
