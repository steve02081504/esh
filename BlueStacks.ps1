function Install-apk{
	Param(
		[Parameter(Mandatory=$true)]
		[string]$apkPath
	)
	. "C:\Program Files\BlueStacks_nxt\HD-Player.exe" --instance Pie64 --cmd installApk --filepath "$apkPath"
}

function Show-apks{
	#读取C:\ProgramData\BlueStacks_nxt\Engine\Pie64\AppCache\AppCache.json
	$AppCache = Get-Content -Path "C:\ProgramData\BlueStacks_nxt\Engine\Pie64\AppCache\AppCache.json" -Raw | ConvertFrom-Json
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
			AppLabel = $AppLabel
			Package = $Package
			VersionName = $VersionName
			VersionCode = $VersionCode
			InstallDate = $InstallDate
			IconFileName = $IconFileName
			Activity = $Activity
			IsFullScreen = $IsFullScreen
			IsHomeApp = $IsHomeApp
			Orientation = $Orientation
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

function Start-apk {
	Param(
		[Parameter(Mandatory=$true)]
		[string]$apkSignOrName
	)
	$apkList = Show-apks
	$apkSign = $apkList | Where-Object {$_.AppLabel -eq $apkSignOrName -or $_.Package -eq $apkSignOrName} | Select-Object -First 1 -ExpandProperty Package
	if($null -eq $apkSign){
		Write-Host "${VirtualTerminal.Colors.Red}Error: ${VirtualTerminal.Colors.Reset}No such apk."
		return
	}
	else{
		. "C:\Program Files\BlueStacks_nxt\HD-Player.exe" --instance Pie64 --cmd launchApp --package "$apkSign"
	}
}
