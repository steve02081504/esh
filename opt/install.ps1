#!/usr/bin/env pwsh
[CmdletBinding()]param([switch]$FromScript=$false)

if((Get-ExecutionPolicy) -eq 'Restricted'){ Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
function illusionlimb($path) {
	Invoke-Expression $(if (Test-Path $PSScriptRoot/../path/esh) { (Get-Content "$PSScriptRoot/$path") -join "`n" }
	else { (Invoke-WebRequest "https://github.com/steve02081504/esh/raw/master/opt/$path").Content })
}

illusionlimb ../src/fixers/CodePageFixer.ps1
illusionlimb ../src/opt/EshFinder.ps1

if (-not $eshDir) {
	Remove-Item $env:LOCALAPPDATA/esh -Confirm -ErrorAction Ignore -Recurse
	Remove-Item $env:TEMP/esh-master -Force -ErrorAction Ignore -Confirm:$false -Recurse
	try { Invoke-WebRequest https://github.com/steve02081504/esh/archive/refs/heads/master.zip -OutFile $env:TEMP/Eshell.zip }
	catch {
		$Host.UI.WriteErrorLine("下载错误 终止脚本")
		exit 1
	}
	Expand-Archive $env:TEMP/Eshell.zip $env:TEMP -Force
	Remove-Item $env:TEMP/Eshell.zip -Force
	Move-Item $env:TEMP/esh-master $env:LOCALAPPDATA/esh -Force
	$eshDir = "$env:LOCALAPPDATA/esh"
	try { Invoke-WebRequest 'https://github.com/steve02081504/SAO-lib/raw/master/SAO-lib.txt' -OutFile "$eshDir/data/SAO-lib.txt" }
	catch {
		Write-Host "啊哦 SAO-lib下载失败了`n这不会影响什么，不过你可以在Esh安装好后使用``Update-SAO-lib``来让Esh有机会显示更多骚话"
	}
}
else {
	Write-Host "检测到已安装 Esh 于 $eshDir"
	if ($EshellUI) { Write-Host "（并且你正在使用它 :)）" }
}

. $eshDir/src/opt/install.ps1

if (-not (Get-Command pwsh -ErrorAction Ignore)) {
	$Host.UI.WriteErrorLine("esh的运行需要PowerShell 6或以上`n访问 https://aka.ms/pscore6 来获取PowerShell 6+ 并使得``pwsh``命令在环境中可用以使得esh能够正常工作")
}
elseif ((-not $EshellUI) -and (YorN "要使用 Eshell 吗？")) {
	if ($FromScript -or ($PSVersionTable.PSVersion.Major -lt 6)) {
		. $eshDir/opt/run
		[System.Environment]::Exit($LastExitCode)
	}
	else { . $eshDir/opt/run.ps1 -Invocation $MyInvocation }
}
