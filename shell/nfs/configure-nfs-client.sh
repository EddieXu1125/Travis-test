#!/bin/bash

source ./nfs-arguments.sh

sudo apt update && sudo apt install -y nfs-common
if [[ $? -ne 0 ]];then
    echo "Installation of nfs-common failed"
    exit
else
    echo "Nfs-common is successfully installed"
fi

sudo mkdir -p $clt_read_dir
sudo mkdir -p $clt_readwrite_dir

sudo mount "$server_ip":"$svr_read_dir" "$clt_read_dir"
if [[ $? -ne 0 ]];then
        echo "The read-only directory mounts failed. "
        exit
else
        echo "The read-only directory is successfully mounted."
fi
sudo mount "$server_ip":"$svr_readwrite_dir" "$clt_readwrite_dir"
if [[ $? -ne 0 ]];then
        echo "The read&write directory mounts failed. "
        exit
else
        echo "The read&write directory is successfully mounted."
fi

