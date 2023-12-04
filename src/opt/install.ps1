using namespace System.Management.Automation.Host

. $PSScriptRoot/base.ps1

#对于每个desktop.ini进行+s +h操作
Get-ChildItem $eshDir -Recurse -Filter desktop.ini | ForEach-Object {
	$_.Attributes = 'Hidden', 'System'
}
if ((-not $eshDirFromEnv) -and (YorN "要安装 Esh 到环境变量吗？" -helpMessageY "将可以在任何地方使用``esh``或``EShell``命令")) {
	$env:Path += ";$eshDir/path"
	$UserPath = [Environment]::GetEnvironmentVariable("Path", "User") + ";$eshDir/path"
	[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")
	Write-Host "安装成功！`n现在可以在任何地方使用 ``esh`` 或 ``EShell`` 命令了。"
	$eshDirFromEnv = $true
}
if ($PSVersionTable.PSVersion.Major -lt 6) {
	Write-Warning "当前版本的 PowerShell 不支持 Esh 作为配置文件，跳过配置文件的添加部分`n你可以通过使用合适的``pwsh``重新运行该脚本来添加配置文件"
}
else {
	$profilesDir = Split-Path $PROFILE
	$startScript = ". $eshDir/opt/run.ps1"
	$universalProfile = "$profilesDir/profile.ps1"
	function checkLoaded ($theProfile) { (Get-Content $theProfile -ErrorAction Ignore) -contains $startScript }
	$added = $false
	@(
		$universalProfile
		$profile
	) | ForEach-Object {
		if (checkLoaded $_) {
			Write-Information "在${_}中已经加载过esh"
			$added = $true
		}
	}
	if ((-not $added) -and (YorN "要添加 Eshell 到 PowerShell 配置文件吗？" -defaultN:($Host.Name -ne 'Visual Studio Code Host') -helpMessageY "powershell将表现得与Esh相同" -helpMessageN "让powershell保持原样，你仍然可以通过``esh``命令来使用Esh")) {
		@(
			$universalProfile
			$profile
		) | ForEach-Object {
			if (Test-Path $_) {
				Write-Information "在${_}中添加了esh加载语句"
				Add-Content $_ $startScript
				$added = $true
			}
		}
		if (-not $added) {
			do {
				$response = $Host.UI.PromptForChoice("未找到可用的profile文件", "选择你想要新建并添加Esh加载的配置文件", @(
						[ChoiceDescription]::new("&0`b通用配置文件", $universalProfile),
						[ChoiceDescription]::new("&1`b当前应用针对性配置文件", $profile)
					), 1)
			} until ($response -ne -1)
			$theProfile = @($universalProfile, $profile)[$response]
			New-Item -ItemType Directory -Force -Path $profilesDir | Out-Null
			Write-Information "在${theProfile}中添加了esh加载语句"
			Set-Content $theProfile $startScript
		}
	}
}
if ($IsWindows) {
	$EshCmd = @("$eshDir/path/")[$eshDirFromEnv] + "esh.cmd"
	$wtFragmentDir = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\esh"
	$WtProfileBase = @{
		commandline = $EshCmd; startingDirectory = "~"
		icon = "ms-appx:///ProfileIcons/{0caa0dad-35be-5f56-a8ff-afceeeaa6101}.png"
	}
	$wtFragment = @{
		schema   = "https://aka.ms/terminal-profiles-schema"
		profiles = @(
			@{name = "Eshell" } + $WtProfileBase
			@{name = "Eshell (Root)" ; elevate = $true } + $WtProfileBase
		)
	}
	$wtFragmentJson = ($wtFragment | ConvertTo-Json).Replace("`r`n", "`n")
	if (Test-Path $wtFragmentDir/esh.json) {
		if ((Get-Content $wtFragmentDir/esh.json -Raw) -ne $wtFragmentJson) {
			Set-Content $wtFragmentDir/esh.json $wtFragmentJson -NoNewline
			Write-Warning "检测到旧的 Eshell Windows Terminal 配置文件，其已被更新。"
		}
	}
	else {
		New-Item -ItemType Directory -Force -Path $wtFragmentDir | Out-Null
		Set-Content $wtFragmentDir/esh.json $wtFragmentJson -NoNewline
	}
	$startScript = "@$eshDir/opt/run -Command 1000-7"
	$LoaderPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Esh_loader.cmd"
	if (Test-Path $LoaderPath) {
		if ((Get-Content $LoaderPath -Raw) -ne $startScript) {
			Set-Content $LoaderPath $startScript -NoNewline
			Write-Warning "检测到旧的 Eshell 预启动器，其已被更新。"
		}
	}
	else {
		New-Item -ItemType Directory -Force -Path (Split-Path $LoaderPath) | Out-Null
		Set-Content $LoaderPath $startScript -NoNewline
	}
}
