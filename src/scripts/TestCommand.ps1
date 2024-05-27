function global:Test-Command($Command) {
	if (!$Command) { return $false }
	$backup = $ExecutionContext.InvokeCommand.CommandNotFoundAction
	$ExecutionContext.InvokeCommand.CommandNotFoundAction = $null
	[bool]$(Get-Command $Command -ErrorAction Ignore)
	$ExecutionContext.InvokeCommand.CommandNotFoundAction = $backup
}
function global:Test-Call {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidatePattern('^[\w-]+$')]
		[string]
		$CommandName,
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
