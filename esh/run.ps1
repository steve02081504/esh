if (-not $EshellUI) {
	. $PSScriptRoot/main.ps1
}
if (-not $EshellUI.State.Started) {
	$EshellUI.Init($MyInvocation)
	$EshellUI.LoadVariables()
	$EshellUI.Start()
}
if ($EshellUI.Im.InScope) {
	$global:EshellUI ??= $EshellUI
}
if ($EshellUI.GetFromOf($MyInvocation).FileExplorer) {
	# 该代码由用户点击脚本执行 我们需要启动repl而不是退出
	Write-Warning "Running esh in self-hosted REPL mode."
	$EshellUI.repl($true)
}
