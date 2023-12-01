. $PSScriptRoot\CHT2CHS.map.ps1

[hashtable]${global:CHT2CHS.data.words} = @{}
[hashtable]${global:CHS2CHT.data.words} = @{}

[hashtable]${global:CHS2CHT.data.alphas} = @{}
[hashtable]${global:CHT2CHS.data.alphas} = @{}

function global:CHS2CHT.base {
	param([string]$str)
	[string]$Result = ""
	for ($i = 0; $i -lt $str.Length; $i++) {
		if (([int]$str[$i] -gt 255) -and ${CHS2CHT.data.alphas}.Contains($str[$i])) {
			$Result += ${CHS2CHT.data.alphas}[$str[$i]]
		}
		else {
			$Result += $str[$i]
		}
	}
	return $Result
}
function global:CHS2CHT {
	param([string]$str)
	[string]$Result = CHS2CHT.base $str
	if ($Result.Length -gt 1) {
		${CHS2CHT.data.words}.Keys | ForEach-Object {
			$Result = $Result -replace $_, ${CHS2CHT.data.words}[$_]
		}
	}
	return $Result
}

function global:CHT2CHS.base {
	param([string]$str)
	[string]$Result = ""
	for ($i = 0; $i -lt $str.Length; $i++) {
		if (([int]$str[$i] -gt 255) -and ${CHT2CHS.data.alphas}.Contains($str[$i])) {
			$Result += ${CHT2CHS.data.alphas}[$str[$i]]
		}
		else {
			$Result += $str[$i]
		}
	}
	return $Result
}
function global:CHT2CHS {
	param([string]$str)
	[string]$Result = CHT2CHS.base $str
	if ($Result.Length -gt 1) {
		${CHT2CHS.data.words}.Keys | ForEach-Object {
			$Result = $Result -replace $_, ${CHT2CHS.data.words}[$_]
		}
	}
	return $Result
}

${CHSCHT.oridata.alphas}.Keys | ForEach-Object {
	$Key = $_
	$Value = ${CHSCHT.oridata.alphas}[$Key].ToCharArray()
	if ($Value.Count -gt 0) {
		if ($Value[0] -ne ' ') {
			${CHS2CHT.data.alphas}.Add($Key[0], $Value[0])
		}
		$Value | ForEach-Object {
			if ($_ -ne ' ') {
				${CHT2CHS.data.alphas}.Add($_, $Key[0])
			}
		}
	}
}
Remove-Variable -Name 'CHSCHT.oridata.alphas' -Scope Global
${CHSCHT.oridata.words}.Keys | ForEach-Object {
	$Key = $_
	$Value = ${CHSCHT.oridata.words}[$Key].Trim()
	$S = CHT2CHS.base $Value
	if (($S -ne $Key) -and ($Value.Length -eq ${CHSCHT.oridata.words}[$Key].Length)) {
		${CHT2CHS.data.words}.Add($S, $Key)
	}
	$S = CHS2CHT.base $Key
	if ($S -ne $Value) {
		${CHS2CHT.data.words}.Add($S, $Value)
	}
}
Remove-Variable -Name 'CHSCHT.oridata.words' -Scope Global
