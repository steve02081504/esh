[CmdletBinding()]
param (
	$OutputFile = "$PWD/esh.exe",
	[Parameter(ParameterSetName = 'SigThief')][switch]$SigThief = $false,
	[switch]$DetailedLog = $false
)
DynamicParam {
	if ($SigThief) {
		$SigThiefParam = New-Object System.Management.Automation.RuntimeDefinedParameter('SigThiefFile', [string], ([System.Management.Automation.ParameterAttribute]@{HelpMessage = 'The file to steal signature from.' }))
		$RuntimeParamDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		$RuntimeParamDictionary.Add('SigThiefFile', $SigThiefParam)
		return $RuntimeParamDictionary
	}
}

process {
	function GetToolFromGit($ToolName, $ToolAuthor="steve02081504"){
		Write-Host "Downloading $ToolAuthor/$ToolName..."
		try{
			if (Get-Command git -ErrorAction Ignore) {
				git clone https://github.com/$ToolAuthor/$ToolName "$PSScriptRoot/tools/$ToolName" --depth 1
			}
			else{
				Invoke-WebRequest -Uri https://github.com/$ToolAuthor/$ToolName/archive/refs/heads/master.zip -OutFile "$PSScriptRoot/tools/$ToolName.zip"
				Expand-Archive -Path "$PSScriptRoot/tools/$ToolName.zip" -DestinationPath "$PSScriptRoot/tools"
				Move-Item "$PSScriptRoot/tools/$ToolName-master" "$PSScriptRoot/tools/$ToolName"
				Remove-Item "$PSScriptRoot/tools/$ToolName.zip"
			}
		} catch {
			Write-Warning "Download failed."
			Exit
		}
		Write-Host "Download complete."
	}
	if (-not (Test-Path "$PSScriptRoot/tools/ps2exe/ps2exe.ps1")) {
		if(Get-Command ps2exe -ErrorAction Ignore){
			Write-Host "Existing ps2exe doesn't meet the functionality requirements needed for a build, downloading target fork..."
		}
		GetToolFromGit ps2exe
	}
	if (-not (Test-Path "$PSScriptRoot/tools/psminnifyer/psminnifyer.ps1")) {
		GetToolFromGit psminnifyer
	}
	& $PSScriptRoot/tools/ps2exe/ps2exe.ps1 $PSScriptRoot/main.ps1 "$PSScriptRoot/build/esh.exe" -NoConsole `
		-Minifyer { $_.Replace('$Script:','$').Replace('终止脚本','终止程序') | &$PSScriptRoot/tools/psminnifyer/psminnifyer.ps1 } `
		-TempDir "$PSScriptRoot/build" -iconFile $PSScriptRoot/../img/esh.ico `
		-title 'E-Shell' -description 'E-Shell' -version '1960.7.17.13' `
		-company 'E-tek' -product 'E-Sh' -copyright '(c) E-tek Corporation. All rights reserved.'
	
	$ConfuserFile = if (Test-Path "$PSScriptRoot/tools/ConfuserEx/Confuser.CLI.exe") { "$PSScriptRoot/tools/ConfuserEx/Confuser.CLI.exe" }
	else { (Get-Command Confuser.CLI -ErrorAction Ignore).Source }
	if(-not $ConfuserFile){
		Write-Host "Confuser.CLI not found. Downloading..."
		try{
			Invoke-WebRequest https://github.com/mkaring/ConfuserEx/releases/latest/download/ConfuserEx-CLI.zip -OutFile $PSScriptRoot/tools/ConfuserEx.zip
			New-Item -ItemType Directory -Force -Path $PSScriptRoot/tools/ConfuserEx | Out-Null
			Expand-Archive -Path $PSScriptRoot/tools/ConfuserEx.zip -DestinationPath $PSScriptRoot/tools/ConfuserEx
		} catch {
			Write-Warning "Download failed.. Skipping obfuscation.
Download it from https://github.com/mkaring/ConfuserEx
and put it in the environment path or in $PSScriptRoot/tools/ConfuserEx"
		}
		if (Test-Path "$PSScriptRoot/tools/ConfuserEx/Confuser.CLI.exe") {
			$ConfuserFile = "$PSScriptRoot/tools/ConfuserEx/Confuser.CLI.exe"
			Write-Host "Download complete."
		}
	}
	if($ConfuserFile){
		$OutputLength = (Get-Item "$PSScriptRoot/build/esh.exe").Length
		& $ConfuserFile -n -o="$PSScriptRoot/build" "$PSScriptRoot/build/esh.exe" | Out-Null #太长了
		$ObfusLength = (Get-Item "$PSScriptRoot/build/esh.exe").Length
		if($ObfusLength -ne $OutputLength){
			Write-Host "Obfuscation complete -> $ObfusLength bytes"
		}
		elseif($LASTEXITCODE -eq 1){
			Write-Warning "Obfuscation failed."
		}
	}

	if ($SigThief) {
		if (-not (Test-Path "$PSScriptRoot/tools/SigThief/sigthief.py")) {
			GetToolFromGit SigThief
		}
		if (-not $SigThiefFile) {
			$SigThiefFile = "$env:windir\explorer.exe"
		}
		if (Get-Command python -ErrorAction Ignore) {
			python "$PSScriptRoot/tools/SigThief/sigthief.py" -i $SigThiefFile -t "$PSScriptRoot/build/esh.exe" -o $OutputFile
		}
		else {
			Write-Warning "Python not found. Skipping sigthief."
			Copy-Item "$PSScriptRoot/build/esh.exe" $OutputFile
		}
	}
	else{
		Copy-Item "$PSScriptRoot/build/esh.exe" $OutputFile
		Write-Host "Skipping sigature theft."
	}
	$date = (Get-Date -Year 1960 -Month 7 -Day 17 -Hour 16 -Minute 4 -Second 13 -Millisecond 29)
	[IO.File]::SetCreationTime($OutputFile, $date)
	[IO.File]::SetLastWriteTime($OutputFile, $date)
	[IO.File]::SetLastAccessTime($OutputFile, $date)
}
