#!/usr/bin/env pwsh
$profilesDir = Split-Path $PROFILE
# 遍历环境变量
$env:Path.Split(";") | ForEach-Object {
	if ($_ -like "*[\\/]esh[\\/]path*") {
		if(Test-Path $_ -PathType Container){
			$eshDir = $_ -replace "[\\/]path[\\/]*$",''
			$eshDirFromEnv = $true
		}
		else{
			Write-Warning "检测到无效的esh环境变量于$_，请考虑删除"
		}
	}
}
if (-not $eshDir){
	$eshDir =
	if(Test-Path $profilesDir/esh) {
		 "$profilesDir/esh"
	}
	elseif(Test-Path $PWD/path/esh) {
		$PWD
	}
}
New-Item -ItemType Directory -Force -Path $profilesDir | Out-Null
if (-not $eshDir) {
	Remove-Item $profilesDir/esh -Confirm -ErrorAction Ignore -Recurse
	Remove-Item $profilesDir/esh-master -Force -ErrorAction Ignore -Confirm:$false -Recurse
	Invoke-WebRequest https://github.com/steve02081504/esh/archive/refs/heads/master.zip -OutFile Eshell.zip
	Expand-Archive Eshell.zip $profilesDir -Force
	Remove-Item Eshell.zip -Force
	Move-Item $profilesDir/esh-master $profilesDir/esh -Force
	$eshDir = "$profilesDir/esh"
}
else{
	Write-Host "检测到已安装 Esh 于 $eshDir"
}
function Choice($caption, $message) {
	do {
	    $response = $Host.UI.PromptForChoice($caption, $message, @('&Yes', '&No'), 1)
	} until ($response -ne -1)
	$response -eq 0
}
if ((-not $eshDirFromEnv) -and (Choice("", "你想要安装 Eshell 到环境变量吗？"))) {
	$env:Path += ";$profilesDir/esh/path"
	$UserPath = [Environment]::GetEnvironmentVariable("Path", "User") + ";$profilesDir/esh/path"
	[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")
	Write-Host "安装成功！`n你现在可以在任何地方使用 ``esh`` 或 ``EShell`` 命令了。"
}
$profilEshDir = $eshDir
if ($profilEshDir -like "$profilesDir[\\/]?*") {
	$profilEshDir = $profilEshDir -replace "^$($profilesDir -replace "\\","\\")[\\/]?",'$PSScriptRoot/'
}
$startScript = ". $profilEshDir/run.ps1"
$universalProfile = "$profilesDir/profile.ps1"
function checkLoaded ($theProfile) {
	(Get-Content $theProfile -ErrorAction Ignore) -ccontains $startScript
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
if ((-not $added) -and (Choice("", "你想要添加 Eshell 到 PowerShell 配置文件吗？"))) {
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
if(-not $EshellUI) {
	. $eshDir/run.ps1 -Invocation $MyInvocation
}
Remove-Variable @("profilesDir", "eshDir", "startScript", "universalProfile", "added", "profilEshDir", "eshDirFromEnv") -ErrorAction Ignore
Remove-Item @("function:Choice", "function:checkLoaded", "function:Choice") -ErrorAction Ignore
