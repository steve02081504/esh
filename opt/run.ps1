#!/usr/bin/env pwsh
[CmdletBinding()]param($Invocation = $MyInvocation)
if ($PSVersionTable.PSVersion.Major -lt 6) {
	$Host.UI.WriteErrorLine('PowerShell 6 or higher is required for E-ShellUI.')
	exit 1
}
if (-not $EshellUI) { . $PSScriptRoot/../src/main.ps1 }
$EshellUI.RunFromScript($Invocation)
