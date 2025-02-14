#让我们升级cd来让它可以处理linux路径
while (Test-Path Alias:cd) {
	Remove-Item Alias:cd
}
function global:cd {
	$_RemainingArguments = [System.Collections.ArrayList]$args
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if (-not $arg) {
			$_RemainingArguments.RemoveAt($i)
			continue
		}
		if ($arg -is [System.IO.FileInfo]) {
			$Path = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg -is [System.Management.Automation.ExternalScriptInfo]) {
			$Path = $arg.Source
			if (Test-Path $Path -PathType Leaf) {
				$Path = Split-Path $Path
			}
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$_RemainingArguments = @($_RemainingArguments)
	if (-not "$_RemainingArguments") {
		$_RemainingArguments = @()
	}
	if ($Path -eq '/?') {
		cmd.exe /c cd /?
		return
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	#若path满足%\w+%
	$Path = HandleCmdPath $Path
	#调用原始的cd..?
	#让我们根据RemainingArguments的风格来判断是调用cd还是Set-Location
	#cd是bash提供的内置命令，没有单独的可执行文件
	#所以我们只能通过Set-Location来模拟cd的行为
	$IsLinuxBin = $Path.Length -eq 0
	function baseCD ($Path, [switch]$IsFollowSymbolicLink = $true) {
		function FailedOutPut($ValidPath) {
			$ValidPath ??= $Path
			while ($ValidPath -and !(Test-Path $ValidPath -PathType Container)) {
				$ValidPath = Split-Path $ValidPath
			}
			"bash: cd: $(AutoShortPath $Path): No such file or directory"
			if ($ValidPath) {
				"Last valid path: $(AutoShortPath $ValidPath)"
			}
		}
		$Path ??= '~'
		if (-not $IsFollowSymbolicLink) {
			#循环分割路径，检查每一级路径是否是符号链接
			$PreviousPath = ""
			while ($Path) {
				$CurrentPath = Split-Path $Path
				$ChildPath = Split-Path $Path -Leaf
				$PreviousPath = Join-Path $PreviousPath $CurrentPath
				$Path = $ChildPath
				if (-not (Test-Path $PreviousPath -PathType Container)) {
					FailedOutPut $PreviousPath | Out-Error
				}
				#若是符号链接
				if ((Get-Item $PreviousPath).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
					#则更新路径到符号链接的目标
					$PreviousPath = (Get-Item $PreviousPath).Target
					continue
				}
			}
		}
		if (Test-Path $Path -PathType Leaf) {
			$DirPath = Split-Path $Path
			Out-Warning "bash: cd: $(AutoShortPath $Path): Is a file, guessing you meant $(AutoShortPath $DirPath)"
			$Path = $DirPath
		}
		if (Test-Path $Path -PathType Container) {
			Set-Location $Path
		}
		elseif (Test-Command $Path) {
			$Cmd = Get-Command $Path
			$CmdPath = switch ($Cmd.CommandType) {
				Application { $Cmd.Source }
				Function {
					if(Test-Path $Cmd.Source) { $Cmd.Source }
					elseif (Test-Path $Cmd.Definition) { $Cmd.Definition }
					elseif ($Cmd.Source) {
						$module = Get-Module $Cmd.Source
						if ($module) { $module.ModuleBase }
					}
					elseif (Test-Command "$Path.exe") {
						(Get-Command "$Path.exe").Source
					}
				}
			}

			if ($CmdPath -and (Test-Path $CmdPath -PathType Leaf)) { $CmdPath = Split-Path $CmdPath -ErrorAction Ignore }
			if ($CmdPath -and (Test-Path $CmdPath -PathType Container)) {
				Out-Warning "bash: cd: $(AutoShortPath $Path): Is a command, guessing you meant $(AutoShortPath $CmdPath)"
				Set-Location $CmdPath
			}
			else {
				FailedOutPut | Out-Error
			}
		}
		else {
			$linuxPath = LinuxPathToWindowsPath $Path
			if (Test-Path $linuxPath -PathType Container) {
				Set-Location $linuxPath
			}
			else {
				FailedOutPut | Out-Error
			}
		}
		return
	}
	if ($_RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		baseCD $Path
		return
	}
	#cd: usage: cd [-L|[-P [-e]] [-@]] [dir]
	if (-not $IsLinuxBin) {
		$IsLinuxBin = !(Test-Call Set-Location $args)
	}
	if ($IsLinuxBin) {
		#cd是bash提供的内置命令，没有单独的可执行文件
		#所以我们只能通过Set-Location来模拟cd的行为
		foreach ($arg in $_RemainingArguments) {
			if ($arg -eq "-L") {
				#-L的意思是跟随符号链接
				#但是powershell的Set-Location默认就是跟随符号链接的
				#所以我们不需要做任何事情
			}
			elseif ($arg -eq "-P") {
				#-P的意思是不跟随符号链接
				#由于PWD总能被确定，检查RemainingArguments中是否有-e是没有意义的
				baseCD $Path -IsFollowSymbolicLink:$false
				return
			}
			elseif ($arg -eq "-e") {
				#单独的-e没有任何意义，无视（bash就是这样做的）
			}
			elseif ($arg -eq "-@") {
				#-@的意思是显示扩展属性，我们直接不支持这个功能
			}
			else {
				$result = bash -c "cd $Path $_RemainingArguments"
				if ($LASTEXITCODE) {
					$SillyPath = $args -join ' '
					if (Test-Path $SillyPath) {
						"Guessing you meant $($VirtualTerminal.Colors.Cyan)`"$(AutoShortPath $SillyPath)`"$($VirtualTerminal.Colors.Default), changing to it."
						baseCD $SillyPath
						return
					}
				}
				$result
				return
			}
		}
	}
	else {
		#否则调用Set-Location
		Invoke-Expression "Set-Location $Path $_RemainingArguments"
	}
}

#让我们升级ls来让它可以处理linux路径
while (Test-Path Alias:ls) {
	Remove-Item Alias:ls
}
function global:ls {
	$_RemainingArguments = [System.Collections.ArrayList]$args
	$IsLinuxBin = $false
	$WinArgs = $_RemainingArguments | ForEach-Object {
		# 跳过参数部分
		if ($_ -is [string] -and $_.StartsWith("-")) {
			return $_
		}
		#若是有效的文件路径，保持原样
		if (Test-Path $_) {
			return $_
		}
		$winPath = LinuxPathToWindowsPath $_
		if (Test-Path $winPath) {
			return $winPath
		}
		return $_
	}
	$linuxArgs = $_RemainingArguments | ForEach-Object {
		if ($_ -is [string] -and $_.StartsWith("-")) {
			return $_
		}
		if (Test-Path $_) {
			WindowsPathToLinuxPath $_
		}
		else {
			$_
		}
	}
	#若path满足%\w+%
	$Path = HandleCmdPath $Path
	$IsLinuxBin = !(Test-Call Get-ChildItem $WinArgs)
	# 特殊照顾下参数有-f|-R的情况 因为太常用了
	if ($_RemainingArguments -ccontains "-f" -or $_RemainingArguments -ccontains "-R") {
		if ($_RemainingArguments -ccontains "-f") {
			$TestRemainingArguments = @($WinArgs) -ne "-f"
			$TestRemainingArguments += "-Force"
		}
		if ($_RemainingArguments -ccontains "-R") {
			$TestRemainingArguments = @($WinArgs) -ne "-R"
			$TestRemainingArguments += "-Recurse"
		}
		$IsLinuxBin = !(Test-Call Get-ChildItem $TestRemainingArguments)
		if (-not $IsLinuxBin) {
			$WinArgs = $TestRemainingArguments
		}
	}
	if ($IsLinuxBin) {
		#若是linux的ls.exe
		#则调用ls.exe
		$linuxArgs = '"' + $linuxArgs -join '" "' + '"'
		$linuxArgs = $linuxArgs.Trim()
		ls.exe $linuxArgs
	}
	else {
		#否则调用Get-ChildItem
		Invoke-Expression "Get-ChildItem $WinArgs"
	}
}

#让我们升级rm来让它可以处理linux路径
while (Test-Path Alias:rm) {
	Remove-Item Alias:rm
}
function global:rm {
	$_RemainingArguments = [System.Collections.ArrayList]$args
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if ($arg -is [System.IO.FileInfo]) {
			$Path = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$_RemainingArguments = @($_RemainingArguments)
	if (-not "$_RemainingArguments") {
		$_RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	#若path满足%\w+%
	$Path = HandleCmdPath $Path
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		rm.exe $_RemainingArguments
		return
	}
	if ($_RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用Remove-Item
		Remove-Item $Path
		return
	}
	$IsLinuxBin = !(Test-Call Remove-Item $_RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的rm.exe
		#则调用rm.exe
		$Path = WindowsPathToLinuxPath $Path
		$_RemainingArguments = $_RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$_RemainingArguments = $_RemainingArguments -join " "
		$_RemainingArguments = $_RemainingArguments.Trim()
		Invoke-Expression "rm.exe $Path $_RemainingArguments"
	}
	else {
		#否则调用Remove-Item
		Invoke-Expression "Remove-Item $Path $_RemainingArguments"
	}
}

#让我们升级mv来让它可以处理linux路径
while (Test-Path Alias:mv) {
	Remove-Item Alias:mv
}
function global:mv {
	$_RemainingArguments = [System.Collections.ArrayList]$args
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if ($arg -is [System.IO.FileInfo]) {
			$Path = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	#从RemainingArguments中提取Destination
	$Destination = ""
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if ($arg -is [System.IO.FileInfo]) {
			$Destination = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Destination = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$_RemainingArguments = @($_RemainingArguments)
	if (-not "$_RemainingArguments") {
		$_RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	if (IsLinuxPath $Destination) {
		#则转换为windows路径
		$Destination = LinuxPathToWindowsPath $Destination
	}
	#若path满足%\w+%
	$Path = HandleCmdPath $Path
	$Destination = HandleCmdPath $Destination
	$IsLinuxBin = $Path.Length -eq 0 -and $Destination.Length -eq 0
	if ($IsLinuxBin) {
		mv.exe @args
		return
	}
	if ($_RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用Move-Item
		Move-Item $Path -Destination $Destination
		return
	}
	$IsLinuxBin = !(Test-Call Move-Item $_RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的mv.exe
		#则调用mv.exe
		$Path = WindowsPathToLinuxPath $Path
		$_RemainingArguments = $_RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$_RemainingArguments = $_RemainingArguments -join " "
		$_RemainingArguments = $_RemainingArguments.Trim()
		mv.exe $Path $Destination $_RemainingArguments
	}
	else {
		#否则调用Move-Item
		Invoke-Expression "Move-Item $Path -Destination $Destination $_RemainingArguments"
	}
}

#让我们升级cp来让它可以处理linux路径
while (Test-Path Alias:cp) {
	Remove-Item Alias:cp
}
function global:cp {
	$_RemainingArguments = [System.Collections.ArrayList]$args
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if ($arg -is [System.IO.FileInfo]) {
			$Path = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	#从RemainingArguments中提取Destination
	$Destination = ""
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if ($arg -is [System.IO.FileInfo]) {
			$Destination = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Destination = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$_RemainingArguments = @($_RemainingArguments)
	if (-not "$_RemainingArguments") {
		$_RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	if (IsLinuxPath $Destination) {
		#则转换为windows路径
		$Destination = LinuxPathToWindowsPath $Destination
	}
	#若path满足%\w+%
	$Path = HandleCmdPath $Path
	$Destination = HandleCmdPath $Destination
	$IsLinuxBin = $Path.Length -eq 0 -and $Destination.Length -eq 0
	if ($IsLinuxBin) {
		cp.exe @args
		return
	}
	if ($_RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用Copy-Item
		Copy-Item $Path -Destination $Destination
		return
	}
	$IsLinuxBin = !(Test-Call Copy-Item $_RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的cp.exe
		#则调用cp.exe
		$Path = WindowsPathToLinuxPath $Path
		$_RemainingArguments = $_RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$_RemainingArguments = $_RemainingArguments -join " "
		$_RemainingArguments = $_RemainingArguments.Trim()
		cp.exe $Path $Destination $_RemainingArguments
	}
	else {
		#否则调用Copy-Item
		Invoke-Expression "Copy-Item $Path -Destination $Destination $_RemainingArguments"
	}
}

function global:mkdir {
	$_RemainingArguments = [System.Collections.ArrayList]$args
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if ($arg -is [System.IO.FileInfo]) {
			$Path = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$_RemainingArguments = @($_RemainingArguments)
	if (-not "$_RemainingArguments") {
		$_RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	#若path满足%\w+%
	$Path = HandleCmdPath $Path
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		mkdir.exe @args
		return
	}
	if ($_RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用New-Item
		New-Item $Path -ItemType Directory
		return
	}
	$IsLinuxBin = !(Test-Call New-Item $args)
	if ($IsLinuxBin) {
		#若是linux的mkdir.exe
		#则调用mkdir.exe
		$Path = WindowsPathToLinuxPath $Path
		$_RemainingArguments = $_RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$_RemainingArguments = $_RemainingArguments -join " "
		$_RemainingArguments = $_RemainingArguments.Trim()
		mkdir.exe $Path $_RemainingArguments
	}
	else {
		#否则调用New-Item
		Invoke-Expression "New-Item $Path -ItemType Directory $_RemainingArguments"
	}
}

function global:touch {
	if ($Input) { $ContentToSet = $Input -join "`n" }
	$_RemainingArguments = [System.Collections.ArrayList]$args
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if ($arg -is [System.IO.FileInfo]) {
			$Path = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$_RemainingArguments = @($_RemainingArguments)
	if (-not "$_RemainingArguments") {
		$_RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	#若path满足%\w+%
	$Path = HandleCmdPath $Path
	if ($ContentToSet) {
		$ContentToSet | Out-File $Path -Encoding utf8
		Get-Item $Path
		return
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		touch.exe @args
		return
	}
	if ($_RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用New-Item
		New-Item $Path -ItemType File
		return
	}
	$IsLinuxBin = !(Test-Call New-Item $_RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的touch.exe
		#则调用touch.exe
		$Path = WindowsPathToLinuxPath $Path
		$_RemainingArguments = $_RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$_RemainingArguments = $_RemainingArguments -join " "
		$_RemainingArguments = $_RemainingArguments.Trim()
		touch.exe $Path $_RemainingArguments
	}
	else {
		#否则调用New-Item
		Invoke-Expression "New-Item $Path -ItemType File $_RemainingArguments"
	}
}

#让我们升级cat来让它可以处理linux路径
while (Test-Path Alias:cat) {
	Remove-Item Alias:cat
}
function global:cat {
	$_RemainingArguments = [System.Collections.ArrayList]$args
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $_RemainingArguments.Count; $i++) {
		$arg = $_RemainingArguments[$i]
		if ($arg -is [System.IO.FileInfo]) {
			$Path = $arg
			$_RemainingArguments.RemoveAt($i)
			break
		}
		elseif ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$_RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$_RemainingArguments = @($_RemainingArguments)
	if (-not "$_RemainingArguments") {
		$_RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	#若path满足%\w+%
	$Path = HandleCmdPath $Path
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		cat.exe @args
		return
	}
	if ($_RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#json文件
		if ([System.IO.Path]::GetExtension($Path) -eq ".json") {
			try {
				$FileResult = Get-Content $Path
				$result = $FileResult | ConvertFrom-Json
				if ("$FileResult" -eq ($result | ConvertTo-Json -Depth 100 -Compress)) {
					Add-Member -InputObject $result -MemberType ScriptMethod -Name "toString" -Value {
						$this | ConvertTo-Json -Depth 100 -Compress
					} -Force
				}
				elseif (($result | ConvertTo-Json -Depth 100 | ConvertFrom-Json | ConvertTo-Json -Depth 100) -eq ($result | ConvertTo-Json -Depth 100)) {
					Add-Member -InputObject $result -MemberType ScriptMethod -Name "toString" -Value {
						$this | ConvertTo-Json -Depth 100
					} -Force
				}
			}
			catch { }
			if ($expr_now.StartsWith("cat ")) { # 无输出对象到控制台
				$global:ans_array = [System.Collections.ArrayList]@($result ?? $FileResult) # 设置输出对象
				# nodejs可用？
				if (Test-Command node.exe) {
					#则调用node
					node.exe $PSScriptRoot/cat_json.mjs $Path
					if($LASTEXITCODE -eq 0){ return }
				}
				Write-Host $FileResult
				return
			}
			else {
				return $result
			}
		}

		#则调用Get-Content
		if (Test-Path $Path) {
			Get-Content $Path
		}
		else {
			"cat: $(AutoShortPath $Path): No such file or directory"
		}
		return
	}
	$IsLinuxBin = !(Test-Call Get-Content $_RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的cat.exe
		#则调用cat.exe
		$Path = WindowsPathToLinuxPath $Path
		$_RemainingArguments = $_RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$_RemainingArguments = $_RemainingArguments -join " "
		$_RemainingArguments = $_RemainingArguments.Trim()
		cat.exe $Path $_RemainingArguments
	}
	else {
		#否则调用Get-Content
		Invoke-Expression "Get-Content $Path $_RemainingArguments"
	}
}
