CREATE OR REPLACE PACKAGE Trapit AS

TYPE scenarios_rec IS RECORD(
       delim                        VARCHAR2(10) := '|',
       scenarios_4lis               L4_chr_arr);

FUNCTION Get_Inputs (
            p_package_nm                   VARCHAR2,
            p_procedure_nm                 VARCHAR2)
            RETURN                         scenarios_rec;
PROCEDURE Set_Outputs (
            p_package_nm                   VARCHAR2,
            p_procedure_nm                 VARCHAR2,
            p_act_3lis                     L3_chr_arr);
PROCEDURE Run_Tests;
PROCEDURE Add_Ttu(
            p_package_nm                   VARCHAR2,
            p_procedure_nm                 VARCHAR2, 
            p_active_yn                    VARCHAR2, 
            p_input_file                   VARCHAR2);

END Trapit;
/
SHOW ERROR