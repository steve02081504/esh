$EshellUI.ExecutionHandlers.Add({
	param (
		[string]$line
	)
	#若当前表达式不是合法ps脚本
	if ($global:bad_expr_now) {
		#测试作为js脚本的合法性
		$LastExitCodeBackup = $global:LastExitCode
		$jsexpr = "console.log(($line))"
		node $PSScriptRoot/../scripts/check_js.mjs $jsexpr *> $null
		if ($global:LastExitCode) {
			$jsexpr = $line
			node $PSScriptRoot/../scripts/check_js.mjs $jsexpr *> $null
		}
		if ($global:LastExitCode) { $global:LastExitCode = $LastExitCodeBackup; return }

		"node -e '$($jsexpr -replace "'", "''")'"
	}
}) | Out-Null
