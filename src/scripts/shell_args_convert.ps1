function global:cmd_args_convert {
	param(
		$Arguments
	)
	#若参数是数组
	if ($Arguments -is [array]) {
		#对于每个参数
		$Arguments = $Arguments | ForEach-Object {
			cmd_args_convert $_
		}
		#将参数转换为字符串
		return $Arguments -join ' '
	}
	else {
		if (($Arguments.IndexOf('"') -ge 0) -or ($Arguments.IndexOf(' ') -ge 0)) {
			$Arguments = '"' + $Arguments.Replace('"','"""') + '"'
		}
		return $Arguments
	}
}
function global:pwsh_args_convert {
	param(
		$Arguments
	)
	#若参数是数组
	if ($Arguments -is [array]) {
		#对于每个参数
		$Arguments = $Arguments | ForEach-Object {
			pwsh_args_convert $_
		}
		#将参数转换为字符串
		return $Arguments -join ' '
	}
	else {
		if (($Arguments.IndexOf('"') -ge 0) -or ($Arguments.IndexOf(' ') -ge 0)) {
			$Arguments = '"' + $Arguments.Replace('"','`"') + '"'
		}
		return $Arguments
	}
}
