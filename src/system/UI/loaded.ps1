param ($Arguments)
if ($error.Count -eq $EshellUI.OtherData.BeforeEshLoaded.Errors.Count) {
	$CursorPos = $host.UI.RawUI.CursorPosition
	$CursorPos.Y -= 3
	$host.UI.RawUI.CursorPosition = $CursorPos
	Remove-Variable CursorPos
}

. $PSScriptRoot/logo.ps1
if (-not $Arguments.NoLogo) {
	$EshellUI.Logo.Print()
}
else {
	Write-Host "                  "
	Write-Host "          "
	$CursorPos = $host.UI.RawUI.CursorPosition
	$CursorPos.Y -= 2
	$host.UI.RawUI.CursorPosition = $CursorPos
	Remove-Variable CursorPos
}
if ($EshellUI.LoadingLog.Count -and -not $Arguments.NoLoadingLog) {
	$EshellUI.LoadingLog.Print()
	Write-Host
}
