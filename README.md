# luci-app-smartvpn

SmartVPN - select the best gateway depend on domain or network segment.

## 概述

SmartVPN插件为OpenWrt路由器提供TCP/IP层的智能路由功能，根据域名选择最佳的上网路由，路由器管辖网络范围内所有设备自由上网。支持香港和美国双路由选择，自己灵活定义规则，访问海外网站不再绕路。SmartVPN使用SoftEther构建虚拟网卡，从网络层实现智能路由，使用mwan3设置路由规则，方便灵活扩展。系统使用白名路由逻辑，内置gfwlist清单，能够自动识别绝大多数走海外路由的网站。对个别无法自动识别的网站，自己把域名添加进去即可。

使用本插件需要有能力在海外搭建SoftEther服务。搭建好的SoftEthe服务可以多个家庭共享。

## 安装

### 使用安装包安装

* 安装核心依赖环境

```sh
opkg update
opkg install dnsmasq-full
opkg install softether-server
```

* 安装其它依赖环境（通常路由器已经默认安装）

```sh
opkg install mwan3 luci-app-mwan3
opkg install nlbwmon luci-app-nlbwmon
opkg install collectd collectd-mod-thermal luci-app-statistics
```

* 下载 package-release 目录下的安装包到路由器，然后运行

```sh
opkg install luci-app-smartvpn...    # 主程序
opkg install luci-i18n-smartvpn...   # 语言包
```

### 源码安装

* 下载源代码并添加到openwrt源码目录： ./feeds/luci/application
* 把feeds注册到到package中

```sh
./scripts/feeds update luci
./scripts/feeds install -a -p luci
```

* 配置编译模块

```sh
make menuconfig

# 选择安装以下模块
# - dnsmasq-full（去掉dnsmasq）
# - openssh-sftp-server
# - ipepf3
# - softether-server
# - smartvpn
# - mwan3
# - nlbwmon
# - collectd
# - collectd-mod-exec
# - collectd-mod-ping
# - collectd-mod-thermal
# - luci > translate: 简体+繁体
# - luci-app-smatvpn
# - luci-app-mwan3
# - luci-app-nlbmon
# - luci-app-statistic
```

* 如果您之前已经有配置好的SoftEther服务器配置文件可以把它替换掉以下位置的文件：./root/usr/smartvpn/service/vpn_server.config
  
* 安正常方式编译和烧录OpengWrt固件

### 初始设置

* 在海外出口搭建SoftEther服务

租用海外的VPS，在其上搭建SoftEther服务。我们只需要用到SoftEhter中和小一部分功能，只需要在VPS安装和启动SoftEther服务，建立一个虚拟Hub，然后在这个虚拟Hub上开启SecureNAT功能，让后就可以通过这台VPS访问互联网了。网上有许多SoftEther的安装教程，这里推荐一个比较简单的：[SoftEther安装配置教程](https://www.lixh.cn/archives/2647.html)。

* 把Smar他VPN中的SoftEther与海外出口桥接

系统安装成功后在首次启动时会给softehter服务配置好一个框架。此时softether后会建立好最少三个虚拟交换机`HUB01`、`HUB02`和`MYHUB`。其中HUB01用于与香港出口连接，通过接口`VPNHUB02`与路由器连接；HUB02用于与美国出口连接，通过接口`VPNHUB02`与路由器连接；`MYHUB`用于接受vpn拨号，让移动用户可以访问当前路由器所管辖的局域网，通过虚拟网卡`tap_myhub`路由起的`LAN`接口桥接。可以在OpenWrt的Web的接口管理页面看到。

为了建立海外访问出口，你需要在香港和美国搭建一个SoftEther服务器，然后把路由器的SoftEther服务中的HUB01和HUB02分别于香港和美国的SoftEther建立级联关系。

管理SoftEther需要使用到其服务器管理工具。建立海外SoftEther服务的安装包和管理工具可以用过以下地址下载：[SoftEther下载中心](https://www.softether-download.com/cn.aspx?product=softether)。

SmartVPN已经给softehter服务进行了初始配置。使用管理工具首次连接时，连接端口需要设为1193，无需设置密码，首次连接时管理工具会要求为SoftEhter设置一个管理密码。

在配置好路由器上的SofTther于香港和美国的级联关系后，还需要在OpenWrt上为对应的接口（网卡）设置ip地址，这样SmartVPN才能够通过对应的接口访问海外网络。接口的ip设置需要于对应的海外网关处于同一个网段。例如例如，香港网关为`192.168.29.1`，则`VPNHUB01`接口的ip可以设置为`192.168.29.11`，掩码为`255.255.255.0`，网关为`192.168.29.1`, 网关跃点为`200`.需要注意的网关跃点不能够为默认值0，否则在SmartVPN未启用的时候，所有网络流量都会走该网关。这样就会导致访问国内网站变慢，并白白耗费掉国际出口的流量。

配置好ip后可以使用路由器Web管理界面的“网络诊断“页面测试以下是否可以Ping通网关的ip。

### SmartVPN使用说明

* 服务的启停

系统安装完成后在OpenWrt的Web管理界面中的网络菜单中会出现“SmartVPN“选项。在完成上面所述的初始设置后，点击进入“概览”页面的设置中勾选“已启用”，然后然后点击“保存并应用”按钮即启动SmartVPN。启动后页面的信息栏目可以看到启动状态和当前智能路由中命中的内地、香港和海外ip数量。您在访问还望网络时，命中的ip数量会实时更新。

* 保存快照与恢复

可以把当时SmartVPN匹配的ip集保存下来。日后路由器重启后可以随时恢复快照。

* 软重启

修改主机清单后可以使用软重启让清单马上生效，软重启不会清除掉当前的ip集，提升网络访问的畅顺成都。不使用软重启将会清除掉所有匹配的ip集，此时网络客户端如果使用之前DNS查询获得ip直接访问网络，可能导致无法获得正确的路由，

* 修改主机清单

系统设置了三个主机清单：内地、香港和海外。优先级别从左到右，内地最为优先，确保清单里面的主机使用路由其默认的互联网出口；香港其次，确保经香港出口访问较快的主机不绕路，获得最快的访问速度；海外优先级别最低，内置gfwlist域名和网段清单，仅需添加少量没有收录的网站到里面即可；没有在以上三个清单中的主机则使用默认互联网出口访问网络。修改主机清单后需要“软重启”SmartVPN服务才会生效。海外主机中内置的域名和网段会随版本而更新。你修改后的主机清单会在系统升级的时候保留。

主机清单中域名使用点开头，例如`.github.com`表示该匹配域名及其所有的子域名；网段CIDR格式（掩码位长度）表示，例如`23.0.0.0/8`表示以23开头的所有网络ip。

注：需要了解OpenWrt智能路由或SoftEther的朋友欢迎开Issue讨论。
