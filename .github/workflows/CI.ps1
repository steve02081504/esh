try{
	. $PSScriptRoot/../../opt/install.ps1 -Force -StartEsh no

	. $PSScriptRoot/../../src/main.ps1
	$EshellUI.Init($MyInvocation)
	$EshellUI.Start()

	. $PSScriptRoot/../../opt/uninstall.ps1 -Force -RemoveDir no
}catch{}

if($error){
	$error | ForEach-Object {
		Write-Output "::error file=$($_.InvocationInfo.ScriptName),line=$($_.InvocationInfo.ScriptLineNumber),col=$($_.InvocationInfo.OffsetInLine),endColumn=$($_.InvocationInfo.OffsetInLine),tittle=error::script error"
		Write-Output "::group::script stack trace"
		Write-Output $_.ScriptStackTrace
		Write-Output "::endgroup::"
		Write-Output "::group::error details"
		Write-Output $_
		Write-Output "::endgroup::"
	}
	exit 1
}

Write-Output "Nice CI!"
