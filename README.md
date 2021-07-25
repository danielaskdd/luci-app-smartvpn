# luci-app-smartvpn

SmartVPN - select the best gateway depend on domain or network segment.

### 说明

根据域名选择最佳的上网路由。已经内嵌了gfwlist清单。支持香港和美国双路由选择，对香港出口访问比较快的域名或网段，放入香港主机列表即可。SmartVPN使用SoftEther构建虚拟网卡，从网络层实现智能路由，让家庭的所有设备都无障碍上网。

### 使用方法

* 安装

```
SmartVPN会使用到一下软件，请事先安装好这些软件：
1. mwan3 和 luci-app-mwan3
2. colled 和 luci-app-statistic
3. nlbwmon 和 luci-app-nlbwmon

注：安装SmartVPN时会自动配置以上软件
```

* 初始设置

安装完成后请需要使用SoftEther服务器管理工具设置出境网络通道，并对相关tap网卡设置好ip地址，方可启动SmartVPNap网卡按以下步骤进行设置：

```
1. 使用SoftEther服务器管理客户端连接路由器。连接端口为1193，密码为空，首次登录会要求给SoftEther服务设置初始密码。
2. 为SoftEther的虚拟HUB01配置级联服务器，连接到香港SoftEther出口；虚拟HUB02连接到美国SoftEther出口。
3. 通过OpenWrt的管理界面给vpnhub01网卡设置一个ip，该ip与HUB01香港网关的ip同属一个网段。例如，香港网关为192.168.29.1，则vpnhub01网卡ip可以设置为192.168.29.50）。
4. 按上述同样方法给vpnhub01网卡设置一个ip。
```

* 启动与停止SmartVPN

```
1. 在通过SmartVPN概览页面勾选或取消勾选“已启用”选框，然后点击“保存并应用”按钮，即可启动或停止服务。用这种方式启动时根据域名匹配得到的ip路由都会全部清除。
2. 点击SmartVPN概览页面的“软启动”，此时会让新添加的主机列表生效，但却不会清空之前匹配到的ip路由。
```

* 快照功能

```
1. 保存快照：把当时的ip路由保存起来
2. 恢复快照：把之前保存的ip路由添加进来
```

