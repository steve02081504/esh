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

#set prompt same as cmd
function prompt {"$PWD>"}

#remove alias "rm" as it is conflict with linux submode's /usr/bin/rm
Remove-Item -Path Alias:rm

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

. $PSScriptRoot/BlueStacks.ps1
. $PSScriptRoot/CHT2CHS.ps1

#对于每个appLabel 创建一个函数用于启动
$apkList = Show-apks
$apkList | ForEach-Object {
	$AppLabel = CHT2CHS($_.appLabel)
	$Package = $_.package
	New-Item -Path Function: -Name $AppLabel -Value {
		Start-apk -apkSignOrName $Package
	}
}
Remove-Variable apkList

#clear screen#恢复光标位置
Write-Host -NoNewline "${VirtualTerminal.RestoreCursor}${VirtualTerminal.ClearScreenDown}${VirtualTerminal.Colors.Green}E-Shell"
If ($ImSudo){
	Write-Host -NoNewline "${VirtualTerminal.Colors.Cyan}(root)"
}
Write-Output " ${VirtualTerminal.Colors.Yellow}v1960.7.17"
Write-Output "${VirtualTerminal.Styles.Italic}${VirtualTerminal.Colors.BrightMagenta}(c)${VirtualTerminal.Colors.Reset} E-tek Corporation.${VirtualTerminal.Styles.NoItalic} ${VirtualTerminal.Styles.Underline}All rights reserved${VirtualTerminal.Styles.NoUnderline}."
Write-Output ""
