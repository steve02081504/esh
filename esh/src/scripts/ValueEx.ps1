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
