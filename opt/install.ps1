#!/usr/bin/env pwsh
[CmdletBinding()]param([switch]$FromScript=$false)

# 假如在win8以下的系统上运行，那么我们需要先检查和修复一下输出编码
if ($IsWindows -and ([System.Environment]::OSVersion.Version.Major -le 7)) {
	$CursorPosBackUp = $host.UI.RawUI.CursorPosition
	$CodingBackUp = [Console]::OutputEncoding
	$TestText = '中文测试你好小笼包我是冰激凌'
	function TestAndSet ($Encoding) {
		try { Write-Host $TestText }
		catch { $error.RemoveAt(0); [Console]::OutputEncoding = $Encoding }
		$host.UI.RawUI.CursorPosition = $CursorPosBackUp
	}
	TestAndSet ([System.Text.Encoding]::GetEncoding(936))
	TestAndSet $CodingBackUp
	Write-Host $(' ' * $TestText.Length * 2)
	$host.UI.RawUI.CursorPosition = $CursorPosBackUp
}
# 遍历环境变量
$env:Path.Split(";") | ForEach-Object {
	if ($_ -and (-not (Test-Path $_ -PathType Container))) {
		Write-Warning "检测到无效的环境变量于$_，请考虑删除"
	}
	elseif ($_ -like "*[\\/]esh[\\/]path*") {
		$eshDir = $_ -replace "[\\/]path[\\/]*$", ''
		$eshDirFromEnv = $true
	}
}
# 使用if判断+赋值：我们不能使用??=因为用户可能以winpwsh运行该脚本
if (-not $eshDir) {
	$eshDir =
	if ($EshellUI.Sources.Path -and (Test-Path "${EshellUI.Sources.Path}/path/esh")) { $EshellUI.Sources.Path }
	elseif (Test-Path $PSScriptRoot/../path/esh) { $PSScriptRoot }
	elseif (Test-Path $env:LOCALAPPDATA/esh) { "$env:LOCALAPPDATA/esh" }
}
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
	# 运行环境中完全可能没有pwsh（用户用winpwsh运行该脚本），所以我们需要进行一些额外的检查
	if (-not (Get-Command pwsh -ErrorAction Ignore)) {
		# tiny10或tiny11完全可能没有winget，额外的代码来修复它
		if (-not (Get-Command winget -ErrorAction Ignore)) {
			# 这段if的大前提已经是在winpwsh中了 不需要额外的判断来确定是否使用-UseWindowsPowerShell flag导入Appx
			Import-Module Appx
			Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
		}
		# 额外的判断：在win8以下的系统中，最后一个能运行的pwsh版本是7.2.15
		Invoke-Expression "winget install --id Microsoft.Powershell $(
			if([System.Environment]::OSVersion.Version.Major -le 7){'-v 7.2.15'}
		)"
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
