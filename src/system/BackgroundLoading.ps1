$EshellUI.BackgroundJobs.Push(@(
	{
		$EshellUI.OtherData.PartsUsage.BeginAdd('linux-env')
		if (Test-Command locale) {
			$env:LANG ??= $env:LANGUAGE ??= $env:LC_ALL ??= $(locale -uU)
		}
		if (Test-Command bash) {
			$global:BASH_VERSION = bash -c 'echo "${BASH_VERSION}"'
		}
		$EshellUI.OtherData.PartsUsage.EndAdd('linux-env')
	}
	{
		$EshellUI.OtherData.PartsUsage.BeginAdd('ls-view')
		Update-FormatData -PrependPath "$($EshellUI.Sources.Path)/data/formatxml/ls.bare.format.ps1xml"
		if ($Host.UI.SupportsVirtualTerminal) {
			# https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
			if (-not (Get-Module -ListAvailable Terminal-Icons)) {
				Install-Module Terminal-Icons -Repository PSGallery -Force
			}
			Import-Module Terminal-Icons
			Update-FormatData -PrependPath "$($EshellUI.Sources.Path)/data/formatxml/ls.Terminal-Icons.format.ps1xml"
			if (Test-Command Set-TerminalIconPathResolver) {
				Set-TerminalIconPathResolver { param ($Path) AutoShortPath $Path }
			}
		}
		$EshellUI.OtherData.PartsUsage.EndAdd('ls-view')
	}
	{
		$EshellUI.OtherData.PartsUsage.BeginAdd('discord-rpc')
		if (-not (Get-Module -ListAvailable discordrpc)) {
			Install-Module discordrpc -Repository PSGallery -Force
		}
		Import-Module discordrpc
		$params = @{
			ApplicationID  = "1163063885725704192"
			LargeImageKey  = "icon-full"
			LargeImageText = "Version 1960.7.17"
			Label          = "Popepo 🥔"
			Url            = "https://youtu.be/dQw4w9WgXcQ"
			Details        = "As a $($EshellUI.Im.Sudo ? "king 👑" : "peasant 🐜")"
			State          = "At ``$(AutoShortPath $pwd)``"
			TimerRefresh   = 10
			Start          = "Now"
			UpdateScript   = {
				$params =@{
					State = "At ``$(AutoShortPath $pwd)``"
				}
				Update-DSRichPresence @params
			}
		}
		Start-DSClient @params
		$EshellUI.OtherData.PartsUsage.EndAdd('discord-rpc')
	}
	{
		# 若$env:Path中存在XXXX/app-XXX\resources\app\git\mingw64\bin
		# 则试图更新版本号
		$GitHubDesktopsGitPath = $env:Path -split ';' | Where-Object { $_.EndsWith('\resources\app\git\mingw64\bin') }
		if ($GitHubDesktopsGitPath -and -not (Test-Path $GitHubDesktopsGitPath)) {
			$GitHubDesktopPath = Split-Path $GitHubDesktopsGitPath.TrimEnd('\resources\app\git\mingw64\bin')
			$newVersion = Get-ChildItem $GitHubDesktopPath -Directory -Filter 'app-*' | Where-Object { Test-Path $_\resources } | Select-Object -First 1
			$newPath = Join-Path $newVersion.FullName 'resources\app\git\mingw64\bin'
			$env:Path = $env:Path -replace [regex]::Escape($GitHubDesktopsGitPath), $newPath
			# 将更新后的$env:Path写入系统
			# 首先确定原path是由user还是machine提供的，更新回对应的user或machine环境变量
			$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
			$SystemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
			if ($UserPath -match [regex]::Escape($GitHubDesktopsGitPath)) {
				$UserPath = $UserPath -replace [regex]::Escape($GitHubDesktopsGitPath), $newPath
				[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")
			}
			elseif ($SystemPath -match [regex]::Escape($GitHubDesktopsGitPath)) {
				$SystemPath = $SystemPath -replace [regex]::Escape($GitHubDesktopsGitPath), $newPath
				try {
					[Environment]::SetEnvironmentVariable("Path", $SystemPath, "Machine")
				}catch {}
			}
		}
		if (Test-Command git) {
			$EshellUI.OtherData.PartsUsage.BeginAdd('tab-git')
			if (-not (Get-Module -ListAvailable posh-git)) {
				Install-Module posh-git -Force
			}
			Import-Module posh-git
			$EshellUI.OtherData.PartsUsage.EndAdd('tab-git')
		}
	}
	{
		#set thefuck as alias 'fk'
		if (Test-Command thefuck) {
			$EshellUI.OtherData.PartsUsage.BeginAdd('thefuck')
			try {
				$env:PYTHONIOENCODING = 'utf-8'
				$f = "$(thefuck --alias global:fk)"
				if ($f) { Invoke-Expression $f }
			} catch {}
			$EshellUI.OtherData.PartsUsage.EndAdd('thefuck')
		}
	}
	{
		if (Test-Command npm) {
			$EshellUI.OtherData.PartsUsage.BeginAdd('tab-npm')
			if (-not (Get-Module -ListAvailable npm-completion)) {
				Install-Module npm-completion -Force
			}
			Import-Module npm-completion
			$EshellUI.OtherData.PartsUsage.EndAdd('tab-npm')
		}
	}
	{
		$EshellUI.OtherData.PartsUsage.BeginAdd('Cht2Chs')
		. "$($EshellUI.Sources.Path)/src/scripts/CHT2CHS.ps1"
		$EshellUI.OtherData.PartsUsage.EndAdd('Cht2Chs')
		if (Test-Path 'C:\ProgramData\BlueStacks_nxt') {
			$EshellUI.OtherData.PartsUsage.BeginAdd('Apk-Commands')
			. "$($EshellUI.Sources.Path)/src/commands/special/BlueStacks.ps1"
			$EshellUI.OtherData.PartsUsage.EndAdd('Apk-Commands')
		}
	}
	{
		#import appx with -UseWindowsPowerShell to avoid [Operation is not supported on this platform. (0x80131539)]
		if (Test-Command powershell) {
			$EshellUI.OtherData.PartsUsage.BeginAdd('Appx-Compatibility')
			Import-Module Appx -UseWindowsPowerShell 3> $null
			$EshellUI.OtherData.PartsUsage.EndAdd('Appx-Compatibility')
		}
	}
	{
		#vcpkg integrate powershell
		if ($EshellUI.OtherData.ReloadSafeVariables.vcpkgFunctionExported) { return }
		if (Test-Command vcpkg) {
			$EshellUI.OtherData.PartsUsage.BeginAdd('tab-vcpkg')
			$presetPath = Split-Path $((Get-Command 'vcpkg').source)
			Import-Module "$presetPath/scripts/posh-vcpkg"
			#take TabExpansion function to global
			Rename-Item function:TabExpansion global:TabExpansion -Force
			$EshellUI.OtherData.ReloadSafeVariables.vcpkgFunctionExported = $true
			$EshellUI.OtherData.PartsUsage.EndAdd('tab-vcpkg')
		}
	}
	{
		if (Test-Command yarn) {
			$EshellUI.OtherData.PartsUsage.BeginAdd('tab-yarn')
			if (-not (Get-Module -ListAvailable yarn-completion)) {
				Install-Module yarn-completion -Force
			}
			Import-Module yarn-completion
			$EshellUI.OtherData.PartsUsage.EndAdd('tab-yarn')
		}
	}
	{
		$EshellUI.OtherData.PartsUsage.BeginAdd('final-gc')
		[System.GC]::EndNoGCRegion()
		[System.GC]::Collect([System.GC]::MaxGeneration, [System.GCCollectionMode]::Aggressive, $true, $true)
		$EshellUI.OtherData.PartsUsage.EndAdd('final-gc')
	}
))
