#!/bin/bash

# Client
clt_read_dir=/nfs/gen_r
clt_readwrite_dir=/nfs/gen_rw
svr_read_dir=/var/nfs/gen_r
svr_readwrite_dir=/var/nfs/gen_rw
server_ip="196.168.43.4"

# Server
read_dir=/var/nfs/gen_r
readwrite_dir=/var/nfs/gen_rw
# 对配置文件进行操作
client_ip="196.168.43.3"
readwrite_info="(rw,sync,no_subtree_check)"
read_info="(ro,sync,no_subtree_check)"
conf="/etc/exports"


