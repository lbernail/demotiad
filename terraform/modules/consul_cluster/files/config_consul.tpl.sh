#!/usr/bin/env bash
set -e

SERVERS=$(echo ${TF_CONSUL_SERVERS} | tr ',' ' ')
ROLE=${TF_CONSUL_ROLE}
ROLE=$${ROLE:-client}
OPTIONS=${TF_CONSUL_OPTIONS}
PUBLIC=${TF_CONSUL_PUBLIC}
PUBLIC=$${PUBLIC:-no}

echo "Configuring consul"
JOINS=""
SERVER_COUNT=0
for address in $SERVERS
do
   JOINS="$JOINS -retry-join=$address"
   SERVER_COUNT=$(( $SERVER_COUNT + 1 ))
done

CONSUL_OPTIONS="$OPTIONS"
[ "$ROLE" == "server" ] && CONSUL_OPTIONS="$CONSUL_OPTIONS -server -bootstrap-expect=$SERVER_COUNT"
[ "$PUBLIC" == "yes" ] && CONSUL_OPTIONS="$CONSUL_OPTIONS -client=0.0.0.0"

cat > /etc/sysconfig/consul <<EOF
CONSUL_FLAGS="$CONSUL_OPTIONS $JOINS -data-dir=/opt/consul/data"
EOF

systemctl enable consul.service
systemctl start consul.service
