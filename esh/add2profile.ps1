$profilesDir = Split-Path $profile
$thisDir = $PSScriptRoot
if ($thisDir -like "$profilesDir[\\/]?*") {
	$thisDir = $thisDir -replace "^$($profilesDir -replace "\\","\\")[\\/]?",'$PSScriptRoot/'
}
$startScript = ". $thisDir/run.ps1"
$universalProfile = "$profilesDir/profile.ps1"
function checkLoaded ($theProfile) {
	$loaded = $false
	Get-Content $theProfile -ErrorAction Ignore | ForEach-Object {
		if ($_ -like $startScript) {
			$loaded = $true
		}
	}
	return $loaded
}
$added = $false
@(
	$universalProfile
	$profile
) | ForEach-Object {
	$loaded = checkLoaded $_
	if ($loaded) {
		Write-Warning "在${_}中已经加载过esh"
		$added = $true
	}
	elseif (Test-Path $_) {
		Add-Content $_ $startScript
		Write-Host "已在${_}中添加加载esh的语句"
		$added = $true
	}
}
if (-not $added) {
	Write-Warning "未找到可用的profile文件，新建通用profile文件${universalProfile}"
	New-Item -ItemType Directory -Force -Path $profilesDir | Out-Null
	Set-Content $universalProfile $startScript
}
