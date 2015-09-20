---
layout: post
title:  "小工具开发笔记—IE自动填表器 -- 你好，世界"
date:   2010-09-07
categories: coding
description: "本文讲述如何使用C++开发IE插件以用于自动填表"
summary: "继上篇博文初步介绍了小工具，本文就作为开发笔记正文第一篇，来叙述一下如何使用C++开发一个完整的IE插件。"
---

*本文转自笔者的博客园，保留了当时的写作日期*

###系列导航###
- [小工具开发笔记—IE自动填表器 -- 序]({% post_url 2010-09-05-cpp-develop-ie-auto-fill-form-plugin %})
- 小工具开发笔记—IE自动填表器 -- 你好，世界
- [小工具开发笔记—IE自动填表器 -- 执行JavaScript]({% post_url 2013-03-10-cpp-develop-ie-auto-fill-form-plugin-eval %})

---

继上篇博文初步介绍了小工具，本文就作为开发笔记正文第一篇，来叙述一下如何使用C++开发一个完整的IE插件。在动手编码之前，首先重申一下我的开发目的（即需求和功能）。列表如下：

- 在IE的工具栏里面嵌入一个按钮，效果如图：![061fae9c]({{ site.BASE_PATH }}/assets/cloud/2010/061fae9c.png)
- 当单击这个按钮时，执行自定义事件，我这里定义的事件就是自动填表（为了循序渐进，本文将以一个Hello World窗口为例来演示自定义事件）

目的叙述完毕，准备开工。那么怎么做呢？俗话说：外事找谷歌，内事找百度。咱先百度一下吧，查到一些中文资料，话说IE插件主要分为三种：ActiveX，BHO，Extension。打开自己的IE看一下，果然是唉。

![28862623]({{ site.BASE_PATH }}/assets/cloud/2010/28862623.png)

仔细一看，还多了一种叫做Explorer Bar的东西，其实就是左侧栏的一个导航工具，History和Favorate就是这个类别。再分析一下这三种主要插件：

* ActiveX：一般被用来制作嵌在IE显示层里面的具有丰富UI表现能力的控件，如Silverlight、Flash以及一些网银输入控件（包括万恶的招行），HTML里面使用`<object classid="…" />`标签来显示ActiveX控件。
* [BHO](http://en.wikipedia.org/wiki/Browser_Helper_Object) (Browser Helper Object)：这玩意可以通吃IE以及Windows Explorer，是病毒、木马的根源，一旦BHO被注册之后，即会随IE、Windows Explorer启动。这不是我要找的东西，暂且略过。
* Browser Extension：根据上图及这张图片![b707b94c]({{ site.BASE_PATH }}/assets/cloud/2010/b707b94c.png) 综合分析，可以肯定这就是我要的插件类型！（什么，你问我怎么分析，这个。。。看到不，Blog This, Send to OneNote即在Browser Extension里面出现，又在工具栏里面出现）

继续查资料，这次用谷歌查微软网站，找到一篇[MSDN关于IE添加工具栏的文章](http://msdn.microsoft.com/en-us/library/aa753588(VS.85).aspx)，写的很详细很全。里面提到在IE工具栏里面添加一个按钮只需要修改注册表，增加那么一小段即可，里面的{GUID}可以用工具[guidgen.exe](http://msdn.microsoft.com/en-us/library/ms924300.aspx)自动生成一个。

{% highlight batch %}
HKEY_LOCAL_MACHINE
  Software
    Microsoft
      Internet Explorer
        Extensions
          {GUID}
{% endhighlight %}

- ButtonText – 设置显示在工具栏上面按钮的名字
`HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Extensions\{GUID}\ButtonText`
- HotIcon - 设置显示在工具栏上面按钮的图标
`HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Extensions\{GUID}\HotIcon`
- Icon - 设置显示在工具栏上面按钮的灰色图标（即不可用状态）
`HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Extensions\{GUID}\Icon`
- CLSID - 设为{1FBA04EE-3024-11d2-8F1F-0000F87ABD16}，意思是加载并运行一个COM
`HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Extensions\{GUID}\CLSID`
- ClsidExtension - 设为将要被执行的COM，此对象必须实现IOleCommandTarget接口的IOleCommandTarget::Exec方法以及实现IObjectWithSite接口，下文随机切入正题，我将编码实现这一的一个对象。
`HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Extensions\{GUID}\ClsidExtension`

那么，一份完整的注册表信息如下：

{% highlight batch %}
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Extensions\{77A0B90A-FD44-45B3-ABF3-93F10E80ED4C}]
@="My First IE Extension"
"ButtonText"="Hello World"
"CLSID"="{1FBA04EE-3024-11d2-8F1F-0000F87ABD16}"
"ClsidExtension"="{B73854BF-C89E-44E3-9B54-99D5DD7E948A}"
"Default Visible"="Yes"
"Hot Icon"="D:\\Test\\myicon.ico"
"Icon"="D:\\Test\\myicon.ico"
{% endhighlight %}

将其导入注册表，在此打开IE，便看到了Hello World按钮已经出现。**注：上面的ClsidExtension将用后面代码生成的GUID替换**

![981e4f1b]({{ site.BASE_PATH }}/assets/cloud/2010/981e4f1b.png)
![ce2842cc]({{ site.BASE_PATH }}/assets/cloud/2010/ce2842cc.png)

不过此时COM{B73854BF-C89E-44E3-9B54-99D5DD7E948A}还没有完成，故点击Hello World是没有反应的。好，接下去就是编码了，很容易，我边上图边解释。

**步骤1：创建VC++ATL项目，取名叫HelloWorld，默认配置，直接Finish**

![64a2b173]({{ site.BASE_PATH }}/assets/cloud/2010/64a2b173.png)
![466526e2]({{ site.BASE_PATH }}/assets/cloud/2010/466526e2.png)

**步骤2：选择工程HelloWorld右键Add->Class，选择ATL Simple Object，点击Add**

![f6c24ec1]({{ site.BASE_PATH }}/assets/cloud/2010/f6c24ec1.png)
![43efce5c]({{ site.BASE_PATH }}/assets/cloud/2010/43efce5c.png)

**步骤3：在Short name里面输入Sample，确保IObjectWithSite勾上，向导会产生一个CSample类**

![2c8f9a71]({{ site.BASE_PATH }}/assets/cloud/2010/2c8f9a71.png)
![a9e5aa2d]({{ site.BASE_PATH }}/assets/cloud/2010/a9e5aa2d.png)

**步骤4：修改CExample.h文件，添加IOleCommandTarget接口**

 



{% highlight c++ %}
 class ATL_NO_VTABLE CExample :
     public CComObjectRootEx<CComSingleThreadModel>,
     public CComCoClass<CExample, &CLSID_Example>,
     public IObjectWithSiteImpl<CExample>,
     public IDispatchImpl<IExample, &IID_IExample, &LIBID_HelloWorldLib, /*wMajor =*/ 1, /*wMinor =*/ 0>,
     public IOleCommandTarget
 {
  public:
     CExample()
     {
     }
 
 DECLARE_REGISTRY_RESOURCEID(IDR_EXAMPLE)
 
 
 BEGIN_COM_MAP(CExample)
     COM_INTERFACE_ENTRY(IExample)
     COM_INTERFACE_ENTRY(IDispatch)
     COM_INTERFACE_ENTRY(IObjectWithSite)
     COM_INTERFACE_ENTRY(IOleCommandTarget)
 END_COM_MAP()
 
 
 
     DECLARE_PROTECT_FINAL_CONSTRUCT()
 
     HRESULT FinalConstruct()
     {
         return S_OK;
     }
 
     void FinalRelease()
     {
     }
 
  public:
         virtual /* [input_sync] */ HRESULT STDMETHODCALLTYPE QueryStatus( 
             /* [unique][in] */ __RPC__in_opt const GUID *pguidCmdGroup,
             /* [in] */ ULONG cCmds,
             /* [out][in][size_is] */ __RPC__inout_ecount_full(cCmds) OLECMD prgCmds[  ],
             /* [unique][out][in] */ __RPC__inout_opt OLECMDTEXT *pCmdText);
         
         virtual HRESULT STDMETHODCALLTYPE Exec( 
             /* [unique][in] */ __RPC__in_opt const GUID *pguidCmdGroup,
             /* [in] */ DWORD nCmdID,
             /* [in] */ DWORD nCmdexecopt,
             /* [unique][in] */ __RPC__in_opt VARIANT *pvaIn,
             /* [unique][out][in] */ __RPC__inout_opt VARIANT *pvaOut);
 
 };
{% endhighlight %}
 

 



**步骤5：修改CExample.cpp文件，添加IOleCommandTarget接口实现**

 
{% highlight c++ %}
 /* [input_sync] */ HRESULT STDMETHODCALLTYPE CExample::QueryStatus( 
     /* [unique][in] */ __RPC__in_opt const GUID *pguidCmdGroup,
     /* [in] */ ULONG cCmds,
     /* [out][in][size_is] */ __RPC__inout_ecount_full(cCmds) OLECMD prgCmds[  ],
     /* [unique][out][in] */ __RPC__inout_opt OLECMDTEXT *pCmdText)
 {
     //TODO:
      return S_OK;
 }
 
 HRESULT STDMETHODCALLTYPE CExample::Exec( 
     /* [unique][in] */ __RPC__in_opt const GUID *pguidCmdGroup,
     /* [in] */ DWORD nCmdID,
     /* [in] */ DWORD nCmdexecopt,
     /* [unique][in] */ __RPC__in_opt VARIANT *pvaIn,
     /* [unique][out][in] */ __RPC__inout_opt VARIANT *pvaOut)
 {
     MessageBoxW(NULL, L"你好，世界", L"My First IE Extension", MB_OK | MB_ICONINFORMATION);
     return S_OK;
 }
{% endhighlight %}


 

**步骤6：打开Example.rgs，把里面的GUID填入注册表刚才的位置**

{% highlight batch %}
HKCR
{
  NoRemove CLSID
  {
    ForceRemove {B73854BF-C89E-44E3-9B54-99D5DD7E948A} = s 'Example Class'
    {
      ForceRemove Programmable
      InprocServer32 = s '%MODULE%'
      {
        val ThreadingModel = s 'Apartment'
      }
      TypeLib = s '{FE1A853C-DD4E-4435-87A1-889C86BB604B}'
      Version = s '1.0'
    }
  }
}
{% endhighlight %}

**步骤7：编译、构建（Compile and Build）。如果开发机是Vista或Win7，确保运行VS时有管理员权限，因为编译的最后一步是注册DLL**

OK，完成了，再次启动IE，点击Hello World看看效果。

![fc94b9e6]({{ site.BASE_PATH }}/assets/cloud/2010/fc94b9e6.png)

好，本文就写到这里，下一次我讲一下如何获取IE运行时页面里面的元素并对其进行修改。