#!/bin/bash

pid=$(pgrep -f infinite.sh)

if [ -n "$pid" ]; then
    echo "Killing the infinite process with Process ID: $pid"
    kill -9 $pid
else
    echo "Infinite Process not found."
fi

