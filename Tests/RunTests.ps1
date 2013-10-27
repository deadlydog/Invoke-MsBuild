# Turn on Strict Mode to help catch syntax-related errors.
# 	This must come after a script's/function's param section.
# 	Forces a function to be the first non-comment code to appear in a PowerShell Module.
Set-StrictMode -Version Latest

# Get the directory that this script is in.
$THIS_SCRIPTS_DIRECTORY = Split-Path $script:MyInvocation.MyCommand.Path

Remove-Module Invoke-MsBuild
Import-Module (Join-Path (Split-Path -Path $THIS_SCRIPTS_DIRECTORY -Parent) Invoke-MsBuild.psm1)

$path = (Join-Path $THIS_SCRIPTS_DIRECTORY "Test/Test.sln")
$invalidPath = (Join-Path $THIS_SCRIPTS_DIRECTORY "invalid/path")

Write-Host "Build solution..."
Invoke-MsBuild -Path $path

Write-Host "Build solution via piping..."
$path | Invoke-MsBuild

Write-Host "Build multiple solutions (3) via piping..."
$path, $path, $path | Invoke-MsBuild

Write-Host "Build multiple solutions (3) via piping, where the 2nd one is an invalid path..."
$path, $invalidPath, $path | Invoke-MsBuild