if ($Host.UI.SupportsVirtualTerminal) {

	${global:VirtualTerminal.Escape} = [char]27 + '['
	${global:VirtualTerminal.Colors.Black} = ${VirtualTerminal.Escape} + '30m'
	${global:VirtualTerminal.Colors.Red} = ${VirtualTerminal.Escape} + '31m'
	${global:VirtualTerminal.Colors.Green} = ${VirtualTerminal.Escape} + '32m'
	${global:VirtualTerminal.Colors.Yellow} = ${VirtualTerminal.Escape} + '33m'
	${global:VirtualTerminal.Colors.Blue} = ${VirtualTerminal.Escape} + '34m'
	${global:VirtualTerminal.Colors.Magenta} = ${VirtualTerminal.Escape} + '35m'
	${global:VirtualTerminal.Colors.Cyan} = ${VirtualTerminal.Escape} + '36m'
	${global:VirtualTerminal.Colors.White} = ${VirtualTerminal.Escape} + '37m'
	${global:VirtualTerminal.Colors.Default} = ${VirtualTerminal.Escape} + '39m'
	${global:VirtualTerminal.Colors.BrightBlack} = ${VirtualTerminal.Escape} + '90m'
	${global:VirtualTerminal.Colors.BrightRed} = ${VirtualTerminal.Escape} + '91m'
	${global:VirtualTerminal.Colors.BrightGreen} = ${VirtualTerminal.Escape} + '92m'
	${global:VirtualTerminal.Colors.BrightYellow} = ${VirtualTerminal.Escape} + '93m'
	${global:VirtualTerminal.Colors.BrightBlue} = ${VirtualTerminal.Escape} + '94m'
	${global:VirtualTerminal.Colors.BrightMagenta} = ${VirtualTerminal.Escape} + '95m'
	${global:VirtualTerminal.Colors.BrightCyan} = ${VirtualTerminal.Escape} + '96m'
	${global:VirtualTerminal.Colors.BrightWhite} = ${VirtualTerminal.Escape} + '97m'

	#斜体、下划线、闪烁、反显、隐藏
	${global:VirtualTerminal.Styles.Italic} = ${VirtualTerminal.Escape} + '3m'
	${global:VirtualTerminal.Styles.Underline} = ${VirtualTerminal.Escape} + '4m'
	${global:VirtualTerminal.Styles.Blink} = ${VirtualTerminal.Escape} + '5m'
	${global:VirtualTerminal.Styles.Reverse} = ${VirtualTerminal.Escape} + '7m'
	${global:VirtualTerminal.Styles.Hide} = ${VirtualTerminal.Escape} + '8m'
	${global:VirtualTerminal.Styles.NoItalic} = ${VirtualTerminal.Escape} + '23m'
	${global:VirtualTerminal.Styles.NoUnderline} = ${VirtualTerminal.Escape} + '24m'
	${global:VirtualTerminal.Styles.NoBlink} = ${VirtualTerminal.Escape} + '25m'
	${global:VirtualTerminal.Styles.NoReverse} = ${VirtualTerminal.Escape} + '27m'
	${global:VirtualTerminal.Styles.NoHide} = ${VirtualTerminal.Escape} + '28m'

	${global:VirtualTerminal.ResetAll} = ${VirtualTerminal.Escape} + '0m'
	${global:VirtualTerminal.ResetColors} = ${VirtualTerminal.Escape} + '39m'
	${global:VirtualTerminal.ResetStyles} = ${VirtualTerminal.Escape} + '23m'
	${global:VirtualTerminal.Colors.Reset} = ${VirtualTerminal.ResetColors}
	${global:VirtualTerminal.Styles.Reset} = ${VirtualTerminal.ResetStyles}

	#保存当前光标位置
	${global:VirtualTerminal.SaveCursor} = ${VirtualTerminal.Escape} + 's'
	#恢复光标位置
	${global:VirtualTerminal.RestoreCursor} = ${VirtualTerminal.Escape} + 'u'
	#清除从光标到行尾的内容
	${global:VirtualTerminal.ClearLine} = ${VirtualTerminal.Escape} + 'K'
	#清除从光标到行首的内容
	${global:VirtualTerminal.ClearLineLeft} = ${VirtualTerminal.Escape} + '1K'
	#清除整行
	${global:VirtualTerminal.ClearLineAll} = ${VirtualTerminal.Escape} + '2K'
	#清除从光标到屏幕底部的内容
	${global:VirtualTerminal.ClearScreenDown} = ${VirtualTerminal.Escape} + 'J'
	#清除从屏幕顶部到光标的内容
	${global:VirtualTerminal.ClearScreenUp} = ${VirtualTerminal.Escape} + '1J'
	#清除整屏
	${global:VirtualTerminal.ClearScreenAll} = ${VirtualTerminal.Escape} + '2J'
}
