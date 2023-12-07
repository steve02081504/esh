. "$($EshellUI.Sources.Path)/src/scripts/DiggingPath.ps1"
$EshellUI.Prompt.Builders['npm'] = {
	DiggingPath { Get-Content $_ -Raw | ConvertFrom-Json } $PWD.Path 'package.json' | Set-Variable -Name packageJson
	if ($npminfo = @($packageJson.Name,$packageJson.Version) -ne $null -join '@') {
		$VirtualTerminal.Colors.Red+" "+$npminfo
	}
}
