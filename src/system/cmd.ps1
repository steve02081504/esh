function global:HandleCmdPath($Path) {
	$TempPath = $Path
	$VarList = @()
	while ($TempPath -match '%(\w+)%') {
		$TempPath = $TempPath -replace "%$($Matches[1])%", ''
		$VarList += $Matches[1]
	}
	foreach ($Var in $VarList) {
		$Value = [System.Environment]::GetEnvironmentVariable($Var)
		if ($Value) { $Path = $Path -replace "%$Var%", $Value }
	}
	$Path
}
