#!/bin/bash

# Adjust ownership of the mounted volume
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME

# Execute the main process
exec "$@"
