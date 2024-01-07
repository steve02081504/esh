#让我们升级cd来让它可以处理linux路径
while (Test-Path Alias:cd) {
	Remove-Item Alias:cd
}
function global:cd {
	param(
		#其余的参数
		[Parameter(ValueFromRemainingArguments = $true)]
		[System.Collections.ArrayList]$RemainingArguments
	)
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if (-not $arg) {
			$RemainingArguments.RemoveAt($i)
			continue
		}
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	if (-not "$RemainingArguments") {
		$RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	#调用原始的cd..?
	#让我们根据RemainingArguments的风格来判断是调用cd还是Set-Location
	#cd是bash提供的内置命令，没有单独的可执行文件
	#所以我们只能通过Set-Location来模拟cd的行为
	$IsLinuxBin = $Path.Length -eq 0
	function baseCD ($Path, [switch]$IsFollowSymbolicLink = $true) {
		$Path ??= '~'
		if (-not $IsFollowSymbolicLink) {
			#循环分割路径，检查每一级路径是否是符号链接
			$PreviousPath = ""
			while ($Path) {
				$CurrentPath = Split-Path $Path
				$ChildPath = Split-Path $Path -Leaf
				$PreviousPath = Join-Path $PreviousPath $CurrentPath
				$Path = $ChildPath
				if (-not (Test-Path $PreviousPath)) {
					Out-Error "bash: cd: ${PreviousPath}: No such file or directory"
				}
				#若是符号链接
				if ((Get-Item $PreviousPath).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
					#则更新路径到符号链接的目标
					$PreviousPath = (Get-Item $PreviousPath).Target
					continue
				}
			}
		}
		if (Test-Path $Path) {
			Set-Location $Path
		}
		else {
			Out-Error "bash: cd: ${Path}: No such file or directory"
		}
		return
	}
	if ($RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		baseCD $Path
		return
	}
	#cd: usage: cd [-L|[-P [-e]] [-@]] [dir]
	if (-not $IsLinuxBin) {
		$IsLinuxBin = !(Test-Call Set-Location $RemainingArguments)
	}
	if ($IsLinuxBin) {
		#cd是bash提供的内置命令，没有单独的可执行文件
		#所以我们只能通过Set-Location来模拟cd的行为
		foreach ($arg in $RemainingArguments) {
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
				bash -c "cd $Path $RemainingArguments"
				return
			}
		}
	}
	else {
		#否则调用Set-Location
		Invoke-Expression "Set-Location $Path $RemainingArguments"
	}
}

#让我们升级ls来让它可以处理linux路径
while (Test-Path Alias:ls) {
	Remove-Item Alias:ls
}
function global:ls {
	param(
		#其余的参数
		[Parameter(ValueFromRemainingArguments = $true)]
		[System.Collections.ArrayList]$RemainingArguments
	)
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	if (-not "$RemainingArguments") {
		$RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	$IsLinuxBin = $false
	if ($RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用Get-ChildItem
		if ($Path.Length -eq 0) {
			Get-ChildItem
		}
		elseif (Test-Path $Path) {
			Get-ChildItem $Path
		}
		else {
			ls.exe $(WindowsPathToLinuxPath $Path)
		}
		return
	}
	$IsLinuxBin = !(Test-Call Get-ChildItem $RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的ls.exe
		#则调用ls.exe
		$Path = WindowsPathToLinuxPath $Path
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$RemainingArguments = $RemainingArguments -join " "
		$RemainingArguments = $RemainingArguments.Trim()
		if ($Path.Length -eq 0) {
			ls.exe $RemainingArguments
		}
		else {
			ls.exe $Path $RemainingArguments
		}
	}
	else {
		#否则调用Get-ChildItem
		Invoke-Expression "Get-ChildItem $Path $RemainingArguments"
	}
}

#让我们升级rm来让它可以处理linux路径
while (Test-Path Alias:rm) {
	Remove-Item Alias:rm
}
function global:rm {
	param(
		#其余的参数
		[Parameter(ValueFromRemainingArguments = $true)]
		[System.Collections.ArrayList]$RemainingArguments
	)
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	if (-not "$RemainingArguments") {
		$RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		rm.exe $RemainingArguments
		return
	}
	if ($RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用Remove-Item
		Remove-Item $Path
		return
	}
	$IsLinuxBin = !(Test-Call Remove-Item $RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的rm.exe
		#则调用rm.exe
		$Path = WindowsPathToLinuxPath $Path
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$RemainingArguments = $RemainingArguments -join " "
		$RemainingArguments = $RemainingArguments.Trim()
		rm.exe $Path $RemainingArguments
	}
	else {
		#否则调用Remove-Item
		Invoke-Expression "Remove-Item $Path $RemainingArguments"
	}
}

#让我们升级mv来让它可以处理linux路径
while (Test-Path Alias:mv) {
	Remove-Item Alias:mv
}
function global:mv {
	param(
		#其余的参数
		[Parameter(ValueFromRemainingArguments = $true)]
		[System.Collections.ArrayList]$RemainingArguments
	)
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	#从RemainingArguments中提取Destination
	$Destination = ""
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Destination = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	if (-not "$RemainingArguments") {
		$RemainingArguments = @()
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
	$IsLinuxBin = $Path.Length -eq 0 -and $Destination.Length -eq 0
	if ($IsLinuxBin) {
		mv.exe @args
		return
	}
	if ($RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用Move-Item
		Move-Item $Path -Destination $Destination
		return
	}
	$IsLinuxBin = !(Test-Call Move-Item $RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的mv.exe
		#则调用mv.exe
		$Path = WindowsPathToLinuxPath $Path
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$RemainingArguments = $RemainingArguments -join " "
		$RemainingArguments = $RemainingArguments.Trim()
		mv.exe $Path $Destination $RemainingArguments
	}
	else {
		#否则调用Move-Item
		Invoke-Expression "Move-Item $Path -Destination $Destination $RemainingArguments"
	}
}

#让我们升级cp来让它可以处理linux路径
while (Test-Path Alias:cp) {
	Remove-Item Alias:cp
}
function global:cp {
	param(
		#其余的参数
		[Parameter(ValueFromRemainingArguments = $true)]
		[System.Collections.ArrayList]$RemainingArguments
	)
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	#从RemainingArguments中提取Destination
	$Destination = ""
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Destination = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	if (-not "$RemainingArguments") {
		$RemainingArguments = @()
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
	$IsLinuxBin = $Path.Length -eq 0 -and $Destination.Length -eq 0
	if ($IsLinuxBin) {
		cp.exe @args
		return
	}
	if ($RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用Copy-Item
		Copy-Item $Path -Destination $Destination
		return
	}
	$IsLinuxBin = !(Test-Call Copy-Item $RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的cp.exe
		#则调用cp.exe
		$Path = WindowsPathToLinuxPath $Path
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$RemainingArguments = $RemainingArguments -join " "
		$RemainingArguments = $RemainingArguments.Trim()
		cp.exe $Path $Destination $RemainingArguments
	}
	else {
		#否则调用Copy-Item
		Invoke-Expression "Copy-Item $Path -Destination $Destination $RemainingArguments"
	}
}

function global:mkdir {
	param(
		#其余的参数
		[Parameter(ValueFromRemainingArguments = $true)]
		[System.Collections.ArrayList]$RemainingArguments
	)
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	if (-not "$RemainingArguments") {
		$RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		mkdir.exe @args
		return
	}
	if ($RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用New-Item
		New-Item $Path -ItemType Directory
		return
	}
	$IsLinuxBin = !(Test-Call New-Item $RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的mkdir.exe
		#则调用mkdir.exe
		$Path = WindowsPathToLinuxPath $Path
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$RemainingArguments = $RemainingArguments -join " "
		$RemainingArguments = $RemainingArguments.Trim()
		mkdir.exe $Path $RemainingArguments
	}
	else {
		#否则调用New-Item
		Invoke-Expression "New-Item $Path -ItemType Directory $RemainingArguments"
	}
}

function global:touch {
	param(
		#其余的参数
		[Parameter(ValueFromRemainingArguments = $true)]
		[System.Collections.ArrayList]$RemainingArguments
	)
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	if (-not "$RemainingArguments") {
		$RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		touch.exe @args
		return
	}
	if ($RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用New-Item
		New-Item $Path -ItemType File
		return
	}
	$IsLinuxBin = !(Test-Call New-Item $RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的touch.exe
		#则调用touch.exe
		$Path = WindowsPathToLinuxPath $Path
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$RemainingArguments = $RemainingArguments -join " "
		$RemainingArguments = $RemainingArguments.Trim()
		touch.exe $Path $RemainingArguments
	}
	else {
		#否则调用New-Item
		Invoke-Expression "New-Item $Path -ItemType File $RemainingArguments"
	}
}

#让我们升级cat来让它可以处理linux路径
while (Test-Path Alias:cat) {
	Remove-Item Alias:cat
}
function global:cat {
	param(
		#其余的参数
		[Parameter(ValueFromRemainingArguments = $true)]
		[System.Collections.ArrayList]$RemainingArguments
	)
	#从RemainingArguments中提取Path
	$Path = $null
	for ($i = 0; $i -lt $RemainingArguments.Count; $i++) {
		$arg = $RemainingArguments[$i]
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	if (-not "$RemainingArguments") {
		$RemainingArguments = @()
	}
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		cat.exe @args
		return
	}
	if ($RemainingArguments.Length -eq 0) {
		#若RemainingArguments是空的
		#则调用Get-Content
		Get-Content $Path
		return
	}
	$IsLinuxBin = !(Test-Call Get-Content $RemainingArguments)
	if ($IsLinuxBin) {
		#若是linux的cat.exe
		#则调用cat.exe
		$Path = WindowsPathToLinuxPath $Path
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath $_
			}
			else {
				$_
			}
		}
		$RemainingArguments = $RemainingArguments -join " "
		$RemainingArguments = $RemainingArguments.Trim()
		cat.exe $Path $RemainingArguments
	}
	else {
		#否则调用Get-Content
		Invoke-Expression "Get-Content $Path $RemainingArguments"
	}
}
