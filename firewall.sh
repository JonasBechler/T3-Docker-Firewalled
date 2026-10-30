#!/bin/sh
# Runs in the "firewall" container, which owns the network the agents use.
# Outbound: internet allowed; LAN, host and other containers blocked.
set -eu

# Only the filter table is touched, so Docker's DNS rules (nat table) survive.
iptables -F OUTPUT
iptables -A OUTPUT -o lo -j ACCEPT
# Replies to connections coming in through the published port
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Ollama on the host (port 11434 only). Docker's host gateway lives in a
# private range, so this must come before the reject rules below.
HOST_GW="$(getent ahostsv4 host.docker.internal | awk 'NR==1{print $1}')"
if [ -n "$HOST_GW" ]; then
  iptables -A OUTPUT -d "$HOST_GW" -p tcp --dport 11434 -j ACCEPT
fi

for net in \
  10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 \
  169.254.0.0/16 100.64.0.0/10 \
  224.0.0.0/4 255.255.255.255/32
do
  iptables -A OUTPUT -d "$net" -j REJECT 2>/dev/null \
    || iptables -A OUTPUT -d "$net" -j DROP
done

touch /run/firewall-ready
exec sleep infinity
