#我的msys路径
${MSYS.RootPath}= "E:\msys"

function IsLinuxPath{
	param(
		[string]$Path
	)
	if ($Path.StartsWith("/") -or $Path.StartsWith("~")){
		return $true
	}
	return $false
}

#一个函数以处理linux路径到windows路径的转换
function LinuxPathToWindowsPath{
	param(
		[string]$Path
	)
	#若path以/（单个字母）/开头，则对应windows盘符
	if ($Path -match "^/([a-zA-Z])/"){
		$DriveLetter = $Matches[1]
		$Path = Join-Path -Path "${DriveLetter}:" -ChildPath $Path.Substring(3)
	}
	elseif($Path.StartsWith("~")){
		$Path = Join-Path -Path $HOME -ChildPath $Path.Substring(1)
	}
	else{
		#否则根据msys的rootpath来转换
		$Path = Join-Path -Path ${MSYS.RootPath} -ChildPath $Path
	}
	return $Path
}
function WindowsPathToLinuxPath{
	param(
		[string]$Path
	)
	#若path是rootpath的子目录
	if ($Path.StartsWith(${MSYS.RootPath})){
		#则转换为linux路径
		$Path = $Path.Substring(${MSYS.RootPath}.Length)
	}
	elseif($Path.StartsWith($HOME)){
		$Path = "~" + $Path.Substring($HOME.Length)
	}
	else{
		#否则根据盘符转换
		$DriveLetter = $Path.Substring(0, 1)
		$Path = $Path.Substring(2)
		$Path = "/${DriveLetter}/${Path}"
	}
	$Path = $Path.Replace("\", "/")
	return $Path
}

#一个补全提供器用于补全linux路径
$LinuxPathCompleter={
	param(
		[string]$commandName,
		[string]$parameterName,
		[string]$wordToComplete,
		[string]$commandAst,
		[string]$fakeBoundParameter
	)
	#补全的前提是要补全的词语为linux路径
	if (-not (IsLinuxPath -Path $wordToComplete)){
		return
	}
	#获取对应的windows路径
	$WindowsPath = LinuxPathToWindowsPath -Path $wordToComplete
	#若windows路径不存在
	if (-not (Test-Path -Path $WindowsPath)){
		#测试其父目录是否存在
		$ParentPath = Split-Path -Path $WindowsPath -Parent
		if (-not (Test-Path -Path $ParentPath)){
			#若父目录不存在，则不补全
			return
		}
		#若父目录存在，则根据后半段路径补全
		$WordToComplete = Split-Path -Path $WindowsPath -Leaf
		#遍历父目录下的所有文件和目录
		Get-ChildItem($ParentPath) | ForEach-Object{
			#若文件或目录名以$WordToComplete开头
			if ($_.Name -like "${WordToComplete}*"){
				#输出其linux路径
				WindowsPathToLinuxPath($_.FullName)
			}
		}
	}
	else{
		#若windows路径存在，则遍历其下的所有文件和目录
		Get-ChildItem($WindowsPath) | ForEach-Object{
			#输出其linux路径
			WindowsPathToLinuxPath($_.FullName)
		}
	}
}
Register-ArgumentCompleter -ParameterName "Path" -ScriptBlock $LinuxPathCompleter
Register-ArgumentCompleter -ParameterName "Path1" -ScriptBlock $LinuxPathCompleter
Register-ArgumentCompleter -ParameterName "Path2" -ScriptBlock $LinuxPathCompleter
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

. $PSScriptRoot/linux_bins.ps1

#设置一个函数用于在powershell执行以/开头的命令时，自动转换为windows路径
#设置触发器
Set-PSReadlineKeyHandler -Key Enter -ScriptBlock {
	#获取当前行
	$OriLine = $null
	$Cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$OriLine, [ref]$Cursor)
	$Line = $OriLine.Trim()
	Write-Host ""
	#自行首获取可执行文件路径
	$Executable = $Line.Split(" ")[0]
	$Rest = $Line.Substring($Executable.Length + 1)
	if ($Executable.StartsWith('"')){
		while (-not $Executable.EndsWith('"')){
			$Executable = $Executable + " " + $Line.Substring($Executable.Length + 1).Split(" ")[0]
		}
		$Rest = $Line.Substring($Executable.Length + 1)
	}
	#若当前行以/开头
	if ($Executable.StartsWith("/") -or $Executable.StartsWith("~")){
		[Microsoft.PowerShell.PSConsoleReadLine]::CancelLine()
		Write-Host "`b`b  "
		#则转换为windows路径
		$Executable = LinuxPathToWindowsPath -Path $Executable
		#求值并输出
		& $Executable $Rest | Write-Host
	}
	else{
		[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
	}
}