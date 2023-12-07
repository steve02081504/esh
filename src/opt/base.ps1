using namespace System.Management.Automation.Host
function YorN($message, $helpMessageY = "", $helpMessageN = "", [switch]$defaultN = $false, [switch]$SkipAsDefault=$false) {
	if($SkipAsDefault) { return -not $defaultN }
	do {
		$response = $Host.UI.PromptForChoice("", $message, @(
				[ChoiceDescription]::new('&Yes', $helpMessageY), [ChoiceDescription]::new('&No', $helpMessageN)
			), [int][bool]$defaultN)#不要使用$defaultN+0，这样的操作只在pwsh中有效
	} until ($response -ne -1)
	-not $response
}
