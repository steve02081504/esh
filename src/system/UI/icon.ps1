. "$($EshellUI.Sources.Path)/src/scripts/Console.ps1"
Set-ConsoleIcon "$($EshellUI.Sources.Path)/img/cmd.ico"
Remove-Item function:Set-ConsoleIcon
Remove-Item function:Set-WindowIcon
