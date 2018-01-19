---

title:  "小试Linux下C#桌面程序编程"
date:   2010-08-25
categories: coding
description: "本文讲述了Linux下C#程序开发的一次探索"
summary: "接触Linux已经有一段日子了，从Debian的Ubuntu到Redhat的Fedora，再到SUSE，桌面从GNOME到KDE。感觉Linux还真是不错，桌面挺好看的，应用软件也挺多的。终于忍不住想要自己在Linux下写个小程序看看了。OK，有想法就能付诸实现，做个简单的WinForm程序吧，功能是使用调用远程天气预报WebService"
---

*本文转自笔者的博客园，保留了当时的写作日期*

接触Linux已经有一段日子了，从Debian的Ubuntu到Redhat的Fedora，再到SUSE，桌面从GNOME到KDE。感觉Linux还真是不错，桌面挺好看的，应用软件也挺多的。终于忍不住想要自己在Linux下写个小程序看看了。OK，有想法就能付诸实现，做个简单的WinForm程序吧，功能是使用调用远程[天气预报WebService](http://webservice.webxml.com.cn/WebServices/WeatherWS.asmx?wsdl)。

写GUI程序得有一个现成的UI Framework，那么该用哪个呢？Google了一下，有很多答案，不过引起我注意的是Linux下面可以通过Mono运行时来跑.NET Framework的程序。这让我很惊讶，也很好奇。惊讶的是.NET Framework终于可以实现“跨平台”了，好奇的是效果怎么样，真的能用吗？于是使用VS2010 C#.NET创建WinForm工程，添加Web引用，写几行调用代码，华丽丽的完工。且看一下Windows上面的运行效果。

![8a0f0319]({{ site.BASE_PATH }}/assets/cloud/2010/8a0f0319.png)

接着直接复制binary到Ubuntu下面，尝试运行。没成功，出错了。。。

![5bfbd925]({{ site.BASE_PATH }}/assets/cloud/2010/5bfbd925.png)

原来是.NET Framework版本问题，VS2010默认是4.0。那么我试试2.0，再copy过去，打开，还是不行。。。

![b53c2067]({{ site.BASE_PATH }}/assets/cloud/2010/b53c2067.png)

嗯。。。这次是System.Windows.Forms.dll没有找到。查了一下Mono的GAC，确实没有这个dll。不明白为什么没有，Google一下，发现，原来mono-winform是一个额外的包。使用Sympatic Package Manager自动下载安装了如下包，终于可以运行了。

    libgluezilla (version 2.4.3-2) will be installed 
    libmono-accessibility2.0-cil (version 2.4.4~svn151842-1ubuntu4) will be installed 
    libmono-webbrowser0.5-cil (version 2.4.4~svn151842-1ubuntu4) will be installed 
    libmono-winforms2.0-cil (version 2.4.4~svn151842-1ubuntu4) will be installed

![0d56f306]({{ site.BASE_PATH }}/assets/cloud/2010/0d56f306.png)

乱码。。。不对，是框框码，不是乱码。再Google一下，完了，貌似没解决方案，除非把源码挪到Linux下面用mono msc编译，还得指定编译时-codepage:utf8。

文章就先写到这里，等我找到更好的解决办法时再更新此文，也请“知情人士”给出解决方案，谢谢。下次我会写一篇用C++开发同样功能的跨平台的小程序。