. $PSScriptRoot/hints.ps1
$EshellUI.Logo = ValueEx @{
	Parent = $EshellUI
	'method:Print' = {
		param($hint)
		$local:EshellUI = $this.Parent
		Write-Host -NoNewline "$($VirtualTerminal.ClearScreenDown)$($VirtualTerminal.Colors.Green)E-Shell"
		if ($EshellUI.Im.Sudo) {
			Write-Host -NoNewline "$($VirtualTerminal.Colors.Cyan)(root)"
		}
		Write-Host -NoNewline " $($VirtualTerminal.Colors.Yellow)v1960.7.17"
		if ($EshellUI.Im.VSCodeExtension) {
			Write-Host -NoNewline "$($VirtualTerminal.Colors.Magenta) For $($VirtualTerminal.Styles.Italic)VSCode PowerShell Extension $($VirtualTerminal.Styles.NoItalic)v$($host.Version.ToString())"
		}
		elseif ($EshellUI.Im.WindowsTerminal) {
			Write-Host -NoNewline "$($VirtualTerminal.Colors.Magenta) In $($VirtualTerminal.Styles.Italic)Windows Terminal $($VirtualTerminal.Styles.NoItalic)v$($EshellUI.OtherData.WindowsTerminalVersion)"
		}
		Write-Host
		Write-Host "$($VirtualTerminal.Styles.Italic)$($VirtualTerminal.Colors.BrightMagenta)(c)$($VirtualTerminal.Colors.Reset) E-tek Corporation.$($VirtualTerminal.Styles.NoItalic) $($VirtualTerminal.Styles.Underline)All rights reserved$($VirtualTerminal.Styles.NoUnderline)."

		if ($hint) { Write-Host $hint } else { $EshellUI.Hints.PrintRandom() }

		Write-Host
	}
}
