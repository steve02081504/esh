. $PSScriptRoot/hints.ps1
$EshellUI.Logo = ValueEx @{
	Parent = $EshellUI
	"method:Print" = {
		$local:EshellUI = $this.Parent
		Write-Host -NoNewline "${VirtualTerminal.ClearScreenDown}${VirtualTerminal.Colors.Green}E-Shell"
		if ($EshellUI.Im.Sudo) {
			Write-Host -NoNewline "${VirtualTerminal.Colors.Cyan}(root)"
		}
		Write-Host -NoNewline " ${VirtualTerminal.Colors.Yellow}v1960.7.17"
		if ($EshellUI.Im.VSCodeExtension) {
			Write-Host -NoNewline "${VirtualTerminal.Colors.Magenta} For ${VirtualTerminal.Styles.Italic}VSCode PowerShell Extension ${VirtualTerminal.Styles.NoItalic}v$($host.Version.ToString())"
		}
		Write-Host ""
		Write-Host "${VirtualTerminal.Styles.Italic}${VirtualTerminal.Colors.BrightMagenta}(c)${VirtualTerminal.Colors.Reset} E-tek Corporation.${VirtualTerminal.Styles.NoItalic} ${VirtualTerminal.Styles.Underline}All rights reserved${VirtualTerminal.Styles.NoUnderline}."

		$EshellUI.Hints.PrintRandom()

		Write-Host ""
	}
}
