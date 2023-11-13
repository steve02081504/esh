. $PSScriptRoot/scripts/ValueEx.ps1

$EshellUI ??= $LastExitCode = $this = 72 #Do not remove this line
$EshellUI = ValueEx @{
	Sources = @{
		Path = Split-Path -Parent $PSScriptRoot
	}
	Im = @{
		Sudo = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]“Administrator”)
		VSCodeExtension = $null -ne $psEditor
	}

	MSYS = @{
		RootPath = 'C:\msys64'
	}
	BackgroundLoadingJobs = @{
		__value_type__ = [System.Collections.ArrayList]
		"method:Pop" = {
			$job = $this[0]
			$this.RemoveAt(0)
			$job
		}
		"method:PopAndRun" = {
			$job = $this.Pop()
			$OriginalPref = $ProgressPreference # Default is 'Continue'
			$ProgressPreference = "SilentlyContinue"
			$job.Invoke()
			$ProgressPreference = $OriginalPref
		}
	}
	OtherData = @{
		BeforeEshLoaded = @{
			FunctionList = Get-ChildItem function:\
			VariableList = Get-ChildItem variable:\
			AliasesList = Get-ChildItem alias:\
			promptBackup = $function:prompt
		}
		ReloadSafeVariables = $EshellUI.OtherData.ReloadSafeVariables ?? @{}
	}
	"method:SaveVariables" = {
		if ($this.MSYS.RootPath) { Set-Content "$($this.Sources.Path)/data/vars/MSYSRootPath.txt" $this.MSYS.RootPath }
	}
	"method:LoadVariables" = {
		$this.MSYS.RootPath = Get-Content "$($this.Sources.Path)/data/vars/MSYSRootPath.txt" -ErrorAction Ignore
	}
	"method:Start" = {
		$this.OtherData.BeforeEshLoaded.promptBackup = $function:prompt
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
		. $PSScriptRoot/scripts/VirtualTerminal.ps1

		. $PSScriptRoot/system/UI/loading.ps1
		. $PSScriptRoot/system/UI/title.ps1
		. $PSScriptRoot/system/UI/icon.ps1

		. $PSScriptRoot/system/CodePageFixer.ps1
		. $PSScriptRoot/system/linux.ps1

		. $PSScriptRoot/system/UI/prompt/main.ps1

		#一些耗时的后台任务
		. $PSScriptRoot/system/BackgroundLoading.ps1

		# 对于$PSScriptRoot/commands/others下的所有脚本，若其文件名为*.ps1，则加载之
		Get-ChildItem "$PSScriptRoot/commands/others" | ForEach-Object {
			if ($_.Extension -eq ".ps1") {
				.$_.FullName
			}
		}

		. $PSScriptRoot/system/UI/loaded.ps1
	}
	"method:Reload" = {
		$this.SaveVariables()
		$this.Remove()
		. "$($this.Sources.Path)/main.ps1"
		$EshellUI.LoadVariables()
		$EshellUI.Start()
	}
	"method:FormatSelf" = {
		. $PSScriptRoot/scripts/formatter.ps1
		Format-Code $this.Sources.Path
	}
	"method:ProvidedFunctions" = {
		$FunctionListNow = Get-ChildItem function:\
		$FunctionListNow | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.FunctionList.Name -notcontains $_.Name) { $_ }
		}
	}
	"method:ProvidedVariables" = {
		$VariableListNow = Get-ChildItem variable:\
		$VariableListNow | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.VariableList.Name -notcontains $_.Name) { $_ }
		}
	}
	"method:ProvidedAliases" = {
		$AliasesListNow = Get-ChildItem alias:\
		$AliasesListNow | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.AliasesList.Name -notcontains $_.Name) { $_ }
		}
	}
	"method:Remove" = {
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
	}
}
