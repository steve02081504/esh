#!/usr/bin/env pwsh
using namespace System.Management.Automation

$profilesDir = Split-Path $PROFILE
# 遍历环境变量
$env:Path.Split(";") | ForEach-Object {
	if ($_ -and (-not (Test-Path $_ -PathType Container))) {
		Write-Warning "检测到无效的环境变量于$_，请考虑删除"
		return
	}
	if ($_ -like "*[\\/]esh[\\/]path*") {
		$eshDir = $_ -replace "[\\/]path[\\/]*$", ''
		$eshDirFromEnv = $true
	}
}
if (-not $eshDir) {
	$eshDir =
	if ($EshellUI.Sources.Path -and (Test-Path $EshellUI.Sources.Path)) { $EshellUI.Sources.Path }
	elseif (Test-Path $profilesDir/esh) { "$profilesDir/esh" }
	elseif (Test-Path $PWD/path/esh) { $PWD }
}
New-Item -ItemType Directory -Force -Path $profilesDir | Out-Null
if (-not $eshDir) {
	Remove-Item $profilesDir/esh -Confirm -ErrorAction Ignore -Recurse
	Remove-Item $profilesDir/esh-master -Force -ErrorAction Ignore -Confirm:$false -Recurse
	try { Invoke-WebRequest https://github.com/steve02081504/esh/archive/refs/heads/master.zip -OutFile Eshell.zip }
	catch {
		Write-Host "下载错误 终止脚本"
		exit 1
	}
	Expand-Archive Eshell.zip $profilesDir -Force
	Remove-Item Eshell.zip -Force
	Move-Item $profilesDir/esh-master $profilesDir/esh -Force
	$eshDir = "$profilesDir/esh"
	try { Invoke-WebRequest 'https://github.com/steve02081504/SAO-lib/raw/master/SAO-lib.txt' -OutFile "$eshDir/data/SAO-lib.txt" }
	catch {
		Write-Host "啊哦 SAO-lib下载失败了`n这不会影响什么，不过你可以在Esh安装好后使用``Update-SAO-lib``来让Esh有机会显示更多骚话"
	}
}
else {
	Write-Host "检测到已安装 Esh 于 $eshDir"
}
function YorN($message, [switch]$defaultN = $false) {
	do {
		$response = $Host.UI.PromptForChoice("", $message, @('&Yes', '&No'), $(if($defaultN){1}else{0}))
	} until ($response -ne -1)
	$response -eq 0
}
if ((-not $eshDirFromEnv) -and (YorN "要安装 Eshell 到环境变量吗？")) {
	$env:Path += ";$eshDir/path"
	$UserPath = [Environment]::GetEnvironmentVariable("Path", "User") + ";$eshDir/path"
	[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")
	Write-Host "安装成功！`n现在可以在任何地方使用 ``esh`` 或 ``EShell`` 命令了。"
	$eshDirFromEnv = $true
}
$profilEshDir = $eshDir
if ($profilEshDir -like "$profilesDir[\\/]?*") {
	$profilEshDir = $profilEshDir -replace "^$($profilesDir -replace "\\","\\")[\\/]?", '$PSScriptRoot/'
}
$startScript = ". $profilEshDir/run.ps1"
$universalProfile = "$profilesDir/profile.ps1"
function checkLoaded ($theProfile) {
	(Get-Content $theProfile -ErrorAction Ignore) -contains $startScript
}
$added = $false
@(
	$universalProfile
	$profile
) | ForEach-Object {
	$loaded = checkLoaded $_
	if ($loaded) {
		Write-Host "在${_}中已经加载过esh"
		$added = $true
	}
}
if ((-not $added) -and (YorN "要添加 Eshell 到 PowerShell 配置文件吗？" -defaultN:$true)) {
	@(
		$universalProfile
		$profile
	) | ForEach-Object {
		if (Test-Path $_) {
			Write-Warning "在${_}中添加了esh加载语句"
			Add-Content $_ $startScript
			$added = $true
		}
	}
	if (-not $added) {
		Write-Warning "未找到可用的profile文件，新建通用profile文件${universalProfile}"
		Set-Content $universalProfile $startScript
	}
}
$hasWT = [bool]$(Get-Command wt.exe -ErrorAction Ignore)
if ($hasWT) {
	$wtFragmentDir = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\esh"
	$BaseWtProfile = @{
		name = "Eshell"
		icon = "ms-appx:///ProfileIcons/{0caa0dad-35be-5f56-a8ff-afceeeaa6101}.png"
		commandline = "$(if(-not $eshDirFromEnv) { "$eshDir/path/" })esh.cmd -WorkingDirectory ~"
		hidden = $false
	}
	$RootWtProfile = [PSSerializer]::Deserialize([PSSerializer]::Serialize($BaseWtProfile))
	$RootWtProfile.name = "Eshell (Root)"
	$RootWtProfile.elevate = $true
	$wtFragment = @{
		schema = "https://aka.ms/terminal-profiles-schema"
		profiles = @( $BaseWtProfile, $RootWtProfile )
	}
	if ($PSVersionTable.PSVersion.Major -lt 6) {
		$wtFragmentJson = ($wtFragment | ConvertTo-Json).Replace("`r`n", "`n")
	}
	else{
		$wtFragmentJson = ($wtFragment | ConvertTo-Json -EnumsAsStrings).Replace("`r`n", "`n")
	}
	if(-not (Test-Path $wtFragmentDir/esh.json)) {}
	elseif (Test-Path $wtFragmentDir/esh.json) {
		if (-not (Compare-Object (Get-Content $wtFragmentDir/esh.json | ConvertFrom-Json) $wtFragment)) {
			Set-Content $wtFragmentDir/esh.json $wtFragmentJson -NoNewline
			Write-Warning "检测到旧的 Eshell Windows Terminal 配置文件，其已被更新。"
		}
	}
	elseif(YorN "要添加 Eshell 到 Windows Terminal 吗？") {
		New-Item -ItemType Directory -Force -Path $wtFragmentDir | Out-Null
		Set-Content $wtFragmentDir/esh.json $wtFragmentJson -NoNewline
	}
}

if ($PSVersionTable.PSVersion.Major -lt 6) {
	if(-not (YorN "你需要知道：esh的运行需要PowerShell 6或以上")) {
		Write-Host "爬。"
	}
}
if ((-not $EshellUI) -and (YorN "要使用 Eshell 吗？")) {
	if ($PSVersionTable.PSVersion.Major -lt 6) {
		. $eshDir/run.cmd
	}
	else {
		. $eshDir/run.ps1 -Invocation $MyInvocation
	}
}
Remove-Variable @("profilesDir", "eshDir", "startScript", "universalProfile", "added", "wtFragmentJson", "profilEshDir", "eshDirFromEnv", "hasWT", "wtFragmentDir", "wtFragment", "UserPath", "BaseWtProfile", "RootWtProfile") -ErrorAction Ignore
Remove-Item @("function:YorN", "function:checkLoaded") -ErrorAction Ignore
