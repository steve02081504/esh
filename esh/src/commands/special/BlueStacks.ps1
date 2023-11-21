function global:Install-apk {
	param(
		[Parameter(Mandatory = $true)]
		[string]$apkPath
	)
	. 'C:\Program Files\BlueStacks_nxt\HD-Player.exe' --instance Pie64 --cmd installApk --filepath "$apkPath"
}

function global:Show-apks {
	#读取C:\ProgramData\BlueStacks_nxt\Engine\Pie64\AppCache\AppCache.json
	$AppCache = Get-Content 'C:\ProgramData\BlueStacks_nxt\Engine\Pie64\AppCache\AppCache.json' -Raw | ConvertFrom-Json
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
		$IconPath = "C:\Program Files\BlueStacks_nxt\Engine\Pie64\AppCache\$IconFileName"
		$apk = @{
			appLabel = $AppLabel
			package = $Package
			versionName = $VersionName
			versionCode = $VersionCode
			installDate = $InstallDate
			iconFileName = $IconFileName
			activity = $Activity
			isFullScreen = $IsFullScreen
			isHomeApp = $IsHomeApp
			orientation = $Orientation
			IconPath = $IconPath
		}
		$apkList += $apk
	}
	if ($MyInvocation.InvocationName -eq '.') {
		$apkList | Format-Table
	} else {
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
		Write-Host "${VirtualTerminal.Colors.Red}Error: ${VirtualTerminal.Colors.Reset}No such apk."
		return
	}
	else {
		. 'C:\Program Files\BlueStacks_nxt\HD-Player.exe' --instance Pie64 --cmd launchApp --package "$apkSign"
	}
}

#对于每个appLabel 创建一个函数用于启动
Show-apks | ForEach-Object {
	$AppLabel = CHT2CHS $_.appLabel
	$Package = $_.package
	New-Item -Force Function: -Name "global:App.$AppLabel" -Value {
		Start-apk -apkSignOrName $Package
	}
} | Out-Null
