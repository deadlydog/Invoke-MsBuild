# Changelog

## v2.7.1 - December 11, 2021

Fixes:

- Compare MSBuild version numbers in other languages correctly.

## v2.7.0 - December 11, 2021

Features:

- Add support for 64-bit Visual Studio versions (e.g. VS 2022).

## v2.6.5 - October 29, 2020

Fixes:

- Fix wrong variable name so that the `AutoLaunchBuildErrorsLogOnFailure` parameter is obeyed properly.

## v2.6.4 - February 1, 2019

Fixes:

- Fix hanging indefinitely when waiting for build process to complete.

## v2.6.3 - February 1, 2019

Fixes:

- Fix not handling 32-bit switch correctly.

## v2.6.2 - July 2, 2018

Fixes:

- Use native -WhatIf parameter functionality.

## v2.6.1 - May 1, 2018

Fixes:

- Use `-LiteralPath` parameter for cmdlets to properly support file paths with symbols (e.g. square brackets in file paths).

## v2.6.0 - May 14, 2017

Features:

- Added a BypassVisualStudioDeveloperCommandPrompt parameter to allow the Visual Studio Developer Command Prompt to be bypassed, as it can sometimes take a long time to load, leading to a performance problem.
- Improved the file path validations performed on the scripts parameters.

## v2.5.1 - April 22, 2017

Fixes:

- Fix to find the "Program Files" location correctly on 32 bit windows without throwing an error.

## v2.5.0 - April 21, 2017

Features:

- Added new BuildDuration TimeSpan property to the returned hash table that shows how long the build ran for.

## v2.4.2 - April 20, 2017

Fixes:

- Fixed bug where MsBuild.exe would not be found on 32-bit Windows OSs.

## v2.4.1 - April 20, 2017

Fixes:

- Fixed "CurrentCulture is a ReadOnly property" bug on computers running .Net 4.5.2 and lower.

## v2.4.0 - April 1, 2017

Features:

- Added MsBuildFilePath and VisualStudioDeveloperCommandPromptFilePath script parameters, so users can pass in which versions they would like to use, instead of the script using the latest versions.

Fixes:

- Fixed inverted bool logic that was causing the VS Command Prompt to never be used.

## v2.3.1 - April 1, 2017

Fixes:

- Fixes to truly support VS 2017 MsBuild.

## v2.3.0 - March 20, 2017

Features:

- Added support to find and use Visual Studio 2017's MsBuild.exe.

## v2.2.0 - March 30, 2017

Features:

- Added LogVerbosityLevel parameter to adjust the verbosity MsBuild uses to write to the log file.

Fixes:

- Fixed bug that prevented us from finding msbuild.exe on some machines.

## v2.1.0 - September 20, 2016

Features:

- Added new Use32BitMsBuild parameter to allow users to force the 32-bit version of MsBuild.exe to be used instead of the 64-bit version when both are available.

## v2.0.0 - May 25, 2016

Breaking Changes from v1:

- A hash table with several properties is returned instead of a simple $true/$false/$null value.
- The `GetLogPath` switch is gone and replaced with the `WhatIf` switch.

Features:

- A build log file containing only build errors is created alongside the regular build log file.
- The errors build log file can be auto-launched on build failure.
- New switch has been added to show the build output in the calling scripts console window (does not work with some 3rd party - consoles due to Start-Process cmdlet bug).
- A hash table containing the following properties is now returned:
- BuildSucceeded = $true if the build passed, $false if the build failed, and $null if we are not sure.
- BuildLogFilePath = The path to the builds log file.
- BuildErrorsLogFilePath = The path to the builds error log file.
- ItemToBuildFilePath = The item that MsBuild is ran against.
- CommandUsedToBuild = The full command that is used to invoke MsBuild. This can be useful for inspecting what parameters are - passed to MsBuild.exe.
- Message = A message describing any problems that were encountered by Invoke-MsBuild. This is typically an empty string unless - something went wrong.
- MsBuildProcess = The process that was used to execute MsBuild.exe.

Changes to make when updating from v1 to v2:

- To capture/display the build success result, you must change `Invoke-MsBuild ...` to `(Invoke-MsBuild ...).BuildSucceeded`.
- To get the path where the log file will be created, you must change `Invoke-MsBuild ... -GetLogPath` to `(Invoke-MsBuild ... -WhatIf).BuildLogFilePath`.
