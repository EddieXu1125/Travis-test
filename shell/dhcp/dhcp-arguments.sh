#!/bin/bash

conf_dhcp=/etc/dhcp/dhcpd.conf
conf_inteface=/etc/netplan/00-installer-config.yaml
conf_isc=/etc/default/isc-dhcp-server

range_ip_min=192.168.44.20
range_ip_max=192.168.44.30
interface=enp0s9