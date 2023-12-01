#!/usr/bin/env pwsh
using namespace System.Management.Automation.Host

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
	elseif (Test-Path $PSScriptRoot/path/esh) { $PSScriptRoot }
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

# 移除环境变量
if ($eshDirFromEnv) {
	$matcher = ";?$([regex]::Escape($eshDir))[\\/]path"
	$env:Path = $env:Path -replace $matcher, ''
	$UserPath = [Environment]::GetEnvironmentVariable("Path", "User") -replace $matcher, ''
	[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")
	Write-Host "已从环境变量中移除 Esh。"
}

# 移除 PowerShell 配置文件中的 Eshell 加载语句
$profilesDir = Split-Path $PROFILE
$startScript = ". $eshDir/opt/run.ps1"

Get-ChildItem $profilesDir -Filter *profile.ps1 | ForEach-Object {
	$theprofile = $_.FullName
	$profileContent = Get-Content $theprofile
	if ($profileContent -contains $startScript) {
		$profileContent = $profileContent -replace [regex]::Escape($startScript), ''
		if("$profileContent" -match "^\s*$") {
			Remove-Item $theprofile -Force
			Write-Host "已从 $theprofile 中移除 Esh 加载语句并删除该空文件。"
		}
		else {
			Set-Content $theprofile $profileContent
			Write-Host "已从 $theprofile 中移除 Esh 加载语句。"
		}
	}
}

if($IsWindows){
	# 移除 Windows Terminal 的 Eshell 配置文件
	$wtFragmentDir = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\esh"
	if (Test-Path $wtFragmentDir) {
		Remove-Item $wtFragmentDir -Recurse -Force
		Write-Host "已从 Windows Terminal 中移除 Esh 配置文件。"
	}

	# 移除 Eshell 预启动器
	$LoaderPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Esh_loader.cmd"
	if (Test-Path $LoaderPath) {
		Remove-Item $LoaderPath -Force
		Write-Host "已从 Windows 启动项中移除 Esh 预启动器。"
	}
}

function YorN($message, $helpMessageY = "", $helpMessageN = "", [switch]$defaultN = $false) {
	do {
		$response = $Host.UI.PromptForChoice("", $message, @(
				[ChoiceDescription]::new('&Yes', $helpMessageY), [ChoiceDescription]::new('&No', $helpMessageN)
			), [int][bool]$defaultN)#不要使用$defaultN+0，这样的操作只在pwsh中有效
	} until ($response -ne -1)
	-not $response
}

if ($EshellUI) {
	$EshellUI.Remove()
	Remove-Variable EshellUI -Scope Global
}

if (YorN "要删除 Esh 安装目录吗？" -helpMessageY "将会删除 $eshDir" -helpMessageN "将会保留 $eshDir") {
	Remove-Item $eshDir -Recurse -Force
	Write-Host "已删除 Esh 安装目录。"
}

Write-Host "Eshell 卸载完成。"
$Requements = @()
@( "pwsh", "winget" ) | ForEach-Object {
	if (-not (Get-Command $_ -ErrorAction Ignore)) {
		$Requements += $_
	}
}
if ($Requements) {
	Write-Host "如果你的以下软件是在esh安装期间自动安装的，那么你可能会想要手动卸载它："
	$Requements | ForEach-Object { Write-Host "`t$_" }
}
