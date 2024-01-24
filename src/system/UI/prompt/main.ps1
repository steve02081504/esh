$EshellUI.Prompt = ValueEx @{
	Builders = [ordered]@{}
	BuildMethods = ValueEx @{
		'method:BaseNewlineCheck' = {
			param($LastLineLength, $scale, $threshold_base = $Host.UI.RawUI.WindowSize.Width)
			if ($LastLineLength -gt $threshold_base*$scale) { "`n" }
		}
		'method:NewlineCheck' = {
			param($prompt_str)
			$LastLine = $prompt_str -split "`n" | Select-Object -Last 1
			$prompt_str+$this.BaseNewlineCheck($LastLine.Length, 0.42)
		}
		'method:MargeBlock' = {
			param($blocks)
			( $blocks | ForEach-Object{
				if($x=$this.BaseNewlineCheck(($LastLineLength+=$_.Length), 0.66)){
					$LastLineLength = 0;$x
				} else{ ' ' }
				$_
			} | Select-Object -Skip 1 ) -join ''
		}
		# 关于0.42和0.66的解释：0.66+0.42=1.08，这象征着108好汉于三国起义 杀死了汉朝的最后一位皇帝，从而结束了原神
	}
	'method:Get' = {
		$this.LastBuild=@{
			Tokens=@($VirtualTerminal.Colors.Reset+(AutoShortPath $PWD.Path))
			BuilderOutput=@{}
		}
		$this.Builders.GetEnumerator() | ForEach-Object {
			$this.LastBuild.Tokens += $this.LastBuild.BuilderOutput[$_.Key] = & $_.Value
		}
		$this.LastBuild.Value = $this.BuildMethods.NewlineCheck(
			$this.BuildMethods.MargeBlock($this.LastBuild.Tokens)
		) + ' ' + $VirtualTerminal.Colors.Reset + '>' * ($NestedPromptLevel+1)
		$this.LastBuild.LineNum = ($this.LastBuild.Value -split "`n").Length
		$this.LastBuild.Value
	}
}
#遍历脚本所在文件夹
Get-ChildItem $PSScriptRoot/builders *.ps1 | Sort-Object -Property Name | ForEach-Object { . $_.FullName }

function global:prompt {
	$LastExitCodeBackup = $global:LastExitCode
	$RawUIColorsBackup = @{
		Foreground = $Host.UI.RawUI.ForegroundColor
		Background = $Host.UI.RawUI.BackgroundColor
	}
	$(try{
		$VirtualTerminal.SaveCursor + $EshellUI.Prompt.Get()
	}
	catch {
		$_ | Out-Error
		"err >"
	}) | Write-Host -NoNewline
	[char]0
	$global:LastExitCode = $LastExitCodeBackup
	$Host.UI.RawUI.ForegroundColor = $RawUIColorsBackup.Foreground
	$Host.UI.RawUI.BackgroundColor = $RawUIColorsBackup.Background
}
