if (-not (Get-Module -ListAvailable -Name PowerShell-Beautifier)) {
	Install-Module -Name PowerShell-Beautifier
}
function Format-Code {
	param(
		[string]$path = "."
	)
	#若是目录
	if (Test-Path $path -PathType Container) {
		$files = Get-ChildItem -Path $path -Recurse -Include *.ps1
		foreach ($file in $files) {
			Format-Code -Path $file.FullName
		}
	}
	#若是文件
	else {
		$ext = [System.IO.Path]::GetExtension($path)
		if ($ext -eq ".ps1") {
			Edit-DTWBeautifyScript $path -IndentType Tabs -NewLine LF
		}
	}
}
