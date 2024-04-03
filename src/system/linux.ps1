#查找$EshellUI.MSYS.RootPath是否是可用的msys路径
if (-not (Test-Path $EshellUI.MSYS.RootPath)) {
	if(Test-Command rm.exe) {
		$Path = Split-Path (Get-Command rm.exe).Source
		$EshellUI.MSYS.RootPath = $Path -replace "([\\/]usr)[\\/]?bin[\\/]?$"
	}
	Get-PSDrive -PSProvider FileSystem | ForEach-Object { $_.Name } | ForEach-Object {
		#若该盘符下存在msys路径
		$EshellUI.MSYS.RootPath ??= if (Test-Path "${_}:\msys64") { "${_}:\msys64" }
		elseif (Test-Path "${_}:\msys") { "${_}:\msys" }
	}
	if (Test-Path $EshellUI.MSYS.RootPath) {
		$EshellUI.LoadingLog.AddInfo("Now MSYS RootPath is auto set to $($VirtualTerminal.Colors.Green)$($EshellUI.MSYS.RootPath)")
		$EshellUI.SaveVariables()
	}
	else{
		$EshellUI.LoadingLog.AddWarning(
"Auto set MSYS RootPath failed.
Set it manually by $(
	$VirtualTerminal.Colors.Green
)`$EshellUI.MSYS.RootPath $($VirtualTerminal.Colors.White)= $($VirtualTerminal.Colors.Blue)'path'$(
	$VirtualTerminal.Colors[${global:Out-Performance}.Warning.Color]
) then run $(
	$VirtualTerminal.Colors.Green
)`$EshellUI.$($VirtualTerminal.Colors.Magenta)SaveVariables()$(
	$VirtualTerminal.Colors[${global:Out-Performance}.Warning.Color]
) or $(
	$VirtualTerminal.Colors.Green
)exit$(
	$VirtualTerminal.Colors[${global:Out-Performance}.Warning.Color]
) to save it.")
	}
}

if (Test-Command locale) {
	$env:LANG ??= $env:LANGUAGE ??= $env:LC_ALL ??= $(locale -uU)
}

function global:Test-PathEx($Path) {
	if (IsLinuxPath $Path) { $Path = LinuxPathToWindowsPath $Path }
	return Test-Path $Path
}

function global:IsLinuxPath([string]$Path) {
	if ($Path.StartsWith("/") -or $Path.StartsWith("~")) {
		return $true
	}
	if (($PWD.Path -eq $env:USERPROFILE) -and $Path.StartsWith(".") -and -not (Test-Path $Path)) {
		return $true
	}
	return $false
}

#一个函数以处理linux路径到windows路径的转换
function global:LinuxPathToWindowsPath([string]$Path) {
	if ($PWD.Path -eq $env:USERPROFILE){
		if($Path.StartsWith("./")) {
			$Path = "~" + $Path.Substring(1)
		}
		elseif ($Path.StartsWith(".")) {
			$Path = "~/" + $Path
		}
	}
	#若path以/（单个字母）/开头，则对应windows盘符
	if (($Path -match "^/([a-zA-Z])/") -or ($Path -match "^/([a-zA-Z])$")) {
		$DriveLetter = $Matches[1]
		return Join-Path "${DriveLetter}:" $Path.Substring(2)
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
		return Join-Path "root:\" $Path
	}
}
function global:LinuxPathToFullWindowsPath($Path) {
	# "root:\" -> $EshellUI.MSYS.RootPath
	(LinuxPathToWindowsPath $Path).Replace("root:\", $EshellUI.MSYS.RootPath)
}
function global:WindowsPathToLinuxPath([string]$Path) {
	#若path是rootpath的子目录
	if ($Path.StartsWith($EshellUI.MSYS.RootPath)) {
		#则转换为linux路径
		$Path = $Path.Substring($EshellUI.MSYS.RootPath.Length)
		if (-not $Path) { $Path = '/' }
		$Path = $Path.Replace("\", "/")
		if ($Path.StartsWith("/home/$env:UserName")) {
			$Path = "~" + $Path.Substring(("/home/$env:UserName").Length)
		}
	}
	elseif ($Path.StartsWith('root:')) {
		$Path = $Path.Substring(5)
		if (-not $Path) { $Path = '/' }
	}
	elseif ($Path.StartsWith($HOME)) {
		$Path = "~" + $Path.Substring($HOME.Length)
	}
	elseif ($Path.Length -lt 2) {}
	elseif ($Path.Substring(1, 1) -eq ":") {
		#否则根据盘符转换
		$DriveLetter = $Path.Substring(0, 1)
		$Path = $Path.Substring(3)
		$Path = "/${DriveLetter}/${Path}"
	}
	$Path = $Path.Replace("\", "/")
	# '~/AppData/\w+/X -> ~/.X
	if ($Path.StartsWith("~/AppData/")) {
		$TestPath = $Path -replace ('\~/AppData/\w+/', "~/.")
		if (Test-Path $(LinuxPathToWindowsPath $TestPath)) {
			$Path = $TestPath
		}
	}
	return $Path
}
function global:AutoShortPath($Path) {
	[regex]$matcher = "^($([regex]::Escape($HOME))|root:|$([regex]::Escape($EshellUI.MSYS.RootPath)))"
	if ($matcher.IsMatch($Path)) {
		WindowsPathToLinuxPath $Path
	}
	else {
		$Path
	}
}

if (Test-Command rm.exe) {
	. "$($EshellUI.Sources.Path)/src/commands/special/linux_bins.ps1"
}

if (Test-Path $EshellUI.MSYS.RootPath) {
	New-PSDrive -PSProvider FileSystem -Root $EshellUI.MSYS.RootPath -Name 'root' -Scope Global | Out-Null
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
	Remove-Variable LinuxPathCompleter

	#设置一个函数用于在powershell执行以/开头的命令时，自动转换为windows路径
	#设置触发器
	$EshellUI.ExecutionHandlers.Add({
		param (
			[string]$OriLine
		)
		$Expr = $Line = $OriLine.Trim()
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
			#则转换为windows路径
			$Executable = LinuxPathToWindowsPath $Executable
			$Expr = "$Executable $Rest"
			if(Test-Command $Executable) {
				return $Expr
			}
		}
	}) | Out-Null
	Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
		#获取当前行
		$OriLine = $null
		$Cursor = $null
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$OriLine, [ref]$Cursor)
		$Line = $OriLine
		#自光标位置分隔出当前单词
		$BeforeCursor = $Line.Substring(0, $Cursor)
		$Rest = $Line.Substring($Cursor)
		$WordToComplete = $BeforeCursor.Split(" ")[-1]
		#处理"
		$HasQuote = $false
		if ($WordToComplete.EndsWith('"')) {
			$HasQuote = $true
			while (-not $WordToComplete.StartsWith('"')) {
				$WordToComplete = $BeforeCursor.Substring(0, $BeforeCursor.Length - $WordToComplete.Length - 1).Split(" ")[-1] + " " + $WordToComplete
			}
			$WordToComplete = $WordToComplete.Substring(1, $WordToComplete.Length - 2)
		}
		if (IsLinuxPath $WordToComplete) {
			#则转换为windows路径
			$WordAfterComplete = LinuxPathToWindowsPath $WordToComplete + '/'
			if ($HasQuote) {
				$WordAfterComplete = '"' + $WordAfterComplete + '"'
			}
			$CursorOfBegin = $Cursor - $WordToComplete.Length
			$CursorOfEnd = $Cursor - $CursorOfBegin + $WordAfterComplete.Length
			[Microsoft.PowerShell.PSConsoleReadLine]::Replace($CursorOfBegin, $WordToComplete.Length, $WordAfterComplete)
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($CursorOfEnd)
			[Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete()
			[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$OriLine, [ref]$Cursor)
			$BeginIndex = $OriLine.IndexOf($WordAfterComplete)
			if ($BeginIndex -ne -1) {
				$CursorOfBegin = $BeginIndex
			}
			$CursorOfEnd = $OriLine.Length - $CursorOfBegin - $Rest.Length
			$WordToComplete = $OriLine.Substring($CursorOfBegin, $CursorOfEnd)
			$WordAfterComplete = WindowsPathToLinuxPath $WordToComplete
			[Microsoft.PowerShell.PSConsoleReadLine]::Replace($CursorOfBegin, $CursorOfEnd, $WordAfterComplete)
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($CursorOfBegin + $WordAfterComplete.Length)
		}
		else {
			#否则调用默认的补全
			[Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete()
		}
	}
}
