# Turn on Strict Mode to help catch syntax-related errors.
# 	This must come after a script's/function's param section.
# 	Forces a function to be the first non-comment code to appear in a PowerShell Module.
Set-StrictMode -Version Latest

# Clear the screen before running our tests.
cls

# Get the directory that this script is in.
$THIS_SCRIPTS_DIRECTORY = Split-Path $script:MyInvocation.MyCommand.Path

# Import Invoke-MsBuild. Use -Force to make sure we reload it in case we have been making changes to it.
Import-Module -Name (Join-Path (Join-Path (Split-Path -Path $THIS_SCRIPTS_DIRECTORY -Parent) 'Invoke-MsBuild') 'Invoke-MsBuild.psm1') -Force

$pathToGoodSolution = (Join-Path $THIS_SCRIPTS_DIRECTORY "SolutionThatShouldBuildSuccessfully\SolutionThatShouldBuildSuccessfully.sln")
$pathToBrokenSolution = (Join-Path $THIS_SCRIPTS_DIRECTORY "SolutionThatShouldFailBuild\SolutionThatShouldFailBuild.sln")
$invalidPath = (Join-Path $THIS_SCRIPTS_DIRECTORY "invalid\path")

$testNumber = 0

Write-Host ("{0}. Build solution..." -f ++$testNumber)
if ((Invoke-MsBuild -Path $pathToGoodSolution) -eq $true) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build solution via piping..." -f ++$testNumber)
if (($pathToGoodSolution | Invoke-MsBuild) -eq $true) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build multiple solutions (3) via piping..." -f ++$testNumber)
if (($pathToGoodSolution, $pathToGoodSolution, $pathToGoodSolution | Invoke-MsBuild) -eq @($true, $true, $true)) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build multiple solutions (3) via piping, where the 2nd one is an invalid path... Should get True ERROR True" -f ++$testNumber)
$pathToGoodSolution, $invalidPath, $pathToGoodSolution | Invoke-MsBuild

Write-Host ("{0}. Build broken solution..." -f ++$testNumber)
if ((Invoke-MsBuild -Path $pathToBrokenSolution) -eq $false) { Write-Host "Passed" } else { throw "Test $testNumber failed." }