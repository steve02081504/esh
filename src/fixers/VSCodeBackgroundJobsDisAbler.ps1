if ($EshellUI.Im.VSCodeExtension -and ($host.Version -le [version]'2023.8.0')) {
	$EshellUI.BackgroundJobs.Wait()
	Unregister-Event -SubscriptionId $EshellUI.RegisteredEvents.BackgroundJobs.RawData.SubscriptionId -Force
	Unregister-Event -SubscriptionId $EshellUI.RegisteredEvents.FocusRecordUpdate.RawData.SubscriptionId -Force
	$EshellUI.RegisteredEvents.Remove('BackgroundJobs')
	$EshellUI.RegisteredEvents.Remove('FocusRecordUpdate')
	$EshellUI.LoadingLog.AddWarning(
"EshellUI's BackgroundJobs and FocusRecordUpdate has been disabled due to a bug of PowerShell VSCode Extension.
See $(
	$VirtualTerminal.Styles.Underline+$VirtualTerminal.Colors.BrightCyan
)https://github.com/PowerShell/vscode-powershell/issues/4851$(
	$VirtualTerminal.Styles.NoUnderline+$VirtualTerminal.Colors[${Out-Performance}.Warning.Color]
) for more info."
	)
}
