#!/usr/bin/env pwsh
[CmdletBinding()]param(
	[switch]$Force=$false,
	[switch]$Fix=$false,
	[ValidateSet('yes', 'no', 'ask', 'auto')][string]$StartEsh='auto'
)
function illusionlimb($path) {
	Invoke-Expression $(if (Test-Path $PSScriptRoot/../path/esh) { Get-Content "$PSScriptRoot/../src/$path" -Raw }
	else { (Invoke-WebRequest "https://github.com/steve02081504/esh/raw/master/src/$path").Content })
}

illusionlimb fixers/CodePageFixer.ps1
illusionlimb opt/opt_init.ps1

if (-not $eshDir) {
	illusionlimb opt/download.ps1
}
else {
	Write-Host "检测到已安装 Esh 于 $eshDir"
	if ($EshellUI) { Write-Host "（并且你正在使用它 :)）" }
}

. $eshDir/src/opt/install.ps1 -Force:$Force -StartEsh:$StartEsh -Fix:$Fix
