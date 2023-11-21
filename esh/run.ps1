try{
	if (-not $EshellUI) { . $PSScriptRoot/main.ps1 }
	if (-not $EshellUI) { exit 1 }
	$EshellUI.RunFromScript($MyInvocation)
}
catch {
	$EshellUI.Remove()
	throw $_
}
