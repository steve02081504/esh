if (-not (Test-Command esh.cmd)) {
	function global:EShell {
		pwsh -nologo $(if ($PSVersionTable.PSVersion -gt 7.3) { '-NoProfileLoadTime' })
	}
	#设定别名esh
	Set-Alias esh EShell -Scope global
}

if($IsWindows -and -not(Test-Command sudo)){
	# SudoShadow用于将管理员窗口的输出保存到文件中以便在非管理员窗口中显示
	function global:__SudoShadow__($Command, $UUID = $(New-Guid).Guid) {
		$SudoShadowFile = "$env:Temp/sudo_shadows/$UUID.txt"
		Start-Transcript -Path $SudoShadowFile -UseMinimalHeader | Out-Null
		Invoke-Expression $Command
		Stop-Transcript | Out-Null
		Write-Host "Sudo shadow file was saved to $SudoShadowFile"
	}
	. "$($EshellUI.Sources.Path)/src/scripts/shell_args_convert.ps1"
	[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	function global:sudo(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	) {
		$HasEsh = Test-Command esh.cmd
		$Arguments = if($HasEsh){@()}else{@(if($PSVersionTable.PSVersion -gt 7.3){'-NoProfileLoadTime'}, '-nologo')}
		$baseBinary = @('pwsh.exe', 'esh.cmd')[$HasEsh]
		function runas($baseBinary, $Arguments) {
			if (Test-Command wt.exe) {
				$Arguments = (@($baseBinary) + $Arguments -ne $null) | ForEach-Object { $_.Replace('"', '\"') }
				$baseBinary = 'wt.exe'
			}
			try { Start-Process -Wait -FilePath $baseBinary -ArgumentList $Arguments -Verb runas }
			catch { Write-Warning "Failed to run as admin." }
		}
		if ($RemainingArguments.Length -eq 0) {
			if ($EshellUI.Im.Sudo) {
				Write-Host "I already have $($VirtualTerminal.Styles.Blink)Super Power$($VirtualTerminal.Styles.NoBlink)s."
				return
			}
			runas $baseBinary $Arguments
		}
		else {
			if ($EshellUI.Im.Sudo) {
				Invoke-Expression "$RemainingArguments"
				return
			}
			# Otherwise, run the command as an admin
			$UUID = $(New-Guid).Guid
			$Arguments += @('-Command', (cmd_args_convert "__SudoShadow__ -UUID '$UUID' -Command '$(pwsh_args_convert $RemainingArguments)'"))
			runas $baseBinary $Arguments
			try {
				$Shadow = Get-Content "$env:Temp/sudo_shadows/$UUID.txt" -ErrorAction Stop
				Remove-Item "$env:Temp/sudo_shadows/$UUID.txt"
				$Shadow = ($Shadow | Select-Object -Skip 4 -SkipLast 4) -join "`n"
				#由于Start-Transcript会将宽字符重复写入，所以对于每一个字符在$Shadow中进行渲染以获取其宽度，去除多余的字符
				$Font = New-Object System.Drawing.Font('cascadia mono', 128)
				$Width = 0
				$ShadowHandled = ($Shadow.ToCharArray() | ForEach-Object {
					if ($Width -eq 0) {
						$Width = [Math]::Max([Math]::Floor(
							[System.Windows.Forms.TextRenderer]::MeasureText($_, $Font).Width/
						128)-1, 0)
					}
					elseif ($_ -eq $LastChar) { $Width--; return }
					else { $UseOriginal = $true }
					$LastChar = $_
					$_
				}) -join ''
				if ($UseOriginal) { $ShadowHandled = $Shadow }
				if ($ShadowHandled) { Write-Host $ShadowHandled }
			}
			catch {
				Write-Warning "Failed to get sudo shadow."
			}
		}
	}
}

if ($EshellUI.Im.VSCodeExtension) {
	function global:exit($exitCode = 0) {
		#抠我退出键是吧
		[System.Environment]::Exit($exitCode)
	}
}

function global:reload { $EshellUI.Reload() }
