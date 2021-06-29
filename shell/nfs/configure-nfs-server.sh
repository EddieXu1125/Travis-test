#!/bin/bash
# 在1台Linux上配置NFS服务，另1台电脑上配置NFS客户端挂载2个权限不同的共享目录，分别对应只读访问和读写访问权限；

source ./nfs-arguments.sh

sudo apt update && sudo apt install -y nfs-kernel-server
if [[ $? -ne 0 ]];then
        echo "Installation of nfs-kernel-server failed"
        exit
else
        echo "Nfs-kernel-server is successfully installed"
fi
# Create Share directories on the Host
# 一个文件只读，一个文件可读可写

mkdir -p $read_dir
chown nobody:nogroup $read_dir

mkdir -p $readwrite_dir
chown nobody:nogroup $readwrite_dir

grep -q "$read_dir" "$conf" && sed -i -e "#${read_dir}#s#^[#]##g;#${read_dir}#s#\ .*#${client_ip}${read_info}" "$conf" || echo "${read_dir} ${client_ip}${read_info}" >> "$conf"
grep -q "$readwrite_dir" "$conf" && sed -i -e "#${readwrite_dir}#s#^[#]##g;#${readwrite_dir}#s#\ .*#${client_ip}${readwrite_info}" "$conf" || echo "${readwrite_dir} ${client_ip}${readwrite_info}" >> "$conf"

# 重启服务
systemctl restart nfs-kernel-server


