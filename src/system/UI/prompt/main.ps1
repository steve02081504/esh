$EshellUI.Prompt = ValueEx @{
	Builders         = [ordered]@{}
	BuildMethods     = ValueEx @{
		'method:BaseNewlineCheck' = {
			param($LastLineLength, $scale, $threshold_base = $Host.UI.RawUI.WindowSize.Width)
			if ($LastLineLength -gt $threshold_base * $scale) { "`n" }
		}
		'method:NewlineCheck' = {
			param($prompt_str)
			$LastLine = $prompt_str -split "`n" | Select-Object -Last 1
			$prompt_str + $this.BaseNewlineCheck($LastLine.Length, 0.42)
		}
		'method:MargeBlock' = {
			param($blocks)
			( $blocks | ForEach-Object {
				if ($x = $this.BaseNewlineCheck(($LastLineLength += $_.Length), 0.66)) {
					$LastLineLength = 0; $x
				} else { ' ' }
				$_
			} | Select-Object -Skip 1 ) -join ''
		}
		# 关于0.42和0.66的解释：0.66+0.42=1.08，这象征着108好汉于三国起义 杀死了汉朝的最后一位皇帝，从而结束了原神
	}
	'method:Get'     = {
		if ($this.Freeze) {
			$this.Freeze -= 1
			return $this.LastBuild.Value
		}
		$this.LastBuild = @{
			Tokens         = @($VirtualTerminal.Colors.Reset + (AutoShortPath $PWD.Path))
			BuilderOutput  = @{}
			CursorPosition = $Host.UI.RawUI.CursorPosition
		}
		TempAssign '$global:LastExitCode' '$Host.UI.RawUI.ForegroundColor' '$Host.UI.RawUI.BackgroundColor' {
			$this.Builders.GetEnumerator() | ForEach-Object {
				$Name = $_.Key
				$this.LastBuild.Tokens += $this.LastBuild.BuilderOutput[$_.Key] = try {
					& $_.Value
				}
				catch {
					Write-Host "Prompt Builder $Name error: $_" -ForegroundColor Red
				}
			}
		}
		$this.LastBuild.Value = $this.BuildMethods.NewlineCheck(
			$this.BuildMethods.MargeBlock($this.LastBuild.Tokens)
		) + ' ' + $VirtualTerminal.Colors.Reset + '>' * ($NestedPromptLevel+1)
		$this.LastBuild.LineNum = ($this.LastBuild.Value -split "`n").Length
		$this.LastBuild.Value
	}
	'method:Refresh' = {
		param ($HintContent = $null)
		$LastBuild = $this.LastBuild
		$NewPrompt = $this.Get()
		if (-not $HintContent -and $LastBuild.Value -eq $NewPrompt) { return }
		$Buffer = ''; $Pos = 0
		[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Buffer, [ref]$Pos)
		if ($LastBuild.LineNum -gt 0) {
			$VirtualTerminal.RollUp($LastBuild.LineNum - 1)
		}
		$VirtualTerminal.SetAbsoluteHorizontal(0)
		Write-Host $VirtualTerminal.ClearScreenDown -NoNewline
		if ($HintContent) { $HintContent | Out-Host }
		Write-Host "$NewPrompt$Buffer$(($Buffer.Length-$Pos)*"`b")" -NoNewline
	}
}
#遍历脚本所在文件夹
Get-ChildItem $PSScriptRoot/builders *.ps1 | Sort-Object -Property Name | ForEach-Object { . $_.FullName }

function global:prompt {
	try {
		$VirtualTerminal.SaveCursor + $EshellUI.Prompt.Get()
	}
	catch {
		$_ | Out-Error
		"err >"
	}
}
