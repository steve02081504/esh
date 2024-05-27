. "$($EshellUI.Sources.Path)/src/scripts/Console.ps1"
Set-ConsoleIcon "$($EshellUI.Sources.Path)/img/esh.ico"
Remove-Item @('function:Set-ConsoleIcon', 'function:Set-WindowIcon')
