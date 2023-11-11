$EshellUI["Prompt"] = @{
	Builders = @{}
}
. $PSScriptRoot/base.ps1
. $PSScriptRoot/builders/main.ps1

Add-Member -InputObject $EshellUI.Prompt -MemberType ScriptMethod -Name Get -Value {
	$prompt_str = $PWD.Path
	if (($prompt_str.StartsWith($HOME)) -or ($prompt_str.StartsWith($EshellUI.MSYS.RootPath))) {
		$prompt_str = WindowsPathToLinuxPath $prompt_str
	}

	$EshellUI.Prompt.Builders.Keys | ForEach-Object {
		$prompt_str = $EshellUI.Prompt.Builders[$_].Invoke($prompt_str)
	}
	"$prompt_str ${VirtualTerminal.Colors.Reset}>"
}

function global:prompt { $EshellUI.Prompt.Get() }
