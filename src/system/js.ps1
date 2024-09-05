$EshellUI.ExecutionHandlers.Add({
	param (
		[string]$line
	)
	#若当前表达式不是合法ps脚本
	if ($global:bad_expr_now) {
		#测试作为js脚本的合法性
		$LastExitCodeBackup = $global:LastExitCode
		$jsexpr = "_ => {$line}"
		node $PSScriptRoot/../scripts/check_js.mjs $jsexpr *> $null
		if ($global:LastExitCode) { $global:LastExitCode = $LastExitCodeBackup; return }

		$jsexpr = "new Promise(async resolve => resolve(eval(``$line``)))"
		"node -e '$($jsexpr -replace "'", "''").then(console.log).catch(e => console.log(```${e.name}: `${e.message}``))'"
	}
}) | Out-Null
