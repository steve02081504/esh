@echo off
setlocal enabledelayedexpansion

set "hasCommand="
set "command="
set "remainingArgs="
for %%i in (%*) do (
	if defined hasCommand (
		set "command=%%i"
		set "hasCommand="
	) else (
		if defined hasFile (
			set "hasFile="
			set "remainingArgs=!remainingArgs! %%i"
		) else (
			if "%%i"=="-Command" (
				set "hasCommand=true"
			) else (
				if "%%i"=="-File" (
					set "hasFile=true"
				) else (
					set "remainingArgs=!remainingArgs! %%i"
				)
			)
		)
	)
)

set "Noexit=-NoExit"
set "pwshCommand="

if defined File (
	set "File=!File:"=""!"
	set "pwshCommand=!pwshCommand! ; . !File!"
	set "Noexit="
)
if defined command (
	set "command=!command:"=""!"
	set "pwshCommand=!pwshCommand! ; Invoke-Expression !command!"
	set "Noexit="
)

pwsh.exe %remainingArgs% %Noexit% -nologo -Command ". %~dp0\run.ps1; !pwshCommand!"

@echo on
@exit /b %ERRORLEVEL%
