. $PSScriptRoot/base.ps1

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

if ($EshellUI) {
	$EshellUI.Remove()
	Remove-Variable EshellUI -Scope Global
}

if (YorN "要删除 Esh 安装目录吗？" -helpMessageY "将会删除 $eshDir" -defaultN:($eshDir -match "workspace|workstation")) {
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
