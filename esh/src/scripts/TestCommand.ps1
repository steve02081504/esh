function global:Test-Command {
	param(
		$Command
	)
	#检查命令是否存在
	if (Get-Command $Command -ErrorAction SilentlyContinue) {
		return $true
	}
	else {
		#移除$error中的最后一个错误
		$error.RemoveAt(0)
		return $false
	}
}
