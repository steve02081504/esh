param(
	[switch]$RunInstall=$false,
	[Parameter(ValueFromRemainingArguments = $true)]
	$RemainingArguments
)

#_if PSEXE
	#_include ../src/opt/opt_init.ps1
#_else
	. $PSScriptRoot/../src/opt/opt_init.ps1
#_endif

if (-not $eshDir) {
	#_if PSEXE
		#_include ../src/opt/download.ps1
	#_else
		. $PSScriptRoot/../src/opt/download.ps1
	#_endif
}

if ($RunInstall){
	Invoke-Expression "&'$eshDir/src/opt/install.ps1' $RemainingArguments"
	exit
}
if (-not (Get-Command pwsh -ErrorAction Ignore)) {
	do {
		$response = $Host.UI.PromptForChoice("未在环境变量中找到可用的pwsh", "esh的运行需要PowerShell 6或以上`n尝试自动安装PowerShell吗？", @("自动安装","带我到下载页面","退出"), 0)
	} until ($response -ne -1)
	switch ($response) {
		0 {
			if (-not (Get-Command winget -ErrorAction Ignore)) {
				Import-Module Appx
				Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
			}
			Invoke-Expression "winget install --id Microsoft.Powershell $(
				if([System.Environment]::OSVersion.Version.Major -le 7){'-v 7.2.15'}
			)"
		}
		1 { Start-Process https://aka.ms/pscore6 }
		2 { exit 1 }
	}
}
if (Get-Command pwsh -ErrorAction Ignore) {
	if (Get-Command wt -ErrorAction Ignore) {
		wt $eshDir/path/esh.cmd $RemainingArguments
	}
	else{ & $eshDir/path/esh $RemainingArguments }
}
