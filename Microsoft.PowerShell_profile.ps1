#set thefuck as alias "fk"
$env:PYTHONIOENCODING="utf-8"
Invoke-Expression "$(thefuck --alias fk)"

#set prompt same as cmd
function prompt {"$PWD>"}

#set the title same as cmd
$host.UI.RawUI.WindowTitle = "命令提示符"
#if as root
If (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] “Administrator”)){
    $host.UI.RawUI.WindowTitle += "(root)"
}


#remove alias "rm" as it is conflict with linux submode's /usr/bin/rm
Remove-Item -Path Alias:rm

#import appx with -UseWindowsPowerShell to avoid [Operation is not supported on this platform. (0x80131539)]
Import-Module Appx -UseWindowsPowerShell

#clear screen
Clear-Host
