#!/bin/bash

set -x

if [ "x$NODENAME" == "x" ] ; then
    NODENAME="rabbit"
fi

echo "Starting RabbitMQ Node ${NODENAME}@$(hostname)"

if [ -z "$CLUSTER_WITH" -o "$CLUSTER_WITH" = "$(hostname)" ]; then
    /usr/local/bin/docker-entrypoint.sh rabbitmq-server
else
    echo "Setup Cluster with $CLUSTER_WITH for node ${NODENAME}"
    rabbitmqctl wait /var/lib/rabbitmq/mnesia/${NODENAME}@$(hostname).pid && sleep 20 && \
        [ $(rabbitmqctl cluster_status | grep -oE '\{disc,\[(.*)\]' | grep rabbit | cut -d"[" -f2 | cut -d"]" -f1 | cut -d"," -f1- --output-delimiter=' ' | wc -w) -eq 1 ] && \
        rabbitmqctl stop_app && \
        rabbitmqctl join_cluster ${ENABLE_RAM:+--ram} ${CLUSTER_WITH} && \
        rabbitmqctl start_app &
    /usr/local/bin/docker-entrypoint.sh rabbitmq-server
fi

