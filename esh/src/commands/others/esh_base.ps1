function global:EShell {
	pwsh -nologo $(if ($PSVersionTable.PSVersion -gt 7.3) { "-NoProfileLoadTime" })
}
#设定别名esh
Set-Alias esh EShell -Scope global

. "$($EshellUI.Sources.Path)/src/scripts/shell_args_convert.ps1"
function global:sudo {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	$pwshArguments = "$(if($PSVersionTable.PSVersion -gt 7.3){`"-NoProfileLoadTime`"}) -nologo"
	if ($RemainingArguments.Length -eq 0) {
		if ($EshellUI.Im.Sudo) {
			Write-Host "I already have ${VirtualTerminal.Styles.Blink}Super Power${VirtualTerminal.Styles.NoBlink}s."
		}
		# If the command is empty, open a new PowerShell shell with admin privileges
		elseif (Test-Command wt.exe) {
			Start-Process -Wait -FilePath "wt.exe" -ArgumentList "pwsh.exe $pwshArguments" -Verb runas
		}
		else {
			Start-Process -Wait -FilePath "pwsh.exe" -ArgumentList $pwshArguments -Verb runas
		}
	} else {
		if ($EshellUI.Im.Sudo) {
			Invoke-Expression "$RemainingArguments"
		}
		# Otherwise, run the command as an admin
		elseif (Test-Command wt.exe) {
			$Arguments = @("pwsh","-Command",$(pwsh_args_convert ($RemainingArguments)))
			$Arguments = cmd_args_convert ($Arguments)
			Start-Process -Wait -FilePath "wt.exe" -ArgumentList $Arguments.Replace('"','\"') -Verb runas
		}
		else {
			$Arguments = @("-Command",$(pwsh_args_convert ($RemainingArguments)))
			$Arguments = cmd_args_convert ($Arguments)
			Start-Process -Wait -FilePath "pwsh.exe" -ArgumentList "$pwshArguments $Arguments" -Verb runas
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
		if (($_.Length -ne 2) -and (IsLinuxPath ($_))) {
			#转换为windows路径
			LinuxPathToWindowsPath ($_)
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
Set-Alias global:poweroff shutdown

function global:poweron {
	Write-Host "This computer is already powered on."
}
function global:power {
	param(
		#off / on
		[ValidateSet("off","on")]
		[string]$action
	)
	switch ($action) {
		"off" { poweroff }
		"on" { poweron }
		default {
			Write-Host "I'm the storm that's ${VirtualTerminal.Styles.Blink}approaching!!!!!!!!!!!!!!!!!!!!`nApproaching!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${VirtualTerminal.Styles.NoBlink}"
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
