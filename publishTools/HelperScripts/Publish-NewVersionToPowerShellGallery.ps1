function Publish-ToPowerShellGallery([string] $moduleDirectoryPath, [string] $powerShellGalleryNuGetApiKey, [bool] $isTestingThisScript)
{
	$powerShellGalleryNuGetApiKeyEnvironmentalVariableName = 'PowerShellGalleryNuGetApiKey'

	# If a PowerShell NuGet API Key was not provided, check the Environmental variable for it. If it's not there either, prompt the user for it.
	$isPowerShellGalleryNuGetApiKeyProvidedFromPrompt = $false
	if ([string]::IsNullOrWhiteSpace($powerShellGalleryNuGetApiKey))
	{
		$encodedPowerShellGalleryNuGetApiKey = [Environment]::GetEnvironmentVariable($powerShellGalleryNuGetApiKeyEnvironmentalVariableName, "User")
		if (![string]::IsNullOrWhiteSpace($encodedPowerShellGalleryNuGetApiKey))
		{
			$powerShellGalleryNuGetApiKeyAsBytes = [System.Convert]::FromBase64String($encodedPowerShellGalleryNuGetApiKey)
			$powerShellGalleryNuGetApiKey = [System.Text.Encoding]::UTF8.GetString($powerShellGalleryNuGetApiKeyAsBytes)
		}

		if ([string]::IsNullOrWhiteSpace($powerShellGalleryNuGetApiKey))
		{
			$powerShellGalleryNuGetApiKey = Read-InputBoxDialog -WindowTitle 'PowerShell Gallery API Key Required' -Message 'Please enter your PowerShell Gallery API Key:'
			$isPowerShellGalleryNuGetApiKeyProvidedFromPrompt = $true
		}
	}

	if ([string]::IsNullOrWhiteSpace($powerShellGalleryNuGetApiKey))
	{
		throw 'No PowerShell Gallery API key was provided, so exiting without attempting to publish a new NuGet package.'
	}

	if ($isTestingThisScript)
	{
		Write-Output "Script is in TESTING mode, so we will not actually try to publish the new NuGet package to the PowerShell Gallery."
		return
	}

	# Publish the new version of the module to the PowerShell Gallery.
	Write-Output "Publishing new NuGet package to the PowerShell Gallery..."
	try
	{
		Publish-Module -Path $moduleDirectoryPath -NuGetApiKey $powerShellGalleryNuGetApiKey
	}
	catch
	{
		throw $_.Exception.Message
	}

	$powerShellGalleryNuGetPackageExpectedUrl = "$powerShellGalleryNuGetPackageUrlWithTrailingSlash$newVersionNumber"
	Write-Output "PowerShell Gallery NuGet Package has been published. View it at:  $powerShellGalleryNuGetPackageExpectedUrl"

	# If we prompted the user for the API key, ask them if they want to save it for next time.
	if ($isPowerShellGalleryNuGetApiKeyProvidedFromPrompt)
	{
		$savePowerShellGalleryApiKeyAnswer = Read-MessageBoxDialog -WindowTitle "Save PowerShell Gallery API Key?" -Message 'Would you like to save the API key in an environmental variable so you are not prompted for it next time?'-Buttons YesNo
		if ($savePowerShellGalleryApiKeyAnswer -eq 'Yes')
		{
			$powerShellGalleryNuGetApiKeyAsBytes = [System.Text.Encoding]::UTF8.GetBytes($powerShellGalleryNuGetApiKey)
			$encodedPowerShellGalleryNuGetApiKey = [System.Convert]::ToBase64String($powerShellGalleryNuGetApiKeyAsBytes)
			[Environment]::SetEnvironmentVariable($powerShellGalleryNuGetApiKeyEnvironmentalVariableName, $encodedPowerShellGalleryNuGetApiKey, "User")
		}
	}
}
