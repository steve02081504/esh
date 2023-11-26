function global:ValueEx ($ValueAndMethods) {
	if ($ValueAndMethods.__value__) {
		if ($ValueAndMethods.__type__) {
			$ValueExed = $ValueAndMethods.__type__($ValueAndMethods.__value__)
		}
		else {
			$ValueExed = $ValueAndMethods.__value__
		}
	}
	elseif ($ValueAndMethods.__type__) {
		$ValueExed = $ValueAndMethods.__type__::new()
	}
	else {
		$ValueExed = @{}
	}
	$ValueAndMethods.Remove('__value__')
	$ValueAndMethods.Remove('__type__')
	$ValueAndMethods.GetEnumerator() | ForEach-Object {
		if ($_.Key.StartsWith('method:') -and ($_.Value -is [scriptblock])) {
			Add-Member -InputObject $ValueExed -MemberType ScriptMethod -Name $_.Key.Substring(7) -Value $_.Value -Force
		}
		else {
			$ValueExed[$_.Key] = $_.Value
		}
	}
	return ,$ValueExed
}
function global:IndexEx ($Value,$Index,[switch]$Set = $false,$ValueToSet) {
	if (-not $Index) { return ,$Value }
	if ($Index.Contains('.')) {
		while ($Index.Contains('.')) {
			$Pos = $Index.IndexOf('.')
			$SubIndex = $Index.Substring(0,$Pos)
			$Index = $Index.Substring($Pos + 1)
			$Value = IndexEx $Value $SubIndex
		}
	}
	if ($Set) {
		if ($Value.__arec_set__) { $Value.__arec_set__($Index,$ValueToSet) }
		else { $Value[$Index] = $ValueToSet }
		$Result = $ValueToSet
	}
	else {
		if ($Value.__arec__) { $Result = $Value.__arec__($Index) }
		else { $Result = $Value[$Index] }
	}
	return ,$Result
}
