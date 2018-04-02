---
title:  "Let's Encrypt工作原理"
date:   2018-04-01
categories: container
description: "本文翻译自 https://letsencrypt.org/how-it-works/"
summary: "Let's Encrypt和ACME协议的目标是在无人职守的情况下，全自动获取浏览器信任的证书，进而搭建HTTPS服务器成为可能。"
---

*本文翻译自 https://letsencrypt.org/how-it-works/*

Let's Encrypt和[ACME协议](https://ietf-wg-acme.github.io/acme/)的目标是在无人职守的情况下，全自动获取浏览器信任的证书，进而搭建HTTPS服务器成为可能。这是通过在Web服务器上运行证书管理代理程序来完成的。

为了理解该技术的工作原理，让我们介绍一下使用支持Let's Encrypt的证书管理代理程序来搭建`https://example.com/`的过程。

这个过程有两个步骤。首先，代理程序向CA（Certificate Authority，证书颁发机构，这里指Let's Encrypt）证明Web服务器控制该域名。然后，代理程序可以请求签发，续订和撤销该域名的证书。

## 域名验证
Let’s Encrypt通过`公钥`识别服务器管理员。代理程序首次与Let's Encrypt进行交互时，它会生成一个新的`非对称密钥对`对并向Let's Encrypt CA证明服务器控制一个或多个域名。这与创建帐户并向该帐户添加域名的传统CA过程类似。

为了启动流程，代理程序向Let's Encrypt CA询问它需要做什么以证明它控制`example.com`。Let’s Encrypt CA将查看被请求的域名并发出一组或多组`challenges`。 这些代理程序可以以不同方式来证明其控制该域名。例如，CA可能会为代理程序提供以下两种选择之一：

- 在`example.com`下提供DNS记录，或者
- 在`https://example.com/`下面提供一个带有特定内容的URI资源

除了这些`challenges`之外，Let's Encrypt CA还提供了一个随机数，代理程序必须使用其私钥对其签名才能证明它控制密钥对。

![0000]({{ site.BASE_PATH }}/assets/cloud/2018/howitworks_challenge.png)

代理程序需要完成所提供的`challenges`之一。假设它能够完成上述第二项任务：它在`https://example.com`站点的指定路径上创建一个文件。代理程序还使用其私钥对提供的随机数进行签名。代理程序完成这些步骤后，它会通知CA它已准备好完成验证。

然后，CA的工作就是检查`challenges`是否得到满足。CA验证随机数的签名，并尝试从Web服务器下载文件并确保其具有预期的内容。

![0000]({{ site.BASE_PATH }}/assets/cloud/2018/howitworks_authorization.png)

如果随机数签名有效，并且`challenges`被满足，则具有该公钥标识的代理程序有权对`example.com`进行证书管理。我们称代理程序使用的`非对称密钥对`是作为`example.com`的“授权密钥对”。

## 证书颁发和撤销
一旦代理程序拥有授权密钥对，请求签发，更新和撤销证书就很简单。只需发送证书管理消息并使用授权密钥对对其进行签名即可。

为了获得该域名的证书，该代理程序创建PKCS＃10 [证书签名请求CSR](http://tools.ietf.org/html/rfc2986)，用一个指定的公钥请求Let’s Encrypt CA为`example.com`颁发证书。像往常一样，CSR包含公钥对应的私钥的签名。代理程序还使用`example.com`的授权密钥对对整个CSR进行签名，以便Let's Encrypt CA知道它已被授权。

当Let's Encrypt CA收到请求时，它会验证两个签名。如果一切正常，它会使用来自CSR的公钥为`example.com`颁发证书并将其返回给代理程序。

![0000]({{ site.BASE_PATH }}/assets/cloud/2018/howitworks_certificate.png)

撤销的工作方式类似。代理程序使用`example.com`授权密钥对签名撤销请求，Let's Encrypt CA验证请求是否经过授权。如果验证通过，它将撤销信息发布到常规撤销渠道（即CRL，OCSP）中，以便诸如浏览器的证书依赖方可以知道他们不应该接受撤销的证书。

![0000]({{ site.BASE_PATH }}/assets/cloud/2018/howitworks_revocation.png)
