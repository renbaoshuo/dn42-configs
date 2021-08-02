#!/bin/bash

read -p 'Peer ASN: ' PEER_ASN

echo '*** Closing BGP Session...'
rm /etc/bird/peers/dn42-${PEER_ASN:0-4:4}.conf
birdc c

echo '*** Closing WireGuard Tunnel...'
systemctl disable --now wg-quick@dn42-${PEER_ASN:0-4:4}
rm /etc/wireguard/dn42-${PEER_ASN:0-4:4}.conf

echo '*** Done.'

exit 0

