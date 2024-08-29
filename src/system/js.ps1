$EshellUI.ExecutionHandlers.Add({
	param (
		[string]$line
	)
	#若当前表达式不是合法ps脚本
	if ($global:bad_expr_now) {
		#测试作为js脚本的合法性
		$LastExitCodeBackup = $global:LastExitCode
		$jsexpr = "new Promise(async resolve => resolve(($line))).then(console.log)"
		node $PSScriptRoot/../scripts/check_js.mjs $jsexpr *> $null
		if ($global:LastExitCode) {
			$jsexpr = "new Promise(async resolve => {$line; resolve()}).then(console.log)"
			node $PSScriptRoot/../scripts/check_js.mjs $jsexpr *> $null
		}
		if ($global:LastExitCode) { $global:LastExitCode = $LastExitCodeBackup; return }

		"node -e '$($jsexpr -replace "'", "''")'"
	}
}) | Out-Null
