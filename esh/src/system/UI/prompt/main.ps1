. "$($EshellUI.Sources.Path)/src/scripts/minmax.ps1"

$EshellUI.Prompt = ValueEx @{
	Builders = @{}
	"method:Get" = {
		$prompt_str = $PWD.Path
		if (($prompt_str.StartsWith($HOME)) -or ($prompt_str.StartsWith($EshellUI.MSYS.RootPath))) {
			$prompt_str = WindowsPathToLinuxPath $prompt_str
		}

		$EshellUI.Prompt.Builders.Keys | ForEach-Object {
			$prompt_str = $EshellUI.Prompt.Builders[$_].Invoke($prompt_str)
		}
		"$prompt_str ${VirtualTerminal.Colors.Reset}>"
	}
	"method:NewlineCheck" = {
		param(
			[Parameter(Mandatory = $true)]
			[string]$prompt_str
		)
		$LastLineIndex = Max $prompt_str.LastIndexOf('`n') 0
		$LastLine = $prompt_str.Substring($LastLineIndex)
		#如果$prompt_str最后一行长度大于$Host.UI.RawUI.WindowSize.Width/2则换行
		if ($LastLine.Length -gt ($Host.UI.RawUI.WindowSize.Width / 2)) {
			$prompt_str = "$prompt_str`n"
		}
		return $prompt_str
	}
	"method:AddBlock" = {
		param(
			[Parameter(Position = 0,Mandatory = $true)]
			$prompt_str,
			[Parameter(Position = 1,Mandatory = $true)]
			[string]$block_str
		)
		$LastLineIndex = Max $prompt_str.LastIndexOf('`n') 0
		$LastLine = $prompt_str.Substring($LastLineIndex)
		#如果$LastLine + $block_str长度大于$Host.UI.RawUI.WindowSize.Width则换行
		if (($LastLine + $block_str).Length -gt $Host.UI.RawUI.WindowSize.Width) {
			$prompt_str = "$prompt_str`n"
		}
		return $prompt_str + $block_str
	}
}
. $PSScriptRoot/builders/main.ps1

function global:prompt { $EshellUI.Prompt.Get() }
