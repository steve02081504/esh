if ((Get-ExecutionPolicy) -eq 'Restricted') { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
if ($Script:eshDirFromEnv = Get-Command esh -ErrorAction Ignore) {
	$Script:eshDir = Split-Path $(Split-Path $eshDirFromEnv.Source)
}
# 使用if判断+赋值：我们不能使用??=因为用户可能以winpwsh运行该脚本
if (-not $eshDir) {
	$Script:eshDir =
	#_if PSScript #在PSEXE中不可能有$EshellUI，而$PSScriptRoot无效
	if (Test-Path "$($EshellUI.Sources.Path)/path/esh") { $EshellUI.Sources.Path }
	elseif (Test-Path $PSScriptRoot/../path/esh) { "$PSScriptRoot/.." }
	elseif
	#_else
		#_!!if
	#_endif
	(Test-Path $env:LOCALAPPDATA/esh) { "$env:LOCALAPPDATA/esh" }
}
