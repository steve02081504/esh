function global:Install-Copilot {
	if (-not (Test-Command gh)) {
		#github cli not found
		if (Test-Command winget) {
			try {
				winget install GitHub.cli
				gh extension install github/gh-copilot
			} catch {
				#install failed
				Write-Error "Error: Install github cli failed."
				throw
			}
		}
		else {
			#winget not found
			Write-Error "Please install github cli first."
			throw
		}
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
