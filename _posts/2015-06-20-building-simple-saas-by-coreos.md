---

title:  "使用CoreOS及Docker搭建简单的SaaS云平台"
date:   2015-06-20
categories: container
description: "本文讲述使用CoreOS及Docker搭建简单的SaaS云平台的完整经历"
summary: "2014年是Docker大红大火的一年， DevOps这个新名词+新职位就如雨后春笋般冒出尖角，蓬勃发展起来。与时俱进，笔者带领一支三人团队利用了CoreOS及Docker搭建了一套SaaS平台，用以提供完整套装的SAP Business One的预览环境。

本文会介绍此SaaS平台可以提供何种服务，其工作原理解析，以及最重要的，如何利用CoreOS搭建集群，如何利用Docker跑SAP Business One程序。本文面向开发，测试及DevOps同学。本文假设读者具有一定的容器基础，故行文不对Docker原理及使用作过多介绍。"
---

![1c54b0f8]({{ site.BASE_PATH }}/assets/cloud/2015/1c54b0f8.PNG)

2014年是Docker大红大火的一年， DevOps这个新名词+新职位就如雨后春笋般冒出尖角，蓬勃发展起来。与时俱进，笔者带领一支三人团队利用了CoreOS及Docker搭建了一套SaaS平台，用以提供完整套装的SAP Business One的预览环境。

**本文会介绍此SaaS平台可以提供何种服务，其工作原理解析，以及最重要的，如何利用CoreOS搭建集群，如何利用Docker跑SAP Business One程序。本文面向开发，测试及DevOps同学。本文假设读者具有一定的容器基础，故行文不对Docker原理及使用作过多介绍。**

### 为什么要这样做！
业界有这样一种说法，SAP的ERP套件是世界上最好的ERP解决方案，也是最难部署最难使用的计算机软件！诚然，大型企业上一套SAP Business Suit套件（俗称R3）可能得数月的部署周期，即使是SAP Business One这种针对中小型企业的解决方案也需要好几天的安装部署加调试。

再说一下团队内部开发测试流程是如何开展的：测试工程师小何早上来到公司，从指定的build server上面拷贝一张最新版本(nightly build)的ISO，然后SSH以及RDP分别远程连接一台SUSE Linux测试机和一台Windows测试机，把ISO文件上传到两台服务器并且进行安装。（SAP Business One分成Server和Client两部分，Server得安装在SUSE Linux上面，Client安装在Windows上面）。此处略过安装过程500字。。。下午两点，小何长叹一口气，终于装好了，今天运气真好，整个安装很顺利，全部一次通过，现在可以开始做回归测试了，耶！

事实上，像小何这样的测试工程师在整个部门里有百来人，他们几乎每天都在做同样的工作，安装(升级)à测试à卸载。由于build失败、损坏、网络原因、硬件故障、沟通不畅及人为失误导致的安装失败率已经超过了30%。在特殊的某些日子里，这个数值会达到80%甚至100%。

为了有效的减少重复劳动和提高生产率，团队决定大胆的使用（当时还不是很成熟）的容器解决方案来尝试做一套全自动安装部署的系统。称之为SAP Business One快速部署云平台！

### 本云平台特点及工作机制
从软件架构角度来看，本云平台分为后台和前台两部分组成。后台负责自动监视nightly build server、制作docker image；前台负责接受用户提交请求，然后创建并运行docker image。

从拓扑结构角度来看，云平台有1台master server（前台和后台服务都跑在这里），1台build server（专门用来做docker build）以及4台slave server（用来运行特定的docker image）。slave服务器可以扩容。所有6台服务器都是物理机，256GB内存的配置，安装CoreOS来搭建集群。

* 特点
  - 用户界面友好
  - 三分钟就能准备好一套完整的SAP Business One环境（过去手工安装需要2~3小时）
  - 一次安装多次运行（再也不会由于外部原因导致安装失败了）
* 后台
系统后台是一个基于Jenkins二次开发的模块，对最终用户不可见。其负责自动监视nightly build server、制作docker image、发布image到repository、清除过旧版本的image等工作。是整个云平台的核心。

* 前台
系统前台是一个使用bootstrap + AngulaJS + SparkJAVA + Groovy开发的网站。展现给用户所有安装成功的nightly build的image，接受用户的选择且通过docker去创建和启动特定版本号的image，最终发送邮件通知用户完成且可使用这套环境作开发或测试工作了。Docker创建image的调度由fleet完成。

![04e538df]({{ site.BASE_PATH }}/assets/cloud/2015/04e538df.PNG)
![fd908555]({{ site.BASE_PATH }}/assets/cloud/2015/fd908555.PNG)
![2b7e49ce]({{ site.BASE_PATH }}/assets/cloud/2015/2b7e49ce.PNG)

### 如何搭建CoreOS集群
#### 为什么是CoreOS
团队的需求是希望一台256GB内存的物理机可以尽可能多的跑SAP Business One的实例。从经验数据得知，跑一个SAP Business One的实例需要20~40GB内存开销，取决于用户连接数和使用方式等。假设平均32GB跑一个，那么256的机器可以跑8个。如果使用传统虚拟化的解决方案，恐怕性能损耗会导致最终只能跑5~6个，另外虚拟机比较难实现弹性内存。我们需要一个轻量级的host os，提供标准的容器运行时。CoreOS的轻巧、精简、自建集群等特性决定了它是这个项目的不二选择！

#### 安装CoreOS
CoreOS的安装和大部分Linux发行版不太一样。常用发行版如Ubuntu、Fedora等下载一张LiveCD刻盘插入安装即可。而CoreOS官方提供多种途径的安装方式，如AWS的image、VMWare的image、"LiveCD"的ISO、及纯粹的tar包。本文只讲述如何把CoreOS安装到一台物理机上。

步骤是下载一个特定版本的"LiveCD"的ISO，（本文使用2015年初的一个老版本557.2.0），大概150m。刻成光盘（或者USB盘），插入物理机，重启后进入CoreOS "Live OS"。然后创建一个yaml文件，把以下内容copy进去。


{% highlight yaml %}
#cloud-config
#
#

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1y...

hostname: cnpvg50859256.pvgl.sap.corp

coreos:
  update:
    reboot-strategy: etcd-lock

  etcd:
      name: cnpvg50859256
      # generate a new token for each unique cluster from https://discovery.etcd.io/new
      # discovery: https://discovery.etcd.io/d43034d6ed8451ffadb683e381f187fb
      # Support corporate proxy via env var -> https://github.com/coreos/etcd/pull/909
      # discovery-proxy: http://proxy.wdf.sap.corp:8080
      # multi-region and multi-cloud deployments need to use $public_ipv4
      addr: 10.58.120.156:4001
      peer-addr: 10.58.120.156:7001
      # we don't rely on discovery, we join the cluster manually
      peers: 10.58.136.96:7001

  fleet:
      public-ip: 10.58.120.156
      metadata: name=cnpvg50859256,memory=256GB,role=slave,maxpod=8

  units:
    - name: update-engine.service
      command: stop
    - name: rpc-mountd.service
      command: start
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
    - name: docker.service
      drop-ins:
        - name: 20-proxy.conf
          content: |
            [Service]
            Environment="http_proxy=http://proxy.wdf.sap.corp:8080"
            Environment="https_proxy=http://proxy.wdf.sap.corp:8080"
            Environment="no_proxy=localhost,10.58.136.166"
        - name: 50-insecure-registry.conf
          content: |
            [Service]
            Environment="DOCKER_OPTS=-H tcp://0.0.0.0:7777 --insecure-registry=0.0.0.0/0"
    - name: 00-eth0.network
      runtime: true
      content: |
        [Match]
        Name=eno1

        [Network]
        DNS=10.58.32.32
        Address=10.58.120.156/23
        Gateway=10.58.120.1
{% endhighlight %}

 

接着输入coreos-install -d /dev/sda -C beta -c coreos-install-example.yaml即可安装。安装过程中，CoreOS会再去网上下载一个与LiveCD同版本号的coreos.tar文件进行解压缩并安装的。事实上CoreOS的安装过程大致分为，

* 下载coreos.tar
* 格式化分区
* 解压缩coreos.tar到新分区
* 把安装配置文件yaml里面的具体项逐一展开对新分区里面的物理文件
* 重启进入新系统（手动）

注意事项：

* CoreOS安装完成之后没有默认的root的密码，故需要在yaml里面配置一个ssh_authorized_keys，使用用户core加私钥进行ssh连接
* 本文贴的yaml文件是一个示例，在使用时把里面的信息改成自己需要的值
* 示例里面的20-proxy.conf是因为公司网络需要设置代理才能上外网，故加之
* 示例里面配置了静态IP，是因为公司网络对服务器不允许使用DHCP
* 示例里面的50-insecure-registry.conf增加了对docker tcp 7777端口的匿名访问，实属不安全的做法，不推荐
* 示例里面把coreos update engine服务禁用了，是因为服务器不希望频繁升级导致重启（关于CoreOS的升级策略请参考官方文档）
* 更多安装信息请参考CoreOS[官方文档](https://coreos.com/docs/running-coreos/bare-metal/installing-to-disk/)

### 创建集群
CoreOS使用etcd创建集群，使用fleet来调度任务。etcd以自举的方式维护集群，强一致性算法保证集群里始终只有一个lead。对于消费者而言，无须知道当前时刻集群lead是谁，对机器里任何一台节点发送命令都可以达到同样的效果。fleet扩展了systemd的配置功能，使用户可以像编写systemd的服务文件那样来编写fleet的单元文件。

同样，参考示例yaml文件，里面有一段etcd的配置是用来组建集群的。



{% highlight yaml %}
  etcd:
      name: cnpvg50859256
      # generate a new token for each unique cluster from https://discovery.etcd.io/new
      # discovery: https://discovery.etcd.io/d43034d6ed8451ffadb683e381f187fb
      # Support corporate proxy via env var -> https://github.com/coreos/etcd/pull/909
      # discovery-proxy: http://proxy.wdf.sap.corp:8080
      # multi-region and multi-cloud deployments need to use $public_ipv4
      addr: 10.58.120.156:4001
      peer-addr: 10.58.120.156:7001
      # we don't rely on discovery, we join the cluster manually
      peers: 10.58.136.96:7001
{% endhighlight %}


addr是节点的外网地址，peer-addr是内网地址。本系统不区分内外网故两者是一样的。其次，搭建集群时，第一个安装的CoreOS节点就是集群临时Lead，yaml里面最后面的peers不要写；其后安装的节点把peers写成第一台节点的地址即可。如此，第二台乃至第N台节点安装完毕后会自动加入集群。每当有新的节点加入集群，etcd会根据一系列复杂的算法推选出一个最合适的Lead，集群里有且只会有一个Lead。其实Lead是透明的，在对集群做操作时可以在任何一台节点上输入任何fleet命令并且得到同样的返回。

如 fleetctl list-machines会得到当前集群内所有的节点信息

{% highlight bash %}
$ fleetctl list-machines
MACHINE IP METADATA
0e259400... 10.58.136.164 journalnode=1,maxpod=4,memory=128GB,name=cnpvg50820393,role=slave
3f39385b... 10.58.120.156 maxpod=8,memory=256GB,name=cnpvg50859256,role=slave
4e5066e0... 10.58.136.96 journalnode=1,memory=64GB,name=cnpvg50817038,namenode=1,role=build
af502216... 10.58.114.66 maxpod=4,memory=128GB,name=cnpvg50839576,role=test
c0f2f2f5... 10.58.116.94 maxpod=8,memory=256GB,name=cnpvg50845796,role=slave
d5f5889d... 10.58.136.166 journalnode=1,memory=128GB,name=cnpvg50820394,namenode=1,role=master
{% endhighlight %}
 

而fleetctl list-units会得到当前集群内所有运行着的任务

{% highlight bash %}
$ fleetctl list-units
UNIT MACHINE ACTIVE SUB
b1db.service d5f5889d.../10.58.136.166 active running
cadvisor.service 0e259400.../10.58.136.164 active running
cadvisor.service 3f39385b.../10.58.120.156 active running
cadvisor.service 4e5066e0.../10.58.136.96 active running
cadvisor.service af502216.../10.58.114.66 active running
cadvisor.service c0f2f2f5.../10.58.116.94 active running
cadvisor.service d5f5889d.../10.58.136.166 active running
datanode.service 0e259400.../10.58.136.164 active running
... 
{% endhighlight %}

![9eaa699e]({{ site.BASE_PATH }}/assets/cloud/2015/9eaa699e.PNG)

关于如何使用fleet来创建任务以及如何调度任务，请参考CoreOS[官方文档](https://coreos.com/docs/launching-containers/launching/fleet-unit-files/)

以及数码海洋上面的一篇[教学文章](https://www.digitalocean.com/community/tutorials/how-to-use-fleet-and-fleetctl-to-manage-your-coreos-cluster)

### 如何把SAP Bussiness One安装到Docker容器里去
这个章节描述如何把SAP的产品容器化，虽说是干货，但是非常有针对性，读者可以选择性阅读。

**SAP HANA**

SAP HANA是一套SAP自研的高性能内存式数据库。只能安装在SUSE Linux上面。安装包是一个install.sh文件外加一些tar文件（总共10GB）。这里的难点在于Docker没有提供SUSE的base image！笔者不才，花了3个礼拜时间才完成了SUSE母盘。其过程是郁闷且痛苦的，不堪回首。有了base image之后就容易了，这里没有用Dockerfile来安装HANA，而是手动启动SUSE image，然后把HANA安装进去的。因为HANA安装过程中需要执行privileged操作，所以是手动docker run --privileged的方式启动的。安装完后使用docker save导出HANA image，大小为22GB。哎，太大了，无法使用docker registry，只好自己想办法维护了。对hana.tar使用lz4压缩，最后缩减到8GB。通过nfs方式分发到每台slave节点。

PS：起草本文时docker registry对大文件（10GB以上）的支持可以说是奇烂无比，docker push一个30GB的文件需要4个小时，pull同样的文件需要10个小时。究其原因是docker在btrfs上对layer的存储方式导致了其读写的效率很低，与网络无关。故彻底放弃registry。

PS2：lz4压缩算法是目前"性价比"最高的算法，其压缩30GB文件只需要1分钟左右，平均压缩率在30~50%左右；而lzma或gzip压缩同样尺寸的文件虽然压缩比很高，但是时间太长，需要好几个小时。

**Server**

SAP Business One服务端安装程序是一套基于Java自研外加RPM配合的二进制文件，入口是一个install.sh文件。此程序的特点是需要安装在HANA box上面，其实间接的安装在SUSE Linux上面。其安装步骤是一个Dockerfile，里面的大体内容是from hana，启动hana service，然后执行install.sh。安装完后使用docker save导出SAP Business One的image，大小为35GB（因为包含了HANA的22GB）。由于nfs不是无限容量的，而且大文件分发太占用时间（千兆网络复制一个30GB文件需要5分钟，太慢了），所以需要对这个35GB的image做进一步优化！优化方案是解压缩tar包，删除HANA的layer，再压缩成tar包，最后用lz4压缩至4GB。因为所有的slave节点已经导入过HANA的image，所以再导入一个"残缺"的SAP Business One的image也是OK的。

总结一下，通过docker save/load + lz4的方式来半自动维护image的方式实属无奈之举，然而其性能之优确是目前最好的一种选择。Lz4解压缩外加docker load一个HANA image通常需要3分钟，Lz4解压缩外加docker load一个SAP Business One image通常需要2分钟。团队的服务器硬盘是SATA的，8个200GB组成一个1.6TB的RAID0。Slave节点的硬盘都是RAID0，因为不怕坏，容量高，速度快！

**Client**

SAP Business One客户端安装程序是一个基于InstallShield做出来的setup.msi文件。毋庸置疑，只能装在Windows上。解决方案是KVM！首先使用qemu-kvm创建一个win8.img（大约4GB），然后和一个带有kvm的Ubuntu系统一起做成一个docker容器！接着，每当用户请求某个SAP Business One版本时，系统会创建并启动一个全新的win8 image，然后动态的操作这个Windows系统为其按照指定版本的SAP Business One客户端。

PS：系统如何操作容器里面的Windows系统？答案是在制作win8.img的时候，扔一个基于Groovy的自研应用程序进去作为服务自启动。此服务负责接收HTTP请求并执行特定的命令。为什么不使用Windows默认支持的PowerShell进行RPC通讯？原因有二，其一是项目的控制中心是Jenkins，使其使用PowerShell与Windows通讯实属困难；其二是团队对PowerShell的知识积累不够用。

### 排坑
写到这里，基本上所有的功能模块介绍和其工作原理都有所提及了。然后，笔者来列数一下此系统研发时所遇到的各种各样的地雷吧。有些和docker有关，有些和CoreOS有关，有些和SAP产品有关。建议选择阅读。

**Fleet的稳定性问题**

笔者把这个问题列在第一，是因为其严重程度差一点就废了本项目！在开发结束第一次做集成测试的那天，系统遇到了灾难性的问题，云系统整体奔溃！其表现性状是当有5个以上并发请求时，系统就有可能出现所有fleet运行的单元无故死亡，并且无法自动恢复。这意为着系统的前台、后台、slave节点上面的所有跑着的实例全部奔溃。经排查，发现问题出在fleet上面！总结一下，fleet的非global单元会跑在满足特定条件的节点上面，当fleet发现集群里的节点变得"不够平衡"时，它尝试把某些单元"飘"到另一些满足条件的节点上，而这个"飘"经常会失败。所以最终看到几乎所有服务全部死亡的惨状。解决方案：把所有单元设置成global并且只让他们跑在一台特定的节点上（本例为master节点）。

**Docker的Overlay驱动问题**

本文多次提及制作出的image尺寸之大，已远超docker的最佳实践。但是万万没想到的是，尺寸大会带来另一个问题。那就是当CoreOS升级到某个特定版本时，其底层的文件系统由早期的btrfs变更为extfs + overlay。这是系统灾难的开始。最初，发现HANA的image无法正常启动，后来又发现win8的image无法启动。究其原因，是overlayfs不支持2.5GB以上尺寸文件的写入。请参考bug https://github.com/docker/docker/issues/11700 。目前没有workaround，解决方案是暂时回退CoreOS到一个低版本。

**Docker的Registry大文件问题**

关于大文件，本文提及多次了。总之，当前版本的Registry对大文件支持的不好，故项目使用了docker save/load + lz4 + nfs的解决方案。

**HANA安装时Privilege问题**

HANA安装需要执行privileged操作，无语。Dockerfile无法执行privileged操作。有热心的网友提出建议，希望docker提供一个PRUN指令用以执行特权命令。

**HANA运行时AIO问题**

HANA运行时需要初始化一个很大的AIO（异步IO数）。此问题表现为运行第一个HANA实例时没问题，第二个也OK，第三个就启动失败，以后每一个都启动失败。研究表明，AIO是host与容器共享的。解决方案是修改host的AIO数量，根据Oracle给出的最佳实践，这个值设定为1048576最为理想。fs.aio-max-hr=1048576。

### 后记
起草本文时云系统已经无重大故障稳定运行了三个月了。在这三个月里面，系统还平滑了大小升级了几次，服务客户数累计到达868次。是团队内部运行的相对较成功的项目之一！

本文写了四千多字，如果读者能耐心的看到这里，说明你一定也做了（或者想做）与本文相似的事情。笔者只想说，在技术的海洋里漫游是乐趣无穷但又辛苦万分的！作为技术人员，每个人需要有充足的耐心去克服和逾越各种障碍和壁垒，要有一颗追求完美的心去探索和发现，并且持之以恒！最后，祝所有开发人员写代码零bug，测试人员天天无事干，运维人员零灾难。
