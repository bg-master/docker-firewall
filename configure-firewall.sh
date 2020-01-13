#!/bin/sh

cleanup() {
  echo "Cleanup..."
  iptables -t mangle -D PREROUTING -j $FIREWALL_CHAIN
  iptables -t mangle -F $FIREWALL_CHAIN
  iptables -t mangle -X $FIREWALL_CHAIN
  iptables -D INPUT -j $FIREWALL_CHAIN
  iptables -F $FIREWALL_CHAIN
  iptables -X $FIREWALL_CHAIN
  echo "...done."
  exit 0
}

trap cleanup TERM

echo "Configuring firewall..."

iptables -t mangle -S $FIREWALL_CHAIN

if [ 0 -ne $? ]; then
  iptables -t mangle -N $FIREWALL_CHAIN
fi

iptables -t mangle -F $FIREWALL_CHAIN

# Drop invalid packets
iptables -t mangle -A $FIREWALL_CHAIN -m conntrack --ctstate INVALID -j DROP 
# Drop TCP packets that are new and are not SYN
iptables -t mangle -A $FIREWALL_CHAIN -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
# Drop SYN packets with suspicious MSS value
iptables -t mangle -A $FIREWALL_CHAIN -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP  
# Block packets with bogus TCP flags
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags FIN,RST FIN,RST -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags FIN,ACK FIN -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags ACK,URG URG -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags ACK,FIN FIN -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags ACK,PSH PSH -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags ALL ALL -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags ALL NONE -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP 
iptables -t mangle -A $FIREWALL_CHAIN -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
# Drop ICMP
iptables -t mangle -A $FIREWALL_CHAIN -p icmp -j DROP 
# Drop fragments in all chains
iptables -t mangle -A $FIREWALL_CHAIN -f -j DROP

iptables -t mangle -S $FIREWALL_CHAIN

iptables -t mangle -A PREROUTING -j $FIREWALL_CHAIN


iptables -S $FIREWALL_CHAIN

if [ 0 -ne $? ]; then
  iptables -N $FIREWALL_CHAIN
fi

iptables -F $FIREWALL_CHAIN

iptables -A $FIREWALL_CHAIN -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A $FIREWALL_CHAIN -i lo -j ACCEPT
[ -n "$FIREWALL_OPEN_TCP_PORTS" ] && iptables -A $FIREWALL_CHAIN -p tcp --match multiport --dports $FIREWALL_OPEN_TCP_PORTS -j RETURN
[ -n "$FIREWALL_OPEN_UDP_PORTS" ] && iptables -A $FIREWALL_CHAIN -p udp --match multiport --dports $FIREWALL_OPEN_TCP_PORTS -j RETURN
[ -n "$FIREWALL_ACCEPT_ALL_FROM" ] && iptables -A $FIREWALL_CHAIN -s $FIREWALL_ACCEPT_ALL_FROM -j RETURN
iptables -A $FIREWALL_CHAIN -j DROP

iptables -S $FIREWALL_CHAIN

iptables -A INPUT -j $FIREWALL_CHAIN

echo "...done."

while true; do
  sleep 1 &
  wait $!
done

exit 0
