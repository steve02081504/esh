. $PSScriptRoot/scripts/ValueEx.ps1

$EshellUI ??= 72 #Do not remove this line
$EshellUI = ValueEx @{
	State = @{
		Started = $false
		VariablesLoaded = $false
	}
	Sources = @{
		Path = Split-Path $PSScriptRoot
	}
	Im = ValueEx @{
		Sudo = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]“Administrator”)
		VSCodeExtension = [bool]($psEditor) -and ($Host.Name -eq 'Visual Studio Code Host')
		Editor = [bool]($psEditor)
		WindowsPowerShell = (Split-Path $(Split-Path $PROFILE) -Leaf) -eq 'WindowsPowerShell'
		ISE = [bool]($psISE)
		FirstLoading = $EshellUI -eq $LastExitCode
		WindowsTerminal = [bool]$env:WT_SESSION
		InScope = $EshellUI -ne $global:EshellUI
		"method:InEnvPath" = {
			param($Path=$env:Path)
			$result = $false
			$Path.Split(";") | ForEach-Object {
				if ($_ -like "$([regex]::Escape($this.Sources.Path))[\\/]path*") {
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
		$this.Process = Get-CimInstance -Query "select * from Win32_Process where Handle=$PID"
		$this.ParentProcess = Get-CimInstance -Query "select * from Win32_Process where Handle=$($this.Process.ParentProcessId)"
		$this.Im.StartedFrom = @{
			WindowsTerminal = $this.ParentProcess.Name -eq 'WindowsTerminal.exe'
			FileExplorer = $this.ParentProcess.Name -eq 'explorer.exe'
		}
		$this.Im.From = $this.GetMyFrom($Invocation)
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
			$OriginalPref = $ProgressPreference # Default is 'Continue'
			$ProgressPreference = 'SilentlyContinue'
			$this.Pop().Invoke()
			$ProgressPreference = $OriginalPref
		}
	}
	OtherData = @{
		ReloadSafeVariables = $EshellUI.OtherData.ReloadSafeVariables ?? @{}
		VariableSaveList = @{
			'MSYSRootPath' = 'MSYS.RootPath'
		}
	}
	'method:LoadVariable' = {
		param($FileName)
		Get-Content "$($this.Sources.Path)/data/vars/$FileName.txt" -ErrorAction Ignore
	}
	'method:SaveVariable' = {
		param($Value,$FileName)
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
		if ($this.State.Started) {
			Write-Error 'esh is already started.'
			return
		}
		$LastExitCode = 72 #Do not remove this line
		$this.OtherData.BeforeEshLoaded = @{
			FunctionList = Get-ChildItem function:\
			VariableList = Get-ChildItem variable:\
			AliasesList = Get-ChildItem alias:\
			promptBackup = $function:prompt
			Errors = $Error
			TabHandler = (Get-PSReadLineKeyHandler Tab).Function
			EnterHandler = (Get-PSReadLineKeyHandler Enter).Function
		}
		#注册事件以在退出时保存数据
		Register-EngineEvent PowerShell.Exiting -SupportEvent -Action {
			$EshellUI.SaveVariables()
		}
		#注册事件以在空闲时执行后台任务
		Register-EngineEvent PowerShell.OnIdle -SupportEvent -Action {
			if ($EshellUI.BackgroundJobs.Count) {
				$EshellUI.BackgroundJobs.PopAndRun()
			}
		}
		$EventList = Get-EventSubscriber -Force
		$this.OtherData.ExitingEvent = $EventList[$EventList.Count-2]
		$this.OtherData.IdleEvent = $EventList[$EventList.Count-1]
		Remove-Variable EventList

		. $PSScriptRoot/system/base.ps1

		. $PSScriptRoot/system/UI/loading.ps1
		. $PSScriptRoot/system/UI/title.ps1
		. $PSScriptRoot/system/UI/icon.ps1

		. $PSScriptRoot/system/Fixer.ps1
		. $PSScriptRoot/system/linux.ps1

		. $PSScriptRoot/system/UI/prompt/main.ps1

		. $PSScriptRoot/system/BackgroundLoading.ps1

		Get-ChildItem "$PSScriptRoot/commands" *.ps1 | ForEach-Object { . $_.FullName }

		. $PSScriptRoot/system/UI/loaded.ps1

		$this.State.Started = $true
		$this.OtherData.AfterEshLoaded = @{
			FunctionList = Get-ChildItem function:\
			VariableList = Get-ChildItem variable:\
			AliasesList = Get-ChildItem alias:\
			Errors = $Error
		}
	}
	'method:Reload' = {
		$this.SaveVariables()
		$this.Remove()
		. "$($this.Sources.Path)/src/main.ps1"
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
		Unregister-Event -SubscriptionId $($this.OtherData.ExitingEvent.SubscriptionId ?? 0) -Force
		Unregister-Event -SubscriptionId $($this.OtherData.IdleEvent.SubscriptionId ?? 0) -Force
		$this.ProvidedFunctions() | ForEach-Object { Remove-Item function:\$($_.Name) }
		$this.ProvidedVariables() | ForEach-Object { Remove-Item variable:\$($_.Name) }
		$this.ProvidedAliases() | ForEach-Object { Remove-Item alias:\$($_.Name) }
		Remove-PSReadLineKeyHandler Tab
		Set-PSReadLineKeyHandler Tab $this.OtherData.BeforeEshLoaded.TabHandler
		Remove-PSReadLineKeyHandler Enter
		Set-PSReadLineKeyHandler Enter $this.OtherData.BeforeEshLoaded.EnterHandler
		$this.State.Started = $false
	}
	'method:Repl' = {
		param([switch]$NotEnterNestedPrompt = $false)
		$HistoryId = 0
		if (-not $NotEnterNestedPrompt) { $NestedPromptLevel++ }
		function DefaultPrompt { 'esh' + '>' * ($NestedPromptLevel+1) }
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
			catch { $Host.UI.WriteErrorLine($_) }
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
		param($Invocation)
		try {
			if (-not $this.State.Started) {
				$this.Init($Invocation)
				$this.LoadVariables()
				$this.Start()
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
}
