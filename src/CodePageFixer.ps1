if ([System.Environment]::OSVersion.Version.Major -le 7) {
	$CursorPosBackUp = $host.UI.RawUI.CursorPosition
	$host.UI.RawUI.CursorPosition = [System.Management.Automation.Host.Coordinates]::new(0,0)
	$CodingBackUp = [Console]::OutputEncoding
	$TestText = "中文测试你好小笼包我是冰激凌"
	try { Write-Host $TestText } catch { $error.RemoveAt(0); [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(936) }
	$host.UI.RawUI.CursorPosition = [System.Management.Automation.Host.Coordinates]::new(0,0)
	try { Write-Host $TestText } catch { $error.RemoveAt(0); [Console]::OutputEncoding = $CodingBackUp }
	$host.UI.RawUI.CursorPosition = [System.Management.Automation.Host.Coordinates]::new(0,0)
	Write-Host $(" " * $TestText.Length * 2)
	$host.UI.RawUI.CursorPosition = $CursorPosBackUp
}
