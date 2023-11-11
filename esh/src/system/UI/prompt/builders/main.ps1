$EshellUI.Prompt["Builders"] = @{}

#遍历脚本所在文件夹
Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 | ForEach-Object {
	#获取文件名
	$name = $_.BaseName
	if ($name -ne "main") {
		.$_.FullName
	}
}
