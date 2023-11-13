if ($PSVersionTable.PSVersion.Major -lt 6) {
	Write-Error "PowerShell 6 or higher is required for E-ShellUI."
	exit 1
}
. $PSScriptRoot/src/main.ps1
