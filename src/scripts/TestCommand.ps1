function global:Test-Command($Command) {
	if (!$Command) { return $false }
	[bool]$(Get-Command $Command -ErrorAction Ignore)
}
function global:Test-Call {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidatePattern('^[\w-]+$')]
		[string]
		$CommandName,

		[Parameter(Mandatory = $true)]
		[string[]]
		$TestArgs
	)
	$Command = Get-Command $CommandName

	$proxyCode = [System.Management.Automation.ProxyCommand]::Create($Command)
	$scriptblock = [ScriptBlock]::Create($proxyCode)
	Invoke-Expression "function test { $($scriptblock.Ast.ParamBlock.Extent.Text);`$true }"
	try {
		Invoke-Expression "test $TestArgs"
	}
	catch {
		$false
	}
}
