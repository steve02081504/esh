#set the title same as cmd
$host.UI.RawUI.WindowTitle = '命令提示符'
#if as root
if ($EshellUI.Im.Sudo) {
	$host.UI.RawUI.WindowTitle += '(root)'
}
