function global:Test-Command {
	param(
		$Command
	)
	#检查命令是否存在
	[bool]$(Get-Command $Command -ErrorAction Ignore)
}
