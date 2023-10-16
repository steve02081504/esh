function PromptNewlineCheck {
	param(
		[Parameter(Mandatory = $true)]
		[string]$prompt_str
	)
	$LastLineIndex = Max $prompt_str.LastIndexOf('`n') 0
	$LastLine = $prompt_str.Substring($LastLineIndex)
	#如果$prompt_str最后一行长度大于$Host.UI.RawUI.WindowSize.Width/2则换行
	if ($LastLine.Length -gt ($Host.UI.RawUI.WindowSize.Width / 2)) {
		$prompt_str = "$prompt_str`n"
	}
	return $prompt_str
}
function PromptAddBlock {
	param(
		[Parameter(Position = 0,Mandatory = $true)]
		$prompt_str,
		[Parameter(Position = 1,Mandatory = $true)]
		[string]$block_str
	)
	$LastLineIndex = Max $prompt_str.LastIndexOf('`n') 0
	$LastLine = $prompt_str.Substring($LastLineIndex)
	#如果$LastLine + $block_str长度大于$Host.UI.RawUI.WindowSize.Width则换行
	if (($LastLine + $block_str).Length -gt $Host.UI.RawUI.WindowSize.Width) {
		$prompt_str = "$prompt_str`n"
	}
	return $prompt_str + $block_str
}
. $PSScriptRoot\ukagaka.ps1
function global:prompt {
	if ($PWD.Path.StartsWith($HOME)) {
		$shortPath = '~' + $PWD.Path.Substring($HOME.Length)
	}
	elseif ($PWD.Path.StartsWith(${MSYS.RootPath})) {
		$shortPath = '/' + $PWD.Path.Substring(${MSYS.RootPath}.Length)
		$shortPath = $shortPath.Replace('\','/')
		if ($shortPath.StartsWith('//')) {
			$shortPath = $shortPath.Substring(1)
		}
	}
	else {
		$shortPath = $PWD.Path
	}
	$prompt_str = $shortPath
	#调用git来确认是否在repo中
	if (Test-Command git) {
		$gitRepoUid = git rev-parse --short HEAD 2>$null
		$gitRepoBranch = git rev-parse --abbrev-ref HEAD 2>$null
		$gitChangedFileNum = git status --porcelain 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines
		if ($null -ne $gitRepoUid) {
			$git_prompt_str = " ${VirtualTerminal.Colors.Cyan}$gitRepoUid"
			if ($null -ne $gitRepoBranch) {
				$git_prompt_str = "$git_prompt_str@$gitRepoBranch"
			}
		}
		if ($gitChangedFileNum -gt 0) {
			$git_prompt_str = "$git_prompt_str $gitChangedFileNum file"
			if ($gitChangedFileNum -gt 1) {
				$git_prompt_str = $git_prompt_str + "s"
			}
		}
		if ($git_prompt_str) {
			$prompt_str = PromptAddBlock $prompt_str $git_prompt_str
		}
		$gitRepoRoot = git rev-parse --show-toplevel 2>$null
	}
	if (Test-Path package.json) {
		$packageJson = Get-Content -Path package.json -Raw -ErrorAction SilentlyContinue
	}
	elseif (($null -ne $gitRepoRoot) -and (Test-Path "$gitRepoRoot/package.json")) {
		$packageJson = Get-Content -Path "$gitRepoRoot/package.json" -Raw -ErrorAction SilentlyContinue
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
			$npm_prompt_str = "$npm_prompt_str@$npmRepoVersion"
		}
	}
	if ($npm_prompt_str) {
		$prompt_str = PromptAddBlock $prompt_str $npm_prompt_str
	}
	$ukagaka_prompt_str = $null
	$ukagakaDescription = Test-Ukagaka-Directory $PWD.Path
	if ($ukagakaDescription.Count -gt 0) {
		switch ($x = $ukagakaDescription["type"]) {
			"ghost" {
				$ukagaka_prompt_str = " ${VirtualTerminal.Colors.Green}󰀆 $x"
				if ($ukagakaDescription["name"]) {
					$ukagaka_prompt_str = "$ukagaka_prompt_str $($ukagakaDescription[`"name`"])"
					if ($ukagakaDescription["sakura.name"]) {
						$ukagaka_prompt_str = "$ukagaka_prompt_str($($ukagakaDescription[`"sakura.name`"])"
						if ($ukagakaDescription["kero.name"]) {
							$ukagaka_prompt_str = "$ukagaka_prompt_str&$($ukagakaDescription[`"kero.name`"])"
						}
						$ukagaka_prompt_str = "$ukagaka_prompt_str)"
					}
				}
				elseif ($ukagakaDescription["sakura.name"]) {
					$ukagaka_prompt_str = "$ukagaka_prompt_str $($ukagakaDescription[`"sakura.name`"])"
					if ($ukagakaDescription["kero.name"]) {
						$ukagaka_prompt_str = "$ukagaka_prompt_str&$($ukagakaDescription[`"kero.name`"])"
					}
				}
			}
			"shell" {
				$ukagaka_prompt_str = " ${VirtualTerminal.Colors.Green}󱓨 $x"
				if ($ukagakaDescription["name"]) {
					$ukagaka_prompt_str = "$ukagaka_prompt_str $($ukagakaDescription[`"name`"])"
				}
			}
			"balloon" {
				$ukagaka_prompt_str = " ${VirtualTerminal.Colors.Green}󰍡 $x"
				if ($ukagakaDescription["name"]) {
					$ukagaka_prompt_str = "$ukagaka_prompt_str $($ukagakaDescription[`"name`"])"
				}
			}
			default {
				$ukagaka_prompt_str = " ${VirtualTerminal.Colors.Green} $x"
				if ($ukagakaDescription["name"]) {
					$ukagaka_prompt_str = "$ukagaka_prompt_str $($ukagakaDescription[`"name`"])"
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
	$prompt_str = PromptNewlineCheck ($prompt_str)
	"$prompt_str ${VirtualTerminal.Colors.Reset}>"
}
