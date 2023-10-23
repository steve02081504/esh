function EShell {
	pwsh -nologo $(if ($PSVersionTable.PSVersion -gt 7.3) { "-NoProfileLoadTime" })
}
#设定别名esh
Set-Alias esh EShell
function sudo {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	$pwshArguments = "$(if($PSVersionTable.PSVersion -gt 7.3){`"-NoProfileLoadTime`"}) -nologo"
	if ($RemainingArguments.Length -eq 0) {
		if ($ImSudo) {
			Write-Host "I already have ${VirtualTerminal.Styles.Blink}Super Power${VirtualTerminal.Styles.NoBlink}s."
		}
		# If the command is empty, open a new PowerShell shell with admin privileges
		elseif (Test-Command wt.exe) {
			Start-Process -Wait -FilePath "wt.exe" -ArgumentList "pwsh.exe $pwshArguments" -Verb runas
		}
		else {
			Start-Process -Wait -FilePath "pwsh.exe" -ArgumentList $pwshArguments -Verb runas
		}
	} else {
		if ($ImSudo) {
			Invoke-Expression "$RemainingArguments"
		}
		# Otherwise, run the command as an admin
		elseif (Test-Command wt.exe) {
			$Arguments = @("pwsh","-Command",$(pwsh_args_convert ($RemainingArguments)))
			$Arguments = cmd_args_convert ($Arguments)
			Start-Process -Wait -FilePath "wt.exe" -ArgumentList $Arguments.Replace('"','\"') -Verb runas
		}
		else {
			$Arguments = @("-Command",$(pwsh_args_convert ($RemainingArguments)))
			$Arguments = cmd_args_convert ($Arguments)
			Start-Process -Wait -FilePath "pwsh.exe" -ArgumentList "$pwshArguments $Arguments" -Verb runas
		}
	}
}
function mklink {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	#对于每个参数
	$RemainingArguments = $RemainingArguments | ForEach-Object {
		#若参数长度不是2且是linux路径
		if (($_.Length -ne 2) -and (IsLinuxPath ($_))) {
			#转换为windows路径
			LinuxPathToWindowsPath ($_)
		}
		else {
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
	if ($RemainingArguments.Length -eq 0) {
		#默认为立即关机
		shutdown.exe /s /t 0
	}
	else {
		#关机
		shutdown.exe $RemainingArguments
	}
}
Set-Alias poweroff shutdown

function poweron {
	Write-Host "This computer is already powered on."
}
function power {
	param(
		#off / on
		[ValidateSet("off","on")]
		[string]$action
	)
	switch ($action) {
		"off" { poweroff }
		"on" { poweron }
		default {
			Write-Host "I'm the storm that's ${VirtualTerminal.Styles.Blink}approaching!!!!!!!!!!!!!!!!!!!!`nApproaching!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${VirtualTerminal.Styles.NoBlink}"
		}
	}
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
		if (IsLinuxPath ($_)) {
			#转换为windows路径
			LinuxPathToWindowsPath ($_)
		}
		else {
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

function dirsync {
	param(
		[Parameter(Mandatory = $true)]
		[string]$source,
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$paths
	)
	#对于每个参数
	$paths = $paths | ForEach-Object {
		#若参数是linux路径
		if (IsLinuxPath ($_)) {
			#转换为windows路径
			LinuxPathToWindowsPath ($_)
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

function reload {
	& EShell
	exit
}

function size_format {
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
		if (IsLinuxPath ($_)) {
			#转换为windows路径
			LinuxPathToWindowsPath ($_)
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
					"{0,10} {1}" -f (size_format $size),$_.Name
				}
				else {
					$size = $_.Length
					"{0,10} {1}" -f (size_format $size),$_.Name
				}
			}
		}
		#若参数是文件
		elseif (Test-Path $_) {
			#输出文件大小
			$size = (Get-Item $_).Length
			"{0,10} {1}" -f (size_format $size),$_
		}
	}
}

function coffee { "
    ( (
     ) )
  .______.
  |      |]
  \      /
   `----'
" }

function Update-SAO-lib {
	#获取$PROFILE的父目录
	$src = Split-Path $PROFILE
	try {
		#下载最新的SAO-lib
		Invoke-WebRequest -Uri "https://github.com/steve02081504/SAO-lib/raw/master/SAO-lib.txt" -OutFile "$src/data/SAO-lib.txt"
	}
	catch {}
}
function Update-EShell {
	Update-SAO-lib
	#获取$PROFILE的父目录
	$src = Split-Path $PROFILE
	try {
		#下载最新的EShell
		Invoke-WebRequest -Uri "https://github.com/steve02081504/my-powershell-profile/archive/refs/heads/master.zip" -OutFile "$src\master.zip"
		#解压缩my-powershell-profile-master中的src文件夹到$PROFILE的父目录
		Expand-Archive -Path "$src\master.zip" -DestinationPath "$src" -Force
		#删除旧的EShell
		Remove-Item "$src\src" -Recurse -Force
		#移动my-powershell-profile-master/src到src
		Move-Item "$src\my-powershell-profile-master\src" "$src\src" -Force
		#删除my-powershell-profile-master
		Remove-Item "$src\my-powershell-profile-master" -Recurse -Force

		#删除压缩包
		Remove-Item "$src\master.zip" -Force
		#重载EShell
		reload
	}
	catch {}
}
