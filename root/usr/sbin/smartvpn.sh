#!/bin/sh

############################################
# smartvpn startup scrip for OpenWRT
# create by Daniel Yang 2021-06-18
#    1. translate domain & net definition in /etc/smartdns to dnsmasq configuration format
#    2. put the output file to /tmp/dnsmasq.d and restart dnsmasq
#    3. 
############################################

. /lib/functions.sh
. /lib/functions/network.sh

smartvpn_logger()
{
    logger -s -t softether_vpn "$1"
}

smartvpn_ipset_delete()
{
    ipset flush ip_oversea
    ipset destroy ip_oversea
    ipset flush net_oversea
    ipset destroy net_oversea

    ipset flush ip_hongkong
    ipset destroy ip_hongkong
    ipset flush net_hongkong
    ipset destroy net_hongkong

    ipset flush ip_mainland
    ipset destroy ip_mainland
    ipset flush net_mainland
    ipset destroy net_mainland

    return
}

smartvpn_ipset_create()
{

    ipset list | grep ip_oversea  > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        smartvpn_logger "creating ipset for individual host..."
        ipset create ip_oversea  hash:ip > /dev/null 2>&1
        ipset create ip_hongkong  hash:ip > /dev/null 2>&1
        ipset create ip_mainland  hash:ip > /dev/null 2>&1
    else
        if [[ "$SOFT" != "soft" ]]; then
            smartvpn_logger "Flushing ipset for individual host..."
            ipset flush ip_oversea
            ipset flush ip_hongkong
            ipset flush ip_mainland
        else
            smartvpn_logger "Start at soft mode: keep ipset for individual host"
        fi
    fi
}

smartvpn_ipset_add_by_file()
{
    local _ipfile=$1
    local _ipset_name=$2

    ipset list | grep $_ipset_name > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        ipset create $_ipset_name hash:net > /dev/null 2>&1
    else
        ipset flush $_ipset_name
    fi

    smartvpn_logger "add ip_net to ipset $_ipset_name."
    cat $_ipfile | while read line
    do
        if [ -n "$line" ]; then
            ipset add $_ipset_name $line
        fi
    done
}

dnsmasq_conf_path="/etc/dnsmasq.d/"
smartdns_conf_path="/etc/smartvpn/"

smartvpn_enable()
{

    ifdown lanman
    ifdown vpnhub01
    ifdown vpnhub02

    ifup lanman
    ifup vpnhub01
    ifup vpnhub02

    # 根据proxy.txt生成dnsmasq配置
    gensmartdns.sh "/etc/smartvpn/proxy_oversea.txt" "/tmp/dm_oversea.conf" "/tmp/smartvpn_ip.txt" "ip_oversea" "8.8.8.8" > /dev/null 2>&1

    [ -f /tmp/smartvpn_ip.txt ] && {
        smartvpn_ipset_add_by_file /tmp/smartvpn_ip.txt net_oversea
        hostlist_not_null=1
        rm /tmp/smartvpn_ip.txt
    }

    gensmartdns.sh "/etc/smartvpn/proxy_hongkong.txt" "/tmp/dm_hongkong.conf" "/tmp/smartvpn_ip.txt" "ip_hongkong" "1.1.1.1" > /dev/null 2>&1

    [ -f /tmp/smartvpn_ip.txt ] && {
        smartvpn_ipset_add_by_file /tmp/smartvpn_ip.txt net_hongkong
        hostlist_not_null=1
        rm /tmp/smartvpn_ip.txt
    }

    gensmartdns.sh "/etc/smartvpn/proxy_mainland.txt" "/tmp/dm_mainland.conf" "/tmp/smartvpn_ip.txt" "ip_mainland" "119.29.29.29" > /dev/null 2>&1

    [ -f /tmp/smartvpn_ip.txt ] && {
        smartvpn_ipset_add_by_file /tmp/smartvpn_ip.txt net_mainland
        hostlist_not_null=1
        rm /tmp/smartvpn_ip.txt
    }

    smartvpn_ipset_create   # 创建ipset

    # 把dnsmasq配置文件拷贝到 /etc/dnsmasq.d 目录下
    cp -p /tmp/dm_oversea.conf /tmp/dnsmasq.d
    cp -p /tmp/dm_hongkong.conf /tmp/dnsmasq.d
    cp -p /tmp/dm_mainland.conf /tmp/dnsmasq.d
    rm /tmp/dm_oversea.conf
    rm /tmp/dm_hongkong.conf
    rm /tmp/dm_mainland.conf

    smartvpn_logger "Restarting dnsmasq..."
    /etc/init.d/dnsmasq restart  # 重启nsmasq

    smartvpn_logger "Restarting mwan3..."
    /etc/init.d/mwan3 restart > /dev/null 2>&1
}

smartvpn_open()
{
    if [ $softether_status == "stop" ];
    then
        smartvpn_logger "softether not start! can not enable smartvpn."
        return 1
    fi

    smartvpn_enable
    
    smartvpn_logger "smartvpn is on!"
    echo

    return
}

smartvpn_close()
{    
    smartvpn_logger "Stoping mwan3..."
    /etc/init.d/mwan3 stop > /dev/null 2>&1

    rm /tmp/dnsmasq.d/dm_oversea.conf
    rm /tmp/dnsmasq.d/dm_hongkong.conf
    rm /tmp/dnsmasq.d/dm_mainland.conf

    smartvpn_logger "Restarting dnsmasq..."
    /etc/init.d/dnsmasq restart  # 重启nsmasq
    smartvpn_ipset_delete

    smartvpn_logger "Restarting mwan3..."
    /etc/init.d/mwan3 start > /dev/null 2>&1

    smartvpn_logger "smartvpn is off!"
    echo

    return
}


vpn_status_get()
{
    # network_is_up lanman
    # if [ $? -eq 0 ]; then
    #     vpn_status="up"
    # else
    #     vpn_status="down"
    # fi

    if [ -f /tmp/dnsmasq.d/dm_oversea.conf ]; then
        vpn_status="on"
    else
        vpn_status="off"
    fi

    return
}

softether_status_get()
{
    __tmpPID=$(ps | grep "vpnserver" | grep -v "grep vpnserver" | awk '{print $1}' 2>/dev/null)
    if  [ -n "$__tmpPID" ]; then
        softether_status="start"
    else
        softether_status="stop"
    fi
    return
}

smartvpn_usage()
{
    echo "usage: smartvpn.sh on|off [soft]"
    echo ""
    echo "softether status = $softether_status"
    echo "smartvpn status = $vpn_status"
    echo ""
    echo "# soft：keep current ipset result"
    echo ""
    return
}

# main

vpn_status_get
softether_status_get

config_load "smartvpn"
config_get smartvpn_cfg_switch vpn switch &>/dev/null;

OPT=$1
SOFT=$2

if [ ! -z "$SOFT" ]; then
    if [ "$SOFT" != "soft" ]; then
        echo
        echo "***Error*** second parameter must be 'soft'"
        OPT=""
    fi
fi

smartvpn_lock="/var/run/softether_vpn.lock"
trap "lock -u $smartvpn_lock; exit 1" SIGHUP SIGINT SIGTERM
lock $smartvpn_lock

case $OPT in
    on)
        smartvpn_open
        lock -u $smartvpn_lock
        return $?
    ;;

    off)
        smartvpn_close
        lock -u $smartvpn_lock
        return $?
    ;;

    *)
        smartvpn_usage
        lock -u $smartvpn_lock
        return 1
    ;;
esac
