#!/bin/bash

source ./vsftp-arguments.sh
# 进行vsftp的安装
which vsftp > /dev/null
if [[ $? -ne 0 ]];then
    apt install vsftpd -y
    if [[ $? -ne 0 ]];then
        echo "Failed to install vsftp"
        exit
    fi
else
    echo "Vsftpd has already installed"
fi

#对文件进行备份

if [[ ! -f "${conf}.bak" ]];then
    cp "$conf" "$conf".bak
else
    echo "${conf} has a backup"
fi

#配置一个提供匿名访问的FTP服务器
#匿名访问者可以访问1个目录且仅拥有该目录及其所有子目录的只读访问权限；
#新建匿名用户文件夹
mkdir -p $anon_path 
#更改匿名用户文件夹权限位
chown nobody:nogroup "$anon_path"
echo "This is anonymous file. " | sudo tee "${anon_path}/anonymous.txt"

# 修改vsftpd.conf
# 允许匿名访问
sed -i -e "/anonymous_enable=/s/^[#]//g;/anonymous_enable=/s/NO/YES/g" "$conf"
# 禁止匿名访问者上传文件
sed -i -e "/anon_world_readable_only=/s/^[#]//g;/anon_upload_enable=/s/YES/NO/g" "$conf"
# 禁止匿名访问者上传文件新建文件夹
sed -i -e "/anon_mkdir_write_enable=/s/^[#]//g;/anon_mkdir_write_enable=/s/YES/NO/g" "$conf"
# 指定根目录为/var/ftp/
grep -q "anon_world_readable_only=" "$conf" && sed -i -e "/anon_world_readable_only=/s/^[#]//g;/anon_world_readable_only=/s/\=.*/=YES/g" "$conf" || echo -e "# anonymous can read only\nanon_world_readable_only=YES" >> "$conf"
grep -q "anon_root=" "$conf" && sed -i -e "#anon_root=#s#^[#]##g;#anon_root=#s#\=.*#=/var/ftp#g" "$conf" || echo -e "# Point users at the directory we created earlier\nanon_root=/var/ftp/" >> "$conf"
grep -q "no_anon_password=" "$conf" && sed -i -e "/no_anon_password=/s/^[#]//g;/no_anon_password=/s/\=.*/=YES/g" "$conf" || echo -e "# Stop prompting for a password on the command line.\nno_anon_password=YES" >> "$conf"
grep -q "ftp_username=" "$conf" && sed -i -e "/ftp_username=/s/^[#]//g;/ftp_username=/s/\=.*/=ftp/g" "$conf" || echo -e "# Anonymous user's name\nftp_username=ftp" >> "$conf"

#配置一个支持用户名和密码方式访问的账号，该账号继承匿名访问者所有权限，且拥有对另1个独立目录及其子目录完整读写（包括创建目录、修改文件、删除文件等）权限；
# 添加用户
if [[ $(grep -c "^$user:" /etc/passwd) -eq 0 ]];then
	adduser $user
else
	echo "${user} has already existed!"
fi

# 继承匿名访问者所有权限
mkdir -p $user_path 
chown nobody:nogroup "$user_path"
chmod a-w "$user_path"

# 验证
echo "这是${user}的文件目录"
ls -al "$user_path"

# 建立另一个独立子目录并赋予新用户权限
mkdir -p $user_files_path
chown "$user":"$user" "$user_files_path"
# 验证
echo "这是${user}独立的文件目录"
ls -al "$user_files_path"
echo "This is ${user}'s file " | tee "${user_files_path}/${user}.txt"
#该账号仅可用于FTP服务访问，不能用于系统shell登录；
usermod -s /sbin/nologin $user


#FTP用户不能越权访问指定目录之外的任意其他目录和文件；
# 更改相关配置
sed -i -e "/local_enable=/s/^[#]//g;/local_enbale=/s/NO/YES/g" "$conf"
sed -i -e "/write_enable=/s/^[#]//g;/write_enable=/s/NO/YES/g" "$conf"
sed -i -e "/chroot_local_user=/s/^[#]//g;/chroot_local_user=/s/NO/YES/g" "$conf"


#匿名访问权限仅限白名单IP来源用户访问，禁止白名单IP以外的访问；
# 来源用户限制
# 将用户添加到user_list
if [[ ! -f $userlist ]];then
    touch $userlist
fi
grep -q "$user" $userlist ||  echo "$user" | tee -a $userlist
grep -q "ftp" $userlist || echo "ftp" | tee -a $userlist
grep -q "userlist_enable=" "$conf" && sed -i -e "/userlist_enable=/s/^[#]//g;/userlist_enable=/s/\=.*/=YES/g" "$conf" || echo "userlist_enable=YES" >> "$conf"
grep -q "userlist_file=" "$conf" && sed -i -e "#userlist_file=#s#^[#]##g;#userlist_file=#s#\=.*#=$userlist#g" "$conf" || echo "userlist_file=$userlist" >> "$conf"
grep -q "userlist_deny=" "$conf" && sed -i -e "/userlist_deny=/s/^[#]//g;/userlist_deny=/s/\=.*/=NO/g" "$conf" || echo "userlist_deny=NO" >> "$conf"

# 来源主机限制

if [[ ! -f $allow_hosts ]];then
    touch $allow_hosts
fi
if [[ ! -f $deny_hosts ]];then
    touch $deny_hosts
fi
grep -q "tcp_wrappers=" "$conf" && sed -i -e "/tcp_wrappers=/s/^[#]//g;/tcp_wrappers=/s/NO/YES/g" "$conf" || echo "tcp_wrappers=YES" >> "$conf"
grep -q "vsftpd:ALL" $deny_hosts || echo "vsftpd:ALL" >> $deny_hosts
grep -q "vsftpd:192.168.56.103" $allow_hosts || echo "vsftpd:192.168.56.103" >> $allow_hosts
grep -q "allow_writeable_chroot=" "$conf" && sed -i -e "/allow_writeable_chroot=/s/^[#]//g;/allow_writeable_chroot=/s/NO/YES/g" "$conf" || echo "allow_writeable_chroot=YES" >> "$conf"

# 重启服务
if pgrep -x vsftpd > /dev/null
then 
	systemctl restart vsftpd
else
	systemctl start vsftpd
fi