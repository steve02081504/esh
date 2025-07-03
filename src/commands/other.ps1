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
	begin {
		if ($args.Length -eq 0) {
			#默认为立即关机
			shutdown.exe /s /t 0
		}
		else {
			$pipe = { shutdown.exe $args }.GetSteppablePipeline($MyInvocation.CommandOrigin, $args)
			$pipe.Begin($MyInvocation.ExpectingInput, $ExecutionContext)
		}
	}
	process { if ($args.Length) { $pipe.Process($_) } }
	end { if ($args.Length) { $pipe.End() } }
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
		$paths
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
		elseif ($_ -is [System.Management.Automation.CommandInfo]) {
			$Path = if (Test-Path $_.Source) { $_.Source }
			elseif (Test-Path $_.Definition) { $_.Definition }
			elseif ($_.Source) {
				$module = Get-Module $_.Source
				if ($module) { $module.ModuleBase }
			}
			$Path
		}
		elseif (Test-Path $_) {
			$_
		}
		elseif (Test-Command $_) {
			(Get-Command $_).Source
		}
	}
	#对于每个参数
	$paths | ForEach-Object {
		#若参数是文件夹
		if ((Test-Path $_ -PathType Container) -and (Get-ChildItem $_ -Force | Measure-Object).Count -gt 0) {
			$size = (Get-ChildItem $_ -Recurse -Force | Measure-Object -Property Length -Sum).Sum
			"{0,10} {1}" -f (Format-FileSize $size), $(AutoShortPath $_)
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
		# 若参数是命令
		if (`$_ -is [System.Management.Automation.CommandInfo]) {
			`$_.Source
		}
		# 若是ErrorRecord
		elseif (`$_ -is [System.Management.Automation.ErrorRecord]) {
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
	function global:npm {
		begin {
			$pipe = { npm.ps1 --no-fund @args }.GetSteppablePipeline($MyInvocation.CommandOrigin, $args)
			$pipe.Begin($MyInvocation.ExpectingInput, $ExecutionContext)
		}
		process { $pipe.Process($_) }
		end { $pipe.End() }
	}
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
		$args = $args | ForEach-Object {
			if ($_ -is [System.Management.Automation.CommandInfo]) {
				$_.Source
			}
			elseif($_ -is [System.Management.Automation.ErrorRecord]) {
				$_.InvocationInfo.ScriptName
			}
			elseif (IsLinuxPath $_) {
				LinuxPathToWindowsPath $_
			}
			else { $_ }
		}
		if ($args -is [string]) { $args = @($args) }
		explorer.exe @args
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

function global:fastfetch {
	$logo = @"
             ========================
            ==========================
           ============================
          =====+++++++++++++++++++++++
         =====++*
        ======++
        =====++:::::::::::::::::
       =====++++=::::::::::::::::
      =====++++++++++++++++++++++
     ======++
     =====++
    =====++
   ============================-::
  ============================:::::
   ====+++++++++++++++++++++++::::
    ==++++++++++++++++++++++++++:
"@ -split "`n"

	$OS = Get-WmiObject Win32_OperatingSystem
	$TotalMemoryGB = [Math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
	$FreeMemoryGB = [Math]::Round($OS.FreePhysicalMemory / 1MB, 2)
	$UsedMemoryGB = [Math]::Round(($TotalMemoryGB - $FreeMemoryGB), 2)
	$Disks = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object {
		@{
			DriveLetter = $_.DeviceID
			VolumeName = $_.VolumeName
			FreeSpaceGB = [Math]::Round($_.FreeSpace / 1GB, 2)
			SizeGB = [Math]::Round($_.Size / 1GB, 2)
			UsedSpaceGB = [Math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
			PercentFree = [Math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
		}
	}
	Add-Type -AssemblyName System.Windows.Forms
	if (!(Test-Command Show-apks)) {
		& $PSScriptRoot/special/BlueStacks.ps1
	}
	$info = [ordered]@{
		Host = $env:COMPUTERNAME
		OS = 'E.D.E.N.O.S.'
		Kernel = 'MS-DOS v2.1'
		Uptime = Get-Uptime
		Packages = @(
			@{
				Name = "pacman"
				Count = (pacman -Q | wc -l)
			},
			@{
				Name = "apk"
				Count = (Show-apks | Measure-Object | Select-Object -ExpandProperty Count)
			},
			@{
				Name = "appx"
				Count = (Get-AppxPackage | Measure-Object | Select-Object -ExpandProperty Count)
			},
			@{
				Name = "deno"
				Count = (Get-ChildItem ~/node_modules/.deno | Measure-Object | Select-Object -ExpandProperty Count)
			},
			@{
				Name = "npm"
				Count = (Get-ChildItem ~/node_modules | Measure-Object | Select-Object -ExpandProperty Count)
			}
		) | ForEach-Object { "$($_.Count)($($_.Name))" } | Join-String -Separator "; "
		Shell = "E-Shell 1960.7.17"
		Resolution = "$([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width) x $([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)"
		DE = if ($IsWindows) { [Runtime.InteropServices.RuntimeInformation]::OSDescription } else { $env:DE }
		WM = if ($IsWindows) { "DirectX $((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX").Version)" } else { $env:WM }
		'WM Theme' = if ($IsWindows) { (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\HighContrast" -Name "Pre-High Contrast Scheme")."Pre-High Contrast Scheme" | Split-Path -Leaf } else { $env:WM }
		'WM Font' = if ($IsWindows) { (Get-ItemProperty -Path "HKCU:\Console" -ErrorAction SilentlyContinue).FaceName } else { $env:WM }
		'WM Font Size' = if ($IsWindows) { (Get-ItemProperty -Path "HKCU:\Console" -ErrorAction SilentlyContinue).FontSize } else { $env:WM }
		'Terminal' = if ($IsWindows) { if ($EshellUI.Im.WindowsTerminal) { "Windows Terminal $($env:WT_VERSION)" } else { 'cmd.exe' } } else { $env:TERM }
		CPU = "$(Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty Name) @ $(Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty MaxClockSpeed)MHz"
		GPU = if ($IsWindows) { (Get-CimInstance -ClassName Win32_VideoController).Name } else { $env:GPU }
		Memory = "$($UsedMemoryGB)GB / $($TotalMemoryGB)GB"
		Disk = $Disks | ForEach-Object {
			"$($_.VolumeName)($($_.UsedSpaceGB)gb/$($_.SizeGB)gb)"
		} | Join-String -Separator "; "
		"AI Assist" = $EshellUI.FountAssist
	}

	$logoMaxLength = $logo | ForEach-Object { $_.Length } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
	$logoLength = $logoMaxLength + 3

	$index = 0
	foreach ($key in $info.Keys) {
		if (!$info[$key]) { continue }
		Write-Host $logo[$index] -ForegroundColor Magenta -NoNewline
		$SpaceNum = $logoLength - $($logo[$index].Length)
		$index += 1
		Write-Host $(' '*$SpaceNum) -NoNewline
		Write-Host '| ' -NoNewline -ForegroundColor Green
		Write-Host $key -NoNewline -ForegroundColor Red
		Write-Host ': ' -NoNewline
		Write-Host $info[$key]
	}
}

function global:hex($num){
	[System.Convert]::ToString($num, 16)
}

function global:bin($num) {
	[System.Convert]::ToString($num, 2)
}

function global:dec($num) {
	[System.Convert]::ToInt32($num, 10)
}

function global:oct($num) {
	[System.Convert]::ToString($num, 8)
}

function global:Get-Promptlized-Dir(
	$Filter,
	$Include,
	$Exclude,
	$Path = '.',
	$Recurse = $true
) {
	$str = (Get-ChildItem -Recurse:$Recurse -Path $Path -Filter $Filter -Include $Include -Exclude $Exclude -File | ForEach-Object {
		$content = (Get-Content $_) -join "`n"
		if ($content.IndexOf([byte]0) -ne -1) { return }
		$quote = '```'
		while($content.Contains($quote)) { $quote += '`' }
		"$_" + ':'
		$quote+ $(switch ($_.Extension) {
			'.ps1' { 'pwsh' }
			{$_ -in '.mjs', '.js', '.cjs'} { 'js' }
			'.ts' { 'ts' }
			'.json' { 'json' }
			'.css' { 'css' }
			'.html' { 'html' }
			'.txt' { 'text' }
			'.md' { 'md' }
			{$_ -in '.yml', '.yaml'} { 'yaml' }
			'.xml' { 'xml' }
			'.py' { 'py' }
			'.rb' { 'ruby' }
			'.pl' { 'perl' }
			'.php' { 'php' }
			'.sh' { 'bash' }
			'.cmd' { 'bat' }
			{$_ -in '.c', '.h'} { 'c' }
			{$_ -in '.cpp', '.hpp', '.cxx', '.hxx'} { 'cpp' }
			Default {''}
		})
		$content
		$quote
	}) -join "`n"
	Set-Clipboard -Value $str
}

function global:CleanUpComputer {
	if (!$EShellUI.Im.Sudo) {
		Write-Error "You must run this command as root, try sudo."
		return
	}
	Clear-UserPath
	Dism /Online /Cleanup-Image /startcomponentcleanup /resetbase
	Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction Ignore
	Remove-Item $env:LOCALAPPDATA\Temp\* -Recurse -Force -ErrorAction Ignore
	wevtutil cl System
	wevtutil cl Application
	Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
	Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction Ignore
	Start-Service -Name wuauserv -ErrorAction SilentlyContinue
	Remove-Item -Path "$env:windir\Prefetch\*" -Recurse -Force -ErrorAction Ignore
}

function global:Get-ScreenBufferAsText {
    $stringBuilder = [System.Text.StringBuilder]::new()
    $rawUI = $Host.UI.RawUI
    $captureWidth = $rawUI.BufferSize.Width
    $captureHeight = $rawUI.CursorPosition.Y
    if ($captureHeight -le 0) { return "" }
    $rectangle = [System.Management.Automation.Host.Rectangle]::new(0, 0, $captureWidth, $captureHeight)
    $buffer = $rawUI.GetBufferContents($rectangle)
    for ($y = 0; $y -lt $captureHeight; $y++) {
        $lineContent = ""
        for ($x = 0; $x -lt $captureWidth; $x++) {
            $lineContent += $buffer[$y, $x].Character
        }
        $stringBuilder.AppendLine($lineContent.TrimEnd()) | Out-Null
    }
    return $stringBuilder.ToString().TrimEnd() -replace "`0", ""
}
