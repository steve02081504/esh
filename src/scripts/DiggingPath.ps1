function global:DiggingPath {
	param (
		[Parameter(Mandatory = $true)]
		[scriptblock]$Runner,
		$Path = $PWD.Path,
		$CheckPath = ''
	)
	if($Input) { if($Path){$CheckPath = $Path};$Path = $Input }
	if(-not $Path) { return }
	$DescriptionPath = if($CheckPath){ Join-Path $Path $CheckPath } else { $Path }
	if (Test-Path $DescriptionPath) {
		if($x=$Runner.Invoke(($_=$DescriptionPath))) {
			return $x
		}
	}
	$ParentPath = Split-Path $Path
	DiggingPath $Runner $ParentPath $CheckPath
}
