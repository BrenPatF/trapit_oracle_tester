package hrdemo;
/***************************************************************************************************
Name:        Driver.java
Description: This is a Java driver script for Brendan's HR demo web service procedure. It is
             designed to serve as a template for other web service procedures to allow a database
             developer to do a JDBC integration test easily.

             The template procedure takes an input array of objects and has an output array of 
             objects. It is easy to update for any named object and array types, procedure and
             Oracle connection. Any other signature types would need additional changes.
                                         
				A Template Script for JDBC Integration Testing of Oracle Procedures
				http://aprogrammerwrites.eu/?p=1676

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
B. Furey             12-May-2016 1.0   Created                       

***************************************************************************************************/
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Array;
import java.sql.Struct;

import oracle.jdbc.OracleTypes;
import oracle.sql.ARRAY;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleConnection;

public class Driver {

// Change section 1/2: Replace these constants with your own values

  private static final String DB_CONNECTION = "jdbc:oracle:thin:hr/hr@localhost:1521/xe";
  private static final String TY_IN_OBJ     = "TY_EMP_IN_OBJ";
  private static final String TY_IN_ARR     = "TY_EMP_IN_ARR";
  private static final String TY_OUT_ARR    = "TY_EMP_OUT_ARR";
  private static final String PROC_NAME     = "Emp_WS.AIP_Save_Emps";

  private static OracleConnection conn;

  public static void main(String[] argv) {
    try {
      getDBConnection ();
      prOutArray (callProc (inArray ()));
    }
    catch (SQLException e) {
      System.out.println(e.getMessage());
    }
  }
  private static ARRAY inArray () throws SQLException {

// Change section 2/2: Replace [2] with number of test records, and the arrays with their values

    Struct[] struct = new Struct[2];
    struct[0] = conn.createStruct (TY_IN_OBJ, new Object[] {"LN 1", "EM 1", "IT_PROG", 1000});
    struct[1] = conn.createStruct (TY_IN_OBJ, new Object[] {"LN 2", "EM 2", "IT_PROG", 2000});
    return conn.createARRAY (TY_IN_ARR, struct);
  }
  private static Array callProc (ARRAY objArray) throws SQLException {
    OracleCallableStatement ocs = (OracleCallableStatement) conn.prepareCall ("BEGIN "+PROC_NAME+"(:1, :2); END;");
    ocs.setArray (1, objArray);
    ocs.registerOutParameter (2, OracleTypes.ARRAY, TY_OUT_ARR);
    ocs.execute ();
    return ocs.getARRAY (2);
  }
  private static void prOutArray (Array arr) throws SQLException {
    Object[] objArr = (Object[]) arr.getArray();
    int j = 0;
    for (Object rec : objArr) {
      Object[] objLis = ((Struct)rec).getAttributes ();
      int i = 0;
      String recStr = "";
      for (Object fld : objLis) {
        if (i++ > 0) recStr = recStr + '/';
        recStr = recStr + fld.toString();
      }
      System.out.println ("Record "+(++j)+": "+recStr);
    }
  }
  private static void getDBConnection () throws SQLException {
    conn = (OracleConnection) DriverManager.getConnection (DB_CONNECTION);
    conn.setAutoCommit (false);
    System.out.println ("Connected...");
  }
}