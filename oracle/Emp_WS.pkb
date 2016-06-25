CREATE OR REPLACE PACKAGE BODY Emp_WS AS
/***************************************************************************************************
Description: HR demo web service code. Procedure saves new employees list and returns primary key
             plus same in words, or zero plus error message in output list

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        04-May-2016 1.0   Created

***************************************************************************************************/

/***************************************************************************************************

AIP_Save_Emps: HR demo web service entry point procedure

***************************************************************************************************/
PROCEDURE AIP_Save_Emps (p_emp_in_lis           emp_in_arr,     -- list of employees to insert
                         x_emp_out_lis      OUT emp_out_arr) IS -- list of employee results

  l_emp_out_lis        emp_out_arr;
  bulk_errors          EXCEPTION;
  PRAGMA               EXCEPTION_INIT (bulk_errors, -24381);
  n_err PLS_INTEGER := 0;

BEGIN

  FORALL i IN 1..p_emp_in_lis.COUNT
    SAVE EXCEPTIONS
    INSERT INTO employees (
        employee_id,
        last_name,
        email,
        hire_date,
        job_id,
        salary,
        utid
    ) VALUES (
        employees_seq.NEXTVAL,
        p_emp_in_lis(i).last_name,
        p_emp_in_lis(i).email,
        SYSDATE,
        p_emp_in_lis(i).job_id,
        p_emp_in_lis(i).salary,
        Utils.c_session_id_if_UT
    )
    RETURNING emp_out_rec (employee_id, To_Char(To_Date(employee_id,'J'),'JSP')) BULK COLLECT INTO x_emp_out_lis;

EXCEPTION
  WHEN bulk_errors THEN

    l_emp_out_lis := x_emp_out_lis;

    FOR i IN 1 .. sql%BULK_EXCEPTIONS.COUNT LOOP
      IF i > x_emp_out_lis.COUNT THEN
        x_emp_out_lis.Extend;
      END IF;
      x_emp_out_lis (SQL%Bulk_Exceptions (i).Error_Index) := emp_out_rec (0, SQLERRM (- (SQL%Bulk_Exceptions (i).Error_Code)));
    END LOOP;

    FOR i IN 1..p_emp_in_lis.COUNT LOOP
      IF i > x_emp_out_lis.COUNT THEN
        x_emp_out_lis.Extend;
      END IF;
      IF x_emp_out_lis(i).employee_id = 0 THEN
        n_err := n_err + 1;
      ELSE
        x_emp_out_lis(i) := l_emp_out_lis(i - n_err);
      END IF;
    END LOOP;

END AIP_Save_Emps;

END Emp_WS;
/
SHO ERR
