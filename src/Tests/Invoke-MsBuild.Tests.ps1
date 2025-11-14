using module ./../Invoke-MsBuild/Invoke-MsBuild.psm1

InModuleScope -ModuleName Invoke-MsBuild { # Must use InModuleScope to call private functions of the module.
	Describe 'Get-LatestMsBuildPath' {
		BeforeEach {
			# Create fake Visual Studio installation directories with MSBuild.exe files.
			$vs2017Path = Join-Path $TestDrive 'Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\amd64\MSBuild.exe'
			$vs2019Path = Join-Path $TestDrive 'Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\amd64\MSBuild.exe'
			$vs2022Path = Join-Path $TestDrive 'Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\amd64\MSBuild.exe'
			$vs2026Path = Join-Path $TestDrive 'Program Files\Microsoft Visual Studio\18\Enterprise\MSBuild\Current\Bin\amd64\MSBuild.exe'

			New-Item -Path $vs2017Path -ItemType File -Force
			New-Item -Path $vs2019Path -ItemType File -Force
			New-Item -Path $vs2022Path -ItemType File -Force
			New-Item -Path $vs2026Path -ItemType File -Force

			# Mock the helper function to search in our TestDrive instead of the real Visual Studio directory.
			Mock -CommandName Get-CommonVisualStudioDirectoryPath -MockWith {
				return (Join-Path $TestDrive 'Program Files' 'Microsoft Visual Studio')
			}
		}

		AfterEach {
			# Clean up the fake Visual Studio installation directories after each test to ensure isolation.
			Remove-Item -Path $TestDrive -Recurse -Force
		}

		It 'Should return the latest Visual Studio version MSBuild path' {
			$result = Get-LatestMsBuildPath
			$result | Should -Be $vs2026Path
		}

		It 'Should return VS2022 path when VS2026 does not exist' {
			Remove-Item -Path $vs2026Path -Recurse -Force
			$result = Get-LatestMsBuildPath
			$result | Should -Be $vs2022Path
		}

		It 'Should return VS2022 path when only VS2022 exists' {
			Remove-Item -Path $vs2017Path -Recurse -Force
			Remove-Item -Path $vs2019Path -Recurse -Force
			Remove-Item -Path $vs2026Path -Recurse -Force
		$result = Get-LatestMsBuildPath
		$result | Should -Be $vs2022Path
		}
	}

	Describe 'Get-LatestVisualStudioCommandPromptPath' {
		BeforeEach {
			# Create fake Visual Studio installation directories with VsDevCmd.bat files.
			$vs2017Path = Join-Path $TestDrive 'Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools\VsDevCmd.bat'
			$vs2019Path = Join-Path $TestDrive 'Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\VsDevCmd.bat'
			$vs2022Path = Join-Path $TestDrive 'Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat'
			$vs2026Path = Join-Path $TestDrive 'Program Files\Microsoft Visual Studio\18\Enterprise\Common7\Tools\VsDevCmd.bat'

			New-Item -Path $vs2017Path -ItemType File -Force
			New-Item -Path $vs2019Path -ItemType File -Force
			New-Item -Path $vs2022Path -ItemType File -Force
			New-Item -Path $vs2026Path -ItemType File -Force

			# Mock the helper function to search in our TestDrive instead of the real Visual Studio directory.
			Mock -CommandName Get-CommonVisualStudioDirectoryPath -MockWith {
				return (Join-Path $TestDrive 'Program Files' 'Microsoft Visual Studio')
			}
		}

		AfterEach {
			# Clean up the fake Visual Studio installation directories after each test to ensure isolation.
			Remove-Item -Path $TestDrive -Recurse -Force
		}

		It 'Should return the latest Visual Studio version VsDevCmd.bat path' {
			$result = Get-LatestVisualStudioCommandPromptPath
			$result | Should -Be $vs2026Path
		}

		It 'Should return VS2019 path when VS2022 and VS2026 do not exist' {
			# We need to override the default mock to search in 'Program Files (x86)', since VS2019 is installed there.
			Mock -CommandName Get-CommonVisualStudioDirectoryPath -MockWith {
				return (Join-Path $TestDrive 'Program Files (x86)' 'Microsoft Visual Studio')
			}

			Remove-Item -Path $vs2022Path -Recurse -Force
			Remove-Item -Path $vs2026Path -Recurse -Force
			$result = Get-LatestVisualStudioCommandPromptPath
			$result | Should -Be $vs2019Path
		}

		It 'Should return VS2026 path when only VS2026 exists' {
			Remove-Item -Path $vs2017Path -Recurse -Force
			Remove-Item -Path $vs2019Path -Recurse -Force
			Remove-Item -Path $vs2022Path -Recurse -Force
			$result = Get-LatestVisualStudioCommandPromptPath
			$result | Should -Be $vs2026Path
		}
	}
}
