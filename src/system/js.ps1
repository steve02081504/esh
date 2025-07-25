$EshellUI.ExecutionHandlers.Add({
	param (
		[string]$line
	)
	#若当前表达式不是合法ps脚本
	if ($global:bad_expr_now) {
		if ($line -match '^[\w\.\s]+$') { #简单内容不认为合法
			return
		}
		#测试作为js脚本的合法性
		$LastExitCodeBackup = $global:LastExitCode
		if ($line -match '^\s*\$(?<assign>([^=\s\+\-\*\/\"\'']*|\{.*?\}))\s*=\b\s*(?<value>.*)$') {
			$assign = $Matches['assign']
			$line = $Matches['value']
		}
		$jsexpr = deno --allow-scripts --allow-all $PSScriptRoot/../scripts/check_js.mjs $line
		if ($global:LastExitCode) { $global:LastExitCode = $LastExitCodeBackup; return }

		$jsexpr = "new Promise(async resolve => resolve(eval(``$jsexpr``)))"
		"$(if($assign){"`$$assign = "})deno eval '$($jsexpr -replace "'", "''").then(async r => (await import(`"node:util`")).inspect(r, {colors: true})).then(console.log).catch(e => console.log(``%c`${e.name}: `${e.message}``, `"color: red`"))'"
	}
}) | Out-Null
