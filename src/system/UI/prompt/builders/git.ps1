$EshellUI.Prompt.Builders['git'] = {
	if (Test-Command git) {
		$gitRepoUid = git rev-parse --short HEAD 2>$null
		$gitRepoBranch = git rev-parse --abbrev-ref HEAD 2>$null
		$gitChangedFileNum = git ls-files -mo --exclude-standard 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines
		if ($gitRepoUid -or $gitRepoBranch) {
			$VirtualTerminal.Colors.Cyan + '' + (@($gitRepoBranch, $gitRepoUid) -ne $null -join '@')
		}
		if ($gitChangedFileNum -gt 0) {
			"$gitChangedFileNum file"+@('s')[$gitChangedFileNum -eq 1]
		}
	}
}
