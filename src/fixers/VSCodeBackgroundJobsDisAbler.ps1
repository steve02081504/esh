if ($EshellUI.Im.VSCodeExtension -and ($host.Version -le [version]'2023.8.0')) {
	$EshellUI.BackgroundJobs.Add({
		Unregister-Event -SubscriptionId $EshellUI.OtherData.IdleEvent.SubscriptionId -Force
		$EshellUI.OtherData.Remove('IdleEvent')
	}) | Out-Null
	$EshellUI.LoadingLog.AddWarning(
"EshellUI's BackgroundJobs has been disabled due to a bug of PowerShell VSCode Extension.
See $(
	$VirtualTerminal.Styles.Underline+$VirtualTerminal.Colors.BrightCyan
)https://github.com/PowerShell/vscode-powershell/issues/4851$(
	$VirtualTerminal.Styles.NoUnderline+$VirtualTerminal.Colors[(Get-Host).PrivateData.WarningForegroundColor.ToString()]
) for more info."
	)
}
