#set the title same as cmd
$host.UI.RawUI.WindowTitle = '命令提示符' + $(if ($EshellUI.Im.Sudo) { '(root)' })
