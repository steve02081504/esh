function global:EShell {
	pwsh -nologo $(if ($PSVersionTable.PSVersion -gt 7.3) { '-NoProfileLoadTime' })
}
#设定别名esh
Set-Alias esh EShell -Scope global

# SudoShadow用于将管理员窗口的输出保存到文件中以便在非管理员窗口中显示
function global:__SudoShadow__ {
	param(
		$Command,
		$UUID=$(New-Guid).Guid
	)
	$SudoShadowFile = "$env:Temp/sudo_shadows/$UUID.txt"
	Start-Transcript -Path $SudoShadowFile -UseMinimalHeader | Out-Null
	Invoke-Expression $Command
	Stop-Transcript | Out-Null
	Write-Host "Sudo shadow file was saved to $SudoShadowFile"
}
. "$($EshellUI.Sources.Path)/src/scripts/shell_args_convert.ps1"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
function global:sudo {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	$pwshArguments = "$(if($PSVersionTable.PSVersion -gt 7.3){`"-NoProfileLoadTime`"}) -nologo"
	if ($RemainingArguments.Length -eq 0) {
		if ($EshellUI.Im.Sudo) {
			Write-Host "I already have $($VirtualTerminal.Styles.Blink)Super Power$($VirtualTerminal.Styles.NoBlink)s."
		}
		# If the command is empty, open a new PowerShell shell with admin privileges
		elseif (Test-Command wt.exe) {
			Start-Process -Wait -FilePath 'wt.exe' -ArgumentList "pwsh.exe $pwshArguments" -Verb runas
		}
		else {
			Start-Process -Wait -FilePath 'pwsh.exe' -ArgumentList $pwshArguments -Verb runas
		}
	} else {
		if ($EshellUI.Im.Sudo) {
			Invoke-Expression "$RemainingArguments"
			return
		}
		# Otherwise, run the command as an admin
		$UUID=$(New-Guid).Guid
		$ShadowCommand = "__SudoShadow__ -UUID '$UUID' -Command '$(pwsh_args_convert $RemainingArguments)'"
		if (Test-Command wt.exe) {
			$Arguments = @('pwsh','-Command', $ShadowCommand)
			$Arguments = cmd_args_convert $Arguments
			Start-Process -Wait -FilePath 'wt.exe' -ArgumentList $Arguments.Replace('"','\"') -Verb runas
		}
		else {
			$Arguments = @('-Command', $ShadowCommand)
			$Arguments = cmd_args_convert $Arguments
			Start-Process -Wait -FilePath 'pwsh.exe' -ArgumentList "$pwshArguments $Arguments" -Verb runas
		}
		try {
			$Shadow=Get-Content "$env:Temp/sudo_shadows/$UUID.txt"
			Remove-Item "$env:Temp/sudo_shadows/$UUID.txt"
			$Shadow = $Shadow | Select-Object -Skip 4 -SkipLast 4
			#由于Start-Transcript会将宽字符重复写入，所以对于每一个字符在$Shadow中进行渲染以获取其宽度，去除多余的字符
			$Shadow = $Shadow -join "`n"
			$Font = New-Object System.Drawing.Font('cascadia mono', 128)
			$Width = 0
			$ShadowHandled=($Shadow.ToCharArray() | ForEach-Object {
				if($Width -eq 0) {
					$Width = [Math]::Max([Math]::Floor(
						[System.Windows.Forms.TextRenderer]::MeasureText($_, $Font).Width
					/128)-1,0)
				}
				elseif($_ -eq $LastChar) { $Width--;return }
				else{ $UseOriginal = $true }
				$LastChar = $_
				$_
			}) -join ''
			if($UseOriginal) { $ShadowHandled = $Shadow }
			Write-Host $ShadowHandled
		}
		catch {
			Write-Warning "Failed to get sudo shadow."
		}
	}
}
function global:mklink {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	#对于每个参数
	$RemainingArguments = $RemainingArguments | ForEach-Object {
		#若参数长度不是2且是linux路径
		if (($_.Length -ne 2) -and (IsLinuxPath $_)) {
			#转换为windows路径
			LinuxPathToWindowsPath $_
		}
		else {
			$_
		}
	}
	#调用cmd的mklink
	. cmd /c mklink $RemainingArguments
}
function global:reboot {
	#重启
	shutdown.exe /r /t 0
}
function global:shutdown {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	if ($RemainingArguments.Length -eq 0) {
		#默认为立即关机
		shutdown.exe /s /t 0
	}
	else {
		#关机
		shutdown.exe $RemainingArguments
	}
}
Set-Alias poweroff shutdown -Scope global

function global:poweron {
	Write-Host 'This computer is already powered on.'
}
function global:power {
	param(
		#off / on
		[ValidateSet('off','on')]
		[string]$action
	)
	switch ($action) {
		'off' { poweroff }
		'on' { poweron }
		default {
			Write-Host "I'm the storm that's $($VirtualTerminal.Styles.Blink)approaching!!!!!!!!!!!!!!!!!!!!`nApproaching!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!$($VirtualTerminal.Styles.NoBlink)"
		}
	}
}

if ($EshellUI.Im.VSCodeExtension) {
	function global:exit { #抠我退出键是吧
		param(
			[Parameter(ValueFromRemainingArguments = $true)]
			$exitCode = 0
		)
		[System.Environment]::Exit($exitCode)
	}
}

function global:reload { $EshellUI.Reload() }
