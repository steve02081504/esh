Invoke-Expression @"
function global:Get-Command-Base {
	$([System.Management.Automation.ProxyCommand]::Create((Get-Command Get-Command)))
}
"@

function global:Get-Command-Fixed {
	TempAssign '$ExecutionContext.InvokeCommand.CommandNotFoundAction', $null {
		Get-Command-Base @Args
	}
}

function global:Test-Command($Command) {
	if (!$Command) { return $false }
	[bool]$(Get-Command-Fixed $Command -ErrorAction Ignore)
}

function global:Get-Call-Signature {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidatePattern('^[\w-]+$')]
		[string]
		$CommandName
	)
	$Command = Get-Command-Fixed $CommandName

	$proxyCode = [System.Management.Automation.ProxyCommand]::Create($Command)
	$scriptblock = [ScriptBlock]::Create($proxyCode)
	$scriptblock.Ast.ParamBlock.Extent.Text
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
	Invoke-Expression "function test { $(Get-Call-Signature $CommandName);`$true }"
	try {
		Invoke-Expression "test $TestArgs"
	} catch { $false }
}
