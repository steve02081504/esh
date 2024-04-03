$global:ans_array ??= [System.Collections.ArrayList]@(72)

@('ans', 'err', 'expr') | ForEach-Object {
	Invoke-Expression "
	function global:$_([Parameter(ValueFromRemainingArguments = `$true)]`$ExprAddition) {
		Invoke-Expression ""```$global:$_ `$ExprAddition""
	}
	"
}
$EshellUI.OtherData.HistoryErrorCount = $Error.Count

$PSDefaultParameterValues['Out-Default:OutVariable'] = 'ans_array'
$EshellUI.ExecutionHandlers = [System.Collections.ArrayList]@()
Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
	#获取当前行
	$global:expr = $global:expr_now
	$global:expr_now = $Cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$global:expr_now, [ref]$Cursor)
	$global:ans = $($global:ans_array)
	$global:err = $Error | Select-Object -SkipLast $EshellUI.OtherData.HistoryErrorCount
	$EshellUI.OtherData.HistoryErrorCount = $Error.Count
	foreach($Handler in $EshellUI.ExecutionHandlers) {
		$aret = $Handler.Invoke($global:expr_now)
		if($aret.Count -eq 1) { $aret = $aret[0] }
		if($aret -is [string]) {
			$EshellUI.AcceptLine($aret)
			return
		}
		elseif($aret) { return }
	}
	[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
