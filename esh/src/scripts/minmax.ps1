function global:Max {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[int[]]$RemainingArguments
	)
	$RemainingArguments | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
}
function global:Min {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[int[]]$RemainingArguments
	)
	$RemainingArguments | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
}
