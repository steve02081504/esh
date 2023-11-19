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
	function baseCD ($Path,[switch]$IsFollowSymbolicLink = $true) {
		if ($Path.Length -eq 0) {
			Set-Location ~
		}
		elseif (-not $IsFollowSymbolicLink) {
			#循环分割路径，检查每一级路径是否是符号链接
			$PreviousPath = ""
			while ($Path) {
				$CurrentPath = Split-Path $Path
				$ChildPath = Split-Path $Path -Leaf
				$PreviousPath = Join-Path $PreviousPath $CurrentPath
				$Path = $ChildPath
				if (-not (Test-Path $PreviousPath)) {
					$Host.UI.WriteErrorLine("bash: cd: ${PreviousPath}: No such file or directory")
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
			$Host.UI.WriteErrorLine("bash: cd: ${Path}: No such file or directory")
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
		$LinuxBinArguments = @("-L","-P","-e","-@","--help","--version")
		$RemainingArguments | ForEach-Object {
			$arg = $_
			$LinuxBinArguments | ForEach-Object {
				if ($_.Length -eq 2) {
					if ($arg.StartsWith($_)) {
						$IsLinuxBin = $true
					}
				}
				else {
					if ($arg -eq $_) {
						$IsLinuxBin = $true
					}
				}
			}
		}
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
			elseif ($arg -eq "--help") {
				@"
cd: cd [-L|[-P [-e]] [-@]] [dir]
    Change the shell working directory.

    Change the current directory to DIR.  The default DIR is the value of the
    HOME shell variable. If DIR is "-", it is converted to `$OLDPWD.

    The variable CDPATH defines the search path for the directory containing
    DIR.  Alternative directory names in CDPATH are separated by a colon (:).
    A null directory name is the same as the current directory.  If DIR begins
    with a slash (/), then CDPATH is not used.

    If the directory is not found, and the shell option ``cdable_vars' is set,
    the word is assumed to be  a variable name.  If that variable has a value,
    its value is used for DIR.

    Options:
      -L        force symbolic links to be followed: resolve symbolic
                links in DIR after processing instances of ``..'
      -P        use the physical directory structure without following
                symbolic links: resolve symbolic links in DIR before
                processing instances of ``..'
      -e        if the -P option is supplied, and the current working
                directory cannot be determined successfully, exit with
                a non-zero status
      -@        on systems that support it, present a file with extended
                attributes as a directory containing the file attributes

    The default is to follow symbolic links, as if ``-L' were specified.
    ``..' is processed by removing the immediately previous pathname component
    back to a slash or the beginning of DIR.

    Exit Status:
    Returns 0 if the directory is changed, and if `$PWD is set successfully when
    -P is used; non-zero otherwise.

"@
				return
			}
			else {
				Write-Host "bash: cd: ${arg}: invalid option`ncd: usage: cd [-L|[-P [-e]] [-@]] [dir]"
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
	#若path是linux路径
	if (IsLinuxPath $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath $Path
	}
	$IsLinuxBin = $false
	if ($null -eq $RemainingArguments) {
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
	$LinuxBinArguments = @("-a","--all","-A","--almost-all","-b","--escape","-B","--ignore-backups","-c","--time=ctime","-C","--format=vertical","-d","--directory","-D","--dired","-f","--format=across","-F","--classify","-g","--group-directories-first","-G","--no-group","-h","--human-readable","-H","--si","-i","--inode","-I","--ignore=","-k","--kibibytes","-l","--format=long","-L","--dereference","-m","--format=commas","-n","--numeric-uid-gid","-N","--literal","-o","-1","--format=single-column","-p","--indicator-style=slash","-q","--hide-control-chars","-Q","--quote-name","-r","--reverse","-R","--recursive","-s","--size","-S","--sort=size","-t","--sort=time","-T","--tabsize=COLS","-u","--time=atime","-U","--sort=atime","-v","--sort=version","-w","--width=COLS","-x","--format=across","-X","--sort=extension","-Z","--context","--help","--version")
	$RemainingArguments | ForEach-Object {
		$arg = $_
		$LinuxBinArguments | ForEach-Object {
			if ($_.Length -eq 2) {
				if ($arg.StartsWith($_)) {
					$IsLinuxBin = $true
				}
			}
			else {
				if ($arg -eq $_) {
					$IsLinuxBin = $true
				}
			}
		}
	}
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
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Remove-Item
		Remove-Item $Path
		return
	}
	$LinuxBinArguments = @("-f","--force","-i","--interactive","-I","--interactive=once","--one-file-system","--no-preserve-root","--preserve-root","-r","-R","--recursive","--help","--version")
	$RemainingArguments | ForEach-Object {
		$arg = $_
		$LinuxBinArguments | ForEach-Object {
			if ($_.Length -eq 2) {
				if ($arg.StartsWith($_)) {
					$IsLinuxBin = $true
				}
			}
			else {
				if ($arg -eq $_) {
					$IsLinuxBin = $true
				}
			}
		}
	}
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
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Move-Item
		Move-Item $Path -Destination $Destination
		return
	}
	$LinuxBinArguments = @("-b","--backup","-f","--force","-i","--interactive","-n","--no-clobber","-u","--update","-v","--verbose","--help","--version")
	$RemainingArguments | ForEach-Object {
		$arg = $_
		$LinuxBinArguments | ForEach-Object {
			if ($_.Length -eq 2) {
				if ($arg.StartsWith($_)) {
					$IsLinuxBin = $true
				}
			}
			else {
				if ($arg -eq $_) {
					$IsLinuxBin = $true
				}
			}
		}
	}
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
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Copy-Item
		Copy-Item $Path -Destination $Destination
		return
	}
	$LinuxBinArguments = @("-a","--archive","-b","--backup","-f","--force","-i","--interactive","-l","--link","-L","--dereference","-n","--no-clobber","-P","--no-dereference","-p","--preserve","-R","-r","--recursive","-s","--symbolic-link","-S","--suffix=SUFFIX","-t","--target-directory=DIRECTORY","-T","--no-target-directory","-u","--update","-v","--verbose","--help","--version")
	$RemainingArguments | ForEach-Object {
		$arg = $_
		$LinuxBinArguments | ForEach-Object {
			if ($_.Length -eq 2) {
				if ($arg.StartsWith($_)) {
					$IsLinuxBin = $true
				}
			}
			else {
				if ($arg -eq $_) {
					$IsLinuxBin = $true
				}
			}
		}
	}
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
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用New-Item
		New-Item $Path -ItemType Directory
		return
	}
	$LinuxBinArguments = @("-m","--mode=MODE","-p","--parents","-v","--verbose","--help","--version")
	$RemainingArguments | ForEach-Object {
		$arg = $_
		$LinuxBinArguments | ForEach-Object {
			if ($_.Length -eq 2) {
				if ($arg.StartsWith($_)) {
					$IsLinuxBin = $true
				}
			}
			else {
				if ($arg -eq $_) {
					$IsLinuxBin = $true
				}
			}
		}
	}
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
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用New-Item
		New-Item $Path -ItemType File
		return
	}
	$LinuxBinArguments = @("-a","--time=access","-c","--no-create","-d","--date=STRING","-f","--force","-h","--no-dereference","-m","--time=modification","-r","--reference=FILE","-t","--time=WORD","-v","--verbose","--help","--version")
	$RemainingArguments | ForEach-Object {
		$arg = $_
		$LinuxBinArguments | ForEach-Object {
			if ($_.Length -eq 2) {
				if ($arg.StartsWith($_)) {
					$IsLinuxBin = $true
				}
			}
			else {
				if ($arg -eq $_) {
					$IsLinuxBin = $true
				}
			}
		}
	}
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
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Get-Content
		Get-Content $Path
		return
	}
	$LinuxBinArguments = @("-A","--show-all","-b","--number-nonblank","-e","--show-ends","-E","--show-ends","-n","--number","-s","--squeeze-blank","-t","--show-tabs","-T","--show-tabs","-u","--unbuffered","-v","--show-nonprinting","-w","--width=COLS","--help","--version")
	$RemainingArguments | ForEach-Object {
		$arg = $_
		$LinuxBinArguments | ForEach-Object {
			if ($_.Length -eq 2) {
				if ($arg.StartsWith($_)) {
					$IsLinuxBin = $true
				}
			}
			else {
				if ($arg -eq $_) {
					$IsLinuxBin = $true
				}
			}
		}
	}
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
