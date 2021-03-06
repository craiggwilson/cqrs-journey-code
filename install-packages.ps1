# ==============================================================================================================
# Microsoft patterns & practices
# CQRS Journey project
# ==============================================================================================================
# Copyright (c) Microsoft Corporation and contributors http://cqrsjourney.github.com/contributors/members
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance 
# with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is 
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and limitations under the License.
# ==============================================================================================================

$scriptPath = Split-Path (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Path 
$solutionFolder = Join-Path $scriptPath 'source\Conference'

$packageFiles = Get-Item "$solutionFolder\**\packages.config"

# get all the packages to install
$packages = @()
$packageFiles | ForEach-Object { 
    $xml = New-Object "System.Xml.XmlDocument"
    $xml.Load($_.FullName)
    $xml | Select-Xml -XPath '//packages/package' | 
        Foreach { $packages += " - "+ $_.Node.id + " v" + $_.Node.version }
}
$packages = $packages | Select -uniq
$packages = [system.string]::Join("`r`n", $packages)

# prompt to continue
$caption = "DOWLOADING NUGET PACKAGE DEPENDENCIES";
$message = "You are about to automatically download the following NuGet package dependencies required to build the sample application:
" + $packages + "
 
Microsoft grants you no rights for third party software.  You are responsible for and must locate and read the license terms for each of the above packages. The owners of the above packages are solely responsible for their content and behavior. Microsoft gives no express warranties, guarantees or conditions.
Do you want to proceed?";

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","I agree to download the NuGet packages dependencies.";
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","I do not agree to download the NuGet packages dependencies.";
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no);
$answer = $host.ui.PromptForChoice($caption,$message,$choices,1) 

switch ($answer){
    0 { break }
    1 { exit; break }
} 

# copy NuGet.exe bootstrapper to a temp folder if it's not there (this is to avoid distributing the full version of NuGet, and avoiding source control issues with updates).
$nuget = Join-Path $scriptPath 'build\temp\NuGet.exe'
$nugetExists = Test-Path $nuget

if ($nugetExists -eq 0)
{
	$tempFolder = Join-Path $scriptPath 'build\temp\'
	mkdir $tempFolder -Force > $null
	$nugetOriginal = Join-Path $scriptPath 'build\NuGet.exe'
	Copy-Item $nugetOriginal -Destination $nuget -Force
}

pushd $solutionFolder

# install the packages
$packageFiles | ForEach-Object { & $nuget install $_.FullName -o packages }

popd
