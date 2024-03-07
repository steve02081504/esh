$EshellUI.BackgroundJobs.Push(@(
	{
		$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('ls-view')
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
		$EshellUI.OtherData.PartsMemoryUsage.EndAdd('ls-view')
	}
	{
		# 若$env:Path中存在XXXX/app-XXX\resources\app\git\mingw64\bin
		# 则试图更新版本号
		$GitHubDesktopsGitPath = $env:Path -split ';' | Where-Object { $_.EndsWith('\resources\app\git\mingw64\bin') }
		if ($GitHubDesktopsGitPath -and -not (Test-Path $GitHubDesktopsGitPath)) {
			$GitHubDesktopPath = Split-Path $GitHubDesktopsGitPath.TrimEnd('\resources\app\git\mingw64\bin')
			$newVersion = Get-ChildItem $GitHubDesktopPath -Directory -Filter 'app-*' | Sort-Object -Property Name -Descending | Select-Object -First 1
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
			$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('tab-git')
			if (-not (Get-Module -ListAvailable posh-git)) {
				Install-Module posh-git -Force
			}
			Import-Module posh-git
			$EshellUI.OtherData.PartsMemoryUsage.EndAdd('tab-git')
		}
	}
	{
		#set thefuck as alias 'fk'
		if (Test-Command thefuck) {
			$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('thefuck')
			try {
				$env:PYTHONIOENCODING = 'utf-8'
				$f = "$(thefuck --alias global:fk)"
				if ($f) { Invoke-Expression $f }
			} catch {}
			$EshellUI.OtherData.PartsMemoryUsage.EndAdd('thefuck')
		}
	}
	{
		if (Test-Command npm) {
			$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('tab-npm')
			if (-not (Get-Module -ListAvailable npm-completion)) {
				Install-Module npm-completion -Force
			}
			Import-Module npm-completion
			$EshellUI.OtherData.PartsMemoryUsage.EndAdd('tab-npm')
		}
	}
	{
		$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('Cht2Chs')
		. "$($EshellUI.Sources.Path)/src/scripts/CHT2CHS.ps1"
		$EshellUI.OtherData.PartsMemoryUsage.EndAdd('Cht2Chs')
		if (Test-Path 'C:\ProgramData\BlueStacks_nxt') {
			$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('Apk-Commands')
			. "$($EshellUI.Sources.Path)/src/commands/special/BlueStacks.ps1"
			$EshellUI.OtherData.PartsMemoryUsage.EndAdd('Apk-Commands')
		}
	}
	{
		#import appx with -UseWindowsPowerShell to avoid [Operation is not supported on this platform. (0x80131539)]
		if (Test-Command powershell) {
			$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('Appx-Compatibility')
			Import-Module Appx -UseWindowsPowerShell 3> $null
			$EshellUI.OtherData.PartsMemoryUsage.EndAdd('Appx-Compatibility')
		}
	}
	{
		#vcpkg integrate powershell
		if ($EshellUI.OtherData.ReloadSafeVariables.vcpkgFunctionExported) { return }
		if (Test-Command vcpkg) {
			$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('tab-vcpkg')
			$presetPath = Split-Path $((Get-Command 'vcpkg').source)
			Import-Module "$presetPath/scripts/posh-vcpkg"
			#take TabExpansion function to global
			Rename-Item function:TabExpansion global:TabExpansion -Force
			$EshellUI.OtherData.ReloadSafeVariables.vcpkgFunctionExported = $true
			$EshellUI.OtherData.PartsMemoryUsage.EndAdd('tab-vcpkg')
		}
	}
	{
		if (Test-Command yarn) {
			$EshellUI.OtherData.PartsMemoryUsage.BeginAdd('tab-yarn')
			if (-not (Get-Module -ListAvailable yarn-completion)) {
				Install-Module yarn-completion -Force
			}
			Import-Module yarn-completion
			$EshellUI.OtherData.PartsMemoryUsage.EndAdd('tab-yarn')
		}
	}
))
