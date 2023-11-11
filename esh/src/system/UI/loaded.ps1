if (-not $error) {
	$CursorPos = $host.UI.RawUI.CursorPosition
	$CursorPos.Y -= 3
	$host.UI.RawUI.CursorPosition = $CursorPos
}

. $PSScriptRoot/logo.ps1
$EshellUI.PrintLogo()
