#!/bin/bash

# Set default values for environment variables

SRTLA_PORT=${SRTLA_PORT:-5000}
SLS_HTTP_PORT=${SLS_HTTP_PORT:-8181}
SLS_SRT_PORT=${SLS_SRT_PORT:-30000}
SLS_SRT_LATENCY=${SLS_SRT_LATENCY:-1000}
SLS_DEFAULT_SID=${SLS_DEFAULT_SID:-live/feed1}

# Replace the values in the configuration file
sed -i "s/http_port [0-9]\+;/http_port ${SLS_HTTP_PORT};/" /etc/sls/sls.conf
sed -i "s/listen [0-9]\+;/listen ${SLS_SRT_PORT};/" /etc/sls/sls.conf
sed -i "s/latency [0-9]\+;/latency ${SLS_SRT_LATENCY};/" /etc/sls/sls.conf
sed -i "s/default_sid publish\/[a-zA-Z0-9_]\+;/default_sid publish\/${SLS_DEFAULT_SID};/" /etc/sls/sls.conf

# Start services
(sls -c "/etc/sls/sls.conf" 2>&1 | tee /dev/console) &
(srtla_rec ${SRTLA_PORT} 127.0.0.1 ${SLS_SRT_PORT} 2>&1 | tee /dev/console)
