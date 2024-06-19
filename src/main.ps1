. $PSScriptRoot/scripts/ValueEx.ps1

$EshellUI ??= 72 #Do not remove this line
$script:MyProcess = Get-Process -ID $PID
$EshellUI = ValueEx @{
	State = @{
		Started = $false
		VariablesLoaded = $false
	}
	Sources = @{
		Path = Split-Path $PSScriptRoot
	}
	Im = ValueEx @{
		Sudo = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
		VSCodeExtension = [bool]($psEditor) -and ($Host.Name -eq 'Visual Studio Code Host')
		Editor = [bool]($psEditor)
		WindowsPowerShell = (Split-Path $(Split-Path $PROFILE) -Leaf) -eq 'WindowsPowerShell'
		ISE = [bool]($psISE)
		FirstLoading = $EshellUI -eq $LastExitCode
		WindowsTerminal = [bool]$env:WT_SESSION
		InScope = $EshellUI -ne $global:EshellUI
		"method:InEnvPath" = {
			param($Path = $env:Path)
			$result = $false
			$Path.Split(";") | ForEach-Object {
				if ($_ -match "$([regex]::Escape($this.Sources.Path))[\\/]path*") {
					$result = $true
				}
			}
			$result
		}
	}
	'method:GetMyFrom' = {
		param($Invocation)
		$FromProfile = ($Invocation.CommandOrigin -eq 'Internal') -and (-not $Invocation.PSScriptRoot)
		$FromOtherScript = ($Invocation.CommandOrigin -eq 'Internal') -and ($Invocation.PSScriptRoot)
		$MayFromCommand = ($Invocation.CommandOrigin -eq 'Runspace') -and (-not $Invocation.PSScriptRoot)
		$FromFileExplorer = $MayFromCommand -and ($Invocation.HistoryId -eq 1) -and $this.Im.StartedFrom.FileExplorer
		$FromCommand = $MayFromCommand -and (-not $FromFileExplorer)
		@{
			Profile = $FromProfile
			OtherScript = $FromOtherScript
			Command = $FromCommand
			FileExplorer = $FromFileExplorer
		}
	}
	'method:Init' = {
		param($Invocation)
		$this.Invocation = $Invocation
		$this.Process = Get-Process -ID $PID
		$this.ParentProcess = $this.Process.Parent
		$this.Im.StartedFrom = @{
			WindowsTerminal = $this.ParentProcess.Name -eq 'WindowsTerminal.exe'
			FileExplorer = $this.ParentProcess.Name -eq 'explorer.exe'
		}
		$this.Im.From = $this.GetMyFrom($Invocation)
		$this.ParentPIDS = @()
		$progress = Get-Process -ID $PID
		do {
			$this.ParentPIDS += $progress.ID
			$progressParent = $progress.Parent
			$progress.Dispose()
			$progress = $progressParent
		} while ($progress)
	}
	'method:UpdateProcess' = {
		$EshellUI.Process.Dispose()
		$EshellUI.Process = Get-Process -ID $PID
		$EshellUI.Process
	}

	LoadingLog = ValueEx @{
		__type__ = [System.Collections.ArrayList]
		ErrorLevel = & { enum ErrorLevel{
				Info
				Warning
				Error
		}; [ErrorLevel] }
		'method:AddLog' = {
			param($What, $Level)
			$this.Add([PSCustomObject]@{
				What = $What
				Level = $Level
			}) | Out-Null
		}
		'method:AddInfo' = { param($What); $this.AddLog($What, $this.ErrorLevel::Info) }
		'method:AddWarning' = { param($What); $this.AddLog($What, $this.ErrorLevel::Warning) }
		'method:AddError' = { param($What); $this.AddLog($What, $this.ErrorLevel::Error) }
		'method:Print' = {
			$this | ForEach-Object {
				$What = $_.What # 这个变量是必须的，$_在switch中会被更新为switch的参数
				switch ($_.Level) {
					$this.ErrorLevel::Info { Out-Info $What }
					$this.ErrorLevel::Warning { Out-Warning $What }
					$this.ErrorLevel::Error { Out-Error $What }
				}
			}
		}
	}

	MSYS = @{
		RootPath = 'C:\msys64'
	}
	BackgroundJobs = ValueEx @{
		__type__ = [System.Collections.ArrayList]
		'method:Pop' = {
			$job = $this[0]
			$this.RemoveAt(0)
			$job
		}
		'method:PopAndRun' = {
			$job = $this.Pop()
			$Timer = Start-Job -ScriptBlock { Start-Sleep -Seconds 3 }
			try {
				TempAssign '$ProgressPreference', SilentlyContinue '$global:LastExitCode' $job
			}
			finally {
				if ($Timer.State -ne 'Running') {
					$text = "Background job $(
							"{$($job -replace '\s*\n\s*', ';')}" -replace '{;','{' -replace ';}','}'
						) timed out."
					$EshellUI.Prompt.Refresh($text)
				}
				Stop-Job $Timer
				Remove-Job $Timer
			}
		}
		'method:Push' = {
			param($Jobs)
			$Jobs | ForEach-Object { $this.Add($_) } | Out-Null
		}
		'method:Wait' = {
			while ($this.Count) { $this.PopAndRun() }
		}
	}
	OtherData = @{
		ReloadSafeVariables = $EshellUI.OtherData.ReloadSafeVariables ?? @{}
		VariableSaveList = @{
			'MSYSRootPath' = 'MSYS.RootPath'
		}
		PartsMemoryUsage = ValueEx @{
			__type__ = [System.Collections.Specialized.OrderedDictionary]
			'#pushing_array' = [System.Collections.ArrayList]@()
			PwshBase = $script:MyProcess.WorkingSet64
			'method:BeginAdd' = {
				param ($Name)
				$this['#pushing_array'].Add($EshellUI.UpdateProcess().WorkingSet64) | Out-Null
				$this[$Name] = -1
			}
			'method:EndAdd' = {
				param ($Name)
				$this[$Name] = ($EshellUI.UpdateProcess().WorkingSet64 - $this['#pushing_array'][-1])
				$this['#pushing_array'].RemoveAt($this['#pushing_array'].Count - 1)
				for ($i = 0; $i -lt $this['#pushing_array'].Count; $i++) {
					$this['#pushing_array'][$i] += $this[$Name]
				}
			}
			'method:View' = {
				$Total = 0
				$this.GetEnumerator() | ForEach-Object {
					if ($_.Value) {
						$Total += $_.Value
						@{ $_.Key = Format-FileSize $_.Value }
					}
				}
				@{ Total = Format-FileSize $Total }
			}
		}
	}
	'method:LoadVariable' = {
		param($FileName)
		Get-Content "$($this.Sources.Path)/data/vars/$FileName.txt" -ErrorAction Ignore
	}
	'method:SaveVariable' = {
		param($Value, $FileName)
		if ((-not $Value) -or ($this.LoadVariable($FileName) -eq $Value)) { return }
		Set-Content "$($this.Sources.Path)/data/vars/$FileName.txt" $Value -NoNewline
	}
	'method:SaveVariables' = {
		$this.OtherData.VariableSaveList.GetEnumerator() | ForEach-Object {
			$Value = IndexEx $this $_.Value
			$this.SaveVariable($Value, $_.Name)
		} | Out-Null
	}
	'method:LoadVariables' = {
		$this.OtherData.VariableSaveList.GetEnumerator() | ForEach-Object {
			$Value = $this.LoadVariable($_.Name)
			if ($Value) { IndexEx $this $_.Value -Set $Value }
		} | Out-Null
		$this.State.VariablesLoaded = $true
	}
	'method:Start' = {
		param ($Arguments)
		if ($this.State.Started) {
			Write-Error 'esh is already started.'
			return
		}

		$this.OtherData.PartsMemoryUsage.BeginAdd('EshellBase')

		$LastExitCode = 72 #Do not remove this line

		$this.OtherData.PartsMemoryUsage.BeginAdd('BeforeEshLoadRecord')
		$this.OtherData.BeforeEshLoaded = @{
			FunctionList = Get-ChildItem function:\
			VariableList = Get-ChildItem variable:\
			AliasesList = Get-ChildItem alias:\
			promptBackup = $function:prompt
			Errors = $Error
			TabHandler = (Get-PSReadLineKeyHandler Tab).Function
			EnterHandler = (Get-PSReadLineKeyHandler Enter).Function
			DefaultParameterValues = $PSDefaultParameterValues
		}
		$this.OtherData.PartsMemoryUsage.EndAdd('BeforeEshLoadRecord')

		$this.OtherData.PartsMemoryUsage.BeginAdd('RegisterEvents')
		$this.RegisteredEvents = @{
			SaveVariables = @{
				ID = 'PowerShell.Exiting'
				Action = { $EshellUI.SaveVariables() }
			}
			BackgroundJobs = @{
				ID = 'PowerShell.OnIdle'
				Action = {
					if ($EshellUI.BackgroundJobs.Count) {
						$EshellUI.BackgroundJobs.PopAndRun()
					}
				}
			}
			FocusRecordUpdate = @{
				ID = 'PowerShell.OnIdle'
				Action = {
					$LastFocus = $EshellUI.OtherData.GettingFocus
					$EshellUI.OtherData.GettingFocus = $EshellUI.ParentPIDS -contains [esh.Win32]::GetForegroundProcessId()
					if ($LastFocus -ne $EshellUI.OtherData.GettingFocus) {
						$EshellUI.Prompt.Refresh()
					}
				}
			}
		}
		if ($Arguments.NoVariableSaving) {
			$this.RegisteredEvents.Remove('SaveVariables')
		}
		$this.RegisteredEvents.GetEnumerator() | ForEach-Object {
			$_ = $_.Value
			Register-EngineEvent $_.ID -SupportEvent -Action $_.Action
			$_.RawData = (Get-EventSubscriber -Force)[-1]
		}
		$this.OtherData.PartsMemoryUsage.EndAdd('RegisterEvents')

		. $PSScriptRoot/system/base.ps1

		. $PSScriptRoot/system/UI/loading.ps1
		. $PSScriptRoot/system/UI/title.ps1
		. $PSScriptRoot/system/UI/icon.ps1

		Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
		if ($this.Im.WindowsTerminal) {
			$WTPathreg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wt.exe"
			$WindowsTerminalVersion = [regex]::match((Get-ItemProperty $WTPathreg).Path, "_(.*?)_").Groups[1].Value
			$Loginfo = [System.Collections.ArrayList]@(
				"Since failed to get Windows Terminal version from the registry, use Get-AppXPackage instead, which is extremely slow.",
				"Please consider repairing the Windows Terminal installation."
			)
			if ($WindowsTerminalVersion -eq "") {
				$WindowsTerminalVersion = "$((Get-AppXPackage "Microsoft.WindowsTerminal").Version)" # super slow
				# auto fix registry, Remove it by `Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wt.exe" -Force` in root if you want retest
				$FileName = "C:\Program Files\WindowsApps\Microsoft.WindowsTerminal_${WindowsTerminalVersion}_x64__8wekyb3d8bbwe\wt.exe"
				if (Test-Path $FileName) {
					try {
						New-Item -Path $WTPathreg -Force -ErrorAction Stop | Out-Null
						New-ItemProperty -Path $WTPathreg -Name 'Path' -Value $FileName -PropertyType "String" -Force | Out-Null
						$this.LoadingLog.AddInfo("Fixed Windows Terminal registry `"$WTPathreg`"")
					}
					catch {
						$Loginfo.Insert(1, "Esh tried to fix this but failed.(See ``error`` for more info.)")
						$Loginfo[2] = $Loginfo[2].Substring(0, $Loginfo[2].Length - 1) + " or run esh as root."
						$this.LoadingLog.AddWarning($Loginfo -join "`n")
					}
				}
				else {
					$this.LoadingLog.AddWarning($Loginfo -join "`n")
				}
			}
			if ($WindowsTerminalVersion -eq "") {
				$WindowsTerminalVersion = "Unknown"
				$this.LoadingLog.AddError($Loginfo -join "`n")
			}
			$this.OtherData.WindowsTerminalVersion = $WindowsTerminalVersion
		}

		$this.OtherData.PartsMemoryUsage.BeginAdd('autovars')
		. $PSScriptRoot/system/autovars.ps1
		$this.OtherData.PartsMemoryUsage.EndAdd('autovars')

		$this.OtherData.PartsMemoryUsage.BeginAdd('linux')
		. $PSScriptRoot/system/linux.ps1
		if (Test-Command bash) {
			$global:BASH_VERSION = bash -c 'echo "${BASH_VERSION}"'
		}
		$this.OtherData.PartsMemoryUsage.EndAdd('linux')

		$this.OtherData.PartsMemoryUsage.BeginAdd('cmd')
		. $PSScriptRoot/system/cmd.ps1
		$this.OtherData.PartsMemoryUsage.EndAdd('cmd')

		$this.OtherData.PartsMemoryUsage.BeginAdd('Prompt')
		. $PSScriptRoot/system/UI/prompt/main.ps1
		. $PSScriptRoot/system/steam.ps1
		$this.OtherData.PartsMemoryUsage.EndAdd('Prompt')

		$this.OtherData.PartsMemoryUsage.BeginAdd('BackgroundLoadings')
		. $PSScriptRoot/system/BackgroundLoading.ps1
		if (-not $Arguments.NoProfile) {
			$this.BackgroundJobs.Push({
				if (Test-Path "$($EshellUI.Sources.Path)/data/profile.ps1") {
					. "$($EshellUI.Sources.Path)/data/profile.ps1"
				}
				if (Test-Path ~/.esh_rc.ps1) {
					. ~/.esh_rc.ps1
				}
			})
		}
		if ($Arguments.NoBackgroundLoading) {
			$this.BackgroundJobs.Wait()
		}
		$this.OtherData.PartsMemoryUsage.EndAdd('BackgroundLoadings')

		$this.OtherData.PartsMemoryUsage.BeginAdd('CommandNotFoundHandler')
		$this.OtherData.BeforeEshLoaded.CommandNotFoundHandler = $ExecutionContext.InvokeCommand.CommandNotFoundAction
		$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
			param($Name, $EventArgs)
			if ($Name.StartsWith('get-')) { return }
			$EventArgs.Command = Get-Command null -ErrorAction Ignore
			if (Test-Command thefuck) {
				$env:PYTHONIOENCODING = 'utf-8'
				if ($EshellUI.CommandNotFound.HinttingText) {
					Write-Host $EshellUI.CommandNotFound.HinttingText
				}
				$Command = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()[-1].CommandLine
				$result = thefuck $Command
				$result = if (!$LastExitCode) {
					Get-Command $result -ErrorAction Ignore
				} else { $null }
			}
			if ($result) {
				$EventArgs.Command = $result[0]
			}
			elseif ($EshellUI.CommandNotFound.HinttingFailedText) {
				Write-Host $EshellUI.CommandNotFound.HinttingFailedText
			}
			$EventArgs.StopSearch = $true
		}
		Invoke-Expression "function global:Get-Command {$(Get-Call-Signature Get-Command);Get-Command-Fixed @PSBoundParameters}"
		$this.OtherData.PartsMemoryUsage.EndAdd('CommandNotFoundHandler')

		$this.OtherData.PartsMemoryUsage.BeginAdd('Commands')
		Get-ChildItem "$PSScriptRoot/commands" *.ps1 | ForEach-Object { . $_.FullName }
		$this.OtherData.PartsMemoryUsage.EndAdd('Commands')

		$this.OtherData.PartsMemoryUsage.BeginAdd('Fixers')
		Get-ChildItem "$PSScriptRoot/Fixers" *.ps1 | ForEach-Object { . $_.FullName }
		$this.OtherData.PartsMemoryUsage.EndAdd('Fixers')

		. $PSScriptRoot/system/UI/loaded.ps1 -Arguments $Arguments


		$this.OtherData.PartsMemoryUsage.BeginAdd('AfterEshLoadRecord')
		$this.State.Started = $true
		$this.OtherData.AfterEshLoaded = @{
			FunctionList = Get-ChildItem function:\
			VariableList = Get-ChildItem variable:\
			AliasesList = Get-ChildItem alias:\
			Errors = $Error
		}
		$this.OtherData.PartsMemoryUsage.EndAdd('AfterEshLoadRecord')

		$this.OtherData.PartsMemoryUsage.BeginAdd('FocusRecord')
		$this.OtherData.GettingFocus = $EshellUI.ParentPIDS -contains [esh.Win32]::GetForegroundProcessId()
		$this.OtherData.PartsMemoryUsage.EndAdd('FocusRecord')

		$this.OtherData.PartsMemoryUsage.EndAdd('EshellBase')
	}
	'method:Reload' = {
		$this.SaveVariables()
		$this.Remove()
		. "$($this.Sources.Path)/src/main.ps1"
		$EshellUI.Init($this.Invocation)
		$EshellUI.LoadVariables()
		$EshellUI.Start()
	}
	'method:RunInstall' = {
		$eshDir = $this.Sources.Path
		$eshDirFromEnv = $this.Im.InEnvPath()
		. $PSScriptRoot/opt/install.ps1
	}
	'method:RunUnInstall' = {
		$eshDir = $this.Sources.Path
		$eshDirFromEnv = $this.Im.InEnvPath()
		. $PSScriptRoot/opt/uninstall.ps1
	}
	'method:ProvidedFunctions' = {
		$this.OtherData.AfterEshLoaded.FunctionList | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.FunctionList.Name -notcontains $_.Name) { $_ }
		}
	}
	'method:ProvidedVariables' = {
		$this.OtherData.AfterEshLoaded.VariableList | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.VariableList.Name -notcontains $_.Name) { $_ }
		}
	}
	'method:ProvidedAliases' = {
		$this.OtherData.AfterEshLoaded.AliasesList | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.AliasesList.Name -notcontains $_.Name) { $_ }
		}
	}
	'method:Remove' = {
		if (-not $this.State.Started) {
			Write-Error 'esh is not started.'
			return
		}
		$this.SaveVariables()
		$function:prompt = $this.OtherData.BeforeEshLoaded.promptBackup
		$this.RegisteredEvents.GetEnumerator() | Where-Object { $_.Value.RawData } | ForEach-Object {
			Unregister-Event -SubscriptionId $_.Value.RawData.SubscriptionId -Force
		}
		$this.ProvidedFunctions() | ForEach-Object { Remove-Item function:\$($_.Name) }
		$this.ProvidedVariables() | ForEach-Object { Remove-Item variable:\$($_.Name) }
		$this.ProvidedAliases() | ForEach-Object { Remove-Item alias:\$($_.Name) }
		Remove-PSReadLineKeyHandler Tab
		Set-PSReadLineKeyHandler Tab $this.OtherData.BeforeEshLoaded.TabHandler
		Remove-PSReadLineKeyHandler Enter
		Set-PSReadLineKeyHandler Enter $this.OtherData.BeforeEshLoaded.EnterHandler
		$PSDefaultParameterValues = $this.OtherData.BeforeEshLoaded.DefaultParameterValues
		$ExecutionContext.InvokeCommand.CommandNotFoundAction = $this.OtherData.BeforeEshLoaded.CommandNotFoundHandler
		$this.State.Started = $false
	}
	'method:AcceptLine' = {
		param($Expr)
		$OriLine = $global:expr_now
		[Microsoft.PowerShell.PSConsoleReadLine]::CancelLine()
		Write-Host "`b`b  "
		do {
			try {
				$StartExecutionTime = Get-Date
				$(if ($Expr) {
					Invoke-Expression $Expr | Out-Default
				} else { $global:ans }) *>&1 | Out-Host
				$EndExecutionTime = Get-Date
			}
			catch {
				if ($_.Exception -is [System.Management.Automation.ParseException]) {
					Write-Host '?>' -NoNewline
					$Apply = Read-Host
					if ($Apply -ne '') {
						$Expr = $OriLine += "`n" + $Apply
					}
					else { $EndExecutionTime = Get-Date }
				}
				else { $EndExecutionTime = Get-Date }
				if ($EndExecutionTime) {
					$global:ans = $null
					Out-Error ($global:err = $_)
				}
			}
		} until ($EndExecutionTime -ne $null)
		[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($OriLine)
		[PSCustomObject](@{
			CommandLine = $Expr
			ExecutionStatus = "Completed"
			StartExecutionTime = $StartExecutionTime
			EndExecutionTime = $EndExecutionTime
		}) | Add-History
	}
	'method:Repl' = {
		param([switch]$NotEnterNestedPrompt = $false)
		$HistoryId = 0
		if (-not $NotEnterNestedPrompt) { $NestedPromptLevel++ }
		function DefaultPrompt { 'esh' + '>' * ($NestedPromptLevel + 1) }
		:repl while ($true) {
			Write-Host -NoNewline $($global:prompt ?? $this.Prompt.Get() ?? $(DefaultPrompt))
			$expr = PSConsoleHostReadLine
			switch ($expr.Trim()) {
				'' { continue }
				'exit' { break repl }
			}
			$HistoryId++
			$local:myInvocation = [System.Management.Automation.InvocationInfo]::Create(
				[System.Management.Automation.CmdletInfo]::new('Esh-Repl', [System.Management.Automation.PSCmdLet]),
				[System.Management.Automation.Language.ScriptExtent]::new(
					[System.Management.Automation.Language.ScriptPosition]::new('esh', $HistoryId, 1, $expr),
					[System.Management.Automation.Language.ScriptPosition]::new('esh', $HistoryId, $expr.Length, $expr)
				)
			)
			$StartExecutionTime = Get-Date
			try { Invoke-Expression $expr | Out-Default }
			catch { Out-Error $_ }
			$EndExecutionTime = Get-Date
			[PSCustomObject](@{
				CommandLine = $expr
				ExecutionStatus = 'Completed'
				StartExecutionTime = $StartExecutionTime
				EndExecutionTime = $EndExecutionTime
			}) | Add-History
		}
		if (-not $NotEnterNestedPrompt) { $NestedPromptLevel-- }
	}
	'method:RunFromScript' = {
		param($Invocation, $Arguments)
		try {
			if (-not $this.State.Started) {
				$this.Init($Invocation)
				if (-not $Arguments.NoVariableLoading) {
					$this.LoadVariables()
				}
				$this.Start($Arguments)
				$StartedInThisCall = $true
			}
			$global:EshellUI ??= $this
			if ($this.GetMyFrom($Invocation).FileExplorer) {
				# 该代码由用户点击脚本执行 我们需要启动repl而不是退出
				Write-Warning 'Running esh in self-hosted REPL mode.'
				$this.Repl($true)
			}
			elseif (-not $StartedInThisCall) {
				Write-Warning "esh is already running.`nIf you want to run a nested esh, use `n`t'`$EshellUI.Repl()'`nor`n`t'`$Host.EnterNestedPrompt()'`ninstead.`nor use 'esh' to start a new esh."
			}
		}
		catch {
			$EshellUI.Remove()
			throw $_
		}
	}
	'method:CompileExeFile' = {
		param($OutputFile = $PWD.Path)
		if (IsLinuxPath $OutputFile) {
			$OutputFile = LinuxPathToWindowsPath $OutputFile
		}
		if (Test-Path $OutputFile -PathType Container) {
			$OutputFile = Join-Path $OutputFile 'esh.exe'
		}
		if (Test-Path $OutputFile) {
			try { Remove-Item $OutputFile -Force -ErrorAction Stop }
			catch {
				Write-Error "Failed to remove $OutputFile"
				return
			}
		}
		&"$($this.Sources.Path)/runner/build.ps1" -OutputFile $OutputFile
		"Compiled to $(AutoShortPath $OutputFile) with size $((Get-Item $OutputFile).Length) bytes"
	}
}
$script:MyProcess.Dispose()
Remove-Variable MyProcess -Scope Script
