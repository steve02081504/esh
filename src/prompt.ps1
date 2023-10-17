. $PSScriptRoot\prompt.base.ps1
. $PSScriptRoot\prompt.builders.ps1

function global:prompt {
	$shortPath = $PWD.Path
	if (($shortPath.StartsWith($HOME)) -or ($shortPath.StartsWith(${MSYS.RootPath}))) {
		$shortPath = WindowsPathToLinuxPath $shortPath
	}
	$prompt_str = $shortPath

	$prompt_str = GitPromptBuilder $prompt_str
	$prompt_str = NpmPromptBuilder $prompt_str
	$prompt_str = UkagakaPromptBuilder $prompt_str

	$prompt_str = PromptNewlineCheck $prompt_str
	"$prompt_str ${VirtualTerminal.Colors.Reset}>"
}
