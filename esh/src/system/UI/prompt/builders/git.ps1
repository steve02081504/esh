$EshellUI.Prompt.Builders["git"] = {
	param(
		[Parameter(Mandatory = $true)]
		[string]$prompt_str
	)
	if (Test-Command git) {
		$gitRepoUid = git rev-parse --short HEAD 2>$null
		$gitRepoBranch = git rev-parse --abbrev-ref HEAD 2>$null
		$gitChangedFileNum = git status --porcelain 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines
		if ($null -ne $gitRepoUid) {
			$git_prompt_str = " ${VirtualTerminal.Colors.Cyan}$gitRepoUid"
			if ($null -ne $gitRepoBranch) {
				$git_prompt_str += "@$gitRepoBranch"
			}
		}
		if ($gitChangedFileNum -gt 0) {
			$git_prompt_str = "$git_prompt_str $gitChangedFileNum file"
			if ($gitChangedFileNum -gt 1) {
				$git_prompt_str += "s"
			}
		}
		if ($git_prompt_str) {
			$prompt_str = $EshellUI.Prompt.AddBlock($prompt_str,$git_prompt_str)
		}
	}
	$prompt_str
}
