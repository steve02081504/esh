$EshellUI.ExecutionHandlers.Add({
	param (
		[string]$line
	)
	#若当前表达式不是合法ps脚本
	if ($global:bad_expr_now) {
		#测试作为js脚本的合法性
		$LastExitCodeBackup = $global:LastExitCode
		if ($line -match '^\s*\$(?<assign>([^=\s\+\-\*\/\"\'']*|\{.*?\}))\s*=\b\s*(?<value>.*)$') {
			$assign = $Matches['assign']
			$line = $Matches['value']
		}
		$jsexpr = "_ => {$line}"
		deno --allow-scripts --allow-all $PSScriptRoot/../scripts/check_js.mjs $jsexpr *> $null
		if ($global:LastExitCode) { $global:LastExitCode = $LastExitCodeBackup; return }

		$jsexpr = "new Promise(async resolve => resolve(eval(``$line``)))"
		"$(if($assign){"`$$assign = "})deno eval '$($jsexpr -replace "'", "''").then(async r => (await import(`"node:util`")).inspect(r, {colors: true})).then(console.log).catch(e => console.log(```${e.name}: `${e.message}``))'"
	}
}) | Out-Null
