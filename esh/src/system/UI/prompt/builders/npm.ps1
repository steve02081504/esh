﻿$EshellUI.Prompt.Builders["npm"] = {
	param(
		[Parameter(Mandatory = $true)]
		[string]$prompt_str
	)
	if (Test-Path package.json) {
		$packageJson = Get-Content -Path package.json -Raw -ErrorAction SilentlyContinue
	}
	elseif (Test-Command git) {
		$gitRepoRoot = git rev-parse --show-toplevel 2>$null
		if (($null -ne $gitRepoRoot) -and (Test-Path "$gitRepoRoot/package.json")) {
			$packageJson = Get-Content -Path "$gitRepoRoot/package.json" -Raw -ErrorAction SilentlyContinue
		}
	}
	$npm_prompt_str = $null
	if ($null -ne $packageJson) {
		$packageJson = ConvertFrom-Json $packageJson
		$npmRepoName = $packageJson.Name
		$npmRepoVersion = $packageJson.Version
	}
	if ($null -ne $npmRepoName) {
		$npm_prompt_str = " ${VirtualTerminal.Colors.Red} $npmRepoName"
		if ($null -ne $npmRepoVersion) {
			$npm_prompt_str += "@$npmRepoVersion"
		}
	}
	if ($npm_prompt_str) {
		$prompt_str = $EshellUI.Prompt.AddBlock($prompt_str,$npm_prompt_str)
	}
	$prompt_str
}