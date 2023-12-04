$EshellUI.BackgroundJobs.AddRange(@(
	{
		Update-FormatData -PrependPath "$($EshellUI.Sources.Path)/data/formatxml/ls.bare.format.ps1xml"
		if ($Host.UI.SupportsVirtualTerminal) {
			# https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
			if (-not (Get-Module -ListAvailable Terminal-Icons)) {
				Install-Module Terminal-Icons -Repository PSGallery -Force
			}
			Import-Module Terminal-Icons
			Update-FormatData -PrependPath "$($EshellUI.Sources.Path)/data/formatxml/ls.Terminal-Icons.format.ps1xml"
		}
	}
	{
		if (Test-Command git) {
			if (-not (Get-Module -ListAvailable posh-git)) {
				Install-Module posh-git -Force
			}
			Import-Module posh-git
		}
	}
	{
		#set thefuck as alias 'fk'
		if (Test-Command thefuck) {
			try {
				$env:PYTHONIOENCODING = 'utf-8'
				$f = "$(thefuck --alias global:fk)"
				if ($f) { Invoke-Expression $f }
			} catch {}
		}
	}
	{
		if (Test-Command npm) {
			if (-not (Get-Module -ListAvailable npm-completion)) {
				Install-Module npm-completion -Force
			}
			Import-Module npm-completion
		}
	}
	{
		. "$($EshellUI.Sources.Path)/src/scripts/CHT2CHS.ps1"
		if (Test-Path 'C:\ProgramData\BlueStacks_nxt') {
			. "$($EshellUI.Sources.Path)/src/commands/special/BlueStacks.ps1"
		}
	}
	{
		#import appx with -UseWindowsPowerShell to avoid [Operation is not supported on this platform. (0x80131539)]
		if (Test-Command powershell) {
			Import-Module Appx -UseWindowsPowerShell 3> $null
		}
	}
	{
		#vcpkg integrate powershell
		if ($EshellUI.OtherData.ReloadSafeVariables.vcpkgFunctionExported) { return }
		if (Test-Command vcpkg) {
			$presetPath = Split-Path $((Get-Command 'vcpkg').source)
			Import-Module "$presetPath/scripts/posh-vcpkg"
			#take TabExpansion function to global
			Rename-Item function:TabExpansion global:TabExpansion -Force
			$EshellUI.OtherData.ReloadSafeVariables.vcpkgFunctionExported = $true
		}
	}
	{
		if (Test-Command yarn) {
			if (-not (Get-Module -ListAvailable yarn-completion)) {
				Install-Module yarn-completion -Force
			}
			Import-Module yarn-completion
		}
	}
))

# fixer of https://github.com/PowerShell/vscode-powershell/issues/4851
if ($EshellUI.Im.VSCodeExtension) {
	$EshellUI.BackgroundJobs.Add({
		Unregister-Event -SubscriptionId $EshellUI.OtherData.IdleEvent.SubscriptionId -Force
		$EshellUI.OtherData.Remove('IdleEvent')
	}) | Out-Null
}
