. "$($EshellUI.Sources.Path)/src/scripts/DiggingPath.ps1"
$EshellUI.DirProfile = @{
	path = ''
	commands = @()
	backupcommands = @{}
	paths = @()
	logo = ''
}
$EshellUI.Prompt.Builders['_dirProfileLoader'] = {
	$profileDir = DiggingPath { $_ } $PWD.Path '.esh'
	if($profileDir -eq $EshellUI.DirProfile.path) { return }
	$PathArray = $env:Path -split ';'
	$EshellUI.DirProfile.commands -ne $null | ForEach-Object {
		Remove-Alias -Name $_ -Scope global -Force -ErrorAction Ignore
	}
	$EshellUI.DirProfile.backupcommands.GetEnumerator() | ForEach-Object {
		Set-Alias -Name $_.Key -Value $_.Value -Scope global -Force -ErrorAction Ignore
	}
	$EshellUI.DirProfile.envpaths | ForEach-Object {
		$PathArray = $PathArray -ne $_
	}
	$EshellUI.DirProfile = @{
		path = $profileDir
		commands = @()
		backupcommands = @{}
		envpaths = @()
		logo = $EshellUI.DirProfile.logo
	}
	Get-ChildItem "$profileDir/commands" -Filter *.ps1 -ErrorAction Ignore | Sort-Object -Property Name | ForEach-Object {
		$funcname = $_.Name -replace '\.ps1$'
		if($alia=Get-Alias -Name $funcname -Scope global -ErrorAction Ignore) {
			$EshellUI.DirProfile.backupcommands += @{
				$alia.Name = $alia.Definition
			}
		}
		Set-Alias -Name $funcname -Value "$([System.IO.Path]::GetFullPath($_.FullName, $PWD.Path))" -Scope global -Force
		$EshellUI.DirProfile.commands+=$funcname
	}
	Get-Content "$profileDir/paths.txt" -ErrorAction Ignore | ForEach-Object {
		$fullpath = [System.IO.Path]::GetFullPath($_, $PWD.Path)
		if($PathArray -notcontains $fullpath) {
			$EshellUI.DirProfile.envpaths+=$fullpath
			$PathArray+=$fullpath
		}
	}
	$newlogo = Import-PowerShellDataFile "$profileDir/logo.psd1" -ErrorAction Ignore
	$newlogo ??= Get-Content "$profileDir/logo.txt" -ErrorAction Ignore
	if($EshellUI.DirProfile.logo -ne $newlogo) {
		$EshellUI.DirProfile.logo = $newlogo
		if($newlogo){ $newlogo | Out-Host }
	}
	$(if($EshellUI.DirProfile.commands.Count -gt 0 -or $EshellUI.DirProfile.envpaths.Count -gt 0) {
		$VirtualTerminal.Colors.Magenta+'Path provided env:'
		if($EshellUI.DirProfile.commands.Count -gt 0){
			"$($EshellUI.DirProfile.commands.Count) commands:"+$VirtualTerminal.Colors.Green
			$EshellUI.DirProfile.commands -join " "
			$VirtualTerminal.Colors.Magenta
		}
		if($EshellUI.DirProfile.envpaths.Count -gt 0){
			"$($EshellUI.DirProfile.envpaths.Count) enveronment paths"
		}
	}) | Out-Host
	$env:Path = $PathArray -ne '' -join ';'
}
