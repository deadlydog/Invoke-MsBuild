function Publish-NewReleaseToGitHub($gitHubReleaseParameters)
{
    Install-Module -Name New-GitHubRelease -Scope CurrentUser -Force

    $gitHubAccessTokenEnvironmentalVariableName = 'GitHubAccessToken'
    $gitHubAccessToken = $gitHubReleaseParameters.GitHubAccessToken

    # If a GitHub Access Token was not provided, check the Environmental variable for it. If it's not there either, prompt the user for it.
    $isGitHubAccessTokenProvidedFromPrompt = $false
    if ([string]::IsNullOrWhiteSpace($gitHubAccessToken))
    {
        $encodedGitHubAccessToken = [Environment]::GetEnvironmentVariable($gitHubAccessTokenEnvironmentalVariableName, "User")
        if (![string]::IsNullOrWhiteSpace($encodedGitHubAccessToken))
        {
			$gitHubAccessTokenAsBytes = [System.Convert]::FromBase64String($encodedGitHubAccessToken)
            $gitHubAccessToken = [System.Text.Encoding]::UTF8.GetString($gitHubAccessTokenAsBytes)
        }

        if ([string]::IsNullOrWhiteSpace($gitHubAccessToken))
        {
            $gitHubAccessToken = Read-InputBoxDialog -WindowTitle 'GitHub Access Token Required' -Message 'Please enter your GitHub Access Token:'
            $isGitHubAccessTokenProvidedFromPrompt = $true
        }
    }

    if ([string]::IsNullOrWhiteSpace($gitHubAccessToken))
    {
        throw 'No GitHub Access Token was provided, so exiting without attempting to publish a new Release.'
    }
    $gitHubReleaseParameters.GitHubAccessToken = $gitHubAccessToken

    # Publish the new version of the module to GitHub.
    Write-Output "Creating new GitHub release..."
    $gitHubReleaseCreationResult = New-GitHubRelease @gitHubReleaseParameters

    # If we prompted the user for the Access Token and the publish succeeded, ask them if they want to save it for next time.
    if ($isGitHubAccessTokenProvidedFromPrompt -and $gitHubReleaseCreationResult.ReleaseCreationSucceeded)
    {
        $saveGitHubAccessKeyAnswer = Read-MessageBoxDialog -WindowTitle "Save GitHub Access Token?" -Message 'Would you like to save the GitHub Access Token in an environmental variable so you are not prompted for it next time?' -Buttons YesNo
        if ($saveGitHubAccessKeyAnswer -eq 'Yes')
        {
			$gitHubAccessTokenAsBytes = [System.Text.Encoding]::UTF8.GetBytes($gitHubAccessToken)
            $encodedGitHubAccessToken = [System.Convert]::ToBase64String($gitHubAccessTokenAsBytes)
            [Environment]::SetEnvironmentVariable($gitHubAccessTokenEnvironmentalVariableName, $encodedGitHubAccessToken, "User")
        }
    }

    # Let the user know if the new Release was created successfully or not.
    if ($gitHubReleaseCreationResult.Succeeded -eq $true)
    { 
        Write-Output "Release published successfully! View it at $($gitHubReleaseCreationResult.ReleaseUrl)"
    }
    elseif ($gitHubReleaseCreationResult.ReleaseCreationSucceeded -eq $false)
    { 
        throw "The release was not created. Error message is: $($gitHubReleaseCreationResult.ErrorMessage)"
    }
    elseif ($gitHubReleaseCreationResult.AllAssetUploadsSucceeded -eq $false)
    { 
        throw "The release was created, but not all of the assets were uploaded to it. View it at $($gitHubReleaseCreationResult.ReleaseUrl). Error message is: $($gitHubReleaseCreationResult.ErrorMessage)"
    }
}
