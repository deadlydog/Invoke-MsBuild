# Project Description
A PowerShell module to make building projects and solutions with MsBuild easy. It provides features such as:
* Check if the build succeeded or failed
* Automatically open the build log file when the build fails
* View the build output in the current console window, a new window, or not at all
* Fire-and-forget building (via the -PassThru switch)

The module simply passes through any MsBuild command-line parameters you supply, so it supports all functionality (e.g. project types, targets, etc.) that you would get by calling MsBuild directly. The module builds using the Visual Studio Command Prompt when available in order to support more project types that MsBuild.exe alone may not support, such as XNA projects.

# Getting Started
You can either download the `Invoke-MsBuild.psm1` file from the [Releases page](https://github.com/deadlydog/Invoke-MsBuild/releases) directly, or [install the module from the PowerShell Gallery](https://www.powershellgallery.com/packages/Invoke-MsBuild/).

Here is an example of how to import the Invoke-MsBuild module into your powershell session and call it:

```
Import-Module -Name "C:\PathTo\Invoke-MsBuild.psm1"
Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln"
```

When the -PassThru switch is provided, the process being used to run MsBuild.exe is returned.

When the -PassThru switch is not provided, a hash table with the following properties is returned:

* BuildSucceeded = $true if the build passed, $false if the build failed, and $null if we are not sure.
* BuildLogFilePath = The path to the build's log file.
* BuildErrorsLogFilePath = The path to the build's error log file.
* ItemToBuildFilePath = The item that MsBuild is ran against.
* CommandUsedToBuild = The full command that is used to invoke MsBuild. This can be useful for inspecting what parameters are passed to MsBuild.exe.
* Message = A message describing any problems that were encoutered by Invoke-MsBuild. This is typically an empty string unless something went wrong.
* MsBuildProcess = The process that was used to execute MsBuild.exe.

# Examples

```
$buildResult = Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln"

if ($buildResult.BuildSucceeded -eq $true)
{ Write-Host "Build completed successfully." }
else if (!$buildResult.BuildSucceeded -eq $false)
{ Write-Host "Build failed. Check the build log file $($buildResult.BuildLogFilePath) for errors." }
else if ($buildResult.BuildSucceeded -eq $null)
{ Write-Host "Unsure if build passed or failed: $($buildResult.Message)" }
```

Perform the default MsBuild actions on the Visual Studio solution to build the projects in it, and returns a hash table containing the results.
The PowerShell script will halt execution until MsBuild completes.

---

```
$process = Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln" -PassThru

while (!$process.HasExited)
{
    Write-Host "Solution is still buildling..."
    Start-Sleep -Seconds 1
}
```

Perform the default MsBuild actions on the Visual Studio solution to build the projects in it.
The PowerShell script will not halt execution; instead it will return the process running MsBuild.exe back to the caller while the build is performed.
You can check the process's HasExited property to check if the build has completed yet or not.

---

```
if ((Invoke-MsBuild -Path $pathToSolution).BuildSucceeded -eq $true)
{
    Write-Host "Build completed successfully."
}
```
Perfom the build against the file specified at $pathToSolution and checks it for success in a single line.

---

```
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -MsBuildParameters "/target:Clean;Build" -ShowBuildOutputInNewWindow
```

Cleans then Builds the given C# project.
A window displaying the output from MsBuild will be shown so the user can view the progress of the build.

---

```
Invoke-MsBuild -Path "C:\MySolution.sln" -Params "/target:Clean;Build /property:Configuration=Release;Platform=x64;BuildInParallel=true /verbosity:Detailed /maxcpucount"
```

Cleans then Builds the given solution, specifying to build the project in parallel in the Release configuration for the x64 platform.
Here the shorter "Params" alias is used instead of the full "MsBuildParameters" parameter name.

---

```
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -ShowBuildOutputInNewWindow -PromptForInputBeforeClosing -AutoLaunchBuildLogOnFailure
```

Builds the given C# project.
A window displaying the output from MsBuild will be shown so the user can view the progress of the build, and it will not close until the user
gives the window some input after the build completes. This function will also not return until the user gives the window some input, halting the powershell script execution.
If the build fails, the build log will automatically be opened in the default text viewer.

---

```
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath "C:\BuildLogs" -KeepBuildLogOnSuccessfulBuilds -AutoLaunchBuildErrorsLogOnFailure
```

Builds the given C# project.
The build log will be saved in "C:\BuildLogs", and they will not be automatically deleted even if the build succeeds.
If the build fails, the build errors log will automatically be opened in the default text viewer.

---

```
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath PathDirectory
```

Builds the given C# project.
The keyword 'PathDirectory' is used, so the build log will be saved in "C:\Some Folder\", which is the same directory as the project being built (i.e. directory specified in the Path).

---

```
Invoke-MsBuild -Path "C:\Database\Database.dbproj" -P "/t:Deploy /p:TargetDatabase=MyDatabase /p:TargetConnectionString=`"Data Source=DatabaseServerName`;Integrated Security=True`;Pooling=False`" /p:DeployToDatabase=True"
```

Deploy the Visual Studio Database Project to the database "MyDatabase".
Here the shorter "P" alias is used instead of the full "MsBuildParameters" parameter name.
The shorter alias' of the MsBuild parameters are also used; "/t" instead of "/target", and "/p" instead of "/property".

---

```
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -WhatIf
```

Returns the result object containing the same property values that would be created if the build was ran with the same parameters.
The BuildSucceeded property will be $null since no build will actually be invoked.
This will display all of the returned object's properties and their values.

---

```
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" > $null
```

Builds the given C# project, discarding the result object and not displaying its properties.

# Full Documentation

Below is the module's help information. Once the module has been imported, this can also be accessed in PowerShell by using `Get-Help Invoke-MsBuild -Full`.

	.SYNOPSIS
	Builds the given Visual Studio solution or project file using MsBuild.
	
	.DESCRIPTION
	Executes the MsBuild.exe tool against the specified Visual Studio solution or project file.
	Returns a hash table with properties for determining if the build succeeded or not, as well as other information (see the OUTPUTS section for list of properties).
	If using the PathThru switch, the process running MsBuild is returned instead.
	
	.PARAMETER Path
	The path of the Visual Studio solution or project to build (e.g. a .sln or .csproj file).
	
	.PARAMETER MsBuildParameters
	Additional parameters to pass to the MsBuild command-line tool. This can be any valid MsBuild command-line parameters except for the path of 
	the solution/project to build.
	
	See http://msdn.microsoft.com/en-ca/library/vstudio/ms164311.aspx for valid MsBuild command-line parameters.
	
	.PARAMETER Use32BitMsBuild
	If this switch is provided, the 32-bit version of MsBuild.exe will be used instead of the 64-bit version when both are available.
	
	.PARAMETER BuildLogDirectoryPath
	The directory path to write the build log files to.
	Defaults to putting the log files in the users temp directory (e.g. C:\Users\[User Name]\AppData\Local\Temp).
	Use the keyword "PathDirectory" to put the log files in the same directory as the .sln or project file being built.
	Two log files are generated: one with the complete build log, and one that contains only errors from the build.
	
	.PARAMETER AutoLaunchBuildLogOnFailure
	If set, this switch will cause the build log to automatically be launched into the default viewer if the build fails.
	This log file contains all of the build output.
	NOTE: This switch cannot be used with the PassThru switch.
	
	.PARAMETER AutoLaunchBuildErrorsLogOnFailure
	If set, this switch will cause the build errors log to automatically be launched into the default viewer if the build fails.
	This log file only contains errors from the build output.
	NOTE: This switch cannot be used with the PassThru switch.
	
	.PARAMETER KeepBuildLogOnSuccessfulBuilds
	If set, this switch will cause the MsBuild log file to not be deleted on successful builds; normally it is only kept around on failed builds.
	NOTE: This switch cannot be used with the PassThru switch.
	
	.PARAMETER ShowBuildOutputInNewWindow
	If set, this switch will cause a command prompt window to be shown in order to view the progress of the build.
	By default the build output is not shown in any window.
	NOTE: This switch cannot be used with the ShowBuildOutputInCurrentWindow switch.
	
	.PARAMETER ShowBuildOutputInCurrentWindow
	If set, this switch will cause the build process to be started in the existing console window, instead of creating a new one.
	By default the build output is not shown in any window.
	NOTE: This switch will override the ShowBuildOutputInNewWindow switch.
	NOTE: There is a problem with the -NoNewWindow parameter of the Start-Process cmdlet; this is used for the ShowBuildOutputInCurrentWindow switch.
		  The bug is that in some PowerShell consoles, the build output is not directed back to the console calling this function, so nothing is displayed.
		  To avoid the build process from appearing to hang, PromptForInputBeforeClosing only has an effect with ShowBuildOutputInCurrentWindow when running 
		  in the default "ConsoleHost" PowerShell console window, as we know it works properly with that console (it does not in other consoles like ISE, PowerGUI, etc.).
	
	.PARAMETER PromptForInputBeforeClosing
	If set, this switch will prompt the user for input after the build completes, and will not continue until the user presses a key.
	NOTE: This switch only has an effect when used with the ShowBuildOutputInNewWindow and ShowBuildOutputInCurrentWindow switches (otherwise build output is not displayed).
	NOTE: This switch cannot be used with the PassThru switch.
	NOTE: The user will need to provide input before execution will return back to the calling script (so do not use this switch for automated builds).
	NOTE: To avoid the build process from appearing to hang, PromptForInputBeforeClosing only has an effect with ShowBuildOutputInCurrentWindow when running 
		  in the default "ConsoleHost" PowerShell console window, as we know it works properly with that console (it does not in other consoles like ISE, PowerGUI, etc.).

	.PARAMETER PassThru
	If set, this switch will cause the calling script not to wait until the build (launched in another process) completes before continuing execution.
	Instead the build will be started in a new process and that process will immediately be returned, allowing the calling script to continue 
	execution while the build is performed, and also to inspect the process to see when it completes.
	NOTE: This switch cannot be used with the AutoLaunchBuildLogOnFailure, AutoLaunchBuildErrorsLogOnFailure, KeepBuildLogOnSuccessfulBuilds, or PromptForInputBeforeClosing switches.
	
	.PARAMETER WhatIf
	If set, the build will not actually be performed.
	Instead it will just return the result object containing the file paths that would be created if the build is performed with the same parameters.
	
	.OUTPUTS
	
	When the -PassThru switch is provided, the process being used to run MsBuild.exe is returned.
	When the -PassThru switch is not provided, a hash table with the following properties is returned:
	
	BuildSucceeded = $true if the build passed, $false if the build failed, and $null if we are not sure.
	BuildLogFilePath = The path to the build's log file.
	BuildErrorsLogFilePath = The path to the build's error log file.
	ItemToBuildFilePath = The item that MsBuild is ran against.
	CommandUsedToBuild = The full command that is used to invoke MsBuild. This can be useful for inspecting what parameters are passed to MsBuild.exe.
	Message = A message describing any problems that were encoutered by Invoke-MsBuild. This is typically an empty string unless something went wrong.
	MsBuildProcess = The process that was used to execute MsBuild.exe.
	
	.EXAMPLE
	$buildResult = Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln"
	
	if ($buildResult.BuildSucceeded -eq $true)
	{ Write-Host "Build completed successfully." }
	else if (!$buildResult.BuildSucceeded -eq $false)
	{ Write-Host "Build failed. Check the build log file $($buildResult.BuildLogFilePath) for errors." }
	else if ($buildResult.BuildSucceeded -eq $null)
	{ Write-Host "Unsure if build passed or failed: $($buildResult.Message)" }
	
	Perform the default MsBuild actions on the Visual Studio solution to build the projects in it, and returns a hash table containing the results.
	The PowerShell script will halt execution until MsBuild completes.
	
	.EXAMPLE
	$process = Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln" -PassThru
	
	while (!$process.HasExited)
	{
		Write-Host "Solution is still buildling..."
		Start-Sleep -Seconds 1
	}
	
	Perform the default MsBuild actions on the Visual Studio solution to build the projects in it.
	The PowerShell script will not halt execution; instead it will return the process running MsBuild.exe back to the caller while the build is performed.
	You can check the process's HasExited property to check if the build has completed yet or not.
	
	.EXAMPLE
	
	if ((Invoke-MsBuild -Path $pathToSolution).BuildSucceeded -eq $true)
	{
		Write-Host "Build completed successfully."
	}
	
	Perfom the build against the file specified at $pathToSolution and checks it for success in a single line.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -MsBuildParameters "/target:Clean;Build" -ShowBuildOutputInNewWindow
	
	Cleans then Builds the given C# project.
	A window displaying the output from MsBuild will be shown so the user can view the progress of the build.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\MySolution.sln" -Params "/target:Clean;Build /property:Configuration=Release;Platform=x64;BuildInParallel=true /verbosity:Detailed /maxcpucount"
	
	Cleans then Builds the given solution, specifying to build the project in parallel in the Release configuration for the x64 platform.
	Here the shorter "Params" alias is used instead of the full "MsBuildParameters" parameter name.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -ShowBuildOutputInNewWindow -PromptForInputBeforeClosing -AutoLaunchBuildLogOnFailure
	
	Builds the given C# project.
	A window displaying the output from MsBuild will be shown so the user can view the progress of the build, and it will not close until the user
	gives the window some input after the build completes. This function will also not return until the user gives the window some input, halting the powershell script execution.
	If the build fails, the build log will automatically be opened in the default text viewer.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath "C:\BuildLogs" -KeepBuildLogOnSuccessfulBuilds -AutoLaunchBuildErrorsLogOnFailure
	
	Builds the given C# project.
	The build log will be saved in "C:\BuildLogs", and they will not be automatically deleted even if the build succeeds.
	If the build fails, the build errors log will automatically be opened in the default text viewer.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath PathDirectory
	
	Builds the given C# project.
	The keyword 'PathDirectory' is used, so the build log will be saved in "C:\Some Folder\", which is the same directory as the project being built (i.e. directory specified in the Path).
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Database\Database.dbproj" -P "/t:Deploy /p:TargetDatabase=MyDatabase /p:TargetConnectionString=`"Data Source=DatabaseServerName`;Integrated Security=True`;Pooling=False`" /p:DeployToDatabase=True"
	
	Deploy the Visual Studio Database Project to the database "MyDatabase".
	Here the shorter "P" alias is used instead of the full "MsBuildParameters" parameter name.
	The shorter alias' of the MsBuild parameters are also used; "/t" instead of "/target", and "/p" instead of "/property".
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -WhatIf
	
	Returns the result object containing the same property values that would be created if the build was ran with the same parameters.
	The BuildSucceeded property will be $null since no build will actually be invoked.
	This will display all of the returned object's properties and their values.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" > $null
	
	Builds the given C# project, discarding the result object and not displaying its properties.
	
	.LINK
	Project home: https://github.com/deadlydog/Invoke-MsBuild
	
	.NOTES
	Name:   Invoke-MsBuild
	Author: Daniel Schroeder (originally based on the module at http://geekswithblogs.net/dwdii/archive/2011/05/27/part-2-automating-a-visual-studio-build-with-powershell.aspx)
	Version: 2.1.0
