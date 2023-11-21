if ([System.Environment]::OSVersion.Version.Major -le 7) {
	$CursorPosBackUp = $host.UI.RawUI.CursorPosition
	$CodingBackUp = [Console]::OutputEncoding
	$TestText = '中文测试你好小笼包我是冰激凌'
	function TestAndSet ($Encoding) {
		try { Write-Host $TestText }
		catch { $error.RemoveAt(0); [Console]::OutputEncoding = $Encoding }
		$host.UI.RawUI.CursorPosition = $CursorPosBackUp
	}
	TestAndSet ([System.Text.Encoding]::GetEncoding(936))
	TestAndSet $CodingBackUp
	Write-Host $(' ' * $TestText.Length * 2)
	$host.UI.RawUI.CursorPosition = $CursorPosBackUp
}
