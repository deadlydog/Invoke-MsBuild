param
(
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $PowerShellGalleryNuGetApiKey,

	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $GitHubAccessToken
)

$THIS_SCRIPTS_DIRECTORY = Split-Path $script:MyInvocation.MyCommand.Path
$helperScriptsDirectory = Join-Path -Path $THIS_SCRIPTS_DIRECTORY -ChildPath 'HelperScripts'
$commonFunctionsScriptFilePath = Join-Path -Path $helperScriptsDirectory -ChildPath 'CommonFunctions.ps1'
$newGitHubReleaseScriptFilePath = Join-Path -Path $helperScriptsDirectory -ChildPath 'New-GitHubRelease.ps1'
$srcDirectoryPath = Join-Path -Path (Split-Path -Path $THIS_SCRIPTS_DIRECTORY -Parent) -ChildPath 'src'

# Dot-source in the other scripts containing functions this script will use.
. $commonFunctionsScriptFilePath
. $newGitHubReleaseScriptFilePath

# Buid the paths to the files to modify and publish.
$moduleDirectoryPath = Join-Path $srcDirectoryPath 'Invoke-MsBuild'
$scriptFilePath = Join-Path $moduleDirectoryPath 'Invoke-MsBuild.psm1'
$manifestFilePath = Join-Path $moduleDirectoryPath 'Invoke-MsBuild.psd1'

Clear-Host

# Regex patterns used to find the current version number and release notes.
$scriptVersionNumberRegexPattern = '(?i)Version:\s*(?<Version>.*?)\s*$'
$manifestVersionNumberRegexPattern = "(?i)ModuleVersion = '(?<Version>.*?)'"
$manifestReleaseNotesRegexPattern = "(?is)ReleaseNotes = '(?<ReleaseNotes>.*?)'"

# Get the script's current version number.
$currentScriptVersionNumberMatches = Select-String -Path $scriptFilePath -Pattern $scriptVersionNumberRegexPattern | Select-Object -First 1
if ($currentScriptVersionNumberMatches.Matches.Count -le 0 -or !$currentScriptVersionNumberMatches.Matches[0].Success)
{ throw "Could not find the script's current version number." }
$currentScriptVersionNumberMatch = $currentScriptVersionNumberMatches.Matches[0]
$currentScriptVersionNumber = $currentScriptVersionNumberMatch.Groups['Version'].Value
$currentScriptVersionNumberLine = $currentScriptVersionNumberMatch.Value

# Get the manifest's current version number.
$currentManifestVersionNumberMatches = Select-String -Path $manifestFilePath -Pattern $manifestVersionNumberRegexPattern | Select-Object -First 1
if ($currentManifestVersionNumberMatches.Matches.Count -le 0 -or !$currentManifestVersionNumberMatches.Matches[0].Success) 
{ throw "Could not find the manifest's current version number." }
$currentManifestVersionNumberMatch = $currentManifestVersionNumberMatches.Matches[0]
$currentManifestVersionNumber = $currentManifestVersionNumberMatch.Groups['Version'].Value
$currentManifestVersionNumberLine = $currentManifestVersionNumberMatch.Value

# Get the manifest's current release notes.
# We have to get the file contents first so that Select-String will search across multiple lines, since the release notes may span multiple lines.
$manifestFileContents = Get-Content -Path $manifestFilePath -Raw
$currentManifestReleaseNotesMatches = Select-String -InputObject $manifestFileContents -Pattern $manifestReleaseNotesRegexPattern | Select-Object -First 1
if ($currentManifestReleaseNotesMatches.Matches.Count -le 0 -or !$currentManifestReleaseNotesMatches.Matches[0].Success) 
{ throw "Could not find the manifests's current release notes." }
$currentManifestReleaseNotesMatch = $currentManifestReleaseNotesMatches.Matches[0]
$currentManifestReleaseNotes = $currentManifestReleaseNotesMatch.Groups['ReleaseNotes'].Value
$currentManifestReleaseNotesLine = $currentManifestReleaseNotesMatch.Value

## Left here for debugging purposes
#$currentScriptVersionNumber
#$currentScriptVersionNumberLine
#$currentManifestVersionNumber
#$currentManifestVersionNumberLine
#$currentManifestReleaseNotes
#$currentManifestReleaseNotesLine

# Prompt for what version number we should give the script.
$newVersionNumber = Read-InputBoxDialog -WindowTitle 'Version Number' -Message "What should the script's Version Number be?" -DefaultText $currentScriptVersionNumber
if ([string]::IsNullOrWhiteSpace($newVersionNumber)) { throw 'You must specify a version number.' }
$newVersionNumber = $newVersionNumber.Trim()

# Prompt for the release notes for this version.
$newReleaseNotes = Read-MultiLineInputBoxDialog -WindowTitle 'Release Notes' -Message 'What release notes should be included with this version?' -DefaultText $currentManifestReleaseNotes
if ($newReleaseNotes -eq $null) { throw 'You cancelled out of the release notes prompt.' }
if ($newReleaseNotes.Contains("'")) 
{ 
	$errorMessage = 'Single quotes are not allowed in the Release Notes, as they break our ability to parse them with PowerShell. Exiting script.'
	Read-MessageBoxDialog -Message $errorMessage -WindowTitle 'Single Quotes Not Allowed In Release Notes'
	throw $errorMessage
}
$newReleaseNotes = $newReleaseNotes.Trim()

# Build the new lines to insert into the files. Wrap manifest values in single quotes in case the are empty strings still (can't replace an empty string).
$newScriptVersionNumberLine = $currentScriptVersionNumberLine.Replace($currentScriptVersionNumber, $newVersionNumber)
$newManifestVersionNumberLine = $currentManifestVersionNumberLine.Replace("'$currentManifestVersionNumber'", "'$newVersionNumber'")
$newManifestReleaseNotesLine = $currentManifestReleaseNotesLine.Replace("'$currentManifestReleaseNotes'", "'$newReleaseNotes'")

# Update the version number and release notes in the module script and manifest.
Replace-TextInFile -filePath $scriptFilePath -textToReplace $currentScriptVersionNumberLine -replacementText $newScriptVersionNumberLine
Replace-TextInFile -filePath $manifestFilePath -textToReplace $currentManifestVersionNumberLine -replacementText $newManifestVersionNumberLine
Replace-TextInFile -filePath $manifestFilePath -textToReplace $currentManifestReleaseNotesLine -replacementText $newManifestReleaseNotesLine

# Publish the new version of the module to the PowerShell Gallery.
Publish-Module -Path $moduleDirectoryPath -NuGetApiKey $PowerShellGalleryNuGetApiKey

# Publish the new version of the module to GitHub.
$gitHubReleaseParameters = 
@{
	GitHubUserAndRepository = 'deadlydog/Invoke-MsBuild'
	GitHubAccessToken = $GitHubAccessToken
	ReleaseName = "Invoke-MsBuild v" + $newVersionNumber
	TagName = "v" + $newVersionNumber
	ReleaseNotes = $newReleaseNotes
	ArtifactFilePaths = [string[]]@($scriptFilePath, $manifestFilePath)
	IsPreRelease = $newVersionNumber -match '-+|[a-zA-Z]+'	# Assume true when matches semver prerelease versioning (e.g. 1.2.3-alpha). i.e. contains a dash or letters.
	IsDraft = $false
}
New-GitHubRelease @gitHubReleaseParameters