---

title:  "在Godaddy空间上部署ASP.NET MVC3 + EntityFramework4.1 + MySQL应用程序"
date:   2011-07-17
categories: coding
description: "本文介绍如何在Godaddy空间上部署ASP.NET MVC3 + EntityFramework4.1 + MySQL应用程序"
summary: "首先一句话介绍一下godaddy.com这个网站。这是一家国外知名度极高的域名注册商+空间供应商，她提供Linux和Windows两种空间。本文当然是针对后者，在Windows空间上部署ASP.NET MVC3 + EntityFramework4.1 + MySQL应用程序。
从其官方网站介绍上可以看到，godaddy的Windows空间默认使用IIS7，支持ASP.NET 4.0集成模式（Integrated Mode）, MVC2。那么，如何部署MVC3、EntityFramework以及MySQL呢？"
---

*本文转自笔者的博客园，保留了当时的写作日期*


**【2012-02-19更新一下】Godady空间服务器已经升级，正式支持ASP.NET MVC3应用程序了，所以文本可以成为历史了，关于MYSQL那段还有用。**

首先一句话介绍一下[godaddy.com](http://godaddy.com/)这个网站。这是一家国外知名度极高的域名注册商+空间供应商，她提供Linux和Windows两种空间。本文当然是针对后者，在Windows空间上部署[ASP.NET MVC3](http://www.asp.net/mvc/mvc3) + [EntityFramework4.1](http://www.microsoft.com/download/en/details.aspx?displaylang=en&id=8363) + [MySQL](http://www.mysql.com/downloads/connector/net/)应用程序。

 

从其[官方网站介绍](http://www.godaddy.com/hosting/web-hosting.aspx?ci=9009)上可以看到，godaddy的Windows空间默认使用IIS7，支持ASP.NET 4.0集成模式（Integrated Mode）, MVC2。那么，如何部署MVC3、EntityFramework以及MySQL呢？

 

其实很简单，我们知道，MVC3或者MVC2都是基于ASP.NET核心的扩展（通过IHttpModuler），EntityFramework更可直接当作一个外部引用集来发布，**故对于MVC和EF只需要简单的把所有（相关）的程序集（Assembly）复制到网站的bin目录下即可。**

 

具体而言，对于MVC3来说，有如下程序集，

- `C:\Program Files\Microsoft ASP.NET\ASP.NET Web Pages\v1.0\Assemblies\*.dll`
- `C:\Program Files\Microsoft ASP.NET\ASP.NET MVC 3\Assemblies\*.dll`

 

对于EntityFramework来说，有如下程序集，

- `C:\Program Files\Microsoft ADO.NET Entity Framework 4.1\Binaries\*.dll`

 

而MySQL则需要额外的一部工作。首先第一步是一样的，把MySQL Connector程序集复制到bin目录下，

**（注：本文以MySQL Connector Net 6.3.6为例，不同版本配置文件略有不同）**

- `C:\Program Files\MySQL\MySQL Connector Net 6.3.6\Assemblies\v4.0\*.dll`

其次，由于godaddy使用共享网站服务器，故我们不能在上面安装任何软件（包括MySQL Connector），所以还需要额外在我们网站的Web.config里面加上一段内容，具体如下，

{% highlight xml %}
<configuration>
  <!-- ... -->
  <system.data> 
    <DbProviderFactories> 
      <add name="MySQL Data Provider" invariant="MySql.Data.MySqlClient" description=".Net Framework Data Provider for MySQL" type="MySql.Data.MySqlClient.MySqlClientFactory, MySql.Data, Version=6.3.6.0, Culture=neutral, PublicKeyToken=c5687fc88969c44d" /> 
    </DbProviderFactories> 
  </system.data>
  <!-- ... -->
</configuration>
{% endhighlight %}
 

至此，大功告成。接着上传所有内容到FTP即可。祝大家使用godaddy一切顺利！