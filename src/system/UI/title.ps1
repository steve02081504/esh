#set the title same as cmd
$EshellUI.OtherData.BeforeEshLoaded.WindowTitle = $host.UI.RawUI.WindowTitle
$host.UI.RawUI.WindowTitle = '命令提示符' + $(if ($EshellUI.Im.Sudo) { '(root)' })
