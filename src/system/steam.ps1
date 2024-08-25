# 在用户运行irm XXXXsteamXXXX|iex命令时禁止执行,并显示诈骗警告
$EshellUI.ExecutionHandlers.Add({
	param (
		[string]$OriLine
	)
	$line = $OriLine.Trim()
	#若以irm开头,|\s*iex结尾
	if ($line -match '^irm\s+.*\s*iex$' -and $line -like "*steam*") {
		#禁止执行
		[Microsoft.PowerShell.PSConsoleReadLine]::CancelLine()
		Write-Host "`b`b  " -NoNewline
		Write-Host
		#输出警告
		Write-Host "别搁这里执行脑瘫命令了，赶紧退款或者给店家差评吧。" -ForegroundColor Red
		return 1
	}
}) | Out-Null
