#!/bin/bash

echo '*** Informations'

ip a

read -p 'Wireguard Private Key: '           WIREGUARD_PRIVATE_KEY
read -p 'IPv4 Address: '                    OWN_IP
read -p 'IPv6 Address: '                    OWN_IPv6
read -p 'Peer ASN: '                        PEER_ASN
read -p 'Use Link-local IP Address: [y/N] ' USE_LINK_LOCAL
read -p 'Peer IPv4 Address: '               PEER_IP
read -p 'Peer IPv6 Address: '               PEER_IPv6
read -p 'Peer Link-local Address: '         PEER_LINK_LOCAL
read -p 'Peer WireGuard EndPoint: '         PEER_WIREGUARD_ENDPOINT
read -p 'Peer WireGuard Public Key: '       PEER_WIREGUARD_PUBLIC_KEY

OWN_LINK_LOCAL="fe80::247"

WIREGUARD_CONFIG_FILE="/etc/wireguard/dn42-${PEER_ASN:0-4:4}.conf"
BIRD_CONFIG_FILE="/etc/bird/peers/dn42-${PEER_ASN:0-4:4}.conf"

echo '*** Writing WireGuard configs...'
echo "# Peer dn42-${PEER_ASN:0-4:4}
[Interface]
PrivateKey = ${WIREGUARD_PRIVATE_KEY}
ListenPort = 4${PEER_ASN:0-4:4}" > $WIREGUARD_CONFIG_FILE

if [[ $USE_LINK_LOCAL =~ ^[Yy](es)?$ ]]; then
    echo "PostUp     = ip addr add ${OWN_LINK_LOCAL}/128 peer ${PEER_LINK_LOCAL}/128 dev %i" >> $WIREGUARD_CONFIG_FILE
fi

if [[ $PEER_IPv6 != "" ]]; then
    echo "PostUp     = ip addr add ${OWN_LINK_LOCAL}/64 dev %i
PostUp     = ip addr add ${OWN_IPv6}/128 peer ${PEER_IPv6}/128 dev %i" >> $WIREGUARD_CONFIG_FILE
fi

echo "PostUp     = ip addr add ${OWN_IP}/32 peer ${PEER_IP}/32 dev %i
Table      = off

[Peer]
PublicKey  = ${PEER_WIREGUARD_PUBLIC_KEY}
Endpoint   = ${PEER_WIREGUARD_ENDPOINT}
AllowedIPs = 0.0.0.0/0, ::/0
" >> $WIREGUARD_CONFIG_FILE

systemctl enable --now wg-quick@dn42-${PEER_ASN:0-4:4}
systemctl status wg-quick@dn42-${PEER_ASN:0-4:4}

echo '*** Sleep for 10 seconds.'
sleep 10

echo '*** WireGuard tunnel details:'
wg show dn42-${PEER_ASN:0-4:4}

echo '*** Writing BIRD configs...'
echo "# Peer dn42-${PEER_ASN:0-4:4}
protocol bgp dn42_${PEER_ASN:0-4:4} from dnpeers {" > $BIRD_CONFIG_FILE

if [[ $USE_LINK_LOCAL =~ ^[Yy](es)?$ ]]; then
    echo "    neighbor ${PEER_LINK_LOCAL} % 'dn42-${PEER_ASN:0-4:4}' as ${PEER_ASN};" >> $BIRD_CONFIG_FILE
    echo "    source address ${OWN_LINK_LOCAL};" >> $BIRD_CONFIG_FILE
else
    echo "    neighbor ${PEER_IPv6} as ${PEER_ASN};" >> $BIRD_CONFIG_FILE
fi

echo "}" >> $BIRD_CONFIG_FILE


birdc c

birdc s p dn42_${PEER_ASN:0-4:4}

echo '*** Sleep for 10 seconds.'
sleep 10

echo '*** BGP session details:'
birdc s p a dn42_${PEER_ASN:0-4:4}

exit 0
