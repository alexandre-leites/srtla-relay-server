#!/bin/bash

while read -r line; do
    echo "Processing: $line"
    if [[ "$line" == *"PROCESS_STATE_EXITED"* ]]; then
        echo "A process has exited. Restarting all processes."
        supervisorctl restart all
    fi
done
