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

if defined command (
	set "command=!command:"=""!"
)
if defined File (
	set "File=!File:"=""!"
)

if defined command (
	if defined File (
		pwsh !remainingArgs! -nologo -Command ". %~dp0\run.ps1; . !File!; Invoke-Expression !command!"
	) else (
		pwsh !remainingArgs! -nologo -Command ". %~dp0\run.ps1; Invoke-Expression !command!"
	)
) else (
	if defined File (
		pwsh !remainingArgs! -nologo -Command ". %~dp0\run.ps1; . !File!"
	) else (
		pwsh !remainingArgs! -nologo -NoExit -File "%~dp0\run.ps1"
	)
)

@echo on
@exit /b %ERRORLEVEL%
