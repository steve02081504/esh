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
		if "%%i"=="-Command" (
			set "hasCommand=true"
		) else (
			set "remainingArgs=!remainingArgs! %%i"
		)
	)
)

if defined command (
	pwsh !remainingArgs! -nologo -Command ". %~dp0\run.ps1; Invoke-Expression !command!"
) else (
	pwsh !remainingArgs! -nologo -NoExit -File "%~dp0\run.ps1"
)

@echo on
@exit /b %ERRORLEVEL%
