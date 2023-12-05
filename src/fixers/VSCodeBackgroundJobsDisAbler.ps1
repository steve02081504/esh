# fixer of https://github.com/PowerShell/vscode-powershell/issues/4851
if ($EshellUI.Im.VSCodeExtension) {
	$EshellUI.BackgroundJobs.Add({
		Unregister-Event -SubscriptionId $EshellUI.OtherData.IdleEvent.SubscriptionId -Force
		$EshellUI.OtherData.Remove('IdleEvent')
	}) | Out-Null
}
