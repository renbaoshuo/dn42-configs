#!/bin/bash

echo '*** Informations'

ip a

read -p 'Wireguard Private Key: '     WIREGUARD_PRIVATE_KEY
read -p 'IPv4 Address: '              OWN_IP
read -p 'IPv6 Address: '              OWN_IPv6
read -p 'Peer ASN: '                  PEER_ASN
read -p 'Listen Port: '               LISTEN_PORT
read -p 'Peer IPv4 Address: '         PEER_IP
read -p 'Peer IPv6 Address: '         PEER_IPv6
read -p 'Peer WireGuard EndPoint: '   PEER_WIREGUARD_ENDPOINT
read -p 'Peer WireGuard Public Key: ' PEER_WIREGUARD_PUBLIC_KEY

echo "# Peer dn42-${PEER_ASN}
[Interface]
PrivateKey = ${WIREGUARD_PRIVATE_KEY}
ListenPort = ${LISTEN_PORT}
PostUp     = ip addr add fe80::247/64 dev %i
PostUp     = ip addr add ${OWN_IPv6}/128 peer ${PEER_IPv6}/128 dev %i
PostUp     = ip addr add ${OWN_IP}/32 peer ${PEER_IP}/32 dev %i
Table      = off

[Peer]
PublicKey  = ${PEER_WIREGUARD_PUBLIC_KEY}
Endpoint   = ${PEER_WIREGUARD_ENDPOINT}
AllowedIPs = 0.0.0.0/0, ::/0
" > /etc/wireguard/dn42-$PEER_ASN.conf

systemctl enable --now wg-quick@dn42-$PEER_ASN
systemctl status wg-quick@dn42-$PEER_ASN

echo '*** Sleep for 10 seconds.'
sleep 10

wg show dn42-$PEER_ASN


echo "# Peer dn42-${PEER_ASN}
protocol bgp dn42_${PEER_ASN} from dnpeers {
    neighbor ${PEER_IPv6} as ${PEER_ASN};
}
" > /etc/bird/peers/dn42-$PEER_ASN.conf

birdc c

birdc s p dn42_$PEER_ASN

echo '*** Sleep for 10 seconds.'
sleep 10

birdc s p a dn42_$PEER_ASN
