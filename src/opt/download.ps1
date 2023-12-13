Remove-Item $env:LOCALAPPDATA/esh -Confirm -ErrorAction Ignore -Recurse
if (Get-Command git -ErrorAction Ignore) {
	try { git clone https://github.com/steve02081504/esh $env:LOCALAPPDATA/esh --depth 1 }
	catch {
		$Host.UI.WriteErrorLine("下载错误 终止脚本")
		exit 1
	}
}
else{
	Remove-Item $env:TEMP/esh-master -Force -ErrorAction Ignore -Confirm:$false -Recurse
	try { Invoke-WebRequest https://bit.ly/Esh-zip -OutFile $env:TEMP/Eshell.zip }
	catch {
		$Host.UI.WriteErrorLine("下载错误 终止脚本")
		exit 1
	}
	Expand-Archive $env:TEMP/Eshell.zip $env:TEMP -Force
	Remove-Item $env:TEMP/Eshell.zip -Force
	Move-Item $env:TEMP/esh-master $env:LOCALAPPDATA/esh -Force
}
$Script:eshDir = "$env:LOCALAPPDATA/esh"
try { Invoke-WebRequest https://bit.ly/SAO-lib -OutFile $eshDir/data/SAO-lib.txt }
catch {
	Write-Host "啊哦 SAO-lib下载失败了`n这不会影响什么，不过你可以在Esh安装好后使用``Update-SAO-lib``来让Esh有机会显示更多骚话"
}
