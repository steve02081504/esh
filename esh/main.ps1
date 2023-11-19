if ($PSVersionTable.PSVersion.Major -lt 6) {
	$Host.UI.WriteErrorLine("PowerShell 6 or higher is required for E-ShellUI.")
	exit 1
}
. $PSScriptRoot/src/main.ps1
