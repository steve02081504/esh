function global:ValueEx ($ValueAndMethods) {
	if ($ValueAndMethods.__value__) {
		if ($ValueAndMethods.__value_type__) {
			$ValueExed = $ValueAndMethods.__value_type__($ValueAndMethods.__value__)
		}
		else {
			$ValueExed = $ValueAndMethods.__value__
		}
	}
	elseif ($ValueAndMethods.__value_type__) {
		$ValueExed = $ValueAndMethods.__value_type__::new()
	}
	else {
		$ValueExed = @{}
	}
	$ValueAndMethods.Remove('__value__')
	$ValueAndMethods.Remove('__value_type__')
	$ValueAndMethods.GetEnumerator() | ForEach-Object {
		if ($_.Key.StartsWith('method:') -and ($_.Value -is [scriptblock])) {
			Add-Member -InputObject $ValueExed -MemberType ScriptMethod -Name $_.Key.Substring(7) -Value $_.Value -Force
		}
		elseif ($_.Value -is [hashtable]) {
			$ValueExed[$_.Key] = ValueEx ($_.Value)
		}
		else {
			$ValueExed[$_.Key] = $_.Value
		}
	}
	return ,$ValueExed
}
