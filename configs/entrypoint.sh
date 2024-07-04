#!/bin/bash

# Adjust ownership of the mounted volume
if [ -z "$(ls -A /root)" ]; then
    cp -r /tmproot/ /root/
fi

# Execute the main process
exec "$@"
