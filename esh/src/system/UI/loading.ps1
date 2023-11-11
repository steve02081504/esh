if ($EshellUI.Im.VSCodeExtension -and (-not $EshellUI.OtherData.VSCodeExtensionHostCleared)) {
	Clear-Host
	$EshellUI.OtherData["VSCodeExtensionHostCleared"] = $true
}
Write-Host "E-Shell v1765.3.13"
Write-Host "Loading..."
Write-Host ""
