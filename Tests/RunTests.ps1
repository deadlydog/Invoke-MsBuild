# Turn on Strict Mode to help catch syntax-related errors.
# 	This must come after a script's/function's param section.
# 	Forces a function to be the first non-comment code to appear in a PowerShell Module.
Set-StrictMode -Version Latest

# Clear the screen before running our tests.
cls

# Get the directory that this script is in.
$THIS_SCRIPTS_DIRECTORY = Split-Path $script:MyInvocation.MyCommand.Path

Remove-Module Invoke-MsBuild
Import-Module (Join-Path (Split-Path -Path $THIS_SCRIPTS_DIRECTORY -Parent) Invoke-MsBuild.psm1)

$pathToGoodSolution = (Join-Path $THIS_SCRIPTS_DIRECTORY "SolutionThatShouldBuildSuccessfully\SolutionThatShouldBuildSuccessfully.sln")
$pathToBrokenSolution = (Join-Path $THIS_SCRIPTS_DIRECTORY "SolutionThatShouldFailBuild\SolutionThatShouldFailBuild.sln")
$invalidPath = (Join-Path $THIS_SCRIPTS_DIRECTORY "invalid\path")

Write-Host "Build solution... Should get True"
Invoke-MsBuild -Path $pathToGoodSolution

Write-Host "Build solution via piping... Should get True"
$pathToGoodSolution | Invoke-MsBuild

Write-Host "Build multiple solutions (3) via piping... Should get True True True"
$pathToGoodSolution, $pathToGoodSolution, $pathToGoodSolution | Invoke-MsBuild

Write-Host "Build multiple solutions (3) via piping, where the 2nd one is an invalid path... Should get True ERROR True"
$pathToGoodSolution, $invalidPath, $pathToGoodSolution | Invoke-MsBuild

Write-Host "Build broken solution... Should get False"
Invoke-MsBuild -Path $pathToBrokenSolution