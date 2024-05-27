. "$($EshellUI.Sources.Path)/src/scripts/DiggingPath.ps1"
$EshellUI.DirProfile = @{
	path           = ''
	commands       = @()
	backupcommands = @{}
	paths          = @()
	logo           = ''
}
$EshellUI.Prompt.Builders['_dirProfileLoader'] = {
	$profileDir = DiggingPath { $_ } $PWD.Path '.esh'
	if ($profileDir -eq $EshellUI.DirProfile.path) { return }
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
	Get-Command -Name "Start-$($EshellUI.DirProfile.uuid)-*" | ForEach-Object {
		Remove-Item function:\$($_.Name)
	}
	$EshellUI.DirProfile = @{
		path           = $profileDir
		commands       = @()
		backupcommands = @{}
		envpaths       = @()
		logo           = $EshellUI.DirProfile.logo
		uuid           = [Guid]::NewGuid().ToString()
	}
	if ($profileDir -eq $null) { return }
	$env:EshProfiledDir = Split-Path $profileDir
	$env:EshProfileRoot = $profileDir
	function New-DirProfile-Function {
		param ([string]$funcname, [string]$Command, [string]$DequalFunc)
		if ($DequalFunc) { Invoke-Expression "function global:$DequalFunc { $Command @args }" }
		$DequalFunc ??= $Command
		if ($alia = Get-Alias -Name $funcname -Scope global -ErrorAction Ignore) {
			$EshellUI.DirProfile.backupcommands += @{
				$alia.Name = $alia.Definition
			}
		}
		Set-Alias -Name $funcname -Value $DequalFunc -Scope global -Force
		$EshellUI.DirProfile.commands += $funcname
	}
	Get-ChildItem "$profileDir/commands" -ErrorAction Ignore | ForEach-Object {
		$Ext = [System.IO.Path]::GetExtension($_.Name)
		$funcname = $_.BaseName
		$path = [System.IO.Path]::GetFullPath($_.FullName, $PWD.Path)
		$Command = "Start-Process $path"
		$DequalFunc = "Start-$($EshellUI.DirProfile.uuid)-$funcname"
		$ExtList = @(
			@{
				list   = @('.ps1', '.exe', '.cmd', '.com')
				action = { $Command = $path; $DequalFunc = '' }
			},
			@{ list = @('.js', '.mjs'); actionSoftWare = 'node' }
			@{ list = @('.py'); actionSoftWare = 'python' }
			@{ list = @('.rb'); actionSoftWare = 'ruby' }
			@{ list = @('.pl'); actionSoftWare = 'perl' }
			@{ list = @('.php'); actionSoftWare = 'php' }
			@{ list = @('.sh'); actionSoftWare = 'bash' }
		)
		foreach ($item in $ExtList) {
			if ($item.list -contains $Ext) {
				if ($item.actionSoftWare) { $Command = "$($item.actionSoftWare) $path" }
				else { . $item.action }
				break
			}
		}
		New-DirProfile-Function $funcname $Command $DequalFunc
	}
	Get-Content "$profileDir/paths.txt" -ErrorAction Ignore | ForEach-Object {
		$fullpath = [System.IO.Path]::GetFullPath($_, $PWD.Path)
		if ($PathArray -notcontains $fullpath) {
			$EshellUI.DirProfile.envpaths += $fullpath
			$PathArray += $fullpath
		}
	}
	$newlogo = Import-PowerShellDataFile "$profileDir/logo.psd1" -ErrorAction Ignore
	$newlogo ??= Get-Content "$profileDir/logo.txt" -Raw -ErrorAction Ignore
	if ($EshellUI.DirProfile.logo -ne $newlogo) {
		$EshellUI.DirProfile.logo = $newlogo
		if ($newlogo) { $VirtualTerminal.Colors[$newlogo.color ?? 'default'] + $($newlogo.logo ?? $newlogo) | Out-Host }
	}
	$(if ($EshellUI.DirProfile.commands.Count -gt 0 -or $EshellUI.DirProfile.envpaths.Count -gt 0) {
		$VirtualTerminal.Colors.Magenta + 'Path provided env:'
		if ($EshellUI.DirProfile.commands.Count -gt 0) {
			"$($EshellUI.DirProfile.commands.Count) commands:" + $VirtualTerminal.Colors.Green
			$EshellUI.DirProfile.commands -join " "
			$VirtualTerminal.Colors.Magenta
		}
		if ($EshellUI.DirProfile.envpaths.Count -gt 0) {
			"$($EshellUI.DirProfile.envpaths.Count) enveronment paths"
		}
	}) | Out-Host
	$env:Path = $PathArray -ne '' -join ';'
}
