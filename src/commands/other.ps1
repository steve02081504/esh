function global:mklink {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	$replaceList = @{}
	#对于每个参数
	$RemainingArguments = $RemainingArguments | ForEach-Object {
		#若参数长度不是2且是linux路径
		if (($_.Length -ne 2) -and (IsLinuxPath $_)) {
			#转换为windows路径
			$replaceList[$_] = LinuxPathToFullWindowsPath $_
			$replaceList[$_]
		}
		else {
			$_
		}
	}
	#调用cmd的mklink
	$result = . cmd /c mklink $RemainingArguments
	if($result) {
		$replaceList.GetEnumerator() | ForEach-Object {
			$result = $result.Replace($_.Value, $_.Key)
		}
	}
	$result
}
function global:reboot {
	#重启
	shutdown.exe /r /t 0
}
function global:shutdown {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	if ($RemainingArguments.Length -eq 0) {
		#默认为立即关机
		shutdown.exe /s /t 0
	}
	else {
		#关机
		shutdown.exe $RemainingArguments
	}
}
Set-Alias poweroff shutdown -Scope global

function global:poweron {
	Write-Host 'This computer is already powered on.'
}
function global:power {
	param(
		#off / on
		[ValidateSet('off', 'on')]
		[string]$action
	)
	switch ($action) {
		'off' { poweroff }
		'on' { poweron }
		default {
			Write-Host "I'm the storm that's $($VirtualTerminal.Styles.Blink)approaching!!!!!!!!!!!!!!!!!!!!`nApproaching!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!$($VirtualTerminal.Styles.NoBlink)"
		}
	}
}

function global:clear-emptys {
	param(
		[switch]$recursive,
		[int]$depth = -1,
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$paths
	)
	($paths ?? '.') | ForEach-Object {
		if (IsLinuxPath $_) {
			LinuxPathToWindowsPath $_
		} else { $_ }
	} | ForEach-Object {
		if((Get-Item $_).PSIsContainer){
			$Count = {(Get-ChildItem $_ -Force | Measure-Object).Count}
			if ((&$Count) -gt 0 -and $recursive -and $depth -ne 0) {
				clear-emptys -recursive -depth $($depth - 1) -paths $((Get-ChildItem $_ -Force).FullName)
			}
			if ((&$Count) -eq 0) { Remove-Item $_ }
		}
		elseif ((Get-Item $_).Length -eq 0) { Remove-Item $_ }
	}
}

function global:dirsync {
	param(
		[Parameter(Mandatory = $true)]
		[string]$source,
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$paths
	)
	#对于每个参数
	$paths = $paths | ForEach-Object {
		#若参数是linux路径
		if (IsLinuxPath $_) {
			#转换为windows路径
			LinuxPathToWindowsPath $_
		}
		else {
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

function global:size_format {
	param(
		[Parameter(Mandatory = $true)]
		[double]$size
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
function global:fsize {
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
		if (IsLinuxPath $_) {
			#转换为windows路径
			LinuxPathToWindowsPath $_
		}
		else {
			$_
		}
	}
	#对于每个参数
	$paths | ForEach-Object {
		#若参数是文件夹
		if ((Test-Path $_) -and (Get-ChildItem $_ -Force | Measure-Object).Count -gt 0) {
			#以表格形式输出文件夹下的大小
			Get-ChildItem $_ -Force | ForEach-Object {
				if ($_.PSIsContainer) {
					$size = (Get-ChildItem $_ -Recurse -Force | Measure-Object -Property Length -Sum).Sum
					"{0,10} {1}" -f (size_format $size), $_.Name
				}
				else {
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

function global:code {
	if (Test-Command code.cmd) {
		code.cmd $args
	}
	elseif (Test-Command code-insiders.cmd) {
		code-insiders.cmd $args
	}
	else {
		Write-Host "VS Code not found."
	}
}

function global:Clear-UserPath {
	$UserPath = [Environment]::GetEnvironmentVariable("Path", "User").Split(';')
	$SystemPath = [Environment]::GetEnvironmentVariable("Path", "Machine").Split(';')
	$UserPath.Split(';') | ForEach-Object {
		if ($SystemPath -contains $_) {
			$UserPath = $UserPath -ne $_
			Write-Warning "已自用户变量中移除在系统变量中的路径$_"
		}
	} | Out-Null
	$UserPath = $UserPath | Select-Object -Unique
	$UserPath = $UserPath -join ';'
	[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")
}
