#!/bin/bash

source ./bind9-arguments.sh

sudo apt update && sudo apt install bind9

if [[ $? -ne 0 ]];then
    echo "Failed to install bind9."
else
    echo "Successfully install bind9."
fi


# 修改配置文件

#对文件进行备份
if [[ ! -f "${option_conf}.bak" ]];then
    cp "$option_conf" "$option_conf".bak
else
    echo "${option_conf} has a backup"
fi

cat>> ${option_conf} <<EOF
listen-on { ${dns_server}; };
# disable zone transfers by default 
allow-transfer { none; }; 
forwarders {
    8.8.8.8;
    8.8.4.4;
};
EOF

sudo named-checkconf
if [[ $? -ne 0 ]];then
    echo "Failed to configure ${option_conf}."
    exit
else 
    sudo systemctl restart bind9
fi


# 生成新文件/etc/bind/db.cuc.edu.cn
sudo cp ${db_local} ${des_conf}
# 配置文件/etc/bind/db.cuc.edu.cn
cat>>${des_conf}<<EOF
    IN  NS  ns.cuc.edu.cn.
ns  IN  A   192.168.44.10
${wp}.  IN A  ${server_ip}
${dvwa}.    IN CNAME  ${wp}.
EOF
sudo named-checkconf
if [[ $? -ne 0 ]];then
    echo "Failed to configure ${des_conf}."
    exit
else 
    sudo systemctl restart bind9
fi

# 配置/etc/bind/named.conf.local
#对文件进行备份
if [[ ! -f "${db_local}.bak" ]];then
    cp "$db_local" "$db_local".bak
else
    echo "${db_local} has a backup"
fi

cat>>${local_conf}<<EOF
zone "cuc.edu.cn" {
    type master;
    file "/etc/bind/db.cuc.edu.cn";
};
EOF

sudo systemctl restart bind9.service





