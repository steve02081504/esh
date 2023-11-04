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

#获取当前行
Add-Member -InputObject $host.UI.RawUI -MemberType ScriptMethod -Name GetLineBuffer -Value {
	param($LineIndex = $host.UI.RawUI.CursorPosition.Y)
	if($LineIndex -lt 0) { $host.UI.RawUI.GetLineBuffer($host.UI.RawUI.CursorPosition.Y+$LineIndex) }
	#GetBufferContents(System.Management.Automation.Host.Rectangle r)
	$host.UI.RawUI.GetBufferContents([Management.Automation.Host.Rectangle]::new(0, $LineIndex-1, $host.UI.RawUI.BufferSize.Width, $LineIndex-1))
}
Add-Member -InputObject $host.UI.RawUI -MemberType ScriptMethod -Name GetLineText -Value {
	param($LineIndex = $host.UI.RawUI.CursorPosition.Y)
	$Line = $host.UI.RawUI.GetLineBuffer($LineIndex).Character -join ''
	$Line = $Line.TrimEnd()
	return $Line
}

#as root?
$ImSudo = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]“Administrator”)
$ImVSCodeExtension = $null -ne $psEditor
