#Requires -Version 2.0



# TODO:
#	- Change to return object with properties: [bool]BuildSucceeded, [string]MsBuildLogFilePath, [string]MsBuildErrorLogFilePath, [Process]MsBuildProcess
#	- Instead of GetLogPath, just have a -WhatIf switch that returns the log file paths and defaults/nulls the rest.



function Invoke-MsBuild
{
<#
	.SYNOPSIS
	Builds the given Visual Studio solution or project file using MSBuild.
	
	.DESCRIPTION
	Executes the MSBuild.exe tool against the specified Visual Studio solution or project file.
	Returns true if the build succeeded, false if the build failed, and null if we could not determine the build result.
	If using the PathThru switch, the process running MSBuild is returned instead.
	
	.PARAMETER Path
	The path of the Visual Studio solution or project to build (e.g. a .sln or .csproj file).
	
	.PARAMETER MsBuildParameters
	Additional parameters to pass to the MsBuild command-line tool. This can be any valid MsBuild command-line parameters except for the path of 
	the solution/project to build.
	
	See http://msdn.microsoft.com/en-ca/library/vstudio/ms164311.aspx for valid MsBuild command-line parameters.
	
	.PARAMETER $BuildLogDirectoryPath
	The directory path to write the build log files to.
	Defaults to putting the log files in the users temp directory (e.g. C:\Users\[User Name]\AppData\Local\Temp).
	Use the keyword "PathDirectory" to put the log files in the same directory as the .sln or project file being built.
	Two log files are generated: one with the complete build log, and one that contains only errors from the build.
	
	.PARAMETER AutoLaunchBuildLog
	If set, this switch will cause the build log to automatically be launched into the default viewer if the build fails.
	NOTE: This switch cannot be used with the PassThru switch.
	
	.PARAMETER KeepBuildLogOnSuccessfulBuilds
	If set, this switch will cause the msbuild log file to not be deleted on successful builds; normally it is only kept around on failed builds.
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
		  To avoid the process from appearing to hang, PromptForInputBeforeClosing only has an effect with ShowBuildOutputInCurrentWindow when running 
		  in the default "ConsoleHost" PowerShell console window, as we know it works properly with this console (not others, like ISE, etc.).
	
	.PARAMETER PromptForInputBeforeClosing
	If set, this switch will prompt the user for input after the build completes, and will not continue until the user presses a key.
	NOTE: This switch only has an effect when used with the ShowBuildOutputInNewWindow and ShowBuildOutputInCurrentWindow switches.
	NOTE: This switch cannot be used with the PassThru switch.
	NOTE: The user will need to provide input before execution will return back to the calling script.
	NOTE: To avoid the process from appearing to hang, PromptForInputBeforeClosing only has an effect with ShowBuildOutputInCurrentWindow when running 
		  in the default "ConsoleHost" PowerShell console window, as we know it works properly with this console (not others, like ISE, etc.).

	.PARAMETER PassThru
	If set, this switch will cause the script not to wait until the build (launched in another process) completes before continuing execution.
	Instead the build will be started in a new process and that process will immediately be returned, allowing the calling script to continue 
	execution while the build is performed, and also to inspect the process to see when it completes.
	NOTE: This switch cannot be used with the AutoLaunchBuildLog, KeepBuildLogOnSuccessfulBuilds, or PromptForInputBeforeClosing switches.
	
	.PARAMETER GetLogPath
	If set, the build will not actually be performed.
	Instead it will just return the full path of the MsBuild Log file that would be created if the build is performed with the same parameters.
	
	.OUTPUTS
	When the -PassThru switch is not provided, a boolean value is returned; $true indicates that MsBuild completed successfully, $false indicates 
	that MsBuild failed with errors (or that something else went wrong), and $null indicates that we were unable to determine if the build succeeded or failed.
	
	When the -PassThru switch is provided, the process being used to run the build is returned.
	
	.EXAMPLE
	$buildSucceeded = Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln"
	
	if ($buildSucceeded)
	{ Write-Host "Build completed successfully." }
	else
	{ Write-Host "Build failed. Check the build log file for errors." }
	
	Perform the default MSBuild actions on the Visual Studio solution to build the projects in it, and returns whether the build succeeded or failed.
	The PowerShell script will halt execution until MsBuild completes.
	
	.EXAMPLE
	$process = Invoke-MsBuild -Path "C:\Some Folder\MySolution.sln" -PassThru
	
	Perform the default MSBuild actions on the Visual Studio solution to build the projects in it.
	The PowerShell script will not halt execution; instead it will return the process performing MSBuild actions back to the caller while the action is performed.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -MsBuildParameters "/target:Clean;Build" -ShowBuildOutputInNewWindow
	
	Cleans then Builds the given C# project.
	A window displaying the output from MsBuild will be shown so the user can view the progress of the build.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\MySolution.sln" -Params "/target:Clean;Build /property:Configuration=Release;Platform=x64;BuildInParallel=true /verbosity:Detailed /maxcpucount"
	
	Cleans then Builds the given solution, specifying to build the project in parallel in the Release configuration for the x64 platform.
	Here the shorter "Params" alias is used instead of the full "MsBuildParameters" parameter name.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -ShowBuildOutputInNewWindow -PromptForInputBeforeClosing -AutoLaunchBuildLog
	
	Builds the given C# project.
	A window displaying the output from MsBuild will be shown so the user can view the progress of the build, and it will not close until the user
	gives the window some input. This function will also not return until the user gives the window some input, halting the powershell script execution.
	If the build fails, the build log will automatically be opened in the default text viewer.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath "C:\BuildLogs" -KeepBuildLogOnSuccessfulBuilds -AutoLaunchBuildLog
	
	Builds the given C# project.
	The build log will be saved in "C:\BuildLogs", and they will not be automatically deleted even if the build succeeds.
	If the build fails, the build log will automatically be opened in the default text viewer.
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath PathDirectory
	
	Builds the given C# project.
	The build log will be saved in "C:\Some Folder\", which is the same directory as the project being built (i.e. directory specified in the Path).
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Database\Database.dbproj" -P "/t:Deploy /p:TargetDatabase=MyDatabase /p:TargetConnectionString=`"Data Source=DatabaseServerName`;Integrated Security=True`;Pooling=False`" /p:DeployToDatabase=True"
	
	Deploy the Visual Studio Database Project to the database "MyDatabase".
	Here the shorter "P" alias is used instead of the full "MsBuildParameters" parameter name.
	The shorter alias' of the msbuild parameters are also used; "/t" instead of "/target", and "/p" instead of "/property".
	
	.EXAMPLE
	Invoke-MsBuild -Path "C:\Some Folder\MyProject.csproj" -BuildLogDirectoryPath "C:\BuildLogs" -GetLogPath
	
	Returns the full path to the MsBuild Log file that would be created if the build was ran with the same parameters.
	In this example the returned log path might be "C:\BuildLogs\MyProject.msBuildLog.txt".
	If the BuildLogDirectoryPath was not provided, the returned log path might be "C:\Some Folder\MyProject.msBuildLog.txt".
	
	.LINK
	Project home: https://invokemsbuild.codeplex.com
	
	.NOTES
	Name:   Invoke-MsBuild
	Author: Daniel Schroeder (originally based on the module at http://geekswithblogs.net/dwdii/archive/2011/05/27/part-2-automating-a-visual-studio-build-with-powershell.aspx)
	Version: 2.0.0
#>
	[CmdletBinding(DefaultParameterSetName="Wait")]
	param
	(
		[parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true,HelpMessage="The path to the file to build with MsBuild (e.g. a .sln or .csproj file).")]
		[ValidateScript({Test-Path $_})]
		[string] $Path,

		[parameter(Mandatory=$false)]
		[Alias("Params","P")]
		[string] $MsBuildParameters,

		[parameter(Mandatory=$false,HelpMessage="The directory path to write the build log file to. Use the keyword 'PathDirectory' to put the log file in the same directory as the .sln or project file being built.")]
		[ValidateNotNullOrEmpty()]
		[Alias("L")]
		[string] $BuildLogDirectoryPath = $env:Temp,

		[parameter(Mandatory=$false,ParameterSetName="Wait")]
		[ValidateNotNullOrEmpty()]
		[Alias("AutoLaunch","A")]
		[switch] $AutoLaunchBuildLogOnFailure,

		[parameter(Mandatory=$false,ParameterSetName="Wait")]
		[ValidateNotNullOrEmpty()]
		[Alias("Keep","K")]
		[switch] $KeepBuildLogOnSuccessfulBuilds,

		[parameter(Mandatory=$false)]
		[Alias("ShowBuildWindow","Show","S")]
		[switch] $ShowBuildOutputInNewWindow,

		[parameter(Mandatory=$false)]
		[switch] $ShowBuildOutputInCurrentWindow,

		[parameter(Mandatory=$false,ParameterSetName="Wait")]
		[Alias("Prompt")]
		[switch] $PromptForInputBeforeClosing,

		[parameter(Mandatory=$false,ParameterSetName="PassThru")]
		[switch] $PassThru,

		[parameter(Mandatory=$false)]
		[Alias("Get","G")]
		[switch] $GetLogPath
	)

	BEGIN { }
	END { }
	PROCESS
	{
		# Turn on Strict Mode to help catch syntax-related errors.
		# 	This must come after a script's/function's param section.
		# 	Forces a function to be the first non-comment code to appear in a PowerShell Script/Module.
		Set-StrictMode -Version Latest

        # Default the ParameterSet variables that may not have been set depending on which parameter set is being used. This is required for PowerShell v2.0 compatibility.
        if (!(Test-Path Variable:Private:AutoLaunchBuildLogOnFailure)) { $AutoLaunchBuildLogOnFailure = $false }
        if (!(Test-Path Variable:Private:KeepBuildLogOnSuccessfulBuilds)) { $KeepBuildLogOnSuccessfulBuilds = $false }
        if (!(Test-Path Variable:Private:PassThru)) { $PassThru = $false }
        if (!(Test-Path Variable:Private:ShowBuildOutputInCurrentWindow)) { $ShowBuildOutputInCurrentWindow = $false }

		# If the keyword was supplied, place the log in the same folder as the solution/project being built.
		if ($BuildLogDirectoryPath.Equals("PathDirectory", [System.StringComparison]::InvariantCultureIgnoreCase))
		{
			$BuildLogDirectoryPath = [System.IO.Path]::GetDirectoryName($Path)
		}
		
		# Always get the full path to the Log files directory.
		$BuildLogDirectoryPath = [System.IO.Path]::GetFullPath($BuildLogDirectoryPath)

		# Store the VS Command Prompt to do the build in, if one exists.
		$vsCommandPrompt = Get-VisualStudioCommandPromptPath

		# Local Variables.
		$solutionFileName = (Get-ItemProperty -Path $Path).Name
		$buildLogFilePath = (Join-Path -Path $BuildLogDirectoryPath -ChildPath $solutionFileName) + ".msBuildLog.txt"
		$buildErrorsLogPath = (Join-Path -Path $BuildLogDirectoryPath -ChildPath $solutionFileName) + ".msBuildLog.errors.txt"
		$windowStyleOfNewWindow = if ($ShowBuildOutputInNewWindow) { "Normal" } else { "Hidden" }
		$buildCrashed = $false;

		# If all we want is the path to the Log file that will be generated, return it.
		if ($GetLogPath)
		{
			return $buildLogFilePath
		}

		# Try and build the solution.
		try
		{
			# Build the arguments to pass to MsBuild.
			$buildArguments = """$Path"" $MsBuildParameters /fileLoggerParameters:LogFile=""$buildLogFilePath"" /fileLoggerParameters1:LogFile=""$buildErrorsLogPath"";errorsonly"

			# If the user hasn't set the UseSharedCompilation mode explicitly, turn it off (it's on by default, but can cause msbuild to hang for some reason).
			if ($buildArguments -notlike '*UseSharedCompilation*')
			{
				$buildArguments += " /p:UseSharedCompilation=false " # prevent processes from hanging (Roslyn compiler?)
			}

			# If a VS Command Prompt was found, call MSBuild from that since it sets environmental variables that may be needed to build some projects.
			if ($vsCommandPrompt -ne $null)
			{
				$cmdArgumentsToRunMsBuild = "/k "" ""$vsCommandPrompt"" & msbuild "
			}
			# Else the VS Command Prompt was not found, so just build using MSBuild directly.
			else
			{
				# Get the path to the MsBuild executable.
				$msBuildPath = Get-MsBuildPath
				$cmdArgumentsToRunMsBuild = "/k "" ""$msBuildPath"" "
			}

			# Append the MSBuild arguments to pass into cmd.exe in order to do the build.
			$cmdArgumentsToRunMsBuild += "$buildArguments "
			
			# If necessary, add a pause to wait for input before exiting the cmd.exe window.
			# No pausing allowed when using PassThru or not showing the build output.
			# The -NoNewWindow parameter of Start-Process does not behave correctly in the ISE and other PowerShell hosts (doesn't display any build output), 
			# so only allow it if in the default PowerShell host, since we know that one works.
			$pauseForInput = [string]::Empty
			if ($PromptForInputBeforeClosing -and !$PassThru `
				-and ($ShowBuildOutputInNewWindow -or ($ShowBuildOutputInCurrentWindow -and $Host.Name -eq "ConsoleHost")))
			{ $pauseForInput = "Pause & " }
			$cmdArgumentsToRunMsBuild += "& $pauseForInput Exit"" "

			Write-Debug "Starting new cmd.exe process with arguments ""$cmdArgumentsToRunMsBuild""."

			# Perform the build.
			if ($PassThru)
			{
				if ($ShowBuildOutputInCurrentWindow)
				{
					return Start-Process cmd.exe -ArgumentList $cmdArgumentsToRunMsBuild -NoNewWindow -PassThru
				}
				else
				{
					return Start-Process cmd.exe -ArgumentList $cmdArgumentsToRunMsBuild -WindowStyle $windowStyleOfNewWindow -PassThru
				}
			}
			else
			{
				if ($ShowBuildOutputInCurrentWindow)
				{
					$process = Start-Process cmd.exe -ArgumentList $cmdArgumentsToRunMsBuild -NoNewWindow -Wait -PassThru
				}
				else
				{
					$process = Start-Process cmd.exe -ArgumentList $cmdArgumentsToRunMsBuild -WindowStyle $windowStyleOfNewWindow -Wait -PassThru
				}
				$processExitCode = $process.ExitCode
			}
		}
		catch
		{
			$buildCrashed = $true;
			$errorMessage = $_
			Write-Error ("Unexpected error occurred while building ""$Path"": $errorMessage");
		}

		# If the build crashed, return that the build didn't succeed.
		if ($buildCrashed)
		{
			return $false
		}

        # If we can't find the build's log file in order to inspect it, write a warning and return null.
        if (!(Test-Path -Path $buildLogFilePath))
        {
            Write-Warning "Cannot find the build log file at '$buildLogFilePath', so unable to determine if build succeeded or not."
            return $null
        }

		# Get if the build failed or not by looking at the log file.
		$buildSucceeded = (((Select-String -Path $buildLogFilePath -Pattern "Build FAILED." -SimpleMatch) -eq $null) -and $processExitCode -eq 0)

		# If the build succeeded.
		if ($buildSucceeded)
		{
			# If we shouldn't keep the log files around, delete them.
			if (!$KeepBuildLogOnSuccessfulBuilds)
			{
				if (Test-Path $buildLogFilePath -PathType Leaf) { Remove-Item -Path $buildLogFilePath -Force }
				if (Test-Path $buildErrorsLogPath -PathType Leaf) { Remove-Item -Path $buildErrorsLogPath -Force }
			}
		}
		# Else at least one of the projects failed to build.
		else
		{
			# Write the error message as a warning.
			Write-Warning "FAILED to build ""$Path"". Please check the build log ""$buildLogFilePath"" for details." 

			# If we should show the build log automatically, open it with the default viewer.
			if($AutoLaunchBuildLogOnFailure)
			{
				Start-Process -verb "Open" $buildLogFilePath;
			}
		}

		# Return if the Build Succeeded or Failed.
		return $buildSucceeded
	}
}

function Get-VisualStudioCommandPromptPath
{
<#
	.SYNOPSIS
		Gets the file path to the latest Visual Studio Command Prompt. Returns $null if a path is not found.
	
	.DESCRIPTION
		Gets the file path to the latest Visual Studio Command Prompt. Returns $null if a path is not found.
#>

	# Get some environmental paths.
	$vs2015CommandPromptPath = $env:VS140COMNTOOLS + 'VsDevCmd.bat'
	$vs2013CommandPromptPath = $env:VS120COMNTOOLS + 'VsDevCmd.bat'
	$vs2012CommandPromptPath = $env:VS110COMNTOOLS + 'VsDevCmd.bat'
	$vs2010CommandPromptPath = $env:VS100COMNTOOLS + 'vcvarsall.bat'
	$vsCommandPromptPaths = @($vs2015CommandPromptPath, $vs2013CommandPromptPath, $vs2012CommandPromptPath, $vs2010CommandPromptPath)

	# Store the VS Command Prompt to do the build in, if one exists.
	$vsCommandPromptPath = $null
	foreach ($path in $vsCommandPromptPaths)
	{
		try
		{
			if (Test-Path -Path $path)
			{
				$vsCommandPromptPath = $path
				break
			}
		}
		catch {}
	}

	# Return the path to the VS Command Prompt if it was found.
	return $vsCommandPromptPath
}

function Get-MsBuildPath
{
<#
	.SYNOPSIS
	Gets the path to the latest version of MsBuild.exe. Throws an exception if MSBuild.exe is not found.
	
	.DESCRIPTION
	Gets the path to the latest version of MsBuild.exe. Throws an exception if MSBuild.exe is not found.
#>

	# Get the path to the directory that the latest version of MSBuild is in.
	$MsBuildToolsVersionsStrings = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\' | Where-Object { $_ -match '[0-9]+\.[0-9]' } | Select-Object -ExpandProperty PsChildName
	[double[]]$MsBuildToolsVersions = $MsBuildToolsVersionsStrings | ForEach-Object { [Convert]::ToDouble($_) }
	$LargestMsBuildToolsVersion = $MsBuildToolsVersions | Sort-Object -Descending | Select-Object -First 1 
	$MsBuildToolsVersionsKeyToUse = Get-Item -Path ('HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\{0:n1}' -f $LargestMsBuildToolsVersion)
	$MsBuildDirectoryPath = $MsBuildToolsVersionsKeyToUse | Get-ItemProperty -Name 'MSBuildToolsPath' | Select -ExpandProperty 'MSBuildToolsPath'

	if(!$MsBuildDirectoryPath)
	{
		throw 'MsBuild.exe was not found on the system.'          
	}

	# Get the path to the MSBuild executable.
	$MsBuildPath = (Join-Path -Path $MsBuildDirectoryPath -ChildPath 'msbuild.exe')

	if(!(Test-Path $MsBuildPath -PathType Leaf))
	{
		throw 'MsBuild.exe was not found on the system.'          
	}

	return $MsBuildPath
}

Export-ModuleMember -Function Invoke-MsBuild