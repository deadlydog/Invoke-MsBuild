# Script based on code taken from: https://github.com/majkinetor/au/blob/master/scripts/Github-CreateRelease.ps1
# GitHub Release API Documentation: https://developer.github.com/v3/repos/releases/#create-a-release

# To create a Github Access Token, on GitHub.com go to your account Settings -> Personal Access Tokens, and make sure the token has scope repo/public_repo.

function New-GitHubRelease
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true,HelpMessage="The username the repository is under (e.g. deadlydog).")]
		[string] $GitHubUsername,

		[Parameter(Mandatory=$true,HelpMessage="The repository name to create the release in (e.g. Invoke-MsBuild).")]
		[string] $GitHubRepositoryName,

		[Parameter(Mandatory=$true,HelpMessage="The Acess Token to use as credentials for GitHub. Generate one at GitHub.com -> account Settings -> Personal Access Tokens, and make sure the token has scope repo/public_repo.")]
		[string] $GitHubAccessToken,

		[Parameter(Mandatory=$true,HelpMessage="The name of the tag to create at the the CommitId.")]
		[string] $TagName,

		[Parameter(Mandatory=$false,HelpMessage="The name of the release. If blank, the TagName will be used.")]
		[string] $ReleaseName,

		[Parameter(Mandatory=$false,HelpMessage="Text describing the contents of the tag.")]
		[string] $ReleaseNotes,

		[Parameter(Mandatory=$false,HelpMessage="The full paths of the files to include in the release.")]
		[string[]] $ArtifactFilePaths,

		[Parameter(Mandatory=$false, HelpMessage="Specifies the commitish value that determines where the Git tag is created from. Can be any branch or commit SHA. Unused if the Git tag already exists. Default: the repository's default branch (usually master).")]
		[string] $CommitId, #= 'master',

		[Parameter(Mandatory=$false,HelpMessage="True to create a draft (unpublished) release, False to create a published one. Default: false")]
		[bool] $IsDraft = $false,

		[Parameter(Mandatory=$false,HelpMessage="True to identify the release as a prerelease. False to identify the release as a full release. Default: false")]
		[bool] $IsPreRelease = $false
	)

	if ([string]::IsNullOrEmpty($ReleaseName)) 
	{ 
		$ReleaseName = $TagName
	}

	$NewLine = [Environment]::NewLine

	function Invoke-RestMethodAndThrowDescriptiveErrorOnFailure($requestParametersHashTable)
	{
		$requestDetailsAsNicelyFormattedString = Convert-HashTableToNicelyFormattedString $requestParametersHashTable
		Write-Verbose "Making web request with the following parameters:$NewLine$requestDetailsAsNicelyFormattedString"

		try 
		{
			$webRequestResult = Invoke-RestMethod @requestParametersHashTable
		}
		catch 
		{
			$exception = $_.Exception

			$responseDetails = @{
				ResponseUri = $exception.Response.ResponseUri
				StatusCode = $exception.Response.StatusCode
				StatusDescription = $exception.Response.StatusDescription
				ErrorMessage = $exception.Message
			}
			$responseDetailsAsNicelyFormattedString = Convert-HashTableToNicelyFormattedString $responseDetails

			$errorInfo = "Request Details:" + $NewLine + $requestDetailsAsNicelyFormattedString
			$errorInfo += $NewLine
			$errorInfo += "Response Details:" + $NewLine + $responseDetailsAsNicelyFormattedString
			throw "An unexpected error occurred while making web request: $NewLine$errorInfo"
		}

		Write-Verbose "Web request returned the following result:$NewLine$webRequestResult"
		return $webRequestResult
	}

	function Convert-HashTableToNicelyFormattedString($hashTable)
	{
		[string] $nicelyFormattedString = $hashTable.Keys | ForEach-Object {
			$key = $_
			$value = $hashTable.$key
			"  $key = $value$NewLine"
		}
		return $nicelyFormattedString
	}

	$authHeader = 
	@{ 
		Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($GitHubAccessToken + ":x-oauth-basic"))
	}

	$releaseData = 
	@{
		tag_name         = $TagName
		target_commitish = $CommitId
		name             = $ReleaseName
		body             = $ReleaseNotes
		draft            = $IsDraft
		prerelease       = $IsPreRelease
	}

	$createReleaseWebRequestParameters = 
	@{
		Uri         = "https://api.github.com/repos/$GitHubUsername/$GitHubRepositoryName/releases"
		Method      = 'POST'
		Headers     = $authHeader
		ContentType = 'application/json'
		Body        = (ConvertTo-Json $releaseData -Compress)
	}

	Write-Information "Sending web request to create the new Release..."
	$createReleaseWebRequestResults = Invoke-RestMethodAndThrowDescriptiveErrorOnFailure $createReleaseWebRequestParameters

	$successfulCompletionMessage = "GitHub Release creation complete! View it at: " + $createReleaseWebRequestResults.html_url

	[bool] $thereAreNoArtifactsToIncludeInTheRelease = ($ArtifactFilePaths -eq $null) -or ($ArtifactFilePaths.Count -le 0)
	if ($thereAreNoArtifactsToIncludeInTheRelease)
	{
		Write-Information "No artificats to include in the release. $successfulCompletionMessage"
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
			# Upload Url has template parameters on the end (e.g. ".../assets{?name,label}"), so remove them and append the actual name.
			Uri         = ($createReleaseWebRequestResults.upload_url -replace '{.+}') + "?name=$artifactFileName"
			Method      = 'POST'
			Headers     = $authHeader
			ContentType = 'application/zip'
			InFile      = $artifactFilePath
		}

		$numberOfArtifactsUploaded = $numberOfArtifactsUploaded + 1
		Write-Information "Uploading artifact $numberOfArtifactsUploaded of $numberOfArtifactsToUpload, '$artifactFilePath'."
		Invoke-RestMethodAndThrowDescriptiveErrorOnFailure $uploadArtifactWebRequestParameters > $null
	}

	Write-Information $successfulCompletionMessage
}