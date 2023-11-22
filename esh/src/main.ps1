. $PSScriptRoot/scripts/ValueEx.ps1

$EshellUI ??= $LastExitCode = $this = 72 #Do not remove this line
$EshellUI = ValueEx @{
	State = @{
		Started = $false
		VariablesLoaded = $false
	}
	Sources = @{
		Path = Split-Path $PSScriptRoot
	}
	Im = @{
		Sudo = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]“Administrator”)
		VSCodeExtension = [bool]($psEditor)
		WindowsPowerShell = (Split-Path $(Split-Path $PROFILE) -Leaf) -eq 'WindowsPowerShell'
		ISE = [bool]($psISE)
		FirstLoading = $EshellUI -eq $LastExitCode
		InScope = $EshellUI -ne $global:EshellUI
	}
	'method:GetFromOf' = {
		param($Invocation)
		$FromProfile = ($Invocation.CommandOrigin -eq 'Internal') -and (-not $Invocation.PSScriptRoot)
		$FromOtherScript = ($Invocation.CommandOrigin -eq 'Internal') -and ($Invocation.PSScriptRoot)
		$MayFromCommand = ($Invocation.CommandOrigin -eq 'Runspace') -and (-not $Invocation.PSScriptRoot)
		$FromFileExplorer = $MayFromCommand -and ($Invocation.HistoryId -eq 1)
		$FromCommand = $MayFromCommand -and (-not $FromFileExplorer)
		return @{
			Profile = $FromProfile
			OtherScript = $FromOtherScript
			Command = $FromCommand
			FileExplorer = $FromFileExplorer
		}
	}
	'method:Init' = {
		param($Invocation)
		$this.Im.From = $this.GetFromOf($Invocation)
		$this.Invocation = $Invocation
	}

	MSYS = @{
		RootPath = 'C:\msys64'
	}
	BackgroundLoadingJobs = ValueEx @{
		__type__ = [System.Collections.ArrayList]
		'method:Pop' = {
			$job = $this[0]
			$this.RemoveAt(0)
			$job
		}
		'method:PopAndRun' = {
			$job = $this.Pop()
			$OriginalPref = $ProgressPreference # Default is 'Continue'
			$ProgressPreference = 'SilentlyContinue'
			$job.Invoke()
			$ProgressPreference = $OriginalPref
		}
	}
	OtherData = @{
		ReloadSafeVariables = $EshellUI.OtherData.ReloadSafeVariables ?? @{}
	}
	'method:SaveVariables' = {
		if ($this.MSYS.RootPath) { Set-Content "$($this.Sources.Path)/data/vars/MSYSRootPath.txt" $this.MSYS.RootPath -NoNewline }
	}
	'method:LoadVariables' = {
		$this.MSYS.RootPath = Get-Content "$($this.Sources.Path)/data/vars/MSYSRootPath.txt" -ErrorAction Ignore
		$this.State.VariablesLoaded = $true
	}
	'method:Start' = {
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
		Register-EngineEvent PowerShell.Exiting -Action {
			$EshellUI.SaveVariables()
		} | Out-Null
		#注册事件以在空闲时执行后台任务
		Register-EngineEvent PowerShell.OnIdle -Action {
			if ($EshellUI.BackgroundLoadingJobs.Count) {
				$EshellUI.BackgroundLoadingJobs.PopAndRun()
			}
		} | Out-Null

		. $PSScriptRoot/system/base.ps1

		. $PSScriptRoot/system/UI/loading.ps1
		. $PSScriptRoot/system/UI/title.ps1
		. $PSScriptRoot/system/UI/icon.ps1

		. $PSScriptRoot/system/CodePageFixer.ps1
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
		. "$($this.Sources.Path)/main.ps1"
		$EshellUI.LoadVariables()
		$EshellUI.Start()
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
		$this.SaveVariables()
		$function:prompt = $this.OtherData.BeforeEshLoaded.promptBackup
		Unregister-Event PowerShell.OnIdle
		Unregister-Event PowerShell.Exiting
		$this.ProvidedFunctions() | ForEach-Object {
			Remove-Item function:\$($_.Name)
		}
		$this.ProvidedVariables() | ForEach-Object {
			Remove-Item variable:\$($_.Name)
		}
		$this.ProvidedAliases() | ForEach-Object {
			Remove-Item alias:\$($_.Name)
		}
		Remove-PSReadLineKeyHandler Tab
		Set-PSReadLineKeyHandler Tab $this.OtherData.BeforeEshLoaded.TabHandler
		Remove-PSReadLineKeyHandler Enter
		Set-PSReadLineKeyHandler Enter $this.OtherData.BeforeEshLoaded.EnterHandler
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
				[System.Management.Automation.CmdletInfo]::new('Esh-Repl',[System.Management.Automation.PSCmdLet]),
				[System.Management.Automation.Language.ScriptExtent]::new(
					[System.Management.Automation.Language.ScriptPosition]::new('esh',$HistoryId,1,$expr),
					[System.Management.Automation.Language.ScriptPosition]::new('esh',$HistoryId,$expr.Length,$expr)
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
		try{
			if (-not $this.State.Started) {
				$this.Init($Invocation)
				$this.LoadVariables()
				$this.Start()
			}
			$global:EshellUI ??= $this
			if ($this.GetFromOf($Invocation).FileExplorer) {
				# 该代码由用户点击脚本执行 我们需要启动repl而不是退出
				Write-Warning 'Running esh in self-hosted REPL mode.'
				$this.Repl($true)
			}
		}
		catch {
			$EshellUI.Remove()
			throw $_
		}
	}
}
