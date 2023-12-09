using namespace System.Management.Automation.Host
param(
	[switch]$Force=$false,
	[switch]$Fix=$false,
	[ValidateSet('yes', 'no', 'ask', 'auto')][string]$StartEsh='auto'
)

. $PSScriptRoot/base.ps1

if ($IsWindows) {
	# 运行环境中完全可能没有pwsh（用户用winpwsh运行该脚本），所以我们需要进行一些额外的检查
	try {
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
	}catch{}
	if ((Test-Path "$eshDir/.git") -and (-not (Test-Path "$eshDir/.git/desktop.ini"))) {
		Copy-Item "$eshDir/data/git_icon.ini" "$eshDir/.git/desktop.ini" -Force
	}
	Get-ChildItem $eshDir -Recurse -Filter desktop.ini -Force | ForEach-Object {
		$Dir = Get-Item $(Split-Path $_.FullName) -Force
		$Dir.Attributes = $Dir.Attributes -bor [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::Directory
		$_.Attributes = $_.Attributes -bor [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System
	}
	Get-ChildItem $eshDir -Recurse -Filter .* | ForEach-Object {
		$_.Attributes = $_.Attributes -bor [System.IO.FileAttributes]::Hidden
	}
	if ((Test-Path "$eshDir/../SAO-lib/SAO-lib.txt") -and (-not (Test-Path "$eshDir/data/SAO-lib.txt"))) {
		if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
			New-Item -ItemType SymbolicLink -Path "$eshDir/data/SAO-lib.txt" -Target "$eshDir/../SAO-lib/SAO-lib.txt" -Force
		}
		else{
			try{
				Start-Process -Wait -FilePath cmd.exe -ArgumentList "/c mklink `"$eshDir/data/SAO-lib.txt`" `"$eshDir/../SAO-lib/SAO-lib.txt`"" -Verb runas
			}catch{}
		}
	}
}
if (-not $Fix){
	if ((-not $eshDirFromEnv) -and (YorN "要安装 Esh 到环境变量吗？" -helpMessageY "将可以在任何地方使用``esh``或``EShell``命令" -SkipAsDefault:$Force)) {
		$env:Path += "`;$eshDir/path"
		$UserPath = [Environment]::GetEnvironmentVariable("Path", "User") + "`;$eshDir/path"
		[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")
		Write-Host "安装成功！`n现在可以在任何地方使用 ``esh`` 或 ``EShell`` 命令了。"
		$eshDirFromEnv = $true
	}
	if ($Host.Name -eq 'PSEXE') {
		Write-Warning "通过exe安装会跳过配置文件的设置（毕竟这不是任何powershell环境）`n你随时可以通过使用合适的``pwsh``运行$eshDir/opt/install来添加配置文件"
	}
	elseif ($PSVersionTable.PSVersion.Major -lt 6) {
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
		if ((-not $added) -and (YorN "要添加 Eshell 到 PowerShell 配置文件吗？" -defaultN:($Host.Name -ne 'Visual Studio Code Host') -helpMessageY "powershell将表现得与Esh相同" -helpMessageN "让powershell保持原样，你仍然可以通过``esh``命令来使用Esh（推荐）" -SkipAsDefault:$Force)) {
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
				if(-not $Force){
					do {
						$response = $Host.UI.PromptForChoice("未找到可用的profile文件", "选择你想要新建并添加Esh加载的配置文件", @(
								[ChoiceDescription]::new("&0`b当前应用针对性配置文件", $profile),
								[ChoiceDescription]::new("&1`b通用配置文件", $universalProfile)
							), 0)
					} until ($response -ne -1)
				}
				$theProfile = @($universalProfile, $profile)[$response]
				New-Item -ItemType Directory -Force -Path $profilesDir | Out-Null
				Write-Information "在${theProfile}中添加了esh加载语句"
				Set-Content $theProfile $startScript
			}
		}
	}
}
if ($IsWindows) {
	$EshCmd = @("$eshDir/path/")[$eshDirFromEnv] + "esh.cmd"
	$wtFragmentDir = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\esh"
	$WtProfileBase = [ordered]@{
		commandline = $EshCmd; startingDirectory = "~"
		icon = "$eshDir/img/esh.ico"
	}
	$wtFragment = [ordered]@{
		'$help' = "https://aka.ms/terminal-documentation"
		'$schema' = "https://aka.ms/terminal-profiles-schema"
		profiles = @(
			[ordered]@{name = "Eshell" } + $WtProfileBase
			[ordered]@{name = "Eshell (Root)" ; elevate = $true } + $WtProfileBase
		)
	}
	$wtFragmentJson = ($wtFragment | ConvertTo-Json).Replace("`r`n", "`n").Replace("  ", "`t")+ "`n"
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

if (-not (Get-Command pwsh -ErrorAction Ignore)) {
	$Host.UI.WriteErrorLine("esh的运行需要PowerShell 6或以上`n访问 https://aka.ms/pscore6 来获取PowerShell 6+ 并使得``pwsh``命令在环境中可用以使得esh能够正常工作")
}
else{
	[bool]$StartEsh = (-not $EshellUI) -and $(switch ($StartEsh) {
		no { $false }
		yes { $true }
		default { YorN "要使用 Eshell 吗？" -SkipAsDefault:($Force -and $StartEsh -eq 'auto') }
	})
}
if ($StartEsh) {
	. $eshDir/opt/run
	[System.Environment]::Exit($LastExitCode)
}
