function EShell {
	pwsh.exe -NoProfileLoadTime -nologo
}
#设定别名esh
Set-Alias esh EShell
function sudo {
	param(
		[string]$Command
	)
	if ([string]::IsNullOrWhiteSpace($Command)) {
		# If the command is empty, open a new PowerShell shell with admin privileges
		Start-Process -Wait -FilePath "wt.exe" -ArgumentList "pwsh.exe -NoProfileLoadTime -nologo" -Verb runas
	} else {
		# Otherwise, run the command as an admin
		Start-Process -Wait -FilePath "wt.exe" -ArgumentList "$Command" -Verb runas
	}
}
function mklink {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$RemainingArguments
	)
	#对于每个参数
	$RemainingArguments = $RemainingArguments | ForEach-Object {
		#若参数长度大于2且是linux路径
		if (($_.Length -gt 2) -and (IsLinuxPath($_))) {
			#转换为windows路径
			LinuxPathToWindowsPath($_)
		}
		else{
			$_
		}
	}
	#调用cmd的mklink
	. cmd /c mklink $RemainingArguments
}
