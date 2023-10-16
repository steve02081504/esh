if ($Host.UI.SupportsVirtualTerminal) {

	${VirtualTerminal.Escape} = [char]27 + '['
	${VirtualTerminal.Colors.Black} = ${VirtualTerminal.Escape} + '30m'
	${VirtualTerminal.Colors.Red} = ${VirtualTerminal.Escape} + '31m'
	${VirtualTerminal.Colors.Green} = ${VirtualTerminal.Escape} + '32m'
	${VirtualTerminal.Colors.Yellow} = ${VirtualTerminal.Escape} + '33m'
	${VirtualTerminal.Colors.Blue} = ${VirtualTerminal.Escape} + '34m'
	${VirtualTerminal.Colors.Magenta} = ${VirtualTerminal.Escape} + '35m'
	${VirtualTerminal.Colors.Cyan} = ${VirtualTerminal.Escape} + '36m'
	${VirtualTerminal.Colors.White} = ${VirtualTerminal.Escape} + '37m'
	${VirtualTerminal.Colors.Default} = ${VirtualTerminal.Escape} + '39m'
	${VirtualTerminal.Colors.BrightBlack} = ${VirtualTerminal.Escape} + '90m'
	${VirtualTerminal.Colors.BrightRed} = ${VirtualTerminal.Escape} + '91m'
	${VirtualTerminal.Colors.BrightGreen} = ${VirtualTerminal.Escape} + '92m'
	${VirtualTerminal.Colors.BrightYellow} = ${VirtualTerminal.Escape} + '93m'
	${VirtualTerminal.Colors.BrightBlue} = ${VirtualTerminal.Escape} + '94m'
	${VirtualTerminal.Colors.BrightMagenta} = ${VirtualTerminal.Escape} + '95m'
	${VirtualTerminal.Colors.BrightCyan} = ${VirtualTerminal.Escape} + '96m'
	${VirtualTerminal.Colors.BrightWhite} = ${VirtualTerminal.Escape} + '97m'

	#斜体、下划线、闪烁、反显、隐藏
	${VirtualTerminal.Styles.Italic} = ${VirtualTerminal.Escape} + '3m'
	${VirtualTerminal.Styles.Underline} = ${VirtualTerminal.Escape} + '4m'
	${VirtualTerminal.Styles.Blink} = ${VirtualTerminal.Escape} + '5m'
	${VirtualTerminal.Styles.Reverse} = ${VirtualTerminal.Escape} + '7m'
	${VirtualTerminal.Styles.Hide} = ${VirtualTerminal.Escape} + '8m'
	${VirtualTerminal.Styles.NoItalic} = ${VirtualTerminal.Escape} + '23m'
	${VirtualTerminal.Styles.NoUnderline} = ${VirtualTerminal.Escape} + '24m'
	${VirtualTerminal.Styles.NoBlink} = ${VirtualTerminal.Escape} + '25m'
	${VirtualTerminal.Styles.NoReverse} = ${VirtualTerminal.Escape} + '27m'
	${VirtualTerminal.Styles.NoHide} = ${VirtualTerminal.Escape} + '28m'

	${VirtualTerminal.ResetAll} = ${VirtualTerminal.Escape} + '0m'
	${VirtualTerminal.ResetColors} = ${VirtualTerminal.Escape} + '39m'
	${VirtualTerminal.ResetStyles} = ${VirtualTerminal.Escape} + '23m'
	${VirtualTerminal.Colors.Reset} = ${VirtualTerminal.ResetColors}
	${VirtualTerminal.Styles.Reset} = ${VirtualTerminal.ResetStyles}

	#保存当前光标位置
	${VirtualTerminal.SaveCursor} = ${VirtualTerminal.Escape} + 's'
	#恢复光标位置
	${VirtualTerminal.RestoreCursor} = ${VirtualTerminal.Escape} + 'u'
	#清除从光标到行尾的内容
	${VirtualTerminal.ClearLine} = ${VirtualTerminal.Escape} + 'K'
	#清除从光标到行首的内容
	${VirtualTerminal.ClearLineLeft} = ${VirtualTerminal.Escape} + '1K'
	#清除整行
	${VirtualTerminal.ClearLineAll} = ${VirtualTerminal.Escape} + '2K'
	#清除从光标到屏幕底部的内容
	${VirtualTerminal.ClearScreenDown} = ${VirtualTerminal.Escape} + 'J'
	#清除从屏幕顶部到光标的内容
	${VirtualTerminal.ClearScreenUp} = ${VirtualTerminal.Escape} + '1J'
	#清除整屏
	${VirtualTerminal.ClearScreenAll} = ${VirtualTerminal.Escape} + '2J'

}
