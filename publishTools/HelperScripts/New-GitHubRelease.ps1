# Script based on code taken from: https://github.com/majkinetor/au/blob/master/scripts/Github-CreateRelease.ps1
# GitHub Release API Documentation: https://developer.github.com/v3/repos/releases/#create-a-release

# To create a Github Access Token, on GitHub.com go to your account Settings -> Personal Access Tokens, and make sure the token has scope repo/public_repo.

function New-GitHubRelease
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true,HelpMessage="The user and repository name (e.g. deadlydog/Invoke-MsBuild).")]
		[string] $GitHubUserAndRepository,

		[Parameter(Mandatory=$true)]
		[string] $GitHubAccessToken,

		[Parameter(Mandatory=$true)]
		[string] $ReleaseName,

		[Parameter(Mandatory=$true)]
		[string] $TagName,

		[string] $ReleaseNotes,

		[string[]] $ArtifactFilePaths,

		[bool] $IsDraft = $false,

		[bool] $IsPreRelease = $false
	)

	$ErrorActionPreference = 'STOP'

	$authHeader = 
	@{ 
		Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($GitHubAccessToken + ":x-oauth-basic"))
	}

	$releaseData = 
	@{
		tag_name         = $TagName
		target_commitish = 'master'
		name             = $ReleaseName
		body             = $ReleaseNotes
		draft            = $IsDraft
		prerelease       = $IsPreRelease
	}

	$createReleaseWebRequestParameters = 
	@{
		Uri         = "https://api.github.com/repos/$GitHubUserAndRepository/releases"
		Method      = 'POST'
		Headers     = $authHeader
		ContentType = 'application/json'
		Body        = ConvertTo-Json $releaseData
	}

	Write-Information "Sending web request to create the new Release..."
	$createReleaseWebRequestResults = Invoke-RestMethod @createReleaseWebRequestParameters

	$successfulCompletionMessage = "GitHub Release creation complete! View it at: " + $createReleaseWebRequestResults.html_url

	[bool] $thereAreNoArtifactsToIncludeInTheRelease = ($ArtifactFilePaths -eq $null) -or ($ArtifactFilePaths.Count -le 0)
	if ($thereAreNoArtifactsToIncludeInTheRelease)
	{
		Write-Output "No artificats to include in the release. $successfulCompletionMessage"
		return
	}

	[int] $numberOfArtifactsToUpload = $ArtifactFilePaths.Count
	[int] $numberOfArtifactsUploaded = 0

	Write-Information "Uploading $numberOfArtifactsToUpload artifacts to the new release..."
	foreach ($artifactFilePath in $ArtifactFilePaths) 
	{
		if ([string]::IsNullOrWhiteSpace($artifactFilePath) -or !(Test-Path -Path $artifactFilePath)) 
		{ 
			throw "The specified artifactFilePath '$artifactFilePath' to include in the release was not found."
		}

		$artifactFileName = Get-Item $artifactFilePath | Select-Object -ExpandProperty Name

		$uploadArtifactWebRequestParameters = 
		@{
			Uri         = ($createReleaseWebRequestResults.upload_url -replace '{.+}') + "?name=$artifactFileName"
			Method      = 'POST'
			Headers     = $authHeader
			ContentType = 'application/zip'
			InFile      = $artifactFilePath
		}

		$numberOfArtifactsUploaded = $numberOfArtifactsUploaded + 1
		Write-Information "Uploading artifact $numberOfArtifactsUploaded of $numberOfArtifactsToUpload, '$artifactFilePath'."
		Invoke-RestMethod @uploadArtifactWebRequestParameters > $null
	}

	Write-Output $successfulCompletionMessage
}