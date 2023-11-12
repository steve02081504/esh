$EshellUI["Hints"] = @{
	"Data" = @()
}; @{
	Add = {
		param(
			[string]$hint
		)
		$this.Data += $hint
	}
	AddWithCommand = {
		param(
			[string]$command,
			[string]$hint,
			[string]$check_command
		)
		if (-not $check_command) { $check_command = $command }
		if (Test-Command $check_command) {
			$this.Add("Type '${VirtualTerminal.Colors.BrightYellow}$command${VirtualTerminal.Colors.Reset}' to $hint.")
		}
	}
	PrintRandom = {
		try { Write-Host $(Get-Random $this.Data) }
		catch { $this.PrintRandom }
	}
}.GetEnumerator() | ForEach-Object {
	Add-Member -InputObject $EshellUI.Hints -MemberType ScriptMethod -Name $_.Key -Value $_.Value -Force
}

$EshellUI.Hints.AddWithCommand("fk","fuck typos","thefuck")
$EshellUI.Hints.AddWithCommand("coffee","get a cup of coffee")
$EshellUI.Hints.AddWithCommand("poweron","turn on this computer")
$EshellUI.Hints.Add($(coffee))

Get-Content "$($EshellUI.Sources.Path)/data/SAO-lib.txt" -ErrorAction Ignore -Encoding utf-8 | ForEach-Object { $EshellUI.Hints.Add($_) }
