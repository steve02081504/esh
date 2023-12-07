function global:Install-Copilot {
	if (-not (Test-Command gh)) {
		#github cli not found
		if (Test-Command winget) {
			try { winget install GitHub.cli }
			catch {
				Out-Error 'Install github cli failed.'
				throw
			}
		}
		else {
			#winget not found
			try {
				Import-Module Appx -UseWindowsPowerShell
				Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
			}
			catch {
				Out-Error 'Install github cli -> Install winget failed.'
				throw
			}
		}
	}
	if (-not(gh extension list | Select-String 'github/gh-copilot')) {
		gh extension install github/gh-copilot
	}
}

function global:Copilot {
	try { Install-Copilot } catch { return }
	gh copilot suggest -t shell @args
}

function global:Copilot.GitHub {
	try { Install-Copilot } catch { return }
	gh copilot suggest -t gh @args
}

function global:Copilot.Git {
	try { Install-Copilot } catch { return }
	gh copilot suggest -t git @args
}

function global:Copilot.Explain {
	try { Install-Copilot } catch { return }
	gh copilot explain @args
}
