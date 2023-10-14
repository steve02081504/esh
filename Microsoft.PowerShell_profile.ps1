. $PSScriptRoot/VirtualTerminal.ps1
. $PSScriptRoot/Console.ps1
#保存当前光标位置
Write-Output "${VirtualTerminal.SaveCursor}E-Shell v1765.3.13"
Write-Output "Loading..."
Write-Output ""

#set the title same as cmd
$host.UI.RawUI.WindowTitle = "命令提示符"
Set-ConsoleIcon("$PSScriptRoot/img/cmd.ico")
#as root?
$ImSudo=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] “Administrator”)
#if as root
If ($ImSudo){
	$host.UI.RawUI.WindowTitle += "(root)"
}

#set thefuck as alias "fk"
$env:PYTHONIOENCODING="utf-8"
Invoke-Expression "$(thefuck --alias fk)"

. $PSScriptRoot/linux.ps1

#set prompt same as cmd
function prompt {
	if ($PWD.Path.StartsWith($HOME)) {
		$shortPath = '~' + $PWD.Path.Substring($HOME.Length)
	}
	elseif ($PWD.Path.StartsWith(${MSYS.RootPath})) {
		$shortPath = '/' + $PWD.Path.Substring(${MSYS.RootPath}.Length)
		$shortPath = $shortPath.Replace('\','/')
		if($shortPath.StartsWith('//')){
			$shortPath = $shortPath.Substring(1)
		}
	}
	else {
		$shortPath = $PWD.Path
	}
	if(($shortPath -eq "~") -or ($shortPath -eq "/")){
		"$shortPath >"
	}
	else{
		"$shortPath>"
	}
}

#import appx with -UseWindowsPowerShell to avoid [Operation is not supported on this platform. (0x80131539)]
Import-Module Appx -UseWindowsPowerShell

# https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
	Install-Module -Name Terminal-Icons -Repository PSGallery
}
Import-Module -Name Terminal-Icons

function EShell {
	pwsh.exe -NoProfileLoadTime -nologo
}
function sudo {
	param(
		[string]$Command
	)
	if ([string]::IsNullOrWhiteSpace($Command)) {
		# If the command is empty, open a new PowerShell shell with admin privileges
		Start-Process -Wait -FilePath "wt.exe" -ArgumentList "pwsh.exe -NoProfileLoadTime -nologo" -Verb runas
	} else {
		# Otherwise, run the command as an admin
		Start-Process -Wait -FilePath "wt.exe" -ArgumentList "$Command" -Verb runas
	}
}
function mklink {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	#对于每个参数
	$RemainingArguments = $RemainingArguments | ForEach-Object {
		#若参数长度大于2且是linux路径
		if (($_.Length -gt 2) -and (IsLinuxPath($_))) {
			#转换为windows路径
			LinuxPathToWindowsPath($_)
		}
		else{
			$_
		}
	}
	#调用cmd的mklink
	. cmd /c mklink $RemainingArguments
}

. $PSScriptRoot/BlueStacks.ps1
. $PSScriptRoot/CHT2CHS.ps1

#对于每个appLabel 创建一个函数用于启动
Show-apks | ForEach-Object {
	$AppLabel = CHT2CHS($_.appLabel)
	$Package = $_.package
	New-Item -Path Function: -Name $AppLabel -Value {
		Start-apk -apkSignOrName $Package
	}
}

#clear screen#恢复光标位置
Write-Host -NoNewline "${VirtualTerminal.RestoreCursor}${VirtualTerminal.ClearScreenDown}${VirtualTerminal.Colors.Green}E-Shell"
If ($ImSudo){
	Write-Host -NoNewline "${VirtualTerminal.Colors.Cyan}(root)"
}
Write-Output " ${VirtualTerminal.Colors.Yellow}v1960.7.17"
Write-Output "${VirtualTerminal.Styles.Italic}${VirtualTerminal.Colors.BrightMagenta}(c)${VirtualTerminal.Colors.Reset} E-tek Corporation.${VirtualTerminal.Styles.NoItalic} ${VirtualTerminal.Styles.Underline}All rights reserved${VirtualTerminal.Styles.NoUnderline}."
Write-Output "Type '${VirtualTerminal.Colors.BrightYellow}fk${VirtualTerminal.Colors.Reset}' to fuck typos."
Write-Output ""
