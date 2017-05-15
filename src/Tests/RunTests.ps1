# Turn on Strict Mode to help catch syntax-related errors.
# 	This must come after a script's/function's param section.
# 	Forces a function to be the first non-comment code to appear in a PowerShell Module.
Set-StrictMode -Version Latest

# Clear the screen before running our tests.
Clear-Host

# Get the directory that this script is in.
$THIS_SCRIPTS_DIRECTORY = Split-Path $script:MyInvocation.MyCommand.Path

# Import Invoke-MsBuild. Use -Force to make sure we reload it in case we have been making changes to it.
Import-Module -Name (Join-Path (Join-Path (Split-Path -Path $THIS_SCRIPTS_DIRECTORY -Parent) 'Invoke-MsBuild') 'Invoke-MsBuild.psm1') -Force

$pathToGoodSolution = (Join-Path $THIS_SCRIPTS_DIRECTORY "Solution That Should Build Successfully\SolutionThatShouldBuildSuccessfully.sln")
$pathToWarningSolution = (Join-Path $THIS_SCRIPTS_DIRECTORY "Solution That Should Build Successfully With Warnings\SolutionThatShouldBuildWithWarnings.sln")
$pathToBrokenSolution = (Join-Path $THIS_SCRIPTS_DIRECTORY "Solution That Should Fail Build\SolutionThatShouldFailBuild.sln")
$invalidPath = (Join-Path $THIS_SCRIPTS_DIRECTORY "invalid\path")

$testNumber = 0

Write-Host ("{0}. Build solution..." -f ++$testNumber)
$buildResult = (Invoke-MsBuild -Path $pathToGoodSolution)
if ($buildResult.BuildSucceeded -eq $true) { Write-Host ("Passed in {0:N1} seconds" -f $buildResult.BuildDuration.TotalSeconds) } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build solution with warnings..." -f ++$testNumber)
if ((Invoke-MsBuild -Path $pathToWarningSolution).BuildSucceeded -eq $true) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build solution using 32-bit MsBuild..." -f ++$testNumber)
if ((Invoke-MsBuild -Path $pathToGoodSolution -Use32BitMsBuild).BuildSucceeded -eq $true) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build solution witout using the VS Developer Command Prompt..." -f ++$testNumber)
if ((Invoke-MsBuild -Path $pathToGoodSolution -BypassVisualStudioDeveloperCommandPrompt).BuildSucceeded -eq $true) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build solution via piping..." -f ++$testNumber)
if (($pathToGoodSolution | Invoke-MsBuild).BuildSucceeded -eq $true) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build multiple solutions (3) via piping..." -f ++$testNumber)
if (($pathToGoodSolution, $pathToGoodSolution, $pathToGoodSolution | Invoke-MsBuild).BuildSucceeded -eq @($true, $true, $true)) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Build multiple solutions (3) via piping, where the 2nd one is an invalid path... Should get an ERROR and 2 Trues." -f ++$testNumber)
($pathToGoodSolution, $invalidPath, $pathToGoodSolution | Invoke-MsBuild).BuildSucceeded

Write-Host ("{0}. Build broken solution... Should see a Warning and then Passed." -f ++$testNumber)
if ((Invoke-MsBuild -Path $pathToBrokenSolution).BuildSucceeded -eq $false) { Write-Host "Passed" } else { throw "Test $testNumber failed." }

Write-Host ("{0}. Using -WhatIf switch... Should see object's properties and values." -f ++$testNumber)
Invoke-MsBuild -Path $pathToGoodSolution -WhatIf

Write-Host ("{0}. Build solution... Should see object's properties and values." -f ++$testNumber)
Invoke-MsBuild -Path $pathToGoodSolution

Write-Host ("{0}. Using -PassThru switch... Should see a few building messages." -f ++$testNumber)
$process = Invoke-MsBuild -Path $pathToGoodSolution -PassThru	
while (!$process.HasExited)
{
	Write-Host "Solution is still buildling..."
	Start-Sleep -Milliseconds 250
}

Write-Host ("{0}. Using -ShowBuildOutputInNewWindow switch... Should see a new window that shows the build progress." -f ++$testNumber)
Invoke-MsBuild -Path $pathToGoodSolution -ShowBuildOutputInNewWindow > $null

Write-Host ("{0}. Using -ShowBuildOutputInCurrentWindow switch... Should see build progress in this window (when ran from regular PowerShell console window)." -f ++$testNumber)
Invoke-MsBuild -Path $pathToGoodSolution -ShowBuildOutputInCurrentWindow > $null

Write-Host ("{0}. Build solution in parallel using MsBuild /m switch..." -f ++$testNumber)
if ((Invoke-MsBuild -Path $pathToGoodSolution -MsBuildParameters '/m').BuildSucceeded -eq $true) { Write-Host "Passed" } else { throw "Test $testNumber failed." }
