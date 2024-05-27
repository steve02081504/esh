if ($env:EdenOS) {
	if (Test-Command git.exe) {
		function global:git {
			if ($args -eq '-v') {
				$result = git.exe $args
				$result -replace '.windows', '.EDENOS'
			}
			else {
				git.exe $args
			}
		}
	}

	if (Test-Command uname.exe) {
		function global:uname {
			$result = uname.exe $args
			$result -ireplace 'MSYS_NT', 'EDENOS' -ireplace 'Msys', 'eden'
		}
	}
}
