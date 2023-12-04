#!/usr/bin/env pwsh

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
	Write-Host "未找到 Esh 安装目录，无法卸载。"
	exit 1
}
else {
	Write-Host "检测到已安装 Esh 于 $eshDir"
	if ($EshellUI) { Write-Host "（并且你正在使用它 :(）" }
}

. $eshDir/src/opt/uninstall.ps1
