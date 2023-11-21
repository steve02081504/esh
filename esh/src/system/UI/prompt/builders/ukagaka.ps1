. "$($EshellUI.Sources.Path)/src/scripts/Ukagaka.ps1"
$EshellUI.Prompt.Builders["ukagaka"] = {
	param(
		[Parameter(Mandatory = $true)]
		[string]$prompt_str,
		[Parameter(Mandatory = $true)]
		[HashTable]$BuildMethods
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
			$ukagaka_prompt_str = $BuildMethods.AddBlock($ukagaka_prompt_str," by $($ukagakaDescription[`"craftman`"])")
		}
		if ($ukagakaDescription["githubrepo"]) {
			$ukagaka_prompt_str = $BuildMethods.AddBlock($ukagaka_prompt_str," @ <$($ukagakaDescription[`"githubrepo`"])>")
		}
		elseif ($ukagakaDescription["craftmanurl"]) {
			$ukagaka_prompt_str = $BuildMethods.AddBlock($ukagaka_prompt_str," @ <$($ukagakaDescription[`"craftmanurl`"])>")
		}
	}
	if ($ukagaka_prompt_str) {
		$prompt_str = $BuildMethods.AddBlock($prompt_str,$ukagaka_prompt_str)
	}
	$prompt_str
}
