#查找$EshellUI.MSYS.RootPath是否是可用的msys路径
if (-not $EshellUI.MSYS.RootPath -or -not (Test-Path $EshellUI.MSYS.RootPath)) {
	#若不是，则遍历所有盘符
	$DriveLetters = Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Name }
	$DriveLetters | ForEach-Object {
		#若该盘符下存在msys路径
		if (Test-Path "${_}:\msys64") {
			#则设置为该路径
			$EshellUI.MSYS.RootPath = "${_}:\msys64"
		}
		elseif (Test-Path "${_}:\msys") {
			#或者设置为该路径
			$EshellUI.MSYS.RootPath = "${_}:\msys"
		}
	}
}

function global:IsLinuxPath {
	param(
		[string]$Path
	)
	if ($Path.StartsWith("/") -or $Path.StartsWith("~")) {
		return $true
	}
	if (($PWD.Path -eq $env:USERPROFILE) -and $Path.StartsWith("./")) {
		return $true
	}
	return $false
}

#一个函数以处理linux路径到windows路径的转换
function global:LinuxPathToWindowsPath {
	param(
		[string]$Path
	)
	if (($PWD.Path -eq $env:USERPROFILE) -and $Path.StartsWith("./")) {
		$Path = "~" + $Path.Substring(1)
	}
	#若path以/（单个字母）/开头，则对应windows盘符
	if ($Path -match "^/([a-zA-Z])/") {
		$DriveLetter = $Matches[1]
		return Join-Path "${DriveLetter}:" $Path.Substring(3)
	}
	elseif ($Path.StartsWith("~")) {
		$ResultPath = Join-Path $HOME $Path.Substring(1)
		if (-not (Test-Path $ResultPath)) {
			if ($Path.StartsWith("~/.")) {
				# 检查appdata
				$SubPath = $Path.Substring(3)
				#对于appdata下的每一个目录
				Get-ChildItem "$env:USERPROFILE/AppData/" | ForEach-Object {
					$TestPath = Join-Path $_.FullName $SubPath
					if (Test-Path $TestPath) {
						$ResultPath = $TestPath
					}
				}
			}
		}
		return $ResultPath
	}
	else {
		#否则根据msys的rootpath来转换
		return Join-Path $EshellUI.MSYS.RootPath $Path
	}
}
function global:WindowsPathToLinuxPath {
	param(
		[string]$Path
	)
	#若path是rootpath的子目录
	if ($Path.StartsWith($EshellUI.MSYS.RootPath)) {
		#则转换为linux路径
		$Path = $Path.Substring($EshellUI.MSYS.RootPath.Length)
	}
	elseif ($Path.StartsWith($HOME)) {
		$Path = "~" + $Path.Substring($HOME.Length)
	}
	elseif ($Path.Substring(1,1) -eq ":") {
		#否则根据盘符转换
		$DriveLetter = $Path.Substring(0,1)
		$Path = $Path.Substring(3)
		$Path = "/${DriveLetter}/${Path}"
	}
	$Path = $Path.Replace("\","/")
	return $Path
}

#一个补全提供器用于补全linux路径
$LinuxPathCompleter = {
	param(
		[string]$commandName,
		[string]$parameterName,
		[string]$wordToComplete,
		[string]$commandAst,
		[string]$fakeBoundParameter
	)
	#补全的前提是要补全的词语为linux路径
	if (-not (IsLinuxPath $wordToComplete)) {
		return
	}
	#获取对应的windows路径
	$WindowsPath = LinuxPathToWindowsPath $wordToComplete
	#若windows路径不存在
	if (-not (Test-Path $WindowsPath)) {
		#测试其父目录是否存在
		$ParentPath = Split-Path $WindowsPath
		if (-not (Test-Path $ParentPath)) {
			#若父目录不存在，则不补全
			return
		}
		#若父目录存在，则根据后半段路径补全
		$WordToComplete = Split-Path $WindowsPath -Leaf
		#遍历父目录下的所有文件和目录
		Get-ChildItem $ParentPath | ForEach-Object {
			#若文件或目录名以$WordToComplete开头
			if ($_.Name -like "${WordToComplete}*") {
				#输出其linux路径
				WindowsPathToLinuxPath $_.FullName
			}
		}
	}
	else {
		#若windows路径存在，则遍历其下的所有文件和目录
		Get-ChildItem $WindowsPath | ForEach-Object {
			#输出其linux路径
			WindowsPathToLinuxPath $_.FullName
		}
	}
}
Register-ArgumentCompleter -ParameterName "Path" -ScriptBlock $LinuxPathCompleter
Register-ArgumentCompleter -ParameterName "Destination" -ScriptBlock $LinuxPathCompleter
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

if (Test-Command rm.exe) {
	. "$($EshellUI.Sources.Path)/src/commands/special/linux_bins.ps1"
}

#设置一个函数用于在powershell执行以/开头的命令时，自动转换为windows路径
#设置触发器
Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
	#获取当前行
	$OriLine = $null
	$Cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$OriLine,[ref]$Cursor)
	$Line = $OriLine.Trim()
	#自行首获取可执行文件路径
	$Executable = $Line.Split(" ")[0]
	$Rest = $Line.Substring($Executable.Length).Trim()
	if ($Executable.StartsWith('"')) {
		while ((-not $Executable.EndsWith('"')) -and ($Executable.Length -lt $Line.Length)) {
			$Executable = $Executable + " " + $Line.Substring($Executable.Length + 1).Split(" ")[0]
		}
		$Rest = $Line.Substring($Executable.Length).Trim()
	}
	#若当前行以/开头
	if ($Executable.StartsWith("/") -or $Executable.StartsWith("~")) {
		Write-Host ""
		[Microsoft.PowerShell.PSConsoleReadLine]::CancelLine()
		Write-Host "`b`b  "
		#则转换为windows路径
		$Executable = LinuxPathToWindowsPath $Executable
		#求值并输出
		$StartExecutionTime = Get-Date
		try { Invoke-Expression "$Executable $Rest *>&1" | Out-Default }
		catch { $Host.UI.WriteErrorLine($_) }
		$EndExecutionTime = Get-Date
		[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($OriLine)
		[PSCustomObject](@{
			CommandLine = "$Executable $Rest"
			ExecutionStatus = "Completed"
			StartExecutionTime = $StartExecutionTime
			EndExecutionTime = $EndExecutionTime
		}) | Add-History
	}
	else {
		if ($EshellUI.Im.VSCodeExtension -and ($NestedPromptLevel -eq 0)) {
			if ($Line.StartsWith("exit")) {
				#若当前行以exit开头，则退出vscode
				Invoke-Expression "global:$Line"
				return
			}
		}
		[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
	}
}
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
	#获取当前行
	$OriLine = $null
	$Cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$OriLine,[ref]$Cursor)
	$Line = $OriLine
	#自光标位置分隔出当前单词
	$BeforeCursor = $Line.Substring(0,$Cursor)
	$Rest = $Line.Substring($Cursor)
	$WordToComplete = $BeforeCursor.Split(" ")[-1]
	#处理"
	$HasQuote = $false
	if ($WordToComplete.EndsWith('"')) {
		$HasQuote = $true
		while (-not $WordToComplete.StartsWith('"')) {
			$WordToComplete = $BeforeCursor.Substring(0,$BeforeCursor.Length - $WordToComplete.Length - 1).Split(" ")[-1] + " " + $WordToComplete
		}
		$WordToComplete = $WordToComplete.Substring(1,$WordToComplete.Length - 2)
	}
	#若当前单词以/开头
	if ($WordToComplete.StartsWith("/") -or $WordToComplete.StartsWith("~")) {
		#则转换为windows路径
		$WordAfterComplete = LinuxPathToWindowsPath $WordToComplete + '/'
		if ($HasQuote) {
			$WordAfterComplete = '"' + $WordAfterComplete + '"'
		}
		$CursorOfBegin = $Cursor - $WordToComplete.Length
		$CursorOfEnd = $Cursor - $CursorOfBegin + $WordAfterComplete.Length
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($CursorOfBegin,$WordToComplete.Length,$WordAfterComplete)
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($CursorOfEnd)
		[Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete()
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$OriLine,[ref]$Cursor)
		$BeginIndex = $OriLine.IndexOf($WordAfterComplete)
		if ($BeginIndex -ne -1) {
			$CursorOfBegin = $BeginIndex
		}
		$CursorOfEnd = $OriLine.Length - $CursorOfBegin - $Rest.Length
		$WordToComplete = $OriLine.Substring($CursorOfBegin,$CursorOfEnd)
		$WordAfterComplete = WindowsPathToLinuxPath $WordToComplete
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($CursorOfBegin,$CursorOfEnd,$WordAfterComplete)
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($CursorOfBegin + $WordAfterComplete.Length)
	}
	else {
		#否则调用默认的补全
		[Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete()
	}
}
