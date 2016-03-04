# Get the directory that this script is in.
$THIS_SCRIPTS_DIRECTORY = Split-Path $script:MyInvocation.MyCommand.Path

$moduleDirectory = Join-Path $THIS_SCRIPTS_DIRECTORY 'Invoke-MsBuild'

Publish-Module -Path $moduleDirectory