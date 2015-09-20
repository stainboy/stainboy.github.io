---
layout: post
title:  "编写爬虫程序的神器 - Groovy + Jsoup + Sublime"
date:   2014-07-04
categories: coding
description: "本文介绍如何使用Groovy + Jsoup + Sublime编写爬虫程序"
summary: "最近项目里面接触到了一种神奇的语言Groovy -- 一种全面兼容Java语言且提供了大量额外语法功能的动态语言。加上网络上有开源的Jsoup项目 -- 一个轻量级的使用CSS选择器来解析HTML内容的类库，这样的组合编写爬虫简直如沐春风。"
---

*本文转自笔者的博客园，保留了当时的写作日期*


写过很多个爬虫小程序了，之前几次主要用C# + [Html Agility Pack](http://htmlagilitypack.codeplex.com/)来完成工作。由于.NET FCL只提供了"底层"的HttpWebRequest和"中层"的WebClient，故对HTTP操作还是需要编写很多代码的。加上编写C#需要使用Visual Studio这个很"重"的工具，开发效率长期以来处于一种低下的状态。

 

最近项目里面接触到了一种神奇的语言[Groovy](http://www.groovy-lang.org/) -- 一种全面兼容Java语言且提供了大量额外语法功能的**动态语言**。加上网络上有开源的[Jsoup项目](http://jsoup.org/) -- 一个轻量级的使用CSS选择器来解析HTML内容的类库，这样的组合编写爬虫简直如沐春风。

 

**抓cnblogs首页新闻标题的脚本**
{% highlight groovy %}
Jsoup.connect("http://cnblogs.com").get().select("#post_list > div > div.post_item_body > h3 > a").each {
    println it.text()   
}
{% endhighlight %}

output
![b158222b]({{ site.BASE_PATH }}/assets/cloud/2014/b158222b.png)

 

**抓cnblogs首页新闻详细信息**

{% highlight groovy %}
Jsoup.connect("http://cnblogs.com").get().select("#post_list > div").take(5).each { 
    def url = it.select("> div.post_item_body > h3 > a").attr("href") 
    def title = it.select("> div.post_item_body > h3 > a").text() 
    def description = it.select("> div.post_item_body > p").text() 
    def author = it.select("> div.post_item_body > div > a").text() 
    def comments = it.select("> div.post_item_body > div > span.article_comment > a").text() 
    def view = it.select("> div.post_item_body > div > span.article_view > a").text()

    println "" 
    println "新闻: $title" 
    println "链接: $url" 
    println "描述: $description" 
    println "作者: $author, 评论: $comments, 阅读: $view"   
}
{% endhighlight %}


output
![b0d936b6]({{ site.BASE_PATH }}/assets/cloud/2014/b0d936b6.png)

 

怎么样，很方便是吧。是不是找到一种编写前端JavaScript和jQuery代码的感觉，那就对了！

这里说一个窍门，编写CSS选择器的时候可以借助Google Chrome浏览器的开发工具，如图：
![4610c084]({{ site.BASE_PATH }}/assets/cloud/2014/4610c084.png)

 

再来看看Groovy是如何快速处理JSON和XML的。一句话：方便到家。

 

**抓cnblogs的feeds**

{% highlight groovy %}
new XmlSlurper().parse("http://feed.cnblogs.com/blog/sitehome/rss").with { xml -> 
    def title = xml.title.text() 
    def subtitle  = xml.subtitle.text() 
    def updated = xml.updated.text()

    println "feeds" 
    println "title -> $title" 
    println "subtitle -> $subtitle" 
    println "updated -> $updated"

 

    def entryList = xml.entry.take(3).collect { 
        def id = it.id.text() 
        def subject = it.title.text() 
        def summary = it.summary.text() 
        def author = it.author.name.text() 
        def published = it.published.text() 
        [id, subject, summary, author, published] 
    }.each { 
        println "" 
        println "article -> ${it[1]}" 
        println it[0] 
        println "author -> ${it[3]}" 
    } 
}
{% endhighlight %}

output
![04e3b537]({{ site.BASE_PATH }}/assets/cloud/2014/04e3b537.png)

 

**抓msdn订阅的产品分类信息**
{% highlight groovy %}
new JsonSlurper().parse(new URL("http://msdn.microsoft.com/en-us/subscriptions/json/GetProductCategories?brand=MSDN&localeCode=en-us")).with { rs -> 
    println rs.collect{ it.Name } 
}
{% endhighlight %}

output
![ae6322c8]({{ site.BASE_PATH }}/assets/cloud/2014/ae6322c8.png)

 

再说一下代码编辑器。本方案由于使用Groovy这门动态语言，故可以选择一种轻量级的文本编辑器，这里要推荐[Sublime](http://www.sublimetext.com/)。其中文翻译是“高大尚”的意思。从这个小小的文本编辑器所表现出来的丰富功能和极佳的用户体验来看，也确实对得起这个名字了。

![4b371714]({{ site.BASE_PATH }}/assets/cloud/2014/4b371714.png)

优点：

* 轻量级（客户端6m）
* 支持各种语言的着色，包括Groovy
* 自定义主题包（颜色表）
* 列编辑
* 快速选择，扩展选择等

缺点：

* 不免费，不开源。好在试用版可以无限制使用，只是保存操作时偶尔弹出对话框

最后，分享一段抓取搜房网二手房信息的快速脚本

[http://noria.codeplex.com/SourceControl/latest#miles/soufun/soufun.groovy](http://noria.codeplex.com/SourceControl/latest#miles/soufun/soufun.groovy)

抓取整理后效果图
![9eaa9c55]({{ site.BASE_PATH }}/assets/cloud/2014/9eaa9c55.png)

 

行文至此，希望对爬虫感兴趣的朋友们有所帮助。