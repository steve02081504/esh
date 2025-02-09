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
$EshellUI.ExecutionRecorders = [System.Collections.ArrayList]@()
$EshellUI.ExecutionHandlers = [System.Collections.ArrayList]@()
Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
	#获取当前行
	$global:expr = $global:expr_now
	$global:expr_now = $Cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$global:expr_now, [ref]$Cursor)
	$global:ans = $($global:ans_array)
	$global:ans_array = [System.Collections.ArrayList]@()
	$global:err = $Error | Select-Object -SkipLast $EshellUI.OtherData.HistoryErrorCount
	$global:expr_err_now = $null
	$global:expr_ast = $global:expr_ast_now
	$global:bad_expr = $global:bad_expr_now
	$global:bad_expr_now = $false
	$global:expr_ast_now = [System.Management.Automation.Language.Parser]::ParseInput($global:expr_now, [ref]$null, [ref]$global:expr_err_now)
	if (!$global:expr_err_now) {
		$global:expr_ast_now.FindAll({ param($ast) $ast -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object {
			if (!(Test-Command $_.CommandElements[0])) {
				$global:bad_expr_now = $true
				$global:expr_err_now = try {
					Get-Command $_.CommandElements[0]
				} catch { $_ }
			}
		}
	} else { $global:bad_expr_now = $true }
	foreach ($Recorder in $EshellUI.ExecutionRecorders) {
		try {
			$Recorder.Invoke($global:expr_now)
		}
		catch {
			Write-Host
			Write-Host $_ -ForegroundColor Red
			Write-Host $_.ScriptStackTrace
		}
	}
	$EshellUI.OtherData.HistoryErrorCount = $Error.Count
	foreach ($Handler in $EshellUI.ExecutionHandlers) {
		try {
			$aret = $Handler.Invoke($global:expr_now)
			if ($aret.Count -eq 1) { $aret = $aret[0] }
			if ($aret -is [string]) {
				$EshellUI.AcceptLine($aret)
				return
			}
			elseif ($aret) {
				Write-Error "Invalid return value from ExecutionHandler, type: $($aret.GetType())"
			}
		}
		catch {
			Write-Host
			Write-Host $_ -ForegroundColor Red
			Write-Host $_.ScriptStackTrace
		}
	}
	[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
