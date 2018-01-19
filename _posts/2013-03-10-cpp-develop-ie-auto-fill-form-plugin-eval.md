---

title:  "小工具开发笔记—IE自动填表器 -- 执行JavaScript"
date:   2013-03-10
categories: coding
description: "本文讲述如何使用C++开发IE插件以用于自动填表"
summary: "时刻三年，我原本无心继续更新这篇博文。恰巧近日招商银行网站全新改版，导致我之前开发的小工具无法正常使用，故萌生念头动手开发自动填表器2.0版本。此文将作为博文的一个延续以及补充，不过内容将会围绕2.0版本来讲解。之前的博文也会更新下载2.0填表器。"
---

*本文转自笔者的博客园，保留了当时的写作日期*

###系列导航###
- [小工具开发笔记—IE自动填表器 -- 序]({% post_url 2010-09-05-cpp-develop-ie-auto-fill-form-plugin %})
- [小工具开发笔记—IE自动填表器 -- 你好，世界]({% post_url 2010-09-07-cpp-develop-ie-auto-fill-form-plugin-hello-world %})
- 小工具开发笔记—IE自动填表器 -- 执行JavaScript

---


###引子###
时刻三年，我原本无心继续更新这篇博文。恰巧近日招商银行网站全新改版，导致我之前开发的小工具无法正常使用，故萌生念头动手开发自动填表器2.0版本。此文将作为博文的一个延续以及补充，不过内容将会围绕2.0版本来讲解。之前的博文也会更新下载2.0填表器。

###简介###
首先啰嗦一下为什么1.0填表器不能工作于新版招行。原因很简单，因为1.0只支持有限HTML标签（如HtmlInput, HtmlImage等）。全新改版后的招行“不但”支持了Webkit浏览器，“而且”在页面里面嵌入了frame -- 这是1.0填表器所不能支持的一个控件，也是1.0填表器当时的一个backlog。受限于C++开发的缓慢节奏，我并不打算将这些HtmlElement一一用C++的类来实现，为了一劳永逸解决这个问题，2.0版本引入了动态执行JavaScript脚本的功能 -- 用JS脚本来解决实际业务问题，开发快速，灵活，简单。

OK，再用一句话概括一下2.0填表器：**这是一个IE插件，会在IE的工具栏上面添加一个按钮，点击后根据预配置信息以及当前URL自动寻找一段预编辑的JS，然后在当前页面上下文里执行**。

![2eedf990]({{ site.BASE_PATH }}/assets/cloud/2013/2eedf990.jpg)

看一下2.0的文件结构

![66777aac]({{ site.BASE_PATH }}/assets/cloud/2013/66777aac.jpg)

- athena.dll: 填表器主程序（智慧女神雅典娜？）
- athena.js: 主配置脚本
- jquery.js: 工具脚本
- *.js: 针对某个页面的自动化脚本

首先看一下athena.js配置脚本文件，

{% highlight js %}
{
    "preload" : ["jquery.js"],
    
    "pages" : 
    [
        {
            // cmbchina payment page
            "url" : "https://netpay.cmbchina.com",
            "bot" : "cmbchina.js"
        },
        {
            // google page, for test purpose
            "url" : "https://www.google.com",
            "bot" : "google.js"
        },
        {
            // alipay quick login page
            "url" : "https://tradeexprod.alipay.com",
            "bot" : "alipay.js"
        },
        {
            // alipay login page (does not work!)
            "url" : "https://auth.alipay.com/login",
            "bot" : "alipay_login.js"
        },
        {
            // himovie login page
            "url" : "http://user.himovie.com/",
            "bot" : "himovie.js"
        }
    ]
}
{% endhighlight %}

以上是athena.js配置脚本，是一个JSON格式的文件。里面有两部分信息：preload是一个string array，每一个成员指向一个js脚本，作用是在执行bot之前先执行这些脚本；pages是一个JSON array，每个成员有url和bot两个属性，url用来和当前页面url匹配，如果匹配成功，则执行bot里面的js文件（会先执行preload里面的每一个js，这样就可以用jquery的方法啦）

然后再看一下cmbchina.js主程序，这个脚本负责自动填表招商银行在线支付页面，

{% highlight js %}
(function () {

    var cred = {
        number: "0000000000000000",
        password: "000000",
        month: "00",
        year: "00",
        cvv2: "000"
    };

    try
    {
        var $doc = $(document.frames.mainWorkArea.document);
        if ($doc.find("#CardNoCtrl").length) {

            // we are in the first page
            var bot = new ActiveXObject("Noria.Bot");
            bot.Fill($doc.find("#CardNoCtrl").get(0), cred.number, 0);

        } else if ($doc.find("#PwdCtrl").length) {

            // we are in the second page
            var bot = new ActiveXObject("Noria.Bot");
            bot.Fill($doc.find("#MonthCtrl").get(0), cred.month, 0);
            bot.Fill($doc.find("#YearCtrl").get(0), cred.year, 0);
            bot.Fill($doc.find("#CVV2Ctrl").get(0), cred.cvv2, 0);
            bot.Fill($doc.find("#PwdCtrl").get(0), cred.password, 0);

        } else {

            // unknown places
            alert("Where am I?");

        }
    }
    catch(e)
    {
        alert(e.toString());
    }

})();
{% endhighlight %}

以上则是cmbchina.js，用来自动化操作招行在线支付页面。JS代码就不做多解释了，本文主要讲C++实现。需要一提的是JS里面有一句话 `var bot = new ActiveXObject("Noria.Bot");` 这是创建一个COM对象，用来操作招行本身的ActiveX控件。这个COM对象也是C++开发的，我会在下文介绍。

###功能实现###
现在开始介绍C++代码。首先，这里会出现两个C++类，更准确的说是两个ATL Simple Object。

- CBot类，ProgID=Noria.Bot，暴露一个Fill方法，输入参数是HTMLElement, BSTR, LONG，输出参数无，作用是对ActiveX对象填表。其核心代码如下：


{% highlight c++ %}
STDMETHODIMP CBot::Fill(IHTMLElement* e, BSTR v, LONG p)
{
    HWND hwnd = GetNativeWnd(e);

    // get child window depends on level (p)
    for(int i=0; i<p; i++)
    {
        hwnd = FindWindowExW(hwnd, NULL, NULL, NULL);
    }

    wstring value(v);
    for_each(value.cbegin(), value.cend(), [hwnd](const wchar_t c){
        SendMessageW(hwnd, WM_CHAR, c, 0);
    });

    return S_OK;
}
{% endhighlight %}



- CKaleidoscope类（万花筒？嗯），没有ProgID，要实现IOleCommandTarget接口。这个类用来在IE工具栏上内嵌一个按钮，并且处理点击事情。其核心代码如下：


{% highlight c++ %}
STDMETHODIMP CKaleidoscope::Exec( 
  /* [unique][in] */ __RPC__in_opt const GUID *pguidCmdGroup,
  /* [in] */ DWORD nCmdID,
  /* [in] */ DWORD nCmdexecopt,
  /* [unique][in] */ __RPC__in_opt VARIANT *pvaIn,
  /* [unique][out][in] */ __RPC__inout_opt VARIANT *pvaOut)
{
    LOG_INFO("Begin of CKaleidoscope::Exec");
    HRESULT hr = S_OK;

  IUnknown* pUnknown = NULL;
  hr = this->GetSite(IID_IUnknown, reinterpret_cast<void**>(&pUnknown));
  if(FAILED(hr))
    {
        LOG_FATAL("Failed to get IUnknown, hr=%#X", hr);
        AtlThrow(hr);
    }

    try
    {
        Autobot bot;
        bot.run(pUnknown);
    }
    catch(const std::runtime_error& e)
    {
        LOG_FATAL("Error: %s", e.what());
        MessageBoxA(NULL, e.what(), "Error", MB_OK | MB_ICONERROR);
        hr = S_FALSE;
    }
    catch(const CAtlException& e)
    {
        LOG_FATAL("CAtlException: hr=%#X", e.m_hr);
        MessageBoxA(NULL, "Runtime CAtlException", "Error", MB_OK | MB_ICONERROR);
        hr = S_FALSE;
    }
    catch(...)
    {
        LOG_FATAL("Unknown Error...");
        hr = S_FALSE;
    }

    LOG_INFO("End of CKaleidoscope::Exec");
  return hr;
}
{% endhighlight %}




好吧，看到这里也许会发现，我把核心逻辑实现压入到一个叫做Autobot的类里面。是的，这里Autobot不是汽车人的意思，而是自动填表机器人，其方法run的大致逻辑如下：

- 
  1. 检查上下文，获取当前window和document对象
  2. 加载athena.js配置脚本
  3. 获取当前页面url，检查athena对象里是否有与之匹配的预定义信息
  4. 若无，则结束
  5. 若有，则分别加载并执行preload里的js文件，然后执行匹配的bot文件

其实把逻辑说清楚了就没什么太多技术含量了，我在这里贴出两处核心代码，一是如何找到当前的window和document，二是如果执行一段JS脚本

{% highlight c++ %}
void find(IUnknown* pUnk, IHTMLDocument2** ppDoc2)
{
    HRESULT hr;

    CComQIPtr<IServiceProvider> provider(pUnk);
    if(!provider)
    {
        LOG_FATAL("Failure querying interface IServiceProvider");
        AtlThrow(E_NOINTERFACE);
    }

    CComQIPtr<IWebBrowser2> browser;
    hr = provider->QueryService(SID_SWebBrowserApp, IID_IWebBrowser2, reinterpret_cast<void **>(&browser));
    if (FAILED(hr))
    {
        LOG_FATAL("Failure querying service IWebBrowser2");
        AtlThrow(hr);
    }

    CComDispatchDriver disp;
    hr = browser->get_Document(&disp);
    if (FAILED(hr))
    {
        LOG_FATAL("Failure getting document IDispatch");
        AtlThrow(hr);
    }

    hr = disp->QueryInterface(IID_IHTMLDocument2, (void**)ppDoc2);
    if (FAILED(hr))
    {
        LOG_FATAL("Failure querying interface IHTMLDocument2");
        AtlThrow(hr);
    }
}
{% endhighlight %}

{% highlight c++ %}
void eval(IHTMLWindow2* pWin2, const string& js)
{
    CComVariant ret;
    auto code = Strings::a2w(js);
    HRESULT hr = pWin2->execScript(CComBSTR(code.c_str()), L"JavaScript", &ret);
    if(FAILED(hr))
        AtlThrow(hr);    
}
{% endhighlight %}

###尾声###
行文至此，基本上阐述了填表器2.0的工作原理和主要功能实现，希望对读者能有所帮助。



[程序下载地址](http://nport.codeplex.com/downloads/get/636121)

[补充] 由于实在没有时间测试并且进一步优化，此程序目前只能保证在IE9+Win7环境正常运行。（Win8+IE10基本上不能工作:( ）

[在线浏览代码](http://nport.codeplex.com/SourceControl/changeset/view/72124#1584191)