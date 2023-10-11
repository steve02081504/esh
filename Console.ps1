# 导入Win32 API函数
Add-Type @"
	using System;
	using System.Runtime.InteropServices;
	public class Win32 {
		[DllImport("user32.dll", CharSet = CharSet.Auto)]
		public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
	}
"@

# 设置窗口icon
function Set-WindowIcon($hWnd, $iconPath) {
	$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
	$hIcon = $icon.Handle
	$WM_SETICON = 0x0080
	$ICON_SMALL = 0
	$ICON_BIG = 1
	[Win32]::SendMessage($hWnd, $WM_SETICON, $ICON_SMALL, $hIcon) | Out-Null
	[Win32]::SendMessage($hWnd, $WM_SETICON, $ICON_BIG, $hIcon) | Out-Null
}

# 封装函数
function Set-ConsoleIcon($iconPath) {
	$hWnd = (Get-Process -id $pid).MainWindowHandle
	Set-WindowIcon $hWnd $iconPath
}
