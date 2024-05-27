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
begin {
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
	if (-not (Get-Module -ListAvailable ps12exe)) {
		Install-Module ps12exe -Force
	}
	if (-not (Test-Path "$PSScriptRoot/tools/psminnifyer/psminnifyer.ps1")) {
		GetToolFromGit psminnifyer
	}
	if ($SigThief) {
		if (-not (Test-Path "$PSScriptRoot/tools/SigThief/sigthief.py")) {
			GetToolFromGit SigThief
		}
	}
	$MpressFile = if (Test-Path "$PSScriptRoot/tools/mpress/mpress.exe") { "$PSScriptRoot/tools/mpress/mpress.exe" }
	else { (Get-Command mpress -ErrorAction Ignore).Source }
	if (-not $MpressFile) {
		Write-Host "Mpress not found. Downloading..."
		try {
			Invoke-WebRequest https://web.archive.org/web/20150506065200/http://www.matcode.com/mpress.219.zip -OutFile $PSScriptRoot/tools/mpress.zip
			New-Item -ItemType Directory -Force -Path $PSScriptRoot/tools/mpress | Out-Null
			Expand-Archive -Path $PSScriptRoot/tools/mpress.zip -DestinationPath $PSScriptRoot/tools/mpress
		} catch {
			Write-Warning "Download failed. Skipping compression.
	Download it from https://web.archive.org/web/20150506065200/http://www.matcode.com/mpress.219.zip
	and put it in the environment path or in $PSScriptRoot/tools/mpress"
		}
		if (Test-Path "$PSScriptRoot/tools/mpress/mpress.exe") {
			$MpressFile = "$PSScriptRoot/tools/mpress/mpress.exe"
			Write-Host "Download complete."
		}
	}
}
process {
	ps12exe $PSScriptRoot/main.ps1 "$PSScriptRoot/build/esh.exe" -NoConsole `
		-Minifyer { $_.Replace('$Script:','$').Replace('终止脚本','终止程序') | &$PSScriptRoot/tools/psminnifyer/psminnifyer.ps1 } `
		-TempDir "$PSScriptRoot/build" -iconFile $PSScriptRoot/../img/esh.ico `
		-title 'E-Shell' -description 'E-Shell' -version '1960.7.17.13' `
		-company 'E-tek' -product 'E-Sh' -copyright '(c) E-tek Corporation. All rights reserved.'

	if($MpressFile){
		$OutputLength = (Get-Item "$PSScriptRoot/build/esh.exe").Length
		& $MpressFile "$PSScriptRoot/build/esh.exe" -s | Out-Null
		$ObfusLength = (Get-Item "$PSScriptRoot/build/esh.exe").Length
		if($ObfusLength -ne $OutputLength){
			Write-Host "Compression complete -> $ObfusLength bytes"
		}
		elseif($LastExitCode -eq 1){
			Write-Warning "Compression failed."
		}
	}

	if ($SigThief) {
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
}
end {
	try{
		$date = (Get-Date -Year 1960 -Month 7 -Day 17 -Hour 16 -Minute 4 -Second 13 -Millisecond 29)
		[IO.File]::SetCreationTime($OutputFile, $date)
		[IO.File]::SetLastWriteTime($OutputFile, $date)
		[IO.File]::SetLastAccessTime($OutputFile, $date)
	} catch {
	}
}
