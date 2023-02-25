#set thefuck as alias "fk"
$env:PYTHONIOENCODING="utf-8"
Invoke-Expression "$(thefuck --alias fk)"

#set prompt same as cmd
function prompt {"$PWD>"}

#set the title same as cmd
$host.UI.RawUI.WindowTitle = "命令提示符"

#remove alias "rm" as it is conflict with linux submode's /usr/bin/rm
Remove-Item -Path Alias:rm

#clear screen
Clear-Host
