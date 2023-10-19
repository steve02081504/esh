. $PSScriptRoot/VirtualTerminal.ps1
#保存光标位置便于后面清除输出
if ($Host.UI.SupportsVirtualTerminal -eq 0) {
	$CursorPos = $host.UI.RawUI.CursorPosition
}
Write-Output "${VirtualTerminal.SaveCursor}E-Shell v1765.3.13"
Write-Output "Loading..."
Write-Output ""

. $PSScriptRoot/base.ps1

. $PSScriptRoot/Console.ps1
#set the title same as cmd
$host.UI.RawUI.WindowTitle = "命令提示符"
Set-ConsoleIcon ("$PSScriptRoot/../img/cmd.ico")
#if as root
if ($ImSudo) {
	$host.UI.RawUI.WindowTitle += "(root)"
}


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
Write-Output " ${VirtualTerminal.Colors.Yellow}v1960.7.17"
Write-Output "${VirtualTerminal.Styles.Italic}${VirtualTerminal.Colors.BrightMagenta}(c)${VirtualTerminal.Colors.Reset} E-tek Corporation.${VirtualTerminal.Styles.NoItalic} ${VirtualTerminal.Styles.Underline}All rights reserved${VirtualTerminal.Styles.NoUnderline}."

$hints = @()
if (Test-Command thefuck) {
	$hints += "Type '${VirtualTerminal.Colors.BrightYellow}fk${VirtualTerminal.Colors.Reset}' to fuck typos."
}
if (Test-Command coffee) {
	$hints += "Type '${VirtualTerminal.Colors.BrightYellow}coffee${VirtualTerminal.Colors.Reset}' to get a cup of coffee."
}
Write-Output $(Get-Random $hints)

Write-Output ""
