---

title:  "小工具开发笔记—IE自动填表器 -- 序"
date:   2010-09-05
categories: coding
description: "本文讲述如何使用C++开发IE插件以用于自动填表"
summary: "此工具的开发契机是由于家人需要频繁使用招商银行在线支付系统—众所周知—招行在线支付使用了ActiveX控件，导致每次输入只能手写卡号密码（不能复制粘贴），而卡号比较长，容易输错，故久而久之就有了动手开发辅助工具来自动填表的念头。"
---

*本文转自笔者的博客园，保留了当时的写作日期*

###系列导航###
- 小工具开发笔记—IE自动填表器 -- 序
- [小工具开发笔记—IE自动填表器 -- 你好，世界]({% post_url 2010-09-07-cpp-develop-ie-auto-fill-form-plugin-hello-world %})
- [小工具开发笔记—IE自动填表器 -- 执行JavaScript]({% post_url 2013-03-10-cpp-develop-ie-auto-fill-form-plugin-eval %})

---

小生不才，花费了一周时间（7天×10小时）完成了一个小工具--IE自动填表器。那么就献丑来详解一下开发的全过程吧，希望对有兴趣的看官有所帮助！

* 软件类别：IE插件
* 开发语言：C++
* 开发环境：Visual Studio 2010
* 运行环境：
  * 操作系统：Windows XP/2003 (R2)/Vista/7/2008 (R2)
  * IE版本：6/7/8
  * 运行时：GDI+/XmlLite/Accessibility
* 软件架构：x86, x64(WOW)
* 授权说明：MS-PL
* 程序下载：[http://nport.codeplex.com/releases/view/51863](http://nport.codeplex.com/releases/view/51863)
* 源码下载：[http://nport.codeplex.com/SourceControl/changeset/view/50207#1022227](http://nport.codeplex.com/SourceControl/changeset/view/50207#1022227)
* 程序功能：
  * 预先定义数据，自动填写表单(Form)
  * 可自动填写常用HTML控件
  * 可自动填写ActiveX控件
  * 可自动识别验证码（注：此功能使用HP和Google开源OCR引擎）

程序截图若干张：

**Binaries**

![2d95ae06]({{ site.BASE_PATH }}/assets/cloud/2010/2d95ae06.png)

**IE6**

![67db0d40]({{ site.BASE_PATH }}/assets/cloud/2010/67db0d40.jpg)


**IE7**

![9ebfd283]({{ site.BASE_PATH }}/assets/cloud/2010/9ebfd283.jpg)

**IE8**

![3e5467b9]({{ site.BASE_PATH }}/assets/cloud/2010/3e5467b9.jpg)

![6009e63e]({{ site.BASE_PATH }}/assets/cloud/2010/6009e63e.jpg)

此工具的开发契机是由于家人需要频繁使用招商银行在线支付系统—众所周知—招行在线支付使用了ActiveX控件，导致每次输入只能手写卡号密码（不能复制粘贴），而卡号比较长，容易输错，故久而久之就有了动手开发辅助工具来自动填表的念头。其实早在三年前，小生已经使用C#开发了一个[简洁版的只针对招行的自动填表工具](http://nport.codeplex.com/SourceControl/changeset/view/50211#604842)（WPF + UI Automation）。直到目前完成此工具，之前那款才光荣退休。其实在这次动手编码之前，是考量过市面上同类型产品的，比较出名的是[马桶智能填表](http://www.maxthon.cn/overview.htm)和[火狐自动填表](https://addons.mozilla.org/en-US/firefox/addon/4775/)。但是前者不支持ActiveX填写和验证码识别，后者索性没有ActiveX这种东东（招行只支持IE浏览器`-_-|||`）。所以最终还是自己动手，丰衣足食！

在阅读后续开发内容之前，看官最好了解以下基础知识，这样才能更好的接受和理解本文。

  * `C++/STL`：这是必须的，程序完全使用C++开发，完全面向对象编程，大量使用了STL模板。
  * `C++0X`：这是即C++98标准以来又一新标准，目前还在初期阶段，微软VC10已经实现了部分C++0X功能。
  * `COM/ATL`：这是Windows平台独有技术，只要知道程序是基于COM就行。
  * `GDI+/XmlLite/Accessibility`：这些都是Windows平台独有技术，程序会使用到，了解即可。
  * `API Hook`：API钩子是很古老并且通用的技术，程序使用了[微软实验室的Detours类库](http://research.microsoft.com/en-us/projects/detours/)。
  * `OCR`：简单来说，就是图像识别技术，程序使用了[HP和Google开源OCR引擎](http://code.google.com/p/tesseract-ocr/)来实现验证码自动识别。

OK，序章就到此为止。我将会把整个开发过程份为若干个章节（章节数待定）在近期一一贴出。看官既可以把本文当作一个“技术”苦旅，也可以看作是一个拓展思想、思路的读物。因为我不仅会写道“怎么做”，还会写道“为什么这样做”。