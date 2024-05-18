#!/bin/bash

# Set default values for environment variables
SRTLA_PORT=${SRTLA_PORT:-5000}

SLS_HTTP_PORT=${SLS_HTTP_PORT:-8181}
SLS_SRT_PORT=${SLS_SRT_PORT:-30000}
SLS_DEFAULT_SID=${SLS_DEFAULT_SID:-live/feed1}
SLS_SRT_LATENCY=${SLS_SRT_LATENCY:-1000}
SLS_SRT_TIMEOUT=${SLS_SRT_TIMEOUT:--1}

SLT_SRT_LATENCY=${SLT_SRT_LATENCY:-1000}
SLT_SRT_LOSSMAXTTL=${SLT_SRT_LOSSMAXTTL:-40}

# Replace the values in the configuration file
sed -i "s/http_port [0-9]\+;/http_port ${SLS_HTTP_PORT};/" /etc/sls/sls.conf
sed -i "s/listen [0-9]\+;/listen ${SLS_SRT_PORT};/" /etc/sls/sls.conf
sed -i "s/latency [0-9]\+;/latency ${SLS_SRT_LATENCY};/" /etc/sls/sls.conf
sed -i "s/idle_streams_timeout [0-9]\+;/idle_streams_timeout ${SLS_SRT_TIMEOUT};/" /etc/sls/sls.conf
sed -i "s/default_sid publish\/[a-zA-Z0-9_]\+;/default_sid publish\/${SLS_DEFAULT_SID};/" /etc/sls/sls.conf

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
