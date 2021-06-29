#!/bin/bash
source ./dhcp-arguments.sh

apt update && apt install -y isc-dhcp-server

if [[ $? -ne 0 ]];then
    echo "install isc-dhcp-server failed"
	exit
else
    echo "You have successfully installed DHCP server!"
fi


# 先对文件进行备份
if [[ ! -f "${conf_dhcp}.bak" ]];then
		cp "$conf_dhcp" "$conf_dhcp".bak
else
		echo "${conf_dhcp}.bak already exits!"
fi

# 配置相关文件

#修改配置文件/etc/dhcp/dhcpd.conf
cat<<EOT >> "$conf_dhcp"
subnet 192.168.44.0 netmask 255.255.255.0 {
	# client's ip address range
	range ${range_ip_min} ${range_ip_max};
	option subnet-mask
}
EOT
sed -i -e "/authoritative/s/^[#]//g" "$conf_isc"
if [[ $? -ne 0 ]];then
	echo "Configure dhcpd.conf failed."
	exit
else
	echo "Configure dhcpd.conf successfully."
fi

# 修改配置文件/etc/netplan/00-installer-config.yaml 
cat<<EOT >> "$conf_inteface"
enp0s9:
	dhcp4: no
	addresses: [192.168.44.10/24]
EOT

# 修改配置文件/etc/default/isc-dhcp-server
sed -i -e "/INTERFACESv4=/s/^[#]//g;/INTERFACESv4=/s/\=.*/=\"${interface}\"/g" "$conf_isc"
if [[ $? -ne 0 ]];then
	echo "Selection of interface failed."
	exit
else
	echo "Interface $interface is successfully selected."
fi

#重启服务
systemctl restart isc-dhcp-server
netplan apply