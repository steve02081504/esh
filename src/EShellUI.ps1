. $PSScriptRoot/base.ps1
. $PSScriptRoot/VirtualTerminal.ps1

if ($ImVSCodeExtension) { Clear-Host }
Write-Host "E-Shell v1765.3.13"
Write-Host "Loading..."
Write-Host ""

. $PSScriptRoot/Console.ps1
#set the title same as cmd
$host.UI.RawUI.WindowTitle = "命令提示符"
Set-ConsoleIcon ("$PSScriptRoot/../img/cmd.ico")
#if as root
if ($ImSudo) {
	$host.UI.RawUI.WindowTitle += "(root)"
}

. $PSScriptRoot/CodePageFixer.ps1

. $PSScriptRoot/linux.ps1
. $PSScriptRoot/prompt.ps1
. $PSScriptRoot/other.ps1

#一些耗时的后台任务
. $PSScriptRoot/BackgroundLoading.ps1

$CursorPos = $host.UI.RawUI.CursorPosition
$CursorPos.Y -= 3
$host.UI.RawUI.CursorPosition = $CursorPos
Remove-Variable CursorPos

Write-Host -NoNewline "${VirtualTerminal.ClearScreenDown}${VirtualTerminal.Colors.Green}E-Shell"
if ($ImSudo) {
	Write-Host -NoNewline "${VirtualTerminal.Colors.Cyan}(root)"
}
Write-Host -NoNewline " ${VirtualTerminal.Colors.Yellow}v1960.7.17"
if ($ImVSCodeExtension) {
	Write-Host -NoNewline "${VirtualTerminal.Colors.Magenta} For ${VirtualTerminal.Styles.Italic}VSCode PowerShell Extension ${VirtualTerminal.Styles.NoItalic}v$($host.Version.ToString())"
}
Write-Host ""
Write-Host "${VirtualTerminal.Styles.Italic}${VirtualTerminal.Colors.BrightMagenta}(c)${VirtualTerminal.Colors.Reset} E-tek Corporation.${VirtualTerminal.Styles.NoItalic} ${VirtualTerminal.Styles.Underline}All rights reserved${VirtualTerminal.Styles.NoUnderline}."

. $PSScriptRoot/EShellUI.hints.ps1

Write-Host ""
