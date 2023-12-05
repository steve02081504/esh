#!/usr/bin/env pwsh

if((Get-ExecutionPolicy) -eq 'Restricted'){ Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
function illusionlimb($path) {
	Invoke-Expression $(if (Test-Path $PSScriptRoot/../path/esh) { (Get-Content "$PSScriptRoot/$path") -join "`n" }
	else { (Invoke-WebRequest "https://github.com/steve02081504/esh/raw/master/opt/$path").Content })
}

illusionlimb ../src/fixers/CodePageFixer.ps1
illusionlimb ../src/opt/EshFinder.ps1

if (-not $eshDir) {
	Write-Host "未找到 Esh 安装目录，无法卸载。"
	exit 1
}
else {
	Write-Host "检测到已安装 Esh 于 $eshDir"
	if ($EshellUI) { Write-Host "（并且你正在使用它 :(）" }
}

. $eshDir/src/opt/uninstall.ps1
