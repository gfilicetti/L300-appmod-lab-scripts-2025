#!/bin/bash

# Find the error in the `frontend` container
# Go to Log Analytics
# Query for:
# resource.type="k8s_container"
# resource.labels.container_name="front"

# You'll find this error
# FileNotFoundError: [Errno 2] No such file or directory: '/tmp-incorrect/.ssh/publickey'

# You need to fix the path to the publickey

# See next script for the fix