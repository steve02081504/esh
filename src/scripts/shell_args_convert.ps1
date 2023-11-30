function global:cmd_args_convert($Arguments) {
	($Arguments | ForEach-Object {
		if (($_.IndexOf('"') -ge 0) -or ($_.IndexOf(' ') -ge 0)) {
			'"' + $_.Replace('"', '"""') + '"'
		} else {$_}
	}) -join ' '
}
function global:pwsh_args_convert($Arguments) {
	($Arguments | ForEach-Object {
		if (($_.IndexOf('"') -ge 0) -or ($_.IndexOf(' ') -ge 0)) {
			'"' + $_.Replace('"', '`"') + '"'
		} else {$_}
	}) -join ' '
}
