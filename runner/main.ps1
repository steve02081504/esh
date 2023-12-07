param(
	[switch]$RunInstall=$false,
	[Parameter(ValueFromRemainingArguments = $true)]
	$RemainingArguments
)
if((Get-ExecutionPolicy) -eq 'Restricted'){ Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
$env:Path.Split(";") | ForEach-Object {
	if ($_ -and (-not (Test-Path $_ -PathType Container))) {
		Write-Warning "检测到无效的环境变量于$_，请考虑删除"
	}
	elseif ($_ -like "*[\\/]esh[\\/]path*") {
		$eshDir = $_ -replace "[\\/]path[\\/]*$", ''
		$eshDirFromEnv = $true
	}
}
if (-not $eshDir) {
	$eshDir = if (Test-Path $env:LOCALAPPDATA/esh) { "$env:LOCALAPPDATA/esh" }
}

if (-not $eshDir) {
	Remove-Item $env:LOCALAPPDATA/esh -Confirm -ErrorAction Ignore -Recurse
	Remove-Item $env:TEMP/esh-master -Force -ErrorAction Ignore -Confirm:$false -Recurse
	try { Invoke-WebRequest https://bit.ly/Esh-zip -OutFile $env:TEMP/Eshell.zip }
	catch {
		$Host.UI.WriteErrorLine("下载错误 终止程序")
		exit 1
	}
	Expand-Archive $env:TEMP/Eshell.zip $env:TEMP -Force
	Remove-Item $env:TEMP/Eshell.zip -Force
	Move-Item $env:TEMP/esh-master $env:LOCALAPPDATA/esh -Force
	$eshDir = "$env:LOCALAPPDATA/esh"
	try { Invoke-WebRequest 'https://bit.ly/SAO-lib' -OutFile "$eshDir/data/SAO-lib.txt" }
	catch {
		Write-Host "啊哦 SAO-lib下载失败了`n这不会影响什么，不过你可以在Esh启动后使用``Update-SAO-lib``来让Esh有机会显示更多骚话"
	}
}

if ($RunInstall){
	. $eshDir/src/opt/install.ps1 $RemainingArguments
	exit
}
if (-not (Get-Command pwsh -ErrorAction Ignore)) {
	$Host.UI.WriteErrorLine("esh的运行需要PowerShell 6或以上`n访问 https://aka.ms/pscore6 来获取PowerShell 6+ 并使得``pwsh``命令在环境中可用以使得esh能够正常工作")
	do {
		$response = $Host.UI.PromptForChoice("未找到可用的pwsh", "尝试自动安装PowerShell吗？", @("自动安装","带我到下载页面","退出"), 0)
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
