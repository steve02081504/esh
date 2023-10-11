#clear screen
Clear-Host
Write-Output "E-Shell v1765.3.13"
Write-Output "Loading..."
Write-Output ""

#set the title same as cmd
$host.UI.RawUI.WindowTitle = "命令提示符"
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

. $PSScriptRoot/VirtualTerminal.ps1

#clear screen
Clear-Host
Write-Host -NoNewline "${VirtualTerminal.Colors.Green}E-Shell"
If ($ImSudo){
	Write-Host -NoNewline "${VirtualTerminal.Colors.Cyan}(root)"
}
Write-Output " ${VirtualTerminal.Colors.Yellow}v1960.7.17"
Write-Output "${VirtualTerminal.Styles.Italic}${VirtualTerminal.Colors.BrightMagenta}(c)${VirtualTerminal.Colors.Reset} E-tek Corporation.${VirtualTerminal.Styles.NoItalic} ${VirtualTerminal.Styles.Underline}All rights reserved${VirtualTerminal.Styles.NoUnderline}."
Write-Output ""
