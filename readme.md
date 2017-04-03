# Invoke-MsBuild PowerShell Module

A PowerShell module to make building projects and solutions with MsBuild easy. It provides features such as:

* Check if the build succeeded or failed
* Automatically open the build log file when the build fails
* View the build output in the current console window, a new window, or not at all
* Fire-and-forget building (via the -PassThru switch)

The module simply passes through any MsBuild command-line parameters you supply, so it supports all functionality (e.g. project types, targets, etc.) that you would get by calling MsBuild directly. The module builds using the Visual Studio Command Prompt when available in order to support more project types that MsBuild.exe alone may not support, such as XNA projects.

## Getting Started

You can either download the `Invoke-MsBuild.psm1` file from the [Releases page][ReleasesPageUrl] directly, or [install the module from the PowerShell Gallery][PowerShellGalleryPackageUrl].

Here is an example of how to import the Invoke-MsBuild module into your powershell session and call it:

```PowerShell
Import-Module -Name "C:\PathTo\Invoke-MsBuild.psm1"
Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln"
```

When the -PassThru switch is provided, the process being used to run MsBuild.exe is returned.

When the -PassThru switch is not provided, a hash table with the following properties is returned:

* BuildSucceeded = $true if the build passed, $false if the build failed, and $null if we are not sure.
* BuildLogFilePath = The path to the build's log file.
* BuildErrorsLogFilePath = The path to the build's error log file.
* ItemToBuildFilePath = The item that MsBuild ran against.
* CommandUsedToBuild = The full command that was used to invoke MsBuild. This can be useful for inspecting what parameters are passed to MsBuild.exe.
* Message = A message describing any problems that were encoutered by Invoke-MsBuild. This is typically an empty string unless something went wrong.
* MsBuildProcess = The process that was used to execute MsBuild.exe.

## Examples

```PowerShell
$buildResult = Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln"

if ($buildResult.BuildSucceeded -eq $true)
{ Write-Host "Build completed successfully." }
else if ($buildResult.BuildSucceeded -eq $false)
{ Write-Host "Build failed. Check the build log file $($buildResult.BuildLogFilePath) for errors." }
else if ($buildResult.BuildSucceeded -eq $null)
{ Write-Host "Unsure if build passed or failed: $($buildResult.Message)" }
```

Perform the default MsBuild actions on the Visual Studio solution to build the projects in it, and returns a hash table containing the results.
The PowerShell script will halt execution until MsBuild completes.

---

```PowerShell
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

```PowerShell
if ((Invoke-MsBuild -Path $pathToSolution).BuildSucceeded -eq $true)
{
    Write-Host "Build completed successfully."
}
```

Perfom the build against the file specified at $pathToSolution and checks it for success in a single line.

---

```PowerShell
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -MsBuildParameters "/target:Clean;Build" -ShowBuildOutputInNewWindow
```

Cleans then Builds the given C# project.
A window displaying the output from MsBuild will be shown so the user can view the progress of the build.

---

```PowerShell
Invoke-MsBuild -Path "C:\MySolution.sln" -Params "/target:Clean;Build /property:Configuration=Release;Platform=x64;BuildInParallel=true /verbosity:Detailed /maxcpucount"
```

Cleans then Builds the given solution, specifying to build the project in parallel in the Release configuration for the x64 platform.
Here the shorter "Params" alias is used instead of the full "MsBuildParameters" parameter name.

---

```PowerShell
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -ShowBuildOutputInNewWindow -PromptForInputBeforeClosing -AutoLaunchBuildLogOnFailure
```

Builds the given C# project.
A window displaying the output from MsBuild will be shown so the user can view the progress of the build, and it will not close until the user
gives the window some input after the build completes. This function will also not return until the user gives the window some input, halting the powershell script execution.
If the build fails, the build log will automatically be opened in the default text viewer.

---

```PowerShell
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath "C:\BuildLogs" -KeepBuildLogOnSuccessfulBuilds -AutoLaunchBuildErrorsLogOnFailure
```

Builds the given C# project.
The build log will be saved in "C:\BuildLogs", and they will not be automatically deleted even if the build succeeds.
If the build fails, the build errors log will automatically be opened in the default text viewer.

---

```PowerShell
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath PathDirectory
```

Builds the given C# project.
The keyword 'PathDirectory' is used, so the build log will be saved in "C:\Some Folder\", which is the same directory as the project being built (i.e. directory specified in the Path).

---

```PowerShell
Invoke-MsBuild -Path "C:\Database\Database.dbproj" -P "/t:Deploy /p:TargetDatabase=MyDatabase /p:TargetConnectionString=`"Data Source=DatabaseServerName`;Integrated Security=True`;Pooling=False`" /p:DeployToDatabase=True"
```

Deploy the Visual Studio Database Project to the database "MyDatabase".
Here the shorter "P" alias is used instead of the full "MsBuildParameters" parameter name.
The shorter alias' of the MsBuild parameters are also used; "/t" instead of "/target", and "/p" instead of "/property".

---

```PowerShell
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -WhatIf
```

Returns the result object containing the same property values that would be created if the build was ran with the same parameters.
The BuildSucceeded property will be $null since no build will actually be invoked.
This will display all of the returned object's properties and their values.

---

```PowerShell
Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" > $null
```

Builds the given C# project, discarding the result object and not displaying its properties.

## Full Documentation

Once the module has been imported, you can access the the latest documention in PowerShell by using `Get-Help Invoke-MsBuild -Full`, or just [look at the file in source control here][DocumentationInSourceControlFileUrl].

[ReleasesPageUrl]:https://github.com/deadlydog/Invoke-MsBuild/releases
[PowerShellGalleryPackageUrl]:https://www.powershellgallery.com/packages/Invoke-MsBuild/
[DocumentationInSourceControlFileUrl]:https://github.com/deadlydog/Invoke-MsBuild/blob/master/src/Invoke-MsBuild/Invoke-MsBuild.psm1#L6