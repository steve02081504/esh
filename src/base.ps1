function Max {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[int[]]$RemainingArguments
	)
	$RemainingArguments | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
}
function Min {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[int[]]$RemainingArguments
	)
	$RemainingArguments | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
}
function cmd_args_convert {
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
function pwsh_args_convert {
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
function Test-Command {
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

#as root?
$ImSudo = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]“Administrator”)
$ImVSCodeExtension = Test-Command Test-ScriptExtent
