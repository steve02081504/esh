# esh  

原本只是个人配置文件来着 写着写着面向对象了 再写着写着成了一个方便安装的配置包 再写着写着有点像一个基于另一个shell的shell了  
究竟是为什么呢  

## 使用方法  

- 在windows terminal中将字体设置为[`FriaCode Nerd Font`](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip)
- 运行`opt/install`：参见下方的快速开始命令
- 如果你把它加进了pwsh配置文件，你或许还想追加`-NoProfileLoadTime -nologo`到pwsh启动参数中
- 修改`$EshellUI.MSYS.RootPath`为你的msys2安装路径并`$EshellUI.SaveVariables()`
- 视需要修改其他文件内容

## 快速开始

运行`opt/install`以快速开始（你甚至不需要clone这个项目）：

```powershell
& { (Invoke-WebRequest https://bit.ly/EshInstall).Content | Invoke-Expression }

```

![图片](https://github.com/steve02081504/esh/assets/31927825/39cdadc2-60e6-43f9-bcfc-ef5f973bd12d)

或者通过git进行安装（**一旦安装后删除esh文件夹将导致esh无法正常运行和卸载**）：

```bash
git clone https://github.com/steve02081504/esh && cd esh && ./opt/install

```

如果你正在使用它，你可以这样更新（或者直接通过git来pull）：

```powershell
Update-Eshell

```

这将清除`esh/src`文件夹和`esh/data/SAO-lib.txt`并重新下载最新的esh和SAO-lib

## 功能预览  

最低兼容PS7.2.15和Windows 6.1.7601（自动纠正编码设置）  
![图片](https://github.com/steve02081504/esh/assets/31927825/e87b0407-f874-4d33-9a04-bda6f8c1658c)

支持VSCode的powershell扩展  
tips: 配置`Microsoft.VSCode_profile.ps1`可以让你**仅**在VSCode中自动加载esh，而不会影响到你的日常pwsh使用  
![图片](https://github.com/steve02081504/esh/assets/31927825/8b51aa95-3e86-42ad-af2f-045c748d3937)

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

![图片](https://github.com/steve02081504/esh/assets/31927825/7f2f81a7-f48d-4b4b-a824-29a1aca8ce04)

一键更新所有包管理器的所有软件包！

![图片](https://github.com/steve02081504/esh/assets/31927825/55b75796-0745-4900-b596-d1f2e7decadb)

由于我懒，`dirsync`等其他命令不做介绍，请自行查看`$EshellUI.ProvidedFunctions()`

## 目录结构

```tree
───esh
   ├───.github #github配置文件夹
   │   └───workflows #github actions配置文件夹
   ├───.vscode #vscode配置文件夹
   ├───data #数据文件夹
   │   ├───SAO-lib.txt #SAO-lib骚话库
   │   ├───formatxml #xml格式化数据
   │   └───vars #变量数据存储
   ├───src #esh源码
   │   ├───system #esh基础架构文件夹
   │   │   └───UI #UI文件夹
   │   │       └───prompt #提示符构建文件夹
   │   │           └───builders #提示符构建器文件夹
   │   ├───commands #命令脚本文件夹
   │   │   └───special #特殊命令脚本
   │   ├───opt #安装 卸载 启动脚本 基础文件
   │   └───scripts #收录脚本工具
   ├───img #图片资源
   ├───opt #安装 卸载 启动脚本
   └───path #用于加入环境变量的文件夹
```

### 卸载

如果你想卸载esh，你可以运行`esh -Command $EshellUI.RunUnInstall()`
或者如同安装时一样运行`opt/uninstall`：

```powershell
& { (Invoke-WebRequest https://bit.ly/EshUnInstall).Content | Invoke-Expression }

```

或者

```pwsh
cd $EshellUI.Sources.Path
./opt/uninstall

```

## Q&A

### esh和pwsh的关系是？

简单来说，鸿蒙和安卓的关系  
esh是一个基于pwsh的由ps编写的一大堆脚本，你可以把它加入环境变量当作shell使用，它使用pwsh的语法和命令，但是它有自己的UI和一些特性  
你也可以像这个项目本来的用途一样，将它作为pwsh的配置文件使用，这样你就可以让你的pwsh和esh一模一样了  

### 为什么不基于bash？

这个项目的原名是`my-powershell-profile`。  
就只是我一开始在用pwsh，仅此而已。

### 你为什么不用bash？

语法反人类。

### 你为什么不用zsh/fish/其他shell？

没听过。

### 这个项目的目的是什么？

有句古话叫做“兵欲善其事，必先利其器”。  
我想要一个更好的工作环境。

### 你为什么不用cmd？

你玩原神吗？

### 为什么esh固定显示`v1960.7.17`？这对你来说有什么意义吗？

cooool就对了  
意义是啥我也不知道

### 这个shell不够严谨 整活内容太多了

你说得对 关我啥事 我自己开心

### 为什么你的代码这么烂

糊屎 爽 能跑就行  
有高见欢迎提交pr

### E-tek是真实存在的公司吗？

cooool就对了  
我瞎写的 不过你如果查一下的话会发现这个公司是真的存在的 做牛肉  

### esh和SAO-lib是什么关系？

SAO-lib是一个公开的骚话库，esh使用它来随机骚话显示在logo下方  

### 为什么你的骚话库里有这么多骚话？

？

### 你为什么不用linux而是用微软的技术栈？你是不是不喜欢开源？

别笑 真有这种人
