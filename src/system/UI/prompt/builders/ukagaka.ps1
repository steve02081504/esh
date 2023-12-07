. "$($EshellUI.Sources.Path)/src/scripts/Ukagaka.ps1"
$EshellUI.Prompt.Builders['ukagaka'] = {
	$ukagakaDescription = Test-Ukagaka-Directory $PWD.Path
	if ($ukagakaDescription.Count -gt 0) {
		$detalname = @($ukagakaDescription['sakura.name'],$ukagakaDescription['kero.name']) -ne $null -join '&'
		$VirtualTerminal.Colors.Green+"$(
			switch ($x = $ukagakaDescription.type) {
				'ghost' { "󰀆" };'shell' { "󱓨" };'balloon' { "󰍡" };default { "" }
			}
		) $x"
		if ($name=$ukagakaDescription.name ?? $detalname) {
			"$name$(if ($name -ne $detalname) { "($detalname)" })"
		}
		if ($x=$ukagakaDescription.craftman) { "by $x" }
		if ($x=$ukagakaDescription.githubrepo ?? $ukagakaDescription.craftmanurl){ "@ <$x>" }
	}
}
