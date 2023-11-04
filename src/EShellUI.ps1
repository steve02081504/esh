. $PSScriptRoot/base.ps1
. $PSScriptRoot/VirtualTerminal.ps1

if ($ImVSCodeExtension) {Clear-Host}
#保存光标位置便于后面清除输出
if ($Host.UI.SupportsVirtualTerminal -eq 0) {
	$CursorPos = $host.UI.RawUI.CursorPosition
}
Write-Host "${VirtualTerminal.SaveCursor}E-Shell v1765.3.13"
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

if ($Host.UI.SupportsVirtualTerminal -eq 0) {
	$host.UI.RawUI.CursorPosition = $CursorPos
	Remove-Variable CursorPos
}
Write-Host -NoNewline "${VirtualTerminal.RestoreCursor}${VirtualTerminal.ClearScreenDown}${VirtualTerminal.Colors.Green}E-Shell"
if ($ImSudo) {
	Write-Host -NoNewline "${VirtualTerminal.Colors.Cyan}(root)"
}
if ($ImVSCodeExtension) {
	Write-Host -NoNewline "${VirtualTerminal.Colors.Magenta} For ${VirtualTerminal.Styles.Italic}VSCode PowerShell Extension${VirtualTerminal.Styles.NoItalic}"
}
Write-Host " ${VirtualTerminal.Colors.Yellow}v1960.7.17"
Write-Host "${VirtualTerminal.Styles.Italic}${VirtualTerminal.Colors.BrightMagenta}(c)${VirtualTerminal.Colors.Reset} E-tek Corporation.${VirtualTerminal.Styles.NoItalic} ${VirtualTerminal.Styles.Underline}All rights reserved${VirtualTerminal.Styles.NoUnderline}."

. $PSScriptRoot/EShellUI.hints.ps1

Write-Host ""
