Import-Module ..\powershell_utils\TrapitUtils\TrapitUtils
Test-FormatDB 'lib/lib' 'orclpdb' 'trapit' $PSScriptRoot `
'BEGIN
    Utils.g_w_is_active := FALSE;
END;
/
'
