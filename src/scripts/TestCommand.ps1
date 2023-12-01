function global:Test-Command($Command) {
	[bool]$(Get-Command $Command -ErrorAction Ignore)
}
