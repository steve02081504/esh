# My powershell profile  

只是个人配置文件。

## 使用方法  

- clone后放置于`~/Documents/powershell`
- 在windows terminal中将字体设置为[`FriaCode Nerd Font`](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip)
- 你或许想追加`-NoProfileLoadTime -nologo`到powershell启动参数中
- 修改`src/linux.ps1`中的msys路径
- 视需要修改其他文件内容
- 启动shell

## 快速开始

将以下命令复制粘贴到powershell中以快速开始  
注意：**这将清除你现在的powershell配置文件和已经安装的模块**

```powershell
$PwshProFiles = Split-Path $PROFILE
$ParentPath = Split-Path $PwshProFiles
Remove-Item $PwshProFiles -Confirm -ErrorAction SilentlyContinue
Remove-Item $ParentPath\my-powershell-profile-master -Force -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri https://github.com/steve02081504/my-powershell-profile/archive/refs/heads/master.zip -OutFile Eshell.zip
Expand-Archive -Path Eshell.zip -DestinationPath $ParentPath -Force
Rename-Item $ParentPath\my-powershell-profile-master PowerShell -Force
Remove-Item Eshell.zip -Force
pwsh -nologo $(if($PSVersionTable.PSVersion -gt 7.3){"-NoProfileLoadTime"}) && $(exit)

```

## 功能预览  

最低兼容PS7.2.15和Windows 6.1.7601（自动纠正编码设置）
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/e87b0407-f874-4d33-9a04-bda6f8c1658c)

### 提示符

git提示符支持  
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/24808f4d-c1a1-48b0-94a6-da45b6cc4510)

npm提示符支持  
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/66c1732c-da1b-4d62-ad00-93852dc65529)

ukagaka提示符支持  
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/9c3620ca-f15d-4a7d-8e5a-b0d321e58aab)

可以通过修改`src/prompt.builders`来便捷自定义提示符

### 命令

rm、ls、cd、mv等常见文件操作命令支持linux和powershell两种风格调用  
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/fdf5e98a-5532-4318-9a81-c5337c6d323a)

linux路径支持（包括补全和索引command）  
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/cedc3d38-de89-4c9e-aa97-4bd5fb83dff5)

自动检索AppData
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/08eeaea8-5050-4378-91a2-45713b4b6915)

### 便捷指令

`poweroff`或`power off`关机（`shutdown`也可以不带参数被调用）  
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/a164e5df-661f-47fa-a0fb-364349443410)

不用打开cmd，`mklink`也可以直接被使用（并且支持linux路径）  
![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/d8160647-ce17-4d1a-aca6-eafd48819d8d)

你说得对，但是`sudo`是由前面我忘了 后面我也忘了  

```bash
mkdir superhavyrock && echo 1000-7 > superhavyrock\rockcore
icacls superhavyrock /grant:r Administrators:F
icacls superhavyrock /inheritance:r
rm -rf superhavyrock
```

![图片](https://github.com/steve02081504/my-powershell-profile/assets/31927825/b0b3a4ed-f6fd-446e-a65b-602399bd0abe)

由于我懒，`dirsync`等其他命令不做介绍，请自行查看`src/other`文件
