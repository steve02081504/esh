Add-Type @"
	using System;
	using System.Runtime.InteropServices;
	public class Win32 {
		[DllImport("user32.dll", CharSet = CharSet.Auto)]
		public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
		// 检测窗口焦点
		[DllImport("user32.dll", SetLastError=true)]
		public static extern IntPtr GetWindowThreadProcessId(IntPtr hWnd, out IntPtr processId);
		[DllImport("user32.dll")]
		public static extern IntPtr GetForegroundWindow();
		public static IntPtr GetForegroundProcessId() {
			IntPtr hwnd = GetForegroundWindow();
			IntPtr pid;
			GetWindowThreadProcessId(hwnd, out pid);
			return pid;
		}
		// GetConsoleWindow
		[DllImport("kernel32.dll", ExactSpelling = true)]
		public static extern IntPtr GetConsoleWindow();
	}
"@

# 设置窗口icon
function Set-WindowIcon ($hWnd, $iconPath) {
	$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
	$hIcon = $icon.Handle
	$WM_SETICON = 0x0080
	$ICON_SMALL = 0
	$ICON_BIG = 1
	[Win32]::SendMessage($hWnd, $WM_SETICON, $ICON_SMALL, $hIcon) | Out-Null
	[Win32]::SendMessage($hWnd, $WM_SETICON, $ICON_BIG, $hIcon) | Out-Null
	$icon.Dispose()
}

# 封装函数
function Set-ConsoleIcon ($iconPath) {
	$hWnd = [Win32]::GetConsoleWindow()
	Set-WindowIcon $hWnd $iconPath
}
