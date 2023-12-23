function global:Test-Command($Command) {
	if(!$Command) { return $false }
	[bool]$(Get-Command $Command -ErrorAction Ignore)
}
