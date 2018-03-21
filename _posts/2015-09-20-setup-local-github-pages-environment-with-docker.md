---

title:  "使用Docker搭建本地GitHub Pages开发环境"
date:   2015-09-20
categories: container
description: "本文逐步讲述如何使用Docker搭建本地GitHub Pages开发环境以便更加高效的编写博文"
summary: "pchou写过一个系列来讲述如何一步一步在GitHub Pages上面搭建自己专属的博客。本文作为一个补充，给出一种使用Docker搭建本地的GitHub Pages开发环境的方法，以便各位博主更加高效的编写博文。"
---

###前言###
[pchou](http://pchou.info/)写过[一个系列](http://www.pchou.info/category.html#web-build)来讲述如何一步一步在GitHub Pages上面搭建自己专属的博客。本文作为一个补充，给出一种使用Docker搭建本地的GitHub Pages开发环境的方法，以便各位博主更加高效的编写博文。

###运行效果###

下面我会以Docker容器的方式分别启动pchou和stainboy的博客服务，然后启动浏览器查看效果。注意：pchou博客启动在端口81上面。

    # docker run -d --privileged --name stainboy -p 80:4000 -v ~/git/stainboy.github.io:/opt/web jekyll:2.4.0
    51015fddf8049a0978811eab424e63c9e234b35948dad9bf650db6d716264c01
    # docker run -d --privileged --name pchou -p 81:4000 -v ~/git/pchou.github.io:/opt/web jekyll:2.4.0
    0594ebf60f8239764cf4bdb073e70ca5eb0fae5b363975f3ff22a17d98666adb

    # docker images |grep jekyll
    jekyll                         2.4.0               9732de3ae66a        2 days ago          858 MB
    
    # docker ps -a
    CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
    0594ebf60f82        jekyll:2.4.0        "jekyll serve -s /opt"   42 hours ago        Up 4 hours          0.0.0.0:81->4000/tcp   pchou
    51015fddf804        jekyll:2.4.0        "jekyll serve -s /opt"   42 hours ago        Up About an hour    0.0.0.0:80->4000/tcp   stainboy
    
    # ip addr|grep 192
        inet 192.168.31.242/24 brd 192.168.31.255 scope global eth0

    # google-chrome http://192.168.31.242 &
    # google-chrome http://192.168.31.242:81 &

![d559a576]({{ site.BASE_PATH }}/assets/cloud/2015/d559a576.jpg)
![9d8b1fb0]({{ site.BASE_PATH }}/assets/cloud/2015/9d8b1fb0.jpg)

由于Jekyll服务是实时编译的，所以启动后就可以放手开始编写博文了，任何的改动（只要保存）就会触发站点重新生成。我习惯用Sublime Text来编辑Markdown内容，写完后切换到浏览器刷新看结果。


###准备工作###
- 由于Docker只支持Linux系统，所以需要准备一台Linux Server，建议使用Ubuntu Server的虚拟机
- Linux系统需要安装Docker，建议安装最新版1.8.1
- Linux系统可以安装NFS或者Samba服务，将git repo共享出来，以便Mac/Windows主机做编辑（当然，如果你是vim高手，那么请自动忽略此行）


###操作过程###

首先，克隆你自己的{user}.github.io仓库到Linux主机。

    git clone git@github.com:{user}/{user}.github.io.git

然后，下载jekyll镜像的Dockerfile。可以克隆我的仓库，

    git clone git@github.com:stainboy/stainboy/lean.git

也可以直接下载

    curl -sLO https://raw.githubusercontent.com/stainboy/lean/master/jekyll/Dockerfile

接着，进入Dockerfile所在目录，输入以下命令进行构建

    docker build --no-cache=true -t jekyll:2.4.0 .

当构建成功后，便可启动这个镜像，记得把{user}的地方改成你自己的位置。然后打开浏览器访问即可。

    docker run -d --privileged --name stainboy -p 80:4000 -v /path/to/{user}.github.io:/opt/web jekyll:2.4.0

###原理讲解###

每启动一个Docker容器，即相当于启动了一个轻量级的“Linux实例”，而Jekyll的这个实例里面包含了GitHub Pages所需要用到的所有组件，所以整个环境跑起来跟真实的本地Ruby环境是没有两样的。如此一来，便省去了初学者搭建Ruby和Bundle的花费了。

现在，回过头来再看一下这个Dockerfile到底做了些什么神奇的工作


{% highlight bash %}
FROM daocloud.io/library/ruby

ENV PATH=$PATH:/opt/node-v4.0.0-linux-x64/bin \
    NODE_HOME=/opt/node-v4.0.0-linux-x64/

RUN \
    # download nodejs
    curl -sLO https://nodejs.org/dist/v4.0.0/node-v4.0.0-linux-x64.tar.gz &&\
    tar -xf /node-v4.0.0-linux-x64.tar.gz -C /opt/ &&\
    rm /node-v4.0.0-linux-x64.tar.gz &&\
    # install bundle
    gem install bundle &&\
    # install taobao github-pages
    { \
        echo "source 'http://ruby.taobao.org'"; \
        echo "gem 'github-pages'"; \
    } > Gemfile &&\
    bundle install

# EXPOSE 4000

ENTRYPOINT ["jekyll", "serve", "-s", "/opt/web"]
{% endhighlight %}

构建过程：

- 从DaoCloud下载一个700M的Ruby（一次性工作）
- 从nodejs.org下载nodejs
- 从ruby.taobao.org下载一些gem文件

整个过程可能要好几分钟，取决于你的网络。

###图片处理###

编写博文时总要贴一些图片吧。GitHub Pages不（直接）支持Windows Live Writer，所以对图片的支持不是很理想。那么该如何存储图片资源呢？我的做法是把所有需要用到的图片按照年份归类，当作代码源文件，直接提交到github上面。

    # pwd
    /root/git/stainboy.github.io/assets/cloud/2015
    
    # ls -lht
    total 408K
    -rwxrwxr--+ 1 root root 46K Sep 20 15:25 9d8b1fb0.jpg
    -rwxr--r--  1 root root 65K Sep 20 15:23 d559a576.jpg
    -rwxr--r--  1 root root 65K Sep 19 18:25 2b7e49ce.PNG
    -rwxr--r--  1 root root 76K Sep 19 18:20 fd908555.PNG
    -rwxr--r--  1 root root 53K Sep 19 18:18 1c54b0f8.PNG
    -rwxr--r--  1 root root 45K Sep 19 18:12 9eaa699e.PNG
    -rwxr--r--  1 root root 41K Sep 19 18:08 04e538df.PNG

在MD里面引用，

![d4014ad6]({{ site.BASE_PATH }}/assets/cloud/2015/d4014ad6.PNG)

如此做法优点是所有的资源都在一起，不会出现局部丢失；缺点是日积月累博客所在仓库体积会越来越大，直到有一天clone会变得很困难。


###小结###

持续撰写博文需要的是大毅力，希望本文可以让更多有意向写博客的网友更加快速便捷的搭建博客编写环境，从而写出更好的博客文学！