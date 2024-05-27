if ($IsWindows -and
	([Console]::OutputEncoding -ne [System.Text.Encoding]::UTF8) -and
	([Console]::OutputEncoding.CodePage -ne (.{ [void]($(chcp) -match '(\d+)$'); $Matches[0] }))
) {
	$CursorPosBackUp = $host.UI.RawUI.CursorPosition
	$TestText = '中文测试你好小笼包我是冰激凌'
	foreach ($Encoding in [System.Text.Encoding]::GetEncodings()) {
		try { Write-Host $TestText; break }
		catch { $error.RemoveAt(0); [Console]::OutputEncoding = $Encoding }
		try { $host.UI.RawUI.CursorPosition = $CursorPosBackUp } catch { $Error.RemoveAt(0) }
	}
	Write-Host $(' ' * $TestText.Length * 2)
	try { $host.UI.RawUI.CursorPosition = $CursorPosBackUp } catch { $Error.RemoveAt(0) }
	Remove-Variable @('CursorPosBackUp', 'TestText')
}
