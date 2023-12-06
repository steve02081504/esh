${global:Out-Performance} = @{
	Warning = @{
		Color = 'Yellow'
	}
	Error = @{
		Color = 'Red'
	}
	Info = @{
		Color = 'Blue'
	}
}

function global:Out-Error {
	param ($Value)
	$Host.UI.WriteErrorLine(
		$VirtualTerminal.Colors[
			${global:Out-Performance}.Error.Color ??
			(Get-Host).PrivateData.ErrorForegroundColor.ToString()
		]+(
		(($Value ?? $Input) | ForEach-Object { $_.ToString() }) -join "`r`n"
		)+$VirtualTerminal.Colors.Default
	)
}

function global:Out-Warning {
	param ($Value)
	$Host.UI.WriteWarningLine(
		$VirtualTerminal.Colors[
			${global:Out-Performance}.Warning.Color ??
			(Get-Host).PrivateData.WarningForegroundColor.ToString()
		]+(
		(($Value ?? $Input) | ForEach-Object { $_.ToString() }) -join "`r`n"
		)+$VirtualTerminal.Colors.Default
	)
}

function global:Out-Info {
	param ($Value)
	$Host.UI.WriteLine(
		$VirtualTerminal.Colors[
			${global:Out-Performance}.Info.Color ?? 'Default'
		]+(
		(($Value ?? $Input) | ForEach-Object { $_.ToString() }) -join "`r`n"
		)+$VirtualTerminal.Colors.Default
	)
}
