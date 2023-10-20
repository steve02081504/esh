$global:hints = @()
function new_hint ($hint) {
	$global:hints += $hint
}
function check_hint {
	param(
		[string]$command,
		[string]$hint,
		[string]$check_command
	)
	if (-not $check_command) { $check_command = $command }
	if (Test-Command $check_command) {
		new_hint "Type '${VirtualTerminal.Colors.BrightYellow}$command${VirtualTerminal.Colors.Reset}' to $hint."
	}
}

check_hint fk "fuck typos" thefuck
check_hint coffee "get a cup of coffee"
check_hint poweron "turn on this computer"

new_hint $(coffee)

Get-Content $PSScriptRoot/../data/SAO-lib.txt -ErrorAction SilentlyContinue -Encoding utf-8 | ForEach-Object { new_hint $_ }

function printhints {
	try { Write-Host $(Get-Random $hints) }
	catch { printhints }
}
printhints
Remove-Variable hints
Remove-Item function:check_hint
Remove-Item function:new_hint
Remove-Item function:printhints
