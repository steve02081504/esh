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
	if ($EshellUI.Sources.Path -and (Test-Path $EshellUI.Sources.Path/path/esh)) { $EshellUI.Sources.Path }
	elseif (Test-Path $PSScriptRoot/path/esh) { $PSScriptRoot }
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
function YorN($message, $helpMessageY = "", $helpMessageN = "", [switch]$defaultN = $false) {
	do {
		$response = $Host.UI.PromptForChoice("", $message, @(
				[ChoiceDescription]::new('&Yes', $helpMessageY), [ChoiceDescription]::new('&No', $helpMessageN)
			), [int][bool]$defaultN)#不要使用$defaultN+0，这样的操作只在pwsh中有效
	} until ($response -ne -1)
	-not $response
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
	$startScript = ". $eshDir/run.ps1"
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
	$wtFragmentDir = "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\esh"
	$WtProfileBase = @{
		commandline       = @("$eshDir/path/")[$eshDirFromEnv] + "esh.cmd"
		icon              = "ms-appx:///ProfileIcons/{0caa0dad-35be-5f56-a8ff-afceeeaa6101}.png"
		startingDirectory = "~"
		hidden            = $false
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
}

if (-not (Get-Command pwsh -ErrorAction Ignore)) {
	$Host.UI.WriteErrorLine("esh的运行需要PowerShell 6或以上`n访问 https://aka.ms/pscore6 来获取PowerShell 6+ 并使得``pwsh``命令在环境中可用以使得esh能够正常工作")
}
elseif ((-not $EshellUI) -and (YorN "要使用 Eshell 吗？")) {
	if ($PSVersionTable.PSVersion.Major -lt 6) {
		. $eshDir/run.cmd
		[System.Environment]::Exit($LastExitCode)
	}
	else { . $eshDir/run.ps1 -Invocation $MyInvocation }
}
