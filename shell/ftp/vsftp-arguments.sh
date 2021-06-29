#!/bin/bash

conf=/etc/vsftpd.conf 
anon_path=/var/ftp/anon
user='eddie'
user_path=/home/${user}/ftp
user_files_path=$user_path/files
userlist=/etc/vsftpd.user_list
allow_hosts=/etc/hosts.allow
deny_hosts=/etc/hosts.deny