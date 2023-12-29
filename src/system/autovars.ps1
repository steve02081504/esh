$global:ans ??= 72
function global:ans([Parameter(ValueFromRemainingArguments = $true)]$ExprAddition) {
	Invoke-Expression "`$global:ans $ExprAddition"
}
function global:err([Parameter(ValueFromRemainingArguments = $true)]$ExprAddition) {
	Invoke-Expression "`$global:err $ExprAddition"
}
$EshellUI.OtherData.HistoryErrorCount = $Error.Count

$PSDefaultParameterValues['Out-Default:OutVariable'] = 'ans_array'
$EshellUI.ExecutionHandlers = [System.Collections.ArrayList]@()
Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
	foreach($Handler in $EshellUI.ExecutionHandlers) {
		if(. $Handler) { return }
	}
	if($ans_array -ne $null) { $global:ans = $($global:ans_array) }
	$global:err = $Error | Select-Object -SkipLast $EshellUI.OtherData.HistoryErrorCount
	$EshellUI.OtherData.ErrorCount = $Error.HistoryErrorCount
	[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
