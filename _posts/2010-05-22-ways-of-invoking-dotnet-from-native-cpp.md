---
title:  "N种方法使用C++调用C#.NET库"
date:   2010-05-22
categories: coding
description: "本文描述使用C++调用C#/VB等托管代码，给出三种常规方法和一些变通方法以供参考"
summary: "此文不描述何种场景下需要使用C++调用C#/VB等托管代码，而直接给出三种常规方法和一些变通方法以供参考"
---

*本文转自笔者的LiveSpace，保留了当时的写作日期*

为了减少篇幅，此文不描述何种场景下需要使用C++调用C#/VB等托管代码，而直接给出三种常规方法和一些变通方法以供参考。

###常规方法1：COM###

使用C#把托管类注册成COM，用regasm.exe注册output assembly，然后用C++像调用COM一样调用assembly里面的type。

优点：编写代码简单，调用方便

缺点：需要注册output，发布不够简单

参考：

* [http://www.codeproject.com/KB/cs/ManagedCOM.aspx]()

###常规方法2：CLR###

C#常规编写类，生产assembly，C++使用CLR编译既可直接引用托管类。

优点：编写代码简单，调用方便

缺点：需要了解C++ CLR语法（既不像C++，又不像C#，总之很奇怪）

参考

* [http://www.codeproject.com/KB/mcpp/cppcliintro01.aspx]()
* [http://msdn.microsoft.com/en-us/library/k8d11d4s.aspx]()

###常规方法3（推荐）：API###

C#常规编写类，生产assembly，C++使用SDK提供的CLR非托管接口（CLRCreateInstance）进行调用。

优点：传统C#编程，传统C++编程

缺点：暂时还没发现

参考：

* [http://nport.codeplex.com/SourceControl/changeset/view/45681#903468]()
* [http://msdn.microsoft.com/en-us/library/dd537633.aspx]()

###变通方法：###

  1. 使用C#/VB包装现有托管类，注册成Windows服务，暴露SOAP web service。VC2005可以使用非托管代码添加引用Web service。

  2. 使用C#/VB包装现有托管类，注册成Windows服务。C++利用Windows message和服务通讯。

  3. 使用C#/VB包装现有托管类，注册成Windows服务。C++利用Windows共享内存和服务通讯。

其实利用双进程通讯的方法，可以演变出各种各样调用的思路。聪明的你可以充分发挥想象力，写出自己独有的调用模式。