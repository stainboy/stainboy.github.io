---
title:  "原生云容器设计白皮书"
date:   2018-03-19
categories: container
description: "本文翻译自红帽 https://www.redhat.com/en/resources/cloud-native-container-design-whitepaper"
summary: "为了使容器化的应用程序能更好的成为原生云的标准公民，有一些设计原则是需要遵守的。遵循这些设计原则可以使你的应用被更多原生云平台（例如Kubernetes）所接受，并且可以更高效的予以自动化。"
---

*本文翻译自红帽 https://www.redhat.com/en/resources/cloud-native-container-design-whitepaper*

### 内容摘要
“原生云”是一个术语，用于描述专门为在云端运行而设计的应用程序。通常，原生云应用被设计成松耦合的微服务，并且运行在容器里，由云平台来管理。这些应用程序天然具备容错性，即使当底层的基础设施出现不可用时，它们仍然可以可靠的运行并且扩展自身规模。为了得到这样的能力，原生云平台会针对运行在上面的应用程序“强加”一些条款和约束。这些条款确保了应用程序遵循某些规范，并且允许云平台自动化管理容器化的应用程序。

许多组织意识到设计原生云应用程序的必要性和重要性，但是确无从着手。确保有一套原生云平台，以及运行在上面的容器化应用程序之间的无缝运行，可以带来超强的容错性，即使当底层的基础设施出现不可用时，它们仍然可以可靠的运行并且扩展自身规模。这本白皮书描述了容器设计的一些原则，只有遵循这些原则，应用程序才能成为原生云的良好公民。遵循这些设计原则可以使你的应用程序在各种原生云平台（例如Kubernetes）被自动化管理。

### 软件设计原则
原则存在于生活的许多领域，它们通常代表一个可以被其他人从中获取的基本的真理或信仰。在软件中，原则是相当抽象的准则，这些准则应该在设计软件时要遵循。 它们可以应于任何编程语言，采用不同的模式实现，并且实现了以下不同的做法。

通常情况下，模式和实践是用来实现设计原则结果的工具。编写高质量软件的设计原则总是出自一些核心原则。 这些原则包括：
- `KISS` -- Keep it simple, stupid. 简单就是美。
- `DRY` -- Don’t repeat yourself. 别做重复劳动。
- `YAGNI` -- You aren’t gonna need it. 别过渡设计（直到需要这个功能时才写代码）
- `SoC` -- Separation of concerns. 分离关注点。

即使这些原则并没有给出具体规范，他们也代表了一种语言和共同智慧，并且被许多开发人员理解并经常提及。

除此之外，还有由Robert C. Martin引入的SOLID原则（单一职责、开必原则、里氏替换，接口隔离，依赖倒置）。这些原则为编写更好的面向对象软件提供了指导思想。它是一个由互补原则组成的框架。这个框架也许会有不同的解读，但仍然作为面向对象设计的坚实基础。SOLID原则带给人们的期望是，只要用了，便可以创建一个具有更高质量的系统，并且从长期来看代码更易于维护。

SOLID原则使用面向对象的原语和概念（如`类`、`接口`和`继承`）来诠释面向对象设计。同样，针对云原生应用程序设计的原则，其主原语是`容器境像`而不是`类`。遵循这些原则，我们就有可能创造出更适合于原生云平台（如Kubernetes）的容器化应用。

### 红帽是如何设计原生云容器的？
如今，我们几乎可以将任何应用程序放入容器并运行它。 但是，要创建一个可以通过原生云平台（如Kubernetes）自动化管理和高效编排的容器化应用程序则需要付出更多的努力。

下面的想法受到许多其他作品的启发，如“应用程序的十二要素（[The Twelve-Factor App](https://12factor.net/)）”，它的范围很广，从源代码管理到应用程序可伸缩性模型。 但是，以下讨论的原则的范围将会限制在如何设计基于容器的微服务化的应用程序，并且能够被诸如Kubernetes等原生云平台所管理。

下面列出的创建容器化应用程序的设计原则使用`容器境像`作为基本原语，并使用`容器编排平台`作为目标容器运行时环境。 遵循这些原则将确保所产生的容器在大多数容器编排引擎中表现得像一个优秀的原生云公民，从而能够以自动化的方式调度，伸缩和监控它们。 以下原则重要性排名不分先后。

#### 单一关注原则 SINGLE CONCERN PRINCIPLE (SCP)
在许多方面，这一原则与SOLID的单一职责原则（SRP）相似，后者建议一个`类`应该只有一个职责。 SRP背后的动机是每个职责都是一个变化的枢纽，一个`类`应该有且只有一个理由去变更它。 SCP原则中的“关注”一词突出了关注点，认为这是一种比职责更高层次的抽象，它更好地将范围描述为一个`容器`而不是一个`类`。 虽然SRP的主要动机是有一个单一的变化原因，SCP的主要动机是`容器镜像`的重用和可替换性。 如果你创建一个只解决单个问题的容器，并且使其功能完整化，则在不同的应用程序上下文中重用容器镜像的可能性会更高。

因此，SCP原则规定每个容器都应该解决一个问题并做将它做到最好。 实现它比在面向对象的世界中实现SRP更容易，因为容器通常管理单个进程，并且大部分时间这个进程只处理单个问题。

![367f634a]({{ site.BASE_PATH }}/assets/cloud/2018/2018-03-21_21-20-42.png)

如果你的容器化微服务需要解决多个问题，那么请考虑使用诸如[sidecar](http://blog.kubernetes.io/2015/06/the-distributed-system-toolkit-patterns.html)和[init-containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)的模式将多个容器合并成一个单独的部署单元（[pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)），其中每个容器仍然处理单个问题。如此，你便可以替换解决相同问题的容器。 例如，将Web服务器容器或队列实现容器替换为更新且更具可扩展性的容器。

#### 高可观测性原则 HIGH OBSERVABILITY PRINCIPLE (HOP)
容器提供统一的打包和运行应用程序的方式，然而这种方式对待其内部却像黑匣子一样。 但任何旨在成为原生云公民的容器都必须为运行时环境提供相应的应用程序编程接口（API），以观察容器的健康状况及行为。 这是以统一的方式来自动化管理容器生命周期的基本先决条件，从而提高了系统的弹性和用户体验。

![367f634a]({{ site.BASE_PATH }}/assets/cloud/2018/2018-03-21_21-28-32.png)

在实践中，容器化应用程序至少需要提供两种健康检查API -- [liveness和readiness](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)。 即使是非常健康的应用程序也应该提供一些方法来观察容器化应用程序的状态。 应用程序应将重要事件记录到标准错误（STDERR）和标准输出（STDOUT）中，以便通过诸如`Fluentd`和`Logstash`等工具进行日志聚合，并与`跟踪`和`指标收集`类库（如OpenTracing，Prometheus等）进行集成。

把应用程序视为黑盒子，但实现所有必要的API以帮助云平台以最佳方式观察和管理你的应用程序。

#### 生命周期合规原则 LIFE-CYCLE CONFORMANCE PRINCIPLE (LCP)
HOP规定容器提供API供云平台消费。LCP规定应用程序获取来自云平台的事件。而且，除了获得事件之外，容器应该遵循规定对这些事件作出反应。这正是本原则的名称由来。这就好比在应用程序中使用“写API”来与平台进行交互。

![367f634a]({{ site.BASE_PATH }}/assets/cloud/2018/2018-03-21_21-30-00.png)

来自管理平台的所有事件都旨在帮助你管理容器的生命周期。决定处理哪些事件以及是否对这些事件做出反应完全取决于你的应用程序。

但有些事件尤为重要。例如，任何需要干净关闭进程的应用程序都需要捕获信号：`终止`（`SIGTERM`）消息并尽快关闭它。这是为了避免被另一个信号强制关闭：`杀死`（`SIGKILL`），它一般出现在`终止`信号之后。

还有一些其他事件，例如`启动后`(PostStart)和`停止前`(PreStop)，可能对你的应用程序生命周期管理很重要。例如，有些应用程序需要在服务请求之前进行预热，有些需要在关闭之前释放资源。

#### 镜像不可变原则 IMAGE IMMUTABILITY PRINCIPLE (IIP)
容器化应用程序生来是不可改变的，一旦构建完成，它将不会在不同的运行环境之间发生改变。这意味着必须使用外部手段来存储运行时数据，并依赖于随运行环境而变化的外部配置，而不是在每个运行环境中创建或修改容器。容器化应用程序的任何变更应该导致重新构建容器镜像并在所有环境中重用它。同样出名的原则还有`服务器不可变`/`基础架构不可变`，它们被用于服务器及主机管理。

![367f634a]({{ site.BASE_PATH }}/assets/cloud/2018/2018-03-21_21-31-43.png)

遵循IIP原则应禁止为不同运行环境创建类似的容器镜像，而是在每个运行环境中使用同一个容器镜像。此原则允许在应用程序更新期间实现自动回滚和前滚等操作，这是原生云自动化管理的一个重要方面。

#### PROCESS DISPOSABILITY PRINCIPLE (PDP)
One of the primary motivations for moving to containerized applications is that containers need to be as ephemeral as possible and ready to be replaced by another container instance at any point in time. There are many reasons to replace a container, such as failing a health check, scaling down the application, migrating the containers to a different host, platform resource starvation, or another issue.

![367f634a]({{ site.BASE_PATH }}/assets/cloud/2018/2018-03-21_21-32-52.png)

This means that containerized applications must keep their state externalized or distributed and redundant. It also means the application should be quick in starting up and shutting down, and even be ready for a sudden, complete hardware failure.

Another helpful practice in implementing this principle is to create small containers. Containers in cloud-native environments may be automatically scheduled and started on different hosts. Having smaller containers leads to quicker start-up times because before being restarted, containers need to be physically copied to the host system.

#### SELF-CONTAINMENT PRINCIPLE (S-CP)
This principle dictates that a container should contain everything it needs at build time. The container should rely only on the presence of the Linux ® kernel and have any additional libraries added into it at the time the container is built. In addition to the libraries, it should also contain things such as the language runtime, the application platform if required, and other dependencies needed to run the containerized application.

![367f634a]({{ site.BASE_PATH }}/assets/cloud/2018/2018-03-21_21-34-04.png)

The only exceptions are things such as configurations, which vary between different environments and must be provided at runtime; for example, through Kubernetes ConfigMap.

Some applications are composed of multiple containerized components. For example, a containerized web application may also require a database container. This principle does not suggest merging both containers. Instead, it suggests that the database container contain everything needed to run the database, and the web application container contain everything needed to run the web application, such as the web server. At runtime, the web application container will depend on and access the database container as needed.

#### RUNTIME CONFINEMENT PRINCIPLE (RCP)
S-CP looks at the containers from a build-time perspective and the resulting binary with its content. But a container is not just a single-dimensional black box of one size on the disk. Containers have multiple dimensions at runtime, such as memory usage dimension, CPU usage dimension, and other resource consumption dimensions.

![367f634a]({{ site.BASE_PATH }}/assets/cloud/2018/2018-03-21_21-35-20.png)

This RCP principle suggests that every container declare its resource requirements and pass that information to the platform. It should share the resource profile of a container in terms of CPU, memory, networking, disk influence on how the platform performs scheduling, auto-scaling, capacity management, and the general service-level agreements (SLAs) of the container.

In addition to passing the resource requirements of the container, it is also important that the application stay confined to the indicated resource requirements. If the application stays confined, the platform is less likely to consider it for termination and migration when resource starvation occurs.

### CONCLUSION
Cloud native is more than an end state — it is a way of working. This whitepaper described a number of principles that represent foundational guidelines that containerized applications must comply with in order to be good cloud-native citizens.

In addition to those principles, creating good containerized applications requires familiarity with other container-related best practices and techniques. While the principles described above are more fundamental and apply to most use cases, the best practices listed below require judgment on when to apply or not apply. Here are some of the more common container-related best practices:

- **Aim for small images**. Create smaller images by cleaning up temporary files and avoiding the installation of unnecessary packages. This reduces container size, build time, and networking time when copying container images.
- **Support arbitrary user IDs**. Avoid using the sudo command or requiring a specific userid to run your container.
- **Mark important ports**. While it is possible to specify port numbers at runtime, specifying them using the EXPOSE command makes it easier for both humans and software to use your image.
- **Use volumes for persistent data**. The data that needs to be preserved after a container is destroyed must be written to a volume.
- **Set image metadata**. Image metadata in the form of tags, labels, and annotations makes your container images more usable, resulting in a better experience for developers using your images.
- **Synchronize host and image**. Some containerized applications require the container to be synchronized with the host on certain attributes such as time and machine ID.

Here are links to resources with patterns and best practices to help you implement the above-listed principles more effectively:
- https://www.slideshare.net/luebken/container-patterns
- https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices
- http://docs.projectatomic.io/container-best-practices
- https://docs.openshift.com/enterprise/3.0/creating_images/guidelines.html
- https://www.usenix.org/system/files/conference/hotcloud16/hotcloud16_burns.pdf
- https://leanpub.com/k8spatterns/
- https://12factor.net/
