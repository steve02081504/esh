@echo off
setlocal enabledelayedexpansion

rem shift also shifts %0, so capture %~dp0 before the parse loop.
set "SCRIPT_DIR=%~dp0"

set "hasCommand="
set "hasFile="
set "command="
set "remainingArgs="

:parse
if "%~1"=="" goto :parsed
set "arg=%~1"
if defined hasCommand (
	set "command=!arg!"
	set "hasCommand="
) else (
	if defined hasFile (
		set "hasFile="
		set "remainingArgs=!remainingArgs! !arg!"
	) else (
		if "!arg!"=="-Command" (
			set "hasCommand=true"
		) else (
			if "!arg!"=="-File" (
				set "hasFile=true"
			) else (
				set "remainingArgs=!remainingArgs! !arg!"
			)
		)
	)
)
shift
goto :parse

:parsed
set "Noexit=-NoExit"
set "pwshCommand="
set "NoLogo="

if defined File (
	set "File=!File:"=""!"
	set "pwshCommand=!pwshCommand! ; . !File!"
	set "Noexit="
	set "NoLogo= -Nologo"
)
if defined command (
	set "command=!command:"=""!"
	set "pwshCommand=!pwshCommand! ; Invoke-Expression !command!"
	set "Noexit="
	set "NoLogo= -Nologo"
)

pwsh.exe %remainingArgs% %Noexit% -nologo -Command ". %SCRIPT_DIR%run.ps1!NoLogo!!pwshCommand!"

@echo on
@exit /b %ERRORLEVEL%
