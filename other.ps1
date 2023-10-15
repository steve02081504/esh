function EShell {
	pwsh.exe -NoProfileLoadTime -nologo
}
#设定别名esh
Set-Alias esh EShell
function sudo {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	if ($RemainingArguments.Length -eq 0) {
		# If the command is empty, open a new PowerShell shell with admin privileges
		Start-Process -Wait -FilePath "wt.exe" -ArgumentList "pwsh.exe -NoProfileLoadTime -nologo" -Verb runas
	} else {
		# Otherwise, run the command as an admin
		$Arguments = @("pwsh","-Command",$(pwsh_args_convert($RemainingArguments)))
		$Arguments = (cmd_args_convert($Arguments)+'').Replace('"', '\"')
		Start-Process -Wait -FilePath "wt.exe" -ArgumentList $Arguments -Verb runas
	}
}
function mklink {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	#对于每个参数
	$RemainingArguments = $RemainingArguments | ForEach-Object {
		#若参数长度大于2且是linux路径
		if (($_.Length -gt 2) -and (IsLinuxPath($_))) {
			#转换为windows路径
			LinuxPathToWindowsPath($_)
		}
		else{
			$_
		}
	}
	#调用cmd的mklink
	. cmd /c mklink $RemainingArguments
}
function reboot {
	#重启
	shutdown.exe /r /t 0
}
function shutdown {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	if($RemainingArguments.Length -eq 0){
		#默认为立即关机
		$RemainingArguments = "/s /t 0"
	}
	#关机
	shutdown.exe $RemainingArguments
}
Set-Alias poweroff shutdown

function poweron {
	Write-Host "This coputer is already on."
}

function clear-emptys {
	param(
		[switch]$recursive,
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$paths
	)
	#若参数为空
	if ($paths.Length -eq 0) {
		#默认为当前目录下的所有文件
		$paths = Get-ChildItem | ForEach-Object { $_.FullName }
	}
	#对于每个参数
	$paths = $paths | ForEach-Object {
		#若参数是linux路径
		if (IsLinuxPath($_)) {
			#转换为windows路径
			LinuxPathToWindowsPath($_)
		}
		else{
			$_
		}
	}
	#对于每个参数
	$paths | ForEach-Object {
		#若参数是文件夹，且文件夹不为空（测试隐藏文件）
		if ($recursive -and (Test-Path $_) -and (Get-ChildItem $_ -Force | Measure-Object).Count -gt 0) {
			#对于每个子文件
			Get-ChildItem $_ -Force | ForEach-Object {
				clear-emptys -recursive -paths $_
			}
		}
		#若参数是文件夹，且文件夹为空
		if ((Test-Path $_) -and (Get-ChildItem $_ -Force | Measure-Object).Count -eq 0) {
			#删除文件夹
			Remove-Item $_
		}
		#若参数是文件，且文件大小为0
		elseif ((Test-Path $_) -and (Get-Item $_).Length -eq 0) {
			#删除文件
			Remove-Item $_
		}
	}
}

function dirsync{
	param(
		[Parameter(Mandatory = $true)]
		[string] $source,
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$paths
	)
	#对于每个参数
	$paths = $paths | ForEach-Object {
		#若参数是linux路径
		if (IsLinuxPath($_)) {
			#转换为windows路径
			LinuxPathToWindowsPath($_)
		}
		else{
			$_
		}
	}
	#对于每个参数
	$paths | ForEach-Object {
		#若参数是文件夹
		if (Test-Path $_) {
			#同步文件夹，删除目标文件夹中不存在的文件，并且将隐藏和系统文件包含在同步中
			robocopy.exe $source $_ /MIR /XD .git /XF .gitignore /XA:H /XA:S
		}
	}
}

function reload{
	& EShell
	exit
}

function size_format {
	param (
		[Parameter(Mandatory = $true)]
		[double] $size
	)
	#若文件大小大于1GB
	if ($size -gt 1GB) {
		#输出文件大小
		"{0:N2} GB" -f ($size / 1GB)
	}
	#若文件大小大于1MB
	elseif ($size -gt 1MB) {
		#输出文件大小
		"{0:N2} MB" -f ($size / 1MB)
	}
	#若文件大小大于1KB
	elseif ($size -gt 1KB) {
		#输出文件大小
		"{0:N2} KB" -f ($size / 1KB)
	}
	#否则
	else {
		#输出文件大小
		"{0:N2} B" -f $size
	}
}
function fsize {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$paths
	)
	#若参数为空
	if ($paths.Length -eq 0) {
		#默认为当前目录
		$paths = @('.')
	}
	#对于每个参数
	$paths = $paths | ForEach-Object {
		#若参数是linux路径
		if (IsLinuxPath($_)) {
			#转换为windows路径
			LinuxPathToWindowsPath($_)
		}
		else{
			$_
		}
	}
	#对于每个参数
	$paths | ForEach-Object {
		#若参数是文件夹
		if ((Test-Path $_) -and (Get-ChildItem $_ -Force | Measure-Object).Count -gt 0) {
			#以表格形式输出文件夹下的大小
			Get-ChildItem $_ -Force | ForEach-Object {
				if($_.PSIsContainer){
					$size = (Get-ChildItem $_ -Recurse -Force | Measure-Object -Property Length -Sum).Sum
					"{0,10} {1}" -f (size_format $size), $_.Name
				}
				else{
					$size = $_.Length
					"{0,10} {1}" -f (size_format $size), $_.Name
				}
			}
		}
		#若参数是文件
		elseif (Test-Path $_) {
			#输出文件大小
			$size = (Get-Item $_).Length
			"{0,10} {1}" -f (size_format $size), $_
		}
	}
}
