---
layout: post
title:  "使用C#4.0操作Excel生成图表并导出到文件"
date:   2010-08-27
categories: coding
description: "本文讲述如何使用C#4.0操作Excel生成图表并导出到文件"
summary: "在着手写这篇文章之前，我也和大家一样，在网上找了各种各样相关文章，却发现没有一篇能够“完美”的适用于我的客户场景。在收集了很多信息及资料之后，自己加以琢磨，总算完成了这次任务。那么就献丑把我个人的经验附在博客上。"
---

*本文转自笔者的博客园，保留了当时的写作日期*


在着手写这篇文章之前，我也和大家一样，在网上找了各种各样相关文章，却发现没有一篇能够“完美”的适用于我的客户场景。在收集了很多信息及资料之后，自己加以琢磨，总算完成了这次任务。那么就献丑把我个人的经验附在博客上。

首先，我的场景是什么？我需要架设一台web服务器，在后台“默默”的工作，接收请求，画图，回传。图表要求是：饼图、线图、柱形图、雷达图（本人驽钝，头一次听说有这种图。。。Google了好一会才明白-_-|||）。基于这样的需求，我便需要一套画图“组件”，能够在后台实时工作，勤勤恳恳的为我画图即是。于是想到了使用ASP.NET接受请求，操作Excel画图，最终把图片传去客户端。

我开发机装的是VS2010和Office2010，也即是C#4.0。但是发现网上几乎找不到C#4.0操作Excel 2010的示例，大部分是C#2.0/3.0，Office多是2003/2007。那么C#4.0和之前的版本倒地有什么区别呢？说实话，区别还是蛮大的，不过我不是学者，所以不在这里啰嗦，有兴趣的朋友可以参考此文。但是我要说明的一点是C#4.0支持函数的默认参数，和C++里面的默认参数一样，并且还要强大。这个改进在COM Interop中显的由为重要，见下例：

C#2.0/3.0操作Excel代码

{% highlight csharp %}
Excel.Chart xlChart = (Excel.Chart)xlBook.Charts.Add(Missing.Value, Missing.Value, Missing.Value, Missing.Value); 
Excel.Range chartRage = xlSheet.get_Range("A1:A14", "B1:E14"); 
xlChart.ChartWizard(chartRage, Excel.XlChartType.xl3DColumn, Missing.Value, Excel.XlRowCol.xlColumns, 1, 1, true, "实验室效率分析", "上机时间", "上机次数", Missing.Value); 
{% endhighlight %}

C#4.0操作Excel代码

{% highlight csharp %}
var chart = book.Charts.Add() as Microsoft.Office.Interop.Excel.Chart; 
var range = sheet.Range["A1", "D5"]; 
chart.ChartWizard(range, Title: "学生成绩图"); 
{% endhighlight %}

看出来了吧，由于使用了默认参数，代码变的简洁而且优雅。这实在太适合我这种有强迫症的程序员了，呵呵。

再说到Office2010，比起之前版本有什么区别呢？其他不言，在作图方面，多了一些图表类型及图表式样，并且在编程接口上面也改进了一点点。所以总的来说，只要有条件，还是推荐大家使用C#4.0进行Office的开发。

最后，上图，上代码。

![3b5ca7b0]({{ site.BASE_PATH }}/assets/cloud/2010/3b5ca7b0.jpg)
![867ebb7a]({{ site.BASE_PATH }}/assets/cloud/2010/867ebb7a.png)
![b7fcd7f9]({{ site.BASE_PATH }}/assets/cloud/2010/b7fcd7f9.jpg)
![02f7a6d4]({{ site.BASE_PATH }}/assets/cloud/2010/02f7a6d4.jpg)

代码已经上传到codeplex，[请点这里查看完整代码](http://nport.codeplex.com/SourceControl/changeset/view/49968#1020631)。