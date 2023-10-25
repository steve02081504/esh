#让我们升级cd来让它可以处理linux路径
if (Test-Path -Path Alias:cd) {
	Remove-Item -Path Alias:cd
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
		if ($arg.StartsWith("-")) {
			continue
		}
		$Path = $arg
		$RemainingArguments.RemoveAt($i)
		break
	}
	[string[]]$RemainingArguments = @($RemainingArguments)
	#若path是linux路径
	if (IsLinuxPath -Path $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath -Path $Path
	}
	#调用原始的cd..?
	#让我们根据RemainingArguments的风格来判断是调用cd.exe还是Set-Location
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		cd.exe @args
		return
	}
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Set-Location
		Set-Location -Path $Path
		return
	}
	$LinuxBinArguments = @("-l","--login","-p","--physical","-n","--no-cdpath","-P","--ignore-pwd","-@","--stack","--help","--version")
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
		#若是linux的cd.exe
		#则调用cd.exe
		$Path = WindowsPathToLinuxPath ($Path)
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path -Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath ($_)
			}
			else {
				$_
			}
		}
		$RemainingArguments = $RemainingArguments -join " "
		$RemainingArguments = $RemainingArguments.Trim()
		cd.exe $Path $RemainingArguments
	}
	else {
		#否则调用Set-Location
		Invoke-Expression "Set-Location -Path $Path $RemainingArguments"
	}
}

#让我们升级ls来让它可以处理linux路径
if (Test-Path -Path Alias:ls) {
	Remove-Item -Path Alias:ls
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
	if (IsLinuxPath -Path $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath -Path $Path
	}
	$IsLinuxBin = $false
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Get-ChildItem
		if ($Path.Length -eq 0) {
			Get-ChildItem
		}
		elseif (Test-Path -Path $Path) {
			Get-ChildItem -Path $Path
		}
		else {
			ls.exe $(WindowsPathToLinuxPath ($Path))
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
		$Path = WindowsPathToLinuxPath ($Path)
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path -Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath ($_)
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
if (Test-Path -Path Alias:rm) {
	Remove-Item -Path Alias:rm
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
	if (IsLinuxPath -Path $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath -Path $Path
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		rm.exe $RemainingArguments
		return
	}
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Remove-Item
		Remove-Item -Path $Path
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
		$Path = WindowsPathToLinuxPath ($Path)
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path -Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath ($_)
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
		Invoke-Expression "Remove-Item -Path $Path $RemainingArguments"
	}
}

#让我们升级mv来让它可以处理linux路径
if (Test-Path -Path Alias:mv) {
	Remove-Item -Path Alias:mv
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
	if (IsLinuxPath -Path $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath -Path $Path
	}
	if (IsLinuxPath -Path $Destination) {
		#则转换为windows路径
		$Destination = LinuxPathToWindowsPath -Path $Destination
	}
	$IsLinuxBin = $Path.Length -eq 0 -and $Destination.Length -eq 0
	if ($IsLinuxBin) {
		mv.exe @args
		return
	}
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Move-Item
		Move-Item -Path $Path -Destination $Destination
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
		$Path = WindowsPathToLinuxPath ($Path)
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path -Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath ($_)
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
		Invoke-Expression "Move-Item -Path $Path -Destination $Destination $RemainingArguments"
	}
}

#让我们升级cp来让它可以处理linux路径
if (Test-Path -Path Alias:cp) {
	Remove-Item -Path Alias:cp
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
	if (IsLinuxPath -Path $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath -Path $Path
	}
	if (IsLinuxPath -Path $Destination) {
		#则转换为windows路径
		$Destination = LinuxPathToWindowsPath -Path $Destination
	}
	$IsLinuxBin = $Path.Length -eq 0 -and $Destination.Length -eq 0
	if ($IsLinuxBin) {
		cp.exe @args
		return
	}
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Copy-Item
		Copy-Item -Path $Path -Destination $Destination
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
		$Path = WindowsPathToLinuxPath ($Path)
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path -Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath ($_)
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
		Invoke-Expression "Copy-Item -Path $Path -Destination $Destination $RemainingArguments"
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
	if (IsLinuxPath -Path $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath -Path $Path
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		mkdir.exe @args
		return
	}
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用New-Item
		New-Item -Path $Path -ItemType Directory
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
		$Path = WindowsPathToLinuxPath ($Path)
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path -Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath ($_)
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
		Invoke-Expression "New-Item -Path $Path -ItemType Directory $RemainingArguments"
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
	if (IsLinuxPath -Path $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath -Path $Path
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		touch.exe @args
		return
	}
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用New-Item
		New-Item -Path $Path -ItemType File
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
		$Path = WindowsPathToLinuxPath ($Path)
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path -Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath ($_)
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
		Invoke-Expression "New-Item -Path $Path -ItemType File $RemainingArguments"
	}
}

#让我们升级cat来让它可以处理linux路径
if (Test-Path -Path Alias:cat) {
	Remove-Item -Path Alias:cat
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
	if (IsLinuxPath -Path $Path) {
		#则转换为windows路径
		$Path = LinuxPathToWindowsPath -Path $Path
	}
	$IsLinuxBin = $Path.Length -eq 0
	if ($IsLinuxBin) {
		cat.exe @args
		return
	}
	if ($null -eq $RemainingArguments) {
		#若RemainingArguments是空的
		#则调用Get-Content
		Get-Content -Path $Path
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
		$Path = WindowsPathToLinuxPath ($Path)
		$RemainingArguments = $RemainingArguments | ForEach-Object {
			#若是有效的文件路径
			if (Test-Path -Path $_) {
				#则转换为linux路径
				WindowsPathToLinuxPath ($_)
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
		Invoke-Expression "Get-Content -Path $Path $RemainingArguments"
	}
}
