function global:Get-Ukagaka-Description-File-HashTable($Content) {
	$Description = @{}
	$Content ?? $Input -split '\r?\n' -ne '' | ForEach-Object {
		$Key,$Value = $_ -split ','
		$Description.Add($Key.Trim(), $Value -join ',')
	}
	$Description
}
function global:Read-Ukagaka-Description-File {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	. ($Read={$Description = Get-Content $Path -Encoding UTF8 | Get-Ukagaka-Description-File-HashTable})
	#若charset不是UTF-8或其大小写变体，则重新读取
	if ($Description.charset -and $Description.charset -notmatch 'UTF-?8' ) { . $Read }
	$Description
}
. "$($EshellUI.Sources.Path)/src/scripts/DiggingPath.ps1"
function global:Test-Ukagaka-Common-Directory {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[string]$CheckPath = 'descript.txt'
	)
	DiggingPath { Read-Ukagaka-Description-File $_ } $Path $CheckPath
}
function global:Test-Ukagaka-Ghost-Directory {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	Test-Ukagaka-Common-Directory $Path 'ghost/master/descript.txt'
}
function global:Test-Ukagaka-Directory {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	
	if ($result = Test-Ukagaka-Common-Directory $Path) { $result }
	else { Test-Ukagaka-Ghost-Directory $Path }
}
