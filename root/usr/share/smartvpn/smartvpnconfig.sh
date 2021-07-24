#!/bin/sh

############################################
# smartvpn configuration scrip
# create by Daniel Yang 2021-07-22
############################################

. /lib/functions.sh
. /lib/functions/network.sh

cd "$( dirname $0 )"

. ./conf/network.conf
. ./conf/firewall.conf

process_network_firewall() {

# processing network lan interface(modify only)
config_cb() {
    local stype="$1"
    local sname="$2"
    if [[ "$stype" == "interface" && "$sname" == "$SMARTVPN_LAN_NAME" ]]; then

        echo 
        echo "Processing: network lan interface"

        if [[ "$SET_LOCALIP" == 1 ]]; then
            echo " -- setting lan ip by config"
            uci -q batch <<-EOF >/dev/null
                set network.$sname.ipaddr="$SMARTVPN_LAN_ADDR_IP4"
                set network.$sname.netmask="$SMARTVPN_LAN_MASK_IP4"
                set network.$sname.dns="$SMARTVPN_LAN_DNS_IP4"
                set network.$sname.ifname="$SMARTVPN_LAN_IFNAME"
                commit network
EOF
        else
            uci -q batch <<-EOF >/dev/null
                set network.$sname.ifname="$SMARTVPN_LAN_IFNAME"
                commit network
EOF
        fi
        uci show network.$sname

    fi
}
config_load network
reset_cb 

# process vpn tap interface (replace if already exists)
echo
echo "Processing: vpn tap interface"
uci -q batch <<-EOF >/dev/null
	delete network.$SMARTVPN_LANMAN_NAME
    set network.$SMARTVPN_LANMAN_NAME=interface
	set network.$SMARTVPN_LANMAN_NAME.ifname="$SMARTVPN_LANMAN_IF"
    set network.$SMARTVPN_LANMAN_NAME.proto="$SMARTVPN_LANMAN_PROTO"
    set network.$SMARTVPN_LANMAN_NAME.auto="$SMARTVPN_LANMAN_AUTO"
    set network.$SMARTVPN_LANMAN_NAME.netmask="$SMARTVPN_LANMAN_MASK_IP4"
    set network.$SMARTVPN_LANMAN_NAME.force_link="$SMARTVPN_LANMAN_FOURCE_LINK"
    set network.$SMARTVPN_LANMAN_NAME.ipaddr="$SMARTVPN_LANMAN_ADDR_IP4"
    commit network
EOF
#echo "seting tap interface: $SMARTVPN_LANMAN_NAME"
uci show network.$SMARTVPN_LANMAN_NAME
uci -q batch <<-EOF >/dev/null
	delete network.$SMARTVPN_HUB01_NAME
    set network.$SMARTVPN_HUB01_NAME=interface
	set network.$SMARTVPN_HUB01_NAME.ifname="$SMARTVPN_HUB01_IF"
    set network.$SMARTVPN_HUB01_NAME.proto="$SMARTVPN_HUB01_PROTO"
    set network.$SMARTVPN_HUB01_NAME.auto="$SMARTVPN_HUB01_AUTO"
    set network.$SMARTVPN_HUB01_NAME.netmask="$SMARTVPN_HUB01_MASK_IP4"
    set network.$SMARTVPN_HUB01_NAME.force_link="$SMARTVPN_HUB01_FOURCE_LINK"
    set network.$SMARTVPN_HUB01_NAME.ipaddr="$SMARTVPN_HUB01_ADDR_IP4"
    set network.$SMARTVPN_HUB01_NAME.metric="$SMARTVPN_HUB01_METRIC"
    set network.$SMARTVPN_HUB01_NAME.gateway="$SMARTVPN_HUB01_GATEWAY_IP4"
    commit network
EOF
#echo "seting tap interface: $SMARTVPN_HUB01_NAME"
uci show network.$SMARTVPN_HUB01_NAME
uci -q batch <<-EOF >/dev/null
	delete network.$SMARTVPN_HUB02_NAME
    set network.$SMARTVPN_HUB02_NAME=interface
	set network.$SMARTVPN_HUB02_NAME.ifname="$SMARTVPN_HUB02_IF"
    set network.$SMARTVPN_HUB02_NAME.proto="$SMARTVPN_HUB02_PROTO"
    set network.$SMARTVPN_HUB02_NAME.auto="$SMARTVPN_HUB02_AUTO"
    set network.$SMARTVPN_HUB02_NAME.netmask="$SMARTVPN_HUB02_MASK_IP4"
    set network.$SMARTVPN_HUB02_NAME.force_link="$SMARTVPN_HUB02_FOURCE_LINK"
    set network.$SMARTVPN_HUB02_NAME.ipaddr="$SMARTVPN_HUB02_ADDR_IP4"
    set network.$SMARTVPN_HUB02_NAME.metric="$SMARTVPN_HUB02_METRIC"
    set network.$SMARTVPN_HUB02_NAME.gateway="$SMARTVPN_HUB02_GATEWAY_IP4"
    commit network
EOF
#echo "seting tap interface: $SMARTVPN_HUB02_NAME"
uci show network.$SMARTVPN_HUB02_NAME

# processing network static route(replace if already exist)
delete_route() {
    local config="$1"
    local rttarget

    config_get rttarget "$config" target
    if [[ "$rttarget" == "1.1.1.1" || "$rttarget" == "8.8.8.8" ]]; then
        echo "Old route target $rttarget found, deleting..."
        uci delete network.$config
        #echo "session: $config"
    fi
}
echo 
echo "Processing: network static route"
config_load network
config_foreach delete_route route
uci commit network
echo "Adding static route for 1.1.1.1 and 8.8.8.8"
uci -q batch <<-EOF >/dev/null
	add network route
	set network.@route[-1].target=$SMARTVPN_ROUTE_DNS01_TG
    set network.@route[-1].gateway=$SMARTVPN_ROUTE_DNS01_GW
    set network.@route[-1].interface=$SMARTVPN_ROUTE_DNS01_IF
	add network route
	set network.@route[-1].target=$SMARTVPN_ROUTE_DNS02_TG
    set network.@route[-1].gateway=$SMARTVPN_ROUTE_DNS02_GW
    set network.@route[-1].interface=$SMARTVPN_ROUTE_DNS02_IF
    commit network
EOF

# process firewall defauls
config_cb() {
    local stype="$1"
    local sname="$2"
    if [[ "$stype" == "defaults" ]]; then
        echo 
        echo "Processing: firewall zone defaults"
        uci -q batch <<-EOF >/dev/null
            set firewall.$sname.input="$SMARTVPN_FW_DEFAULT_INPUT"
            set firewall.$sname.output="$SMARTVPN_FW_DEFAULT_OUTPUT"
            set firewall.$sname.forward="$SMARTVPN_FW_DEFAULT_FORWARD"
            set firewall.$sname.synflood_protect="$SMARTVPN_FW_DEFAULT_SYNFLOOD"
            commit firewall
EOF
        uci show firewall.$sname
    fi
}
config_load firewall
reset_cb 

# processing firewall zones
handle_zone() {
    local config="$1"
    local zname
    config_get zname "$config" name

    if [[ "$zname" == "$SMARTVPN_FW_LAN_NAME" ]]; then
        echo "Updating zone $zname($config) setting"
        uci -q batch <<-EOF >/dev/null
            set firewall.$config.network="$SMARTVPN_FW_LAN_IF"
            set firewall.$config.input="$SMARTVPN_FW_LAN_INPUT"
            set firewall.$config.output="$SMARTVPN_FW_LAN_OUTPUT"
            set firewall.$config.forward="$SMARTVPN_FW_LAN_FORWARD"
EOF
        uci show firewall.$config
    elif [[ "$zname" == "$SMARTVPN_FW_WAN_NAME" ]]; then
        echo "Updating zone $zname($config) setting"
        uci -q batch <<-EOF >/dev/null
            set firewall.$config.network="$SMARTVPN_FW_WAN_IF"
            set firewall.$config.input="$SMARTVPN_FW_WAN_INPUT"
            set firewall.$config.output="$SMARTVPN_FW_WAN_OUTPUT"
            set firewall.$config.forward="$SMARTVPN_FW_WAN_FORWARD"
            set firewall.$config.masq="$SMARTVPN_FW_WAN_MASQ"
            set firewall.$config.mtu_fix="$SMARTVPN_FW_WAN_MTU"
EOF
        uci show firewall.$config
    elif [[ "$zname" == "$SMARTVPN_FW_LANMAN_NAME" ]]; then
        echo "Old zone $zname($config) found, delete..."
        uci delete firewall.$config
    fi
}
echo
echo "Processing: firewall zones"
config_load firewall
config_foreach handle_zone zone
uci commit firewall
echo "Adding zone $SMARTVPN_FW_LANMAN_NAME"
config=`uci -q batch` <<-EOF
	add firewall zone
	set firewall.@zone[-1].name=$SMARTVPN_FW_LANMAN_NAME
    set firewall.@zone[-1].network=$SMARTVPN_FW_LANMAN_IF
    set firewall.@zone[-1].input=$SMARTVPN_FW_LANMAN_INPUT
    set firewall.@zone[-1].output=$SMARTVPN_FW_LANMAN_OUTPUT
    set firewall.@zone[-1].forward=$SMARTVPN_FW_LANMAN_FORWARD
    commit firewall
EOF
uci show firewall.$config

# processing firewall forwarding rule
handle_forwarding() {
    local config="$1"
    local dest
    local src
    config_get dest "$config" dest
    config_get src "$config" src

    if [[ "$dest" == "$SMARTVPN_FW_LAN_WAN_FORWARD_DEST" && "$src" == "$SMARTVPN_FW_LAN_WAN_FORWARD_SRC" ]]; then
        echo "Old forwarding rule $src->$dest found, deleting"
        uci delete firewall.$config
    elif [[ "$dest" == "$SMARTVPN_FW_LAN_LANMAN_FORWARD_DEST" && "$src" == "$SMARTVPN_FW_LAN_LANMAN_FORWARD_SRC" ]]; then
        echo "Old forwarding rule $src->$dest found, deleting"
        uci delete firewall.$config
    elif [[ "$dest" == "$SMARTVPN_FW_LANMAN_LAN_FORWARD_DEST" && "$src" == "$SMARTVPN_FW_LANMAN_LAN_FORWARD_SRC" ]]; then
        echo "Old forwarding rule $src->$dest found, deleting"
        uci delete firewall.$config
    fi
}
echo
echo "Processing: firewall forwarding rule"
config_load firewall
config_foreach handle_forwarding forwarding
uci commit firewall
echo "Adding forwarding rule for lan->wan and lan<->lanman"
config=`uci -q batch` <<-EOF
	add firewall forwarding
	set firewall.@forwarding[-1].dest=$SMARTVPN_FW_LAN_WAN_FORWARD_DEST
    set firewall.@forwarding[-1].src=$SMARTVPN_FW_LAN_WAN_FORWARD_SRC
    commit firewall
EOF
uci show firewall.$config
config=`uci -q batch` <<-EOF
	add firewall forwarding
	set firewall.@forwarding[-1].dest=$SMARTVPN_FW_LAN_LANMAN_FORWARD_DEST
    set firewall.@forwarding[-1].src=$SMARTVPN_FW_LAN_LANMAN_FORWARD_SRC
    commit firewall
EOF
uci show firewall.$config
config=`uci -q batch` <<-EOF
	add firewall forwarding
	set firewall.@forwarding[-1].dest=$SMARTVPN_FW_LANMAN_LAN_FORWARD_DEST
    set firewall.@forwarding[-1].src=$SMARTVPN_FW_LANMAN_LAN_FORWARD_SRC
    commit firewall
EOF
uci show firewall.$config

# processing firewall wan access rule
handle_rule() {
    local config="$1"
    local src
    local dest
    local dest_port
    local proto
    local name
    
    config_get src "$config" src "x"
    config_get dest "$config" dest "x"
    config_get dest_port "$config" dest_port "x"
    config_get proto "$config" proto "x"
    config_get name "$config" name "x"

    if [[ "$name" == "$SMARTVPN_FW_SEMAN_NAME" ]]; then
        echo "Old $SMARTVPN_FW_SEMAN_NAME($config) rule found, deleting"
        uci delete firewall.$config
    elif [[ "$name" == "$SMARTVPN_FW_SEUDP_NAME" ]]; then
        echo "Old $SMARTVPN_FW_SEUDP_NAME($config) rule found, deleting"
        uci delete firewall.$config
    elif [[ "$dest" == "$SMARTVPN_FW_IPSEC_DEST" && "$src" == "$SMARTVPN_FW_IPSEC_SRC" && "$proto" == "$SMARTVPN_FW_IPSEC_PROTO" ]]; then
        echo "Old $SMARTVPN_FW_IPSEC_NAME($config) rulefound, deleting"
        uci delete firewall.$config
    elif [[ "$dest" == "$SMARTVPN_FW_ISAKMP_DEST" && "$src" == "$SMARTVPN_FW_ISAKMP_SRC" && "$dest_port" == "$SMARTVPN_FW_ISAKMP_DEST_PORT" ]]; then
        echo "Old $SMARTVPN_FW_ISAKMP_NAME($config) rule found, deleting"
        uci delete firewall.$config
    elif [[ "$src" == "$SMARTVPN_FW_SSH_SRC" && "$dest_port" == "$SMARTVPN_FW_SSH_DEST_PORT" ]]; then
        echo "Old $SMARTVPN_FW_SSH_NAME($config) rule found, deleting"
        uci delete firewall.$config
    fi
}
echo
echo "Processing: firewall wan access rule"
config_load firewall
config_foreach handle_rule rule
uci commit firewall
echo "Adding new $SMARTVPN_FW_IPSEC_NAME rule"
config=`uci -q batch` <<-EOF
	add firewall rule
	set firewall.@rule[-1].name="$SMARTVPN_FW_IPSEC_NAME"
    set firewall.@rule[-1].src="$SMARTVPN_FW_IPSEC_SRC"
    set firewall.@rule[-1].dest="$SMARTVPN_FW_IPSEC_DEST"
    set firewall.@rule[-1].proto="$SMARTVPN_FW_IPSEC_PROTO"
    set firewall.@rule[-1].target="$SMARTVPN_FW_IPSEC_TARGET"
    commit firewall
EOF
uci show firewall.$config
echo "Adding new $SMARTVPN_FW_ISAKMP_NAME rule"
config=`uci -q batch` <<-EOF
	add firewall rule
	set firewall.@rule[-1].name="$SMARTVPN_FW_ISAKMP_NAME"
    set firewall.@rule[-1].src="$SMARTVPN_FW_ISAKMP_SRC"
    set firewall.@rule[-1].dest="$SMARTVPN_FW_ISAKMP_DEST"
    set firewall.@rule[-1].proto="$SMARTVPN_FW_ISAKMP_PROTO"
    set firewall.@rule[-1].dest_port="$SMARTVPN_FW_ISAKMP_DEST_PORT"
    set firewall.@rule[-1].target="$SMARTVPN_FW_ISAKMP_TARGET"
    commit firewall
EOF
uci show firewall.$config
echo "Adding new $SMARTVPN_FW_SSH_NAME rule"
config=`uci -q batch` <<-EOF
	add firewall rule
	set firewall.@rule[-1].name="$SMARTVPN_FW_SSH_NAME"
    set firewall.@rule[-1].src="$SMARTVPN_FW_SSH_SRC"
    set firewall.@rule[-1].src_ip="$SMARTVPN_FW_SSH_SRC_IP"
    set firewall.@rule[-1].dest_port="$SMARTVPN_FW_SSH_DEST_PORT"
    set firewall.@rule[-1].target="$SMARTVPN_FW_SSH_TARGET"
    commit firewall
EOF
uci show firewall.$config
echo "Adding new $SMARTVPN_FW_SEMAN_NAME rule"
config=`uci -q batch` <<-EOF
	add firewall rule
	set firewall.@rule[-1].name="$SMARTVPN_FW_SEMAN_NAME"
    set firewall.@rule[-1].src="$SMARTVPN_FW_SEMAN_SRC"
    set firewall.@rule[-1].dest_port="$SMARTVPN_FW_SEMAN_DEST_PORT"
    set firewall.@rule[-1].target="$SMARTVPN_FW_SEMAN_TARGET"
    commit firewall
EOF
uci show firewall.$config
echo "Adding new $SMARTVPN_FW_SEUDP_NAME rule"
config=`uci -q batch` <<-EOF
	add firewall rule
	set firewall.@rule[-1].name="$SMARTVPN_FW_SEUDP_NAME"
    set firewall.@rule[-1].src="$SMARTVPN_FW_SEUDP_SRC"
    set firewall.@rule[-1].proto="$SMARTVPN_FW_SEUDP_PROTO"
    set firewall.@rule[-1].dest_port="$SMARTVPN_FW_SEUDP_DEST_PORT"
    set firewall.@rule[-1].target="$SMARTVPN_FW_SEUDP_TARGET"
    commit firewall
EOF
uci show firewall.$config

}

check_installed_package(){
    local _packagename=$1
    _tmpPackage=$(opkg list-installed | grep "$_packagename" | awk '{print $1}' 2>/dev/null)
    if [[ -z "$_tmpPackage" ]]; then
        echo "package $_packagename is missing"
        return 1
    fi
    return 0
}

check_env(){
    check_installed_package dnsmasq-full && check_installed_package softethervpn-server \
        && check_installed_package mwan3 && check_installed_package luci-app-smartvpn

    if [ $? -ne 0 ]; then
        echo "Error: required package is missing. Config abort!"
        exit 2
    fi

    return 0
}

SMARTVPN_BACKUP_DIR=/etc/smartvpn/backup
backup_file(){
    local ifname=$1
    local bfname=$( basename $ifname )
    local today=$( date +%Y%m%d )
    local num=0
    local prefix=''
    local ofname

    [[ ! -d $SMARTVPN_BACKUP_DIR ]] && mkdir $SMARTVPN_BACKUP_DIR

    ofname=$SMARTVPN_BACKUP_DIR/$bfname
    while [ -e $ofname ]; do
        num=$(( $num + 1 ))
        prefix=$( printf '%s-%03d-' $today $num )
        ofname=$SMARTVPN_BACKUP_DIR/$prefix$bfname
    done
    [[ -e $SMARTVPN_BACKUP_DIR/$bfname ]] && mv $SMARTVPN_BACKUP_DIR/$bfname $ofname
    cp -p $ifname $SMARTVPN_BACKUP_DIR/$bfname
}

usage()
{
    echo
    echo "Usage: smartvpnconfig.sh  --norestart --localip [all] [network] [mwan3] [nlbwmon] [statistics] [vpnserver] [domain]"
    echo
    echo "  all: config all settings (use --localip)"
    echo "  network: resotre network setting (use --localip)"
    echo "  mwan3: restore mwan3 setting"
    echo "  nlbwmon: restore nlbwmon setting"
    echo "  statistics: restore luci-statisitics setting"
    echo "  vpnserver: restore vpnserver setting"
    echo "  domain: restore system domain setting(mainland/hongkong/oversea)"
    echo
    echo "  --localip: restore route's LAN ip (uses with 'network' or 'all' command)"
    echo "  --norestart: do not restart SmartVPN when config is done"
    echo 
    return
}

action=""
SET_LOCALIP=0
DO_NOT_RESTART=0

while [ -n "$1" ]; do
    case $1 in
    network|mwan3|nlbwmon|statistics|vpnserver|domain)
        action="$action $1"
        ;;

    all)
        action="network mwan3 nlbwmon statistics vpnserver domain"
        ;;

    --localip)
        SET_LOCALIP=1
        ;;

    --norestart)
        DO_NOT_RESTART=1
        ;;

    *)
        echo "Error: unreconize action or option"
        usage
        exit 0
        ;;

    esac
    shift
done

if [[ -z "$action"  ]]; then
    usage
    exit 0
fi

# echo "Action: $action"

# 检查安装环境
check_env

case $action in
    *vpnserver*) 
    if [[ -f ./service/vpn_server.config ]]; then
        echo
        echo "Stoping vpnserver"
        /etc/init.d/softethervpnserver stop
        echo "Updating vpnserver config..."
        sleep 3
        backup_file /usr/libexec/softethervpn/vpn_server.config
        cp -p ./service/vpn_server.config /usr/libexec/softethervpn/vpn_server.config
        echo "Starting vpnserver"    
        /etc/init.d/softethervpnserver start
        sleep 3
        grep 'declare Cascade0' ./service/vpn_server.config > /dev/null
        if [ $? -ne 0 ]; then
            echo "The vpnserver must be setup with cascade connects for SmartVPN to work!"
            echo "Windos SoftEther server management tool to recommended, default password is 'gzdaniel'"
        fi
    else
        echo
        echo "Configuration file for vpnserver is missing !!!"
    fi
esac

case $action in
    *network*) 
    backup_file /etc/config/network
    backup_file /etc/config/firewall
    process_network_firewall
    echo 
    echo "Restarting network..."
    /etc/init.d/network restart
    sleep 2
esac

case $action in
    *nlbwmon*) 
    echo
    echo "Updating nlbwmon config..."
    backup_file /etc/config/nlbwmon
    backup_file /usr/share/nlbwmon/protocols
    cp -p ./service/nlbwmon /etc/config/nlbwmon
    cp -p ./service/protocols /usr/share/nlbwmon/protocols
    echo "Restarting nlbwmon service..."
    /etc/init.d/nlbwmon restart
esac

case $action in
    *statistics*) 
    echo
    echo "Updating luci_statistics config..."
    backup_file /etc/config/luci_statistics
    cp -p ./service/luci_statistics /etc/config/luci_statistics
    echo "Restarting luci_statistics service..."
    /etc/init.d/collectd restart
    /etc/init.d/luci_statistics restart
    rm -f /tmp/luci-indexcache*
    rm -rf /tmp/luci-modulecache/
esac

case $action in
    *mwan3*) 
    echo
    echo "Updating mwan3 to config..."
    backup_file /etc/config/mwan3
    cp -p ./service/mwan3 /etc/config/mwan3
esac

case $action in
    *domain*) 
    echo
    echo "Updating system mainland domain..."
    backup_file /etc/smartvpn/proxy_mainland.txt
    cp -p ./proxy/proxy_mainland.txt /etc/smartvpn/proxy_mainland.txt

    echo
    echo "Updating system hongkong domain..."
    backup_file /etc/smartvpn/proxy_hongkong.txt
    cp -p ./proxy/proxy_hongkong.txt /etc/smartvpn/proxy_hongkong.txt

    echo
    echo "Updating system oversea domain..."
    backup_file /etc/smartvpn/proxy_oversea.txt
    cp -p ./proxy/proxy_oversea.txt /etc/smartvpn/proxy_oversea.txt
    ;;
esac

if [[ "$DO_NOT_RESTART" == 0 ]]; then
    case $action in
        *mwan3*|*domain*|*network*|*vpnserver*) 
        echo
        echo "Restarting SmartVPN..."
        /etc/init.d/smartvpn restart
        ;;
    esac
fi

echo
echo "--- Config is done ---"
exit 0
