CREATE OR REPLACE PACKAGE BODY Utils AS
/***************************************************************************************************
Description: This package contains general utility procedures. It was published initially with two
             other utility packages for the articles linked in the link below:

                 UT_Utils:  Utility procedures for Brendan's database unit testing framework
                 Timer_Set: Code timing utility

Further details: 'Brendan's Database Unit Testing Framework'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        08-May-2016 1.0   Initial for first article
Brendan Furey        21-May-2016 1.1   Replaced SYS.ODCI types with custom types L1_chr_arr etc.
Brendan Furey        24-Jun-2016 1.0   Row_To_List added

***************************************************************************************************/

c_lines                 CONSTANT VARCHAR2(1000) := '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';
c_equals                CONSTANT VARCHAR2(1000) := '=======================================================================================================================================================================================================';

g_log_header_id         PLS_INTEGER := 0;
g_line_lis              L1_chr_arr;
g_line_printed          VARCHAR2(1000);

/***************************************************************************************************

Reset_Log: Logging procedure, resets global header id

***************************************************************************************************/
PROCEDURE Reset_Log (p_log_header_id PLS_INTEGER DEFAULT 0) IS -- log header id
BEGIN

  g_log_header_id := p_log_header_id;

END Reset_Log;

/***************************************************************************************************

Clear_Log: Logging procedure, clears log lines for header id

***************************************************************************************************/
PROCEDURE Clear_Log (p_log_header_id PLS_INTEGER DEFAULT 0) IS -- log header id
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  DELETE log_lines WHERE log_header_id = p_log_header_id;
  IF p_log_header_id > 0 THEN
    DELETE log_headers WHERE id = p_log_header_id;
  END IF;
  COMMIT;

END Clear_Log;

/***************************************************************************************************

Create_Log: Logging procedure, creates log header, returning its id

***************************************************************************************************/
FUNCTION Create_Log (p_description VARCHAR2 DEFAULT NULL) -- log description
                        RETURN PLS_INTEGER IS             -- log header id
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  INSERT INTO log_headers (
        id,
        description,
        creation_date
  ) VALUES (
        log_headers_s.NEXTVAL,
        p_description,
        SYSTIMESTAMP)
  RETURNING id INTO g_log_header_id;
  COMMIT;
  RETURN g_log_header_id;

END Create_Log;

/***************************************************************************************************

Write_Log: Logging procedure, writes log line for header stored in global

***************************************************************************************************/
PROCEDURE Write_Log (p_text             VARCHAR2,                 -- line to write
                     p_group_text       VARCHAR2 DEFAULT NULL) IS -- group text
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  IF p_group_text IS NOT NULL THEN
    g_group_text := p_group_text;
  END IF;

  INSERT INTO log_lines (
        id,
        log_header_id,
        group_text,
        line_text,
        creation_date
  ) VALUES (
        log_lines_s.NEXTVAL,
        g_log_header_id,
        g_group_text,
        p_text,
        SYSTIMESTAMP);
  COMMIT;

END Write_Log;

/***************************************************************************************************

Write_Other_Error: Write the SQL error and backtrace to log, called from WHEN OTHERS

***************************************************************************************************/
PROCEDURE Write_Other_Error (p_package          VARCHAR2 DEFAULT NULL,    -- package name
                             p_proc             VARCHAR2 DEFAULT NULL,    -- procedure name
                             p_group_text       VARCHAR2 DEFAULT NULL) IS -- group text
BEGIN

  Write_Log (p_text =>  'Others error in ' || p_package || '(' || p_proc || '): ' || SQLERRM || ': ' || DBMS_Utility.Format_Error_Backtrace, p_group_text => p_group_text );

END Write_Other_Error;

/***************************************************************************************************

Get_Seconds: Simple function to get the seconds as a number from an interval

***************************************************************************************************/
FUNCTION Get_Seconds (p_interval INTERVAL DAY TO SECOND) -- time intervale
                        RETURN NUMBER IS                 -- time in seconds
BEGIN

  RETURN EXTRACT (SECOND FROM p_interval) + 60 * EXTRACT (MINUTE FROM p_interval) + 3600 * EXTRACT (HOUR FROM p_interval);

END Get_Seconds;

/***************************************************************************************************

Heading: Write a string as a heading with double underlining

***************************************************************************************************/
PROCEDURE Heading (p_head       VARCHAR2,                 -- heading string
                   p_indent_level PLS_INTEGER DEFAULT 0,  -- indent level
                   p_group_text VARCHAR2 DEFAULT NULL) IS -- group text

  l_under       VARCHAR2(500) := Substr (c_equals, 1, Length (p_head));
  l_indent      VARCHAR2(10) := CASE p_indent_level WHEN 1 THEN '     ' WHEN 2 THEN '          ' END;

BEGIN

  Write_Log (p_text => '', p_group_text => p_group_text);
  Write_Log (p_text => l_indent || p_head);
  Write_Log (p_text => l_indent || l_under);

END Heading;

/***************************************************************************************************

List_Delim: Return a delimited string for an input set of from 1 to 15 strings

***************************************************************************************************/
FUNCTION List_Delim ( p_field1 VARCHAR2,        -- input string, first is required, others passed as needed
                      p_field2 VARCHAR2 DEFAULT c_list_end_marker, p_field3 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field4 VARCHAR2 DEFAULT c_list_end_marker, p_field5 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field6 VARCHAR2 DEFAULT c_list_end_marker, p_field7 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field8 VARCHAR2 DEFAULT c_list_end_marker, p_field9 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field10 VARCHAR2 DEFAULT c_list_end_marker, p_field11 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field12 VARCHAR2 DEFAULT c_list_end_marker, p_field13 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field14 VARCHAR2 DEFAULT c_list_end_marker, p_field15 VARCHAR2 DEFAULT c_list_end_marker)
                      RETURN VARCHAR2 IS        -- delimited string

  l_list       L1_chr_arr := L1_chr_arr (p_field2, p_field3, p_field4, p_field5, p_field6, p_field7, p_field8,
                    p_field9, p_field10, p_field11, p_field12, p_field13, p_field14, p_field15);
  l_str         VARCHAR2(4000) := p_field1;

BEGIN

  FOR i IN 1..l_list.COUNT LOOP

    IF l_list(i) = c_list_end_marker THEN
      EXIT;
    END IF;
    l_str := l_str || g_list_delimiter || l_list(i);

  END LOOP;
  RETURN l_str;

END List_Delim;

/***************************************************************************************************

List_Delim: Return a delimited string for an input list of strings

***************************************************************************************************/
FUNCTION List_Delim (p_field_lis        L1_chr_arr,              -- list of strings
                     p_delim            VARCHAR2 DEFAULT g_list_delimiter) -- delimiter
                     RETURN VARCHAR2 IS                                    -- delimited string

  l_str         VARCHAR2(4000) := p_field_lis(1);

BEGIN

  FOR i IN 2..p_field_lis.COUNT LOOP

    l_str := l_str || p_delim || p_field_lis(i);

  END LOOP;
  RETURN l_str;

END List_Delim;

/***************************************************************************************************

Pr_List_As_Line: Print a list of strings as one line, saving for reprinting later if desired,
                 separating fields by a 2-space delimiter; second list is numbers for lengths, with
                 -ve/+ve sign denoting right/left-justify

***************************************************************************************************/
PROCEDURE Pr_List_As_Line (p_val_lis            L1_chr_arr, -- token list
                           p_len_lis            L1_num_arr, -- length list
                           p_indent_level       PLS_INTEGER DEFAULT 0,
                           p_save_line BOOLEAN DEFAULT FALSE) IS  -- TRUE if to save in global
  l_line        VARCHAR2(1000);
  l_fld         VARCHAR2(200);
  l_indent      VARCHAR2(10) := CASE p_indent_level WHEN 1 THEN '     ' WHEN 2 THEN '          ' END;
  l_val         VARCHAR2(1000);
BEGIN

  FOR i IN 1..p_val_lis.COUNT LOOP

    l_val := Nvl (p_val_lis(i), ' ');
    IF p_len_lis(i) < 0 THEN
      l_fld := LPad (l_val, -p_len_lis(i));
    ELSE
      l_fld := RPad (l_val, p_len_lis(i));
    END IF;
    IF i = 1 THEN
      l_line := l_fld;
    ELSE
      l_line := l_line || c_fld_delim || l_fld;
    END IF;

  END LOOP;
  Write_Log (l_indent || l_line);
  IF p_save_line THEN
    g_line_printed := l_indent || l_line;
  END IF;

END Pr_List_As_Line;

/***************************************************************************************************

Reprint_Line: Reprint the line previously printed by Pr_List_As_Line, stored in a global

***************************************************************************************************/
PROCEDURE Reprint_Line IS
BEGIN

  Write_Log (g_line_printed);

END Reprint_Line;

/***************************************************************************************************

Col_Headers: Print a set of column headers, input as lists of values and length/justification's

***************************************************************************************************/
PROCEDURE Col_Headers (p_val_lis        L1_chr_arr,               -- list of headers
                       p_len_lis        L1_num_arr,               -- list of lengths
                       p_indent_level   PLS_INTEGER DEFAULT 0) IS -- indent level

  l_line_lis    L1_chr_arr := L1_chr_arr();

BEGIN

  g_line_lis := L1_chr_arr();
  g_line_lis.EXTEND (p_val_lis.COUNT);
  Write_Log (' ');
  Pr_List_As_Line (p_val_lis, p_len_lis, p_indent_level);

  FOR i IN 1..p_val_lis.COUNT LOOP

    g_line_lis (i) := c_lines;

  END LOOP;
  Pr_List_As_Line (g_line_lis, p_len_lis, p_indent_level, TRUE);

END Col_Headers;

/***************************************************************************************************

Max_Len: Returns the maximum length of a list of strings

***************************************************************************************************/
FUNCTION Max_Len (p_lis L1_chr_arr) -- list of strings
                  RETURN PLS_INTEGER IS       -- maximum length
  l_Max_Len     PLS_INTEGER := 0;
BEGIN

  FOR i IN 1..p_lis.COUNT LOOP

      IF l_Max_Len < Length (p_lis(i)) THEN

        l_Max_Len := Length (p_lis(i));

      END IF;

  END LOOP;
  RETURN l_Max_Len;

END Max_Len;

/***************************************************************************************************

Max_Len: Returns a list of maximum lengths of a list of lists of strings, for each column

***************************************************************************************************/
FUNCTION Max_Len_2lis (p_2lis  L2_chr_arr) -- list of lists of strings
                      RETURN L1_num_arr IS -- list of maximum lengths
  l_Max_Len_2lis     L1_num_arr := L1_num_arr();
BEGIN

  l_Max_Len_2lis.EXTEND (p_2lis(1).COUNT);

  FOR i IN 1..p_2lis.COUNT LOOP

    FOR j IN 1..p_2lis(i).COUNT LOOP

      IF Nvl (l_Max_Len_2lis(j), 0) < Length (p_2lis(i)(j)) THEN

        l_Max_Len_2lis(j) := Length (p_2lis(i)(j));

      END IF;

    END LOOP;

  END LOOP;
  RETURN l_Max_Len_2lis;

END Max_Len_2lis;

/***************************************************************************************************

Row_To_List: Returns a list of tokens from a delimited string

***************************************************************************************************/
FUNCTION Row_To_List (p_row     VARCHAR2)     -- delimited string
                      RETURN    L1_chr_arr IS -- list of tokens
  l_start_pos   PLS_INTEGER := 1;
  l_end_pos     PLS_INTEGER;
  l_arr_index   PLS_INTEGER := 1;
  l_arr         L1_chr_arr := L1_chr_arr();
  l_row         VARCHAR2(4000) := p_row || g_list_delimiter;
BEGIN

  WHILE l_start_pos <= Length (l_row) LOOP

    l_end_pos := Instr (l_row, g_list_delimiter, 1, l_arr_index) - 1;
    IF l_end_pos < 0 THEN
      l_end_pos := Length (l_row);
    END IF;
    l_arr.EXTEND;
    l_arr (l_arr.COUNT) := Substr (l_row, l_start_pos, l_end_pos - l_start_pos + 1);
    l_start_pos := l_end_pos + 2;
    l_arr_index := l_arr_index + 1;
  END LOOP;

  RETURN l_arr;

END Row_To_List;

END Utils;
/
SHOW ERROR
