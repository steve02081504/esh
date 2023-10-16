function Get-Ukagaka-Description-File-HashTable {
	param(
		[Parameter(Mandatory = $true)]
		$Content
	)
	#首先以换行符分割
	$Content = $Content -split "`n"
	#去除末尾可能的`r
	$Content = $Content -replace "`r$"
	#去除空行
	$Content = $Content -ne ""
	$Description = @{}
	foreach ($Line in $Content) {
		$Line = $Line -split ","
		$Description.Add($Line[0].Trim(),$Line[1].Trim())
	}
	$Description
}
function Read-Ukagaka-Description-File {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	$Content = Get-Content -Path $Path -Encoding UTF8
	$Description = Get-Ukagaka-Description-File-HashTable -Content $Content
	#若charset不是UTF-8或其大小写变体，则重新读取
	if ($Description["charset"] -notmatch "UTF-?8") {
		$Content = Get-Content -Path $Path -Encoding $Description["charset"]
		$Description = Get-Ukagaka-Description-File-HashTable -Content $Content
	}
	$Description
}
function Test-Ukagaka-Ghost-Directory {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	$DescriptionPath = Join-Path -Path $Path -ChildPath "ghost/master/descript.txt"
	if (Test-Path -Path $DescriptionPath) {
		Read-Ukagaka-Description-File -Path $DescriptionPath
	}
	else {
		#测试父目录直至根目录
		$ParentPath = Split-Path -Path $Path -Parent
		if ($ParentPath) {
			Test-Ukagaka-Ghost-Directory -Path $ParentPath
		}
		else {
			@{}
		}
	}
}
function Test-Ukagaka-Directory {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)
	$DescriptionPath = Join-Path -Path $Path -ChildPath "ghost/master/descript.txt"
	$DescriptionPath2 = Join-Path -Path $Path -ChildPath "descript.txt"
	if (Test-Path -Path $DescriptionPath) {
		Read-Ukagaka-Description-File -Path $DescriptionPath
	}
	elseif (Test-Path -Path $DescriptionPath2) {
		Read-Ukagaka-Description-File -Path $DescriptionPath2
	}
	else {
		#测试父目录直至根目录
		$ParentPath = Split-Path -Path $Path -Parent
		if ($ParentPath) {
			Test-Ukagaka-Ghost-Directory -Path $ParentPath
		}
		else {
			@{}
		}
	}
}
