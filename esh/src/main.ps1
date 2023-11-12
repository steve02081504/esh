$LastExitCode = $this = $EshellUI = 72 #Do not remove this line
$EshellUI = @{
	Sources = @{
		Path = Split-Path -Parent -Path $PSScriptRoot
	}
	Im = @{
		Sudo = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]“Administrator”)
		VSCodeExtension = $null -ne $psEditor
	}

	MSYS = @{
		RootPath = 'C:\msys64'
	}
	OtherData = @{
		BeforeEshLoaded = @{
			FunctionList = Get-ChildItem function:\
			VariableList = Get-ChildItem variable:\
			AliasesList = Get-ChildItem alias:\
			promptBackup = $function:prompt
		}
	}
	BackgroundLoadingJobs = [System.Collections.ArrayList]@()
}; @{
	SaveVariables = {
		if ($this.MSYS.RootPath) { Set-Content "$($this.Sources.Path)/data/vars/MSYSRootPath.txt" $this.MSYS.RootPath }
	}
	LoadVariables = {
		$this.MSYS.RootPath = Get-Content "$($this.Sources.Path)/data/vars/MSYSRootPath.txt" -ErrorAction Ignore
	}
	Start = {
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
		Get-ChildItem -Path "$PSScriptRoot/commands/others" | ForEach-Object {
			if ($_.Extension -eq ".ps1") {
				.$_.FullName
			}
		}

		. $PSScriptRoot/system/UI/loaded.ps1
	}
	Reload = {
		$this.SaveVariables()
		$this.Remove()
		. "$($this.Sources.Path)/main.ps1"
		$EshellUI.LoadVariables()
		$EshellUI.Start()
	}
	FormatSelf = {
		. $PSScriptRoot/scripts/formatter.ps1
		Format-Code -Path $this.Sources.Path
	}
	ProvidedFunctions = {
		$FunctionListNow = Get-ChildItem function:\
		$FunctionListNow | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.FunctionList.Name -notcontains $_.Name) { $_ }
		}
	}
	ProvidedVariables = {
		$VariableListNow = Get-ChildItem variable:\
		$VariableListNow | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.VariableList.Name -notcontains $_.Name) { $_ }
		}
	}
	ProvidedAliases = {
		$AliasesListNow = Get-ChildItem alias:\
		$AliasesListNow | ForEach-Object {
			if ($this.OtherData.BeforeEshLoaded.AliasesList.Name -notcontains $_.Name) { $_ }
		}
	}
	Remove = {
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
}.GetEnumerator() | ForEach-Object {
	Add-Member -InputObject $EshellUI -MemberType ScriptMethod -Name $_.Key -Value $_.Value -Force
}
#注册事件以在退出时保存数据
Register-EngineEvent PowerShell.Exiting -Action {
	$EshellUI.SaveVariables()
} | Out-Null
#注册事件以在空闲时执行后台任务
Register-EngineEvent PowerShell.OnIdle -Action {
	if ($EshellUI.BackgroundLoadingJobs.Count) {
		#从$EshellUI.BackgroundLoadingJobs中取出一个任务并执行
		$job = $EshellUI.BackgroundLoadingJobs[0]
		$EshellUI.BackgroundLoadingJobs.RemoveAt(0)
		$job.Invoke()
	}
} | Out-Null
