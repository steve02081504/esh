$EshellUI.Prompt = ValueEx @{
	Parent = $EshellUI
	Builders = @{}
	BuildMethods = ValueEx @{
		'method:NewlineCheck' = {
			param(
				[Parameter(Mandatory = $true)]
				[string]$prompt_str
			)
			$LastLineIndex = [Math]::Max($prompt_str.LastIndexOf('`n'),0)
			$LastLine = $prompt_str.Substring($LastLineIndex)
			#如果$prompt_str最后一行长度大于$Host.UI.RawUI.WindowSize.Width/2则换行
			if ($LastLine.Length -gt ($Host.UI.RawUI.WindowSize.Width / 2)) {
				$prompt_str += "`n"
			}
			return $prompt_str
		}
		'method:AddBlock' = {
			param($prompt_str,$block_str)
			$LastLineIndex = [Math]::Max($prompt_str.LastIndexOf('`n'),0)
			$LastLine = $prompt_str.Substring($LastLineIndex)
			#如果$LastLine + $block_str长度大于$Host.UI.RawUI.WindowSize.Width则换行
			if (($LastLine + $block_str).Length -gt $Host.UI.RawUI.WindowSize.Width) {
				$prompt_str += "`n"
			}
			return $prompt_str + $block_str
		}
	}
	'method:Get' = {
		$local:EshellUI = $this.Parent
		$prompt_str = $PWD.Path
		if (($prompt_str.StartsWith($HOME)) -or ($prompt_str.StartsWith($EshellUI.MSYS.RootPath))) {
			$prompt_str = WindowsPathToLinuxPath $prompt_str
		}

		$this.Builders.Keys | ForEach-Object {
			$prompt_str = $this.Builders[$_].Invoke($prompt_str, $this.BuildMethods)
		}
		$prompt_str = $this.BuildMethods.NewlineCheck("$prompt_str $($VirtualTerminal.Colors.Reset)")
		$prompt_str += '>' * ($NestedPromptLevel+1)
		return $prompt_str
	}
}
#遍历脚本所在文件夹
Get-ChildItem $PSScriptRoot/builders *.ps1 | ForEach-Object { . $_.FullName }

function global:prompt { $EshellUI.Prompt.Get() }
