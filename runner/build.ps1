[CmdletBinding()]param ($OutputFile = "$PSScriptRoot/esh.exe")

if (-not (Get-Module -ListAvailable ps2exe)) {
	Install-Module ps2exe
}
Invoke-ps2exe $PSScriptRoot/main.ps1 $OutputFile -NoConsole -iconFile $PSScriptRoot/../img/esh.ico -title 'E-Shell' -description 'E-Shell' -version '1960.7.17.13' -company 'E-tek' -product 'E-Sh' -copyright '(c) E-tek Corporation. All rights reserved.'
