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
		}
		else { $_ }
	}
	foreach ($path in $_RemainingArguments) {
		if ($path.Length -gt 2) {
			if (!$toPath) {
				$toPath = $path
			}
			elseif (!$formPath) {
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
		}
		else { $_ }
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
					"{0,10} {1}" -f (Format-FileSize $size), $(AutoShortPath $_)
				}
				else {
					$size = $_.Length
					"{0,10} {1}" -f (Format-FileSize $size), $(AutoShortPath $_)
				}
			}
		}
		#若参数是文件
		elseif (Test-Path $_) {
			#输出文件大小
			$size = (Get-Item $_).Length
			"{0,10} {1}" -f (Format-FileSize $size), $(AutoShortPath $_)
		}
		else {
			Write-Error "Cannot find path $_"
		}
	}
}

function geneEditorWapper {
	param (
		[Parameter(Mandatory = $true)]
		[string]$EditorName,
		[Parameter(Mandatory = $true)]
		[string]$BaseCommand
	)
	Invoke-Expression @"
function global:$EditorName {
	# 对于所有参数
	`$args = `$args | ForEach-Object {
		# 若是ErrorRecord
		if (`$_ -is [System.Management.Automation.ErrorRecord]) {
			`$_.InvocationInfo.ScriptName
		}
		# 若参数是linux路径
		elseif (IsLinuxPath `$_) {
			# 转换为windows路径
			LinuxPathToWindowsPath `$_
		}
		else { `$_ }
	}
	if (`$args -is [string]) { `$args = @(`$args) }
	. $BaseCommand @args
}
"@
}
if (Test-Command cursor.cmd) {
	geneEditorWapper cursor cursor.cmd
}
elseif (Test-Command code.cmd) {
	geneEditorWapper code code.cmd
}
elseif (Test-Command code-insiders.cmd) {
	geneEditorWapper code code-insiders.cmd
}
Remove-Item Function:\geneEditorWapper -Force

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

function global:Get-RootProcess($Process) {
	while ($Process.Parent) {
		$Process = $Process.Parent
	}
	$Process
}

function global:halt([switch]$Force, [switch]$bare) {
	$Commands = if ($Force -and !$bare) {
		if (!(Get-Command Get-PSAutorun -ErrorAction Ignore)) {
			$path = $env:PSModulePath -split ';' | Select-Object -First 1
			Save-Module AutoRuns -Path $path | Out-Null
		}
		Get-PSAutorun -Logon | ForEach-Object { $_.Value }
	}
	$Process = Get-Process
	$ProcessPaths = $Process | ForEach-Object { $_.Path }
	$Commands = $Commands | Where-Object { $cmd = $_ ; $ProcessPaths | Where-Object { $cmd.IndexOf($_) -ne -1 } }
	$Process | Where-Object {
		if ($Force) {
			(Get-RootProcess $_).Id -ne $EshellUI.RootProcess.Id -and @('WindowsTerminal') -notcontains $_.ProcessName
		}
		else {
			$_.ProcessName -eq 'explorer'
		}
	} | ForEach-Object { Write-Output "Stopping $($_.ProcessName) ($($_.Id))" ; Stop-Process $_ -Force } 1> "~/halt.log"
	if (!(Get-Process | Where-Object { $_.ProcessName -eq 'explorer' })) {
		Start-Process explorer.exe
	}
	Start-Sleep -Seconds 1
	(New-Object -comObject Shell.Application).Windows() | Where-Object { $null -ne $_.FullName } | Where-Object { $_.FullName.toLower().Endswith('\explorer.exe') } | ForEach-Object { $_.Quit() }
	$Process = Get-Process
	$ProcessPaths = $Process | ForEach-Object { $_.Path }
	$Commands | Where-Object { $cmd = $_ ; $ProcessPaths | Where-Object { $cmd.IndexOf($_) -eq -1 } } | ForEach-Object { Invoke-Expression $_ }
	Remove-Item -Path ~/halt.log
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
	function global:Publish-Module-Fixed {
		[CmdletBinding(DefaultParameterSetName = 'ModulePathParameterSet', SupportsShouldProcess = $true, ConfirmImpact = 'Medium', PositionalBinding = $false, HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=398575')]
		param(
			[Parameter(ParameterSetName = 'ModuleNameParameterSet', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
			[ValidateNotNullOrEmpty()]
			[string]${Name},

			[Parameter(ParameterSetName = 'ModulePathParameterSet', ValueFromPipelineByPropertyName = $true)]
			[string]${Path},

			[Parameter(ParameterSetName = 'ModuleNameParameterSet')]
			[ValidateNotNullOrEmpty()]
			[string]${RequiredVersion},

			[string]${NuGetApiKey} = $PSGetAPIKey,

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
		begin {
			try {
				$outBuffer = $null
				if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
					$PSBoundParameters['OutBuffer'] = 1
				}
				$PSBoundParameters.NuGetApiKey = $NuGetApiKey
				if ((!$Name) -and (!$Path)) { $PSBoundParameters.Path = '.' }

				$wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Publish-Module', [System.Management.Automation.CommandTypes]::Function)
				$scriptCmd = { & $wrappedCmd @PSBoundParameters }

				$steppablePipeline = $scriptCmd.GetSteppablePipeline()
				$steppablePipeline.Begin($PSCmdlet)
			}
			catch {
				throw
			}
		}

		process {
			try {
				$steppablePipeline.Process($_)
			}
			catch {
				throw
			}
		}

		end {
			try {
				$steppablePipeline.End()
			}
			catch {
				throw
			}
		}

		clean {
			if ($null -ne $steppablePipeline) {
				$steppablePipeline.Clean()
			}
		}
		<#

		.ForwardHelpTargetName Publish-Module
		.ForwardHelpCategory Function

		#>
	}
	New-Alias -Name Publish-Module -Value Publish-Module-Fixed -Scope Global
}

while (Test-Path Alias:where) {
	Remove-Item Alias:where -Force
}
function global:where {
	$Inputs = @($Input)
	try {
		$result = $Inputs | Where-Object @args
		if ($result) { return $result }
		else { throw }
	}
	catch {
		if (!$Inputs -and (!$($args | Where-Object { $_ -isnot [string] }).Count)) {
			where.exe @args
		}
		else { throw $_ }
	}
}

function global:Set-MouseButton {
	param(
		[ValidateSet("L", "R", 'Left', 'Right', "Auto")]
		[string]$Mode = "Auto"
	)

	[bool]$Mode = if ($Mode -eq "L" -or $Mode -eq "Left") {
		1
	}
	elseif ($Mode -eq "R" -or $Mode -eq "Right") {
		0
	}
	else {
		-not [esh.Win32]::SwapMouseButton($true)
	}

	[esh.Win32]::SwapMouseButton($Mode) | Out-Null

	if ($Mode) {
		Write-Host "Mouse button mode: Left"
	}
	else {
		Write-Host "Mouse button mode: Right"
	}
}
Set-Alias smb Set-MouseButton -Scope global

function global:SystemAutoFix {
	if (!$EShellUI.Im.Sudo) {
		Write-Error "You must run this command as root, try sudo."
		return
	}
	net stop bits
	net stop wuauserv
	net stop CryptSvc
	net stop msiserver
	net stop appidsvc

	Remove-Item $env:SystemRoot\SoftwareDistribution -Force -Recurse -ErrorAction Ignore
	Remove-Item $env:SystemRoot\system32\catroot2 -Force -Recurse -ErrorAction Ignore
	# Rename-Item $env:SystemRoot\softwaredistribution softwaredistribution.old -Force
	# Rename-Item $env:SystemRoot\system32\catroot2 catroot2.old -Force

	regsvr32.exe /s atl.dll
	regsvr32.exe /s urlmon.dll
	regsvr32.exe /s mshtml.dll

	netsh winsock reset
	netsh winsock reset proxy

	rundll32.exe pnpclean.dll, RunDLL_PnpClean /DRIVERS /MAXCLEAN

	Dism /Online /Cleanup-Image /ScanHealth
	Dism /Online /Cleanup-Image /CheckHealth
	Dism /Online /Cleanup-Image /RestoreHealth
	Dism /Online /Cleanup-Image /StartComponentCleanup

	SFC /SCANNOW

	net start bits
	net start wuauserv
	net start CryptSvc
	net start msiserver
	net start appidsvc
}
