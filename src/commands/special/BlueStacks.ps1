$Script:BlueStackInstance = ''
Get-ChildItem -Path C:\ProgramData\BlueStacks_nxt\Engine -Directory | Where-Object {
	# 文件夹下有名为Root.vhd的文件
	Test-Path -Path "$($_.FullName)\Root.vhd"
} | ForEach-Object {
	$Script:BlueStackInstance = $_.Name
}

function global:Install-apk {
	param(
		[Parameter(Mandatory = $true)]
		[string]$apkPath
	)
	. 'C:\Program Files\BlueStacks_nxt\HD-Player.exe' --instance $Script:BlueStackInstance --cmd installApk --filepath "$apkPath"
}

function global:Show-apks {
	#读取C:\ProgramData\BlueStacks_nxt\Engine\$Script:BlueStackInstance\AppCache\AppCache.json
	$AppCache = Get-Content "C:\ProgramData\BlueStacks_nxt\Engine\$Script:BlueStackInstance\AppCache\AppCache.json" -Raw -ErrorAction Ignore | ConvertFrom-Json
	<#
	{
		"activity": "jp.co.cygames.activity.OverrideUnityActivity",
		"appLabel": "公主連結R",
		"iconFileName": "tw.sonet.princessconnect.png",
		"installDate": "22.01.2023",
		"isFullScreen": false,
		"isHomeApp": false,
		"orientation": "",
		"package": "tw.sonet.princessconnect",
		"versionCode": 78,
		"versionName": "3.8.0"
	}
	#>
	$apkList = @()
	$AppCache | ForEach-Object {
		$AppLabel = $_.appLabel
		$Package = $_.package
		$VersionName = $_.versionName
		$VersionCode = $_.versionCode
		$InstallDate = $_.installDate
		$IconFileName = $_.iconFileName
		$Activity = $_.activity
		$IsFullScreen = $_.isFullScreen
		$IsHomeApp = $_.isHomeApp
		$Orientation = $_.orientation
		$IconPath = "C:\ProgramData\BlueStacks_nxt\Engine\$Script:BlueStackInstance\AppCache\$IconFileName"
		$apk = @{
			appLabel     = $AppLabel
			package      = $Package
			versionName  = $VersionName
			versionCode  = $VersionCode
			installDate  = $InstallDate
			iconFileName = $IconFileName
			activity     = $Activity
			isFullScreen = $IsFullScreen
			isHomeApp    = $IsHomeApp
			orientation  = $Orientation
			IconPath     = $IconPath
		}
		$apkList += $apk
	}
	if ($MyInvocation.InvocationName -eq '.') {
		$apkList | Format-Table
	}
	else {
		return $apkList
	}
}

function global:Start-apk {
	param(
		[Parameter(Mandatory = $true)]
		[string]$apkSignOrName
	)
	$apkList = Show-apks
	$apkSign = $apkList | Where-Object { $_.appLabel -eq $apkSignOrName -or $_.package -eq $apkSignOrName } | Select-Object -First 1 -ExpandProperty Package
	if ($null -eq $apkSign) {
		Write-Host "$($VirtualTerminal.Colors.Red)Error: $($VirtualTerminal.Colors.Reset)No such apk."
		return
	}
	else {
		. 'C:\Program Files\BlueStacks_nxt\HD-Player.exe' --instance $Script:BlueStackInstance --cmd launchApp --package "$apkSign"
	}
}

if (!(Test-Command CHT2CHS)) {
	. "$($EshellUI.Sources.Path)/src/scripts/CHT2CHS.ps1"
}
#对于每个appLabel 创建一个函数用于启动
Show-apks | ForEach-Object {
	$AppLabel = CHT2CHS $_.appLabel
	$Package = $_.package
	New-Item -Force Function: -Name "global:App.$AppLabel" -Value {
		Start-apk -apkSignOrName $Package
	}
} | Out-Null
