function global:Update-SAO-lib {
	$eshDir = $EshellUI.Sources.Path
	# 如果"$eshDir/data/SAO-lib.txt"是链接
	if ((Get-Item "$eshDir/data/SAO-lib.txt").Attributes -match 'ReparsePoint') {
		Write-Information "SAO-lib.txt is a link, Skip updating"
		return
	}
	try {
		#下载最新的SAO-lib
		Invoke-WebRequest 'https://github.com/steve02081504/SAO-lib/raw/master/SAO-lib.txt' -OutFile "$eshDir/data/SAO-lib.txt"
	} catch {}
}

function global:Update-gcc-Kawaii {
	if (-not (Test-PathEx /usr/share/locale/zh_CN/LC_MESSAGES/gcc.mo.bak)) {
		Write-Information "the original gcc.mo file is now backed up to gcc.mo.bak"
		mv /usr/share/locale/zh_CN/LC_MESSAGES/gcc.mo /usr/share/locale/zh_CN/LC_MESSAGES/gcc.mo.bak
	}
	$eshDir = $EshellUI.Sources.Path
	Invoke-WebRequest 'https://github.com/Bill-Haku/kawaii-gcc/raw/main/gcc-zh.po' -OutFile "$eshDir/data/gcc-zh.po"
	msgfmt "$eshDir/data/gcc-zh.po" -o /usr/share/locale/zh_CN/LC_MESSAGES/gcc.mo
	Remove-Item "$eshDir/data/gcc-zh.po" -Force
	gcc
}

function global:Update-EShell {
	Update-SAO-lib
	$eshDir = $EshellUI.Sources.Path
	# 如果"$eshDir"是git仓库
	if (Test-Path "$eshDir/.git/config") {
		$pathNow = $PWD
		Set-Location $eshDir
		git pull --rebase
		Set-Location $pathNow
	}
	else {
		$praentpath = Split-Path $eshDir
		$datapath = "$eshDir/data"
		try {
			if (Test-Command git) {
				# 升级到git仓库
				git clone https://github.com/steve02081504/esh $datapath/esh --depth 1 --no-checkout
				#移动并覆盖文件
				Move-Item "$datapath/esh/.git" $eshDir -Force
				Remove-Item "$datapath/esh" -Force -Recurse
				#恢复文件
				$pathNow = $PWD
				Set-Location $eshDir
				git reset --hard HEAD
				Set-Location $pathNow
			}
			else {
				#下载最新的EShell
				Invoke-WebRequest 'https://github.com/steve02081504/esh/archive/refs/heads/master.zip' -OutFile "$datapath/master.zip"
				#删除除了data和desktop.ini文件夹以外的所有文件
				Get-ChildItem "$eshDir" -Force | Where-Object { $_.Name -notin @('data', 'desktop.ini') } | Remove-Item -Recurse -Force
				#更新文件
				Rename-Item "$eshDir" "$praentpath/esh-master"
				Expand-Archive "$praentpath/esh-master/data/master.zip" "$praentpath" -Force
				#删除压缩包
				Remove-Item "$datapath/master.zip" -Force
				Rename-Item "$praentpath/esh-master" "$eshDir"
			}
		} catch {}
	}
	$eshDirFromEnv = $EshellUI.Im.InEnvPath()
	. $eshDir/src/opt/install.ps1 -Fix
	reload
}

function global:Update-All-Paks {
	function Update-HEAD ($text) {
		Write-Host "$($VirtualTerminal.Colors.BrightMagenta)Updating $text...$($VirtualTerminal.Colors.Reset)"
	}
	#Update Powershell Modules
	Update-HEAD 'Powershell Modules'
	Update-Module -Name *
	if (Test-Command pip) {
		Update-HEAD 'pip packages'
		pip-review --auto #pip install pip-review
	}
	if (Test-Command npm) {
		Update-HEAD 'npm packages'
		npm update -g
	}
	if (Test-Command gem) {
		Update-HEAD 'ruby gems'
		gem update
	}
	if (Test-Command cargo) {
		Update-HEAD 'cargo packages'
		cargo install-update -a -g #cargo install cargo-update
	}
	if (Test-Command go) {
		Update-HEAD 'go packages'
		go get -u -v all
	}
	if (Test-Command brew) {
		Update-HEAD 'brew packages'
		brew update
		brew upgrade
		brew cleanup
	}
	if (Test-Command choco) {
		Update-HEAD 'choco packages'
		choco upgrade all -y
	}
	if (Test-Command winget) {
		Update-HEAD 'winget packages'
		winget upgrade --all
	}
	if (Test-Command scoop) {
		Update-HEAD 'scoop packages'
		scoop update *
	}
	if (Test-Command apt) {
		Update-HEAD 'apt packages'
		apt update
		apt upgrade
		apt autoremove
	}
	if (Test-Command pacman) {
		Update-HEAD 'pacman packages'
		pacman -Syu
	}
	if (Test-Command yay) {
		Update-HEAD 'yay packages'
		yay -Syu
	}
	if (Test-Command pkg) {
		Update-HEAD 'pkg packages'
		pkg update
		pkg upgrade
	}
	if (Test-Command pkgin) {
		Update-HEAD 'pkgin packages'
		pkgin update
		pkgin upgrade
	}
	if (Test-Command pkg_add) {
		Update-HEAD 'pkg_add packages'
		pkg_add -u
	}
	if (Test-Command pkgutil) {
		Update-HEAD 'pkgutil packages'
		pkgutil --update
	}
	if (Test-Command port) {
		Update-HEAD 'port packages'
		port selfupdate
		port upgrade outdated
	}
	if (Test-Command fink) {
		Update-HEAD 'fink packages'
		fink selfupdate
		fink update-all
	}
	if (Test-Command nix) {
		Update-HEAD 'nix packages'
		nix-channel --update
		nix-env -u '*'
	}
	if (Test-Command flatpak) {
		Update-HEAD 'flatpak packages'
		flatpak update
	}
	if (Test-Command snap) {
		Update-HEAD 'snap packages'
		snap refresh
	}
	if (Test-Command vcpkg) {
		Update-HEAD 'vcpkg packages'
		if (Test-Command git) {
			$pathNow = $PWD
			Set-Location $(Split-Path $((Get-Command 'vcpkg').source))
			git pull
			Set-Location $pathNow
		}
		vcpkg update
		vcpkg upgrade --no-dry-run
	}
	if (Test-Command gh) {
		Update-HEAD 'Github CLI Extensions'
		gh extension upgrade --all
	}
	if (Test-PathEx /usr/share/locale/zh_CN/LC_MESSAGES/gcc.mo.bak) {
		Update-HEAD 'gcc Kawaii'
		Update-gcc-Kawaii
	}
}
