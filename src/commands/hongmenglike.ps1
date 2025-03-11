if ($env:EdenOS) {
	if (Test-Command git.exe) {
		function global:git {
			begin {
				if ($args -ne '-v') {
					$pipe = { git.exe $args }.GetSteppablePipeline($MyInvocation.CommandOrigin, $args)
					$pipe.Begin($MyInvocation.ExpectingInput, $ExecutionContext)
				}
			}
			process {
				if ($args -eq '-v') {
					$result = git.exe $args
					$result -replace '.windows', '.EDENOS'
				}
				else { $pipe.Process($_) }
			}
			end { if ($args -ne '-v') { $pipe.End() } }
		}
	}

	if (Test-Command uname.exe) {
		function global:uname {
			if ($args -eq '-r') {
				return 'MS-DOS v2.1'
			}
			$result = uname.exe $args
			$result -ireplace 'MSYS_NT', 'EDENOS' -ireplace 'Msys', 'eden'
		}
	}
}
