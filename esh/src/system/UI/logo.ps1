. $PSScriptRoot/hints.ps1
Add-Member -InputObject $EshellUI -MemberType ScriptMethod -Name PrintLogo -Value {
	Write-Host -NoNewline "${VirtualTerminal.ClearScreenDown}${VirtualTerminal.Colors.Green}E-Shell"
	if ($this.Im.Sudo) {
		Write-Host -NoNewline "${VirtualTerminal.Colors.Cyan}(root)"
	}
	Write-Host -NoNewline " ${VirtualTerminal.Colors.Yellow}v1960.7.17"
	if ($EshellUI.Im.VSCodeExtension) {
		Write-Host -NoNewline "${VirtualTerminal.Colors.Magenta} For ${VirtualTerminal.Styles.Italic}VSCode PowerShell Extension ${VirtualTerminal.Styles.NoItalic}v$($host.Version.ToString())"
	}
	Write-Host ""
	Write-Host "${VirtualTerminal.Styles.Italic}${VirtualTerminal.Colors.BrightMagenta}(c)${VirtualTerminal.Colors.Reset} E-tek Corporation.${VirtualTerminal.Styles.NoItalic} ${VirtualTerminal.Styles.Underline}All rights reserved${VirtualTerminal.Styles.NoUnderline}."

	$this.Hints.PrintRandom()

	Write-Host ""
}
