Import-Module .\powershell_utils\OracleUtils\OracleUtils
$inputPath = 'c:/input'
$fileLis = @('.\unit_test\tt_trapit.purely_wrap_outer_inp.json')

$sysSchema = 'sys'
$libSchema = 'lib'
$appSchema = 'app'

$sqlInstalls = @(@{folder = 'install_prereq';     script = 'drop_utils_users.sql';  schema = $sysSchema; prmLis = @($libSchema, $appSchema)},
                 @{folder = 'install_prereq';     script = 'install_sys.sql';       schema = $sysSchema; prmLis = @($libSchema, $appSchema, $inputPath)},
                 @{folder = 'install_prereq\lib'; script = 'install_lib_all.sql';   schema = $libSchema; prmLis = @($appSchema)},
                 @{folder = 'install_prereq\app'; script = 'c_syns_all.sql';        schema = $appSchema; prmLis = @($libSchema)},
                 @{folder = 'lib';                script = 'install_trapit.sql';    schema = $libSchema; prmLis = @($appSchema)},
                 @{folder = 'lib';                script = 'install_trapit_tt.sql'; schema = $libSchema; prmLis = @()},
                 @{folder = 'app';                script = 'c_trapit_syns.sql';     schema = $libSchema; prmLis = @($libSchema)},
                 @{folder = '.';                  script = 'l_objects.sql';         schema = $sysSchema; prmLis = @($sysSchema)},
                 @{folder = '.';                  script = 'l_objects.sql';         schema = $libSchema; prmLis = @($libSchema)},
                 @{folder = '.';                  script = 'l_objects.sql';         schema = $appSchema; prmLis = @($appSchema)})
$fileCopies = [PSCustomObject]@{inputPath = $inputPath
                                fileLis = $fileLis}
$ret = Install-OracleApp -fileCopies $fileCopies -sqlInstalls $sqlInstalls -testMode $false
Write-OracleApp $ret