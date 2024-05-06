# uncomment first element to have schema dropped and re-created
$installs = @(#@{folder = 'install_prereq'; script = 'drop_utils_users'; schema = 'sys'},
              @{folder = 'install_prereq'; script = 'install_sys'; schema = 'sys'},
              @{folder = 'install_prereq\lib'; script = 'install_utils'; schema = 'lib'},
              @{folder = 'install_prereq\app'; script = 'c_syns_all'; schema = 'app'},
              @{folder = 'lib'; script = 'install_trapit'; schema = 'lib'},
              @{folder = 'app'; script = 'c_trapit_syns'; schema = 'app'})
$installs

Foreach($i in $installs){
    sl ($PSScriptRoot + '/' + $i.folder)
    $script = '@./' + $i.script
    $sysdba = ''
    if ($i.schema -eq 'sys') {
        $sysdba = ' AS SYSDBA'
    }
    $conn = $i.schema + '/' + $i.schema + '@orclpdb' + $sysdba
    'Executing: ' + $script + ' for connection ' + $conn
    if ($i.script -eq 'install_utils' -or $i.script -eq 'install_trapit') {
        $schema = 'app'
    } elseif ($i.script -eq 'c_syns_all' -or $i.script -eq 'c_trapit_syns') {
        $schema = 'lib'
    } else {
        $schema = ''
    }
    & sqlplus $conn $script $schema
}
sl $PSScriptRoot
