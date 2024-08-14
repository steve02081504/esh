function global:mklink {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$_RemainingArguments
	)
	$replaceList = @{}
	#对于每个参数
	$_RemainingArguments = $_RemainingArguments | ForEach-Object {
		#若参数长度不是2且是linux路径
		if (($_.Length -ne 2) -and (IsLinuxPath $_)) {
			#转换为windows路径
			$replaceList[$_] = LinuxPathToFullWindowsPath $_
			$replaceList[$_]
		} else { $_ }
	}
	foreach ($path in $_RemainingArguments) {
		if ($path.Length -gt 2) {
			if (!$toPath) {
				$toPath = $path
			}
			elseif (!$formPath){
				$formPath = $path
			}
		}
	}
	if (Test-Path $formPath -ErrorAction Ignore) {
		if (Test-Path $toPath -ErrorAction Ignore) {
			Remove-Item $toPath -Confirm
		}
		if (Test-Path $formPath -PathType Container -ErrorAction Ignore) {
			if ($_RemainingArguments -notcontains '/j') {
				$_RemainingArguments += '/j'
			}
		}
	}
	#调用cmd的mklink
	$result = . cmd /c mklink $_RemainingArguments
	if ($result) {
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
		[string[]]$_RemainingArguments
	)
	if ($_RemainingArguments.Length -eq 0) {
		#默认为立即关机
		shutdown.exe /s /t 0
	}
	else {
		#关机
		shutdown.exe $_RemainingArguments
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
		if ((Get-Item $_).PSIsContainer) {
			$Count = { (Get-ChildItem $_ -Force | Measure-Object).Count }
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

function global:Format-FileSize($size) {
	$size ??= $Input | Where-Object { $_ -ne $null }
	if ($size.Count -gt 1) {
		$size | ForEach-Object { Format-FileSize $_ }
		return
	}
	if ($size -lt 0) {
		return '-' + (Format-FileSize (-$size))
	}
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
		if ((Test-Path $_ -PathType Container) -and (Get-ChildItem $_ -Force | Measure-Object).Count -gt 0) {
			#以表格形式输出文件夹下的大小
			Get-ChildItem $_ -Force | ForEach-Object {
				if ($_.PSIsContainer) {
					$size = (Get-ChildItem $_ -Recurse -Force | Measure-Object -Property Length -Sum).Sum
					"{0,10} {1}" -f (Format-FileSize $size), $_.Name
				}
				else {
					$size = $_.Length
					"{0,10} {1}" -f (Format-FileSize $size), $_.Name
				}
			}
		}
		#若参数是文件
		elseif (Test-Path $_) {
			#输出文件大小
			$size = (Get-Item $_).Length
			"{0,10} {1}" -f (Format-FileSize $size), $_
		}
		else {
			Write-Error "Cannot find path $_"
		}
	}
}

if (Test-Command code.cmd) {
	function global:code { code.cmd @args }
}
elseif (Test-Command code-insiders.cmd) {
	function global:code { code-insiders.cmd @args }
}

if (Test-Command npm) {
	function global:npm { npm.ps1 --no-fund @args }
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

function global:regedit {
	if (Test-Command registryFinder) {
		registryFinder $args
	}
	else {
		regedit.exe $args
	}
}

function global:explorer {
	if ($args.Count -eq 0) {
		explorer.exe .
	}
	else {
		explorer.exe $args
	}
}

function global:UntilSuccess {
	param (
		[int]$WaittingTime = 0,
		[Parameter(ValueFromRemainingArguments = $true)]
		$args
	)
	$LastExitCode = 0
	$sb = [scriptblock]::Create($args)
	do {
		& $sb
		if ($LastExitCode -ne 0) {
			Start-Sleep $WaittingTime
		}
	}while ($LastExitCode)
}
Set-Alias 'until-success' 'UntilSuccess' -Scope global
Set-Alias 'us' 'UntilSuccess' -Scope global

function global:halt {
	taskkill /f /im explorer.exe *> $null
	Start-Process explorer.exe
}

function global:clswl {
	Clear-Host
	$EshellUI.Logo.Print()
}

function global:disconnect {
	Write-Error "$($VirtualTerminal.Colors.Red)You can't disconnect from your own machine, do you mean $($VirtualTerminal.Colors.Yellow)power $($VirtualTerminal.Colors.Default)off $($VirtualTerminal.Colors.Red)or $($VirtualTerminal.Colors.Yellow)shutdown$($VirtualTerminal.Colors.Red)?"
}
Set-Alias dc disconnect -Scope global

function global:null {}

if ($PSGetAPIKey) {
	Invoke-Expression @"
function global:Publish-Module-Base {
	$([System.Management.Automation.ProxyCommand]::Create((Get-Command Get-Command)))
}
"@
	function global:Publish-Module {
		param(
			[Parameter(ParameterSetName = 'ModuleNameParameterSet', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
			[ValidateNotNullOrEmpty()]
			[string]${Name},

			[Parameter(ParameterSetName = 'ModulePathParameterSet', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
			[ValidateNotNullOrEmpty()]
			[string]${Path},

			[Parameter(ParameterSetName = 'ModuleNameParameterSet')]
			[ValidateNotNullOrEmpty()]
			[string]${RequiredVersion},

			[string]${NuGetApiKey}=$PSGetAPIKey,

			[ValidateNotNullOrEmpty()]
			[string]${Repository},

			[Parameter(ValueFromPipelineByPropertyName = $true)][pscredential]
			[System.Management.Automation.CredentialAttribute()]${Credential},

			[ValidateSet('2.0')]
			[version]${FormatVersion},

			[string[]]${ReleaseNotes},

			[ValidateNotNullOrEmpty()]
			[string[]]${Tags},

			[ValidateNotNullOrEmpty()]
			[uri]${LicenseUri},

			[ValidateNotNullOrEmpty()]
			[uri]${IconUri},

			[ValidateNotNullOrEmpty()]
			[uri]${ProjectUri},

			[Parameter(ParameterSetName = 'ModuleNameParameterSet')]
			[ValidateNotNullOrEmpty()]
			[string[]]${Exclude},

			[switch]${Force},

			[Parameter(ParameterSetName = 'ModuleNameParameterSet')]
			[switch]${AllowPrerelease},

			[switch]${SkipAutomaticTags}
		)
		Publish-Module-Base @PSBoundParameters
	}
}
