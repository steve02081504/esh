function GitPromptBuilder {
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
			$prompt_str = PromptAddBlock $prompt_str $git_prompt_str
		}
	}
	$prompt_str
}
function NpmPromptBuilder {
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
		$npmRepoVersion = $packageJson.version
	}
	if ($null -ne $npmRepoName) {
		$npm_prompt_str = " ${VirtualTerminal.Colors.Red} $npmRepoName"
		if ($null -ne $npmRepoVersion) {
			$npm_prompt_str += "@$npmRepoVersion"
		}
	}
	if ($npm_prompt_str) {
		$prompt_str = PromptAddBlock $prompt_str $npm_prompt_str
	}
	$prompt_str
}
. $PSScriptRoot\ukagaka.ps1
function UkagakaPromptBuilder {
	param(
		[Parameter(Mandatory = $true)]
		[string]$prompt_str
	)
	$ukagaka_prompt_str = $null
	$ukagakaDescription = Test-Ukagaka-Directory $PWD.Path
	if ($ukagakaDescription.Count -gt 0) {
		switch ($x = $ukagakaDescription["type"]) {
			"ghost" {
				$ukagaka_prompt_str = " ${VirtualTerminal.Colors.Green}󰀆 $x"
				if ($ukagakaDescription["name"]) {
					$ukagaka_prompt_str += " $($ukagakaDescription[`"name`"])"
					if ($ukagakaDescription["sakura.name"]) {
						$ukagaka_prompt_str += "($($ukagakaDescription[`"sakura.name`"])"
						if ($ukagakaDescription["kero.name"]) {
							$ukagaka_prompt_str += "&$($ukagakaDescription[`"kero.name`"])"
						}
						$ukagaka_prompt_str += ")"
					}
				}
				elseif ($ukagakaDescription["sakura.name"]) {
					$ukagaka_prompt_str += " $($ukagakaDescription[`"sakura.name`"])"
					if ($ukagakaDescription["kero.name"]) {
						$ukagaka_prompt_str += "&$($ukagakaDescription[`"kero.name`"])"
					}
				}
			}
			"shell" {
				$ukagaka_prompt_str = " ${VirtualTerminal.Colors.Green}󱓨 $x"
				if ($ukagakaDescription["name"]) {
					$ukagaka_prompt_str += " $($ukagakaDescription[`"name`"])"
				}
			}
			"balloon" {
				$ukagaka_prompt_str = " ${VirtualTerminal.Colors.Green}󰍡 $x"
				if ($ukagakaDescription["name"]) {
					$ukagaka_prompt_str += " $($ukagakaDescription[`"name`"])"
				}
			}
			default {
				$ukagaka_prompt_str = " ${VirtualTerminal.Colors.Green} $x"
				if ($ukagakaDescription["name"]) {
					$ukagaka_prompt_str += " $($ukagakaDescription[`"name`"])"
				}
			}
		}
		if ($ukagakaDescription["craftman"]) {
			$ukagaka_prompt_str = PromptAddBlock $ukagaka_prompt_str " by $($ukagakaDescription[`"craftman`"])"
		}
		if ($ukagakaDescription["githubrepo"]) {
			$ukagaka_prompt_str = PromptAddBlock $ukagaka_prompt_str " @ <$($ukagakaDescription[`"githubrepo`"])>"
		}
		elseif ($ukagakaDescription["craftmanurl"]) {
			$ukagaka_prompt_str = PromptAddBlock $ukagaka_prompt_str " @ <$($ukagakaDescription[`"craftmanurl`"])>"
		}
	}
	if ($ukagaka_prompt_str) {
		$prompt_str = PromptAddBlock $prompt_str $ukagaka_prompt_str
	}
	$prompt_str
}
