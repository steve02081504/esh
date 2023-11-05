Register-EngineEvent PowerShell.OnIdle -Action {
	#先注销这个事件
	Unregister-Event PowerShell.OnIdle

	#set thefuck as alias "fk"
	if (Test-Command "thefuck") {
		try {
			$env:PYTHONIOENCODING = "utf-8"
			Invoke-Expression "$(thefuck --alias global:fk)"
		} catch {}
	}

	if ($Host.UI.SupportsVirtualTerminal) {
		# https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
		if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
			Install-Module -Name Terminal-Icons -Repository PSGallery -Force
		}
		Import-Module -Name Terminal-Icons
	}

	. $PSScriptRoot/CHT2CHS.ps1
	if (Test-Path "C:\ProgramData\BlueStacks_nxt") {
		. $PSScriptRoot/BlueStacks.ps1
	}

	#import appx with -UseWindowsPowerShell to avoid [Operation is not supported on this platform. (0x80131539)]
	if (Test-Command "powershell.exe") {
		Import-Module Appx -UseWindowsPowerShell 3> $null
	}

	#vcpkg integrate powershell
	if (Test-Command vcpkg) {
		$presetPath = Split-Path $((Get-Command "vcpkg").source) -Parent
		Import-Module "$presetPath/scripts/posh-vcpkg"
		#take TabExpansion function to global
		Rename-Item function:TabExpansion global:TabExpansion
	}
} | Out-Null
