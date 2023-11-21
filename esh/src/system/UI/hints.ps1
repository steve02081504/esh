$EshellUI.Hints = ValueEx @{
	__type__ = [System.Collections.ArrayList]
	"method:AddWithCommand" = {
		param(
			[string]$command,
			[string]$hint,
			[string]$check_command = $command
		)
		if (Test-Command $check_command) {
			$this.Add("Type '${VirtualTerminal.Colors.BrightYellow}$command${VirtualTerminal.Colors.Reset}' to $hint.")
		}
	}
	"method:GetRandom" = {
		$this[$(Get-Random -Minimum 0 -Maximum $this.Count)]
	}
	"method:PrintRandom" = {
		try { Write-Host $this.GetRandom() }
		catch { $this.PrintRandom() }
	}
}

$EshellUI.Hints.AddWithCommand("fk","fuck typos","thefuck") | Out-Null
$EshellUI.Hints.AddWithCommand("coffee","get a cup of coffee") | Out-Null
$EshellUI.Hints.AddWithCommand("poweron","turn on this computer") | Out-Null
$EshellUI.Hints.Add($(coffee)) | Out-Null

Get-Content "$($EshellUI.Sources.Path)/data/SAO-lib.txt" -ErrorAction Ignore -Encoding utf-8 | ForEach-Object { $EshellUI.Hints.Add($_) } | Out-Null
