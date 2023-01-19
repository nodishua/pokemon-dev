#!/bin/bash

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -F -t nat
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 18080 -j DNAT --to 192.168.1.20:18080
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 16666 -j DNAT --to 192.168.1.20:16666
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 1104 -j DNAT --to 192.168.1.20:1104
iptables -t nat -A POSTROUTING -j MASQUERADE

lan_ips=(
192.168.1.42
192.168.1.6
192.168.1.26
192.168.1.208
192.168.1.143
192.168.1.114
192.168.1.147
)

for ip in ${lan_ips[@]}
do
  nums=(${ip//./ })
  echo "$ip -> port ${nums[3]}xx"
  for ((port=10; port<=30; port++))
  do
    cmd="iptables -t nat -A PREROUTING -p tcp -i eth0 --dport ${nums[3]}${port} -j DNAT --to ${ip}:${port}888"
    #echo $cmd
    `$cmd`
  done
done


