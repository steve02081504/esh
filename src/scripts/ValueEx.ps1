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
		elseif ($ValueExed -is [System.Collections.IDictionary]) {
			$ValueExed[$_.Key] = $_.Value
		}
		else {
			Add-Member -InputObject $ValueExed -MemberType NoteProperty -Name $_.Key -Value $_.Value -Force
		}
	}
	return ,$ValueExed
}
function global:IndexEx ($Value, $Index, [switch]$Set = $false, $ValueToSet) {
	if (-not $Index) { return ,$Value }
	if ($Index.Contains('.')) {
		$Index = $Index -split '\.'
		$Index | Select-Object -SkipLast 1 | ForEach-Object {
			$Value = IndexEx $Value $_
		}
		$Index = $Index[-1]
	}
	if ($Set) {
		if ($Value.__arec_set__) { $Value.__arec_set__($Index, $ValueToSet) }
		else { $Value[$Index] = $ValueToSet }
		$Result = $ValueToSet
	}
	else {
		if ($Value.__arec__) { $Result = $Value.__arec__($Index) }
		else { $Result = $Value[$Index] }
	}
	return ,$Result
}

function global:TempAssign {
	$Sb = $args[-1]
	if ($Sb -isnot [scriptblock]) {
		Write-Error "The last argument of TempAssign must be a scriptblock, get '$($Sb.GetType())'" -ErrorAction Stop
	}
	$list = @()
	$namelist = @()
	for ($i = 0; $i -lt $args.Count - 1; $i += 1) {
		$VariableName = if ($args[$i] -is [Object[]]) { $args[$i][0] }
		elseif ($args[$i] -is [string]) { $args[$i] }
		else {
			Write-Error "The $($i + 1)th argument of TempAssign must be a variable name or a pair" -ErrorAction Stop
		}

		$namelist += $VariableName
		$list += Invoke-Expression $VariableName
		if ($args[$i] -is [Object[]]) {
			$Value = $args[$i][1]
			Invoke-Expression "$VariableName = `$Value" | Out-Null
		}
	}
	try { & $Sb }
	finally {
		for ($i = 0; $i -lt $namelist.Count; $i += 1) {
			Invoke-Expression "$($namelist[$i]) = `$list[$i]" | Out-Null
		}
	}
}
