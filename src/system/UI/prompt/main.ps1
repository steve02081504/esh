$EshellUI.Prompt = ValueEx @{
	Parent = $EshellUI
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
		$local:EshellUI = $this.Parent
		$path_str = $PWD.Path
		if ($path_str.StartsWith($HOME) -or $path_str.StartsWith($EshellUI.MSYS.RootPath)) {
			$path_str = WindowsPathToLinuxPath $path_str
		}
		$this.LastBuild=@{
			Tokens=@($VirtualTerminal.Colors.Reset+$path_str)
			BuilderOutput=@{}
		}
		$this.Builders.GetEnumerator() | ForEach-Object {
			$this.LastBuild.Tokens += $this.LastBuild.BuilderOutput[$_.Key] = & $_.Value
		}
		return $this.BuildMethods.NewlineCheck(
			$this.BuildMethods.MargeBlock($this.LastBuild.Tokens)
		) + ' ' + $VirtualTerminal.Colors.Reset + '>' * ($NestedPromptLevel+1)
	}
}
#遍历脚本所在文件夹
Get-ChildItem $PSScriptRoot/builders *.ps1 | Sort-Object -Property Name | ForEach-Object { . $_.FullName }

function global:prompt {
	try{
		$EshellUI.Prompt.Get()
	}
	catch {
		$_ | Out-Error
		"err >"
	}
}
