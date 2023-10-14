#as root?
$ImSudo=([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] “Administrator”)
function Max {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[int[]]$RemainingArguments
	)
	$RemainingArguments | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
}
function Min {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[int[]]$RemainingArguments
	)
	$RemainingArguments | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
}
