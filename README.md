# esh  

原本只是个人配置文件来着 写着写着面向对象了 再写着写着成了一个方便安装的配置包  
究竟是为什么呢  

## 使用方法  

- 在windows terminal中将字体设置为[`FriaCode Nerd Font`](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip)
- 你或许想追加`-NoProfileLoadTime -nologo`到powershell启动参数中
- 修改`$EshellUI.MSYS.RootPath`为你的msys2安装路径并`$EshellUI.SaveVariables()`
- 视需要修改其他文件内容
- 使用`add2profile.ps1`将esh添加到你的powershell配置文件中
- 使用`run.ps1`启动esh
- 考虑添加`esh/path`到你的环境变量中

## 快速开始

将以下命令复制粘贴到powershell中以快速开始  

```powershell
(Invoke-WebRequest https://github.com/steve02081504/esh/raw/master/install.ps1).Content | Invoke-Expression

```

![loading preview](https://github.com/steve02081504/esh/assets/31927825/c7ba3f3f-cdb2-4b93-8fdc-2f5901e0ce12)


如果你正在使用它，你可以这样更新：

```powershell
Update-Eshell

```

这将清除`esh/src`文件夹和`esh/data/SAO-lib.txt`并重新下载最新的esh和SAO-lib

## 分开esh和pwsh

想要将esh和pwsh分开来进一步迷惑你的朋友吗？  
参考[`/run.cmd`](./run.cmd)，使用`-NoExit -File`参数来指定pwsh的启动文件而避免将其加入到你的配置文件中  

```cmd
@echo off
pwsh.exe %* -nologo -NoExit -File %~dp0\run.ps1
@echo on

```

如果你已经将`esh/path`添加到了你的环境变量中，你可以直接在bash或cmd和pwsh中`esh`，或在windows terminal中`esh.cmd -WorkingDirectory ~`来启动esh  
![图片](https://github.com/steve02081504/esh/assets/31927825/f017dd02-80bf-4d1e-9cbc-2ee28d43ede9)

## 功能预览  

最低兼容PS7.2.15和Windows 6.1.7601（自动纠正编码设置）  
![图片](https://github.com/steve02081504/esh/assets/31927825/e87b0407-f874-4d33-9a04-bda6f8c1658c)

支持VSCode的powershell扩展  
tips: 配置`Microsoft.VSCode_profile.ps1`可以让你**仅**在VSCode中自动加载esh，而不会影响到你的日常pwsh使用  
![图片](https://github.com/steve02081504/esh/assets/31927825/f32cdef8-a1fc-42f0-ad1b-64ad87f70a05)

### 提示符

git提示符支持  
![图片](https://github.com/steve02081504/esh/assets/31927825/24808f4d-c1a1-48b0-94a6-da45b6cc4510)

npm提示符支持  
![图片](https://github.com/steve02081504/esh/assets/31927825/66c1732c-da1b-4d62-ad00-93852dc65529)

ukagaka提示符支持  
![图片](https://github.com/steve02081504/esh/assets/31927825/9c3620ca-f15d-4a7d-8e5a-b0d321e58aab)

可以通过修改`esh/src/system/UI/prompt/builders`来便捷自定义提示符

### 命令

rm、ls、cd、mv等常见文件操作命令支持linux和powershell两种风格调用（需要将msys2的bin添加到path）  
![图片](https://github.com/steve02081504/esh/assets/31927825/fdf5e98a-5532-4318-9a81-c5337c6d323a)

linux路径支持（包括补全和索引command）  
![图片](https://github.com/steve02081504/esh/assets/31927825/da57f8b3-59cc-461c-89c7-801951038245)

自动检索AppData
![图片](https://github.com/steve02081504/esh/assets/31927825/08eeaea8-5050-4378-91a2-45713b4b6915)

### 便捷指令

`poweroff`或`power off`关机（`shutdown`也可以不带参数被调用）  
![图片](https://github.com/steve02081504/esh/assets/31927825/a164e5df-661f-47fa-a0fb-364349443410)

不用打开cmd，`mklink`也可以直接被使用（并且支持linux路径）  
![图片](https://github.com/steve02081504/esh/assets/31927825/d8160647-ce17-4d1a-aca6-eafd48819d8d)

你说得对，但是`sudo`是由前面我忘了 后面我也忘了  

```bash
mkdir superhavyrock && echo 1000-7 > superhavyrock\rockcore
icacls superhavyrock /grant:r Administrators:F
icacls superhavyrock /inheritance:r
rm -rf superhavyrock
```

![图片](https://github.com/steve02081504/esh/assets/31927825/b0b3a4ed-f6fd-446e-a65b-602399bd0abe)

由于我懒，`dirsync`等其他命令不做介绍，请自行查看`$EshellUI.ProvidedFunctions()`
