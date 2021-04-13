#!/bin/bash

#export AWS_ACCESS_KEY_ID="ASIAR3XMADGTK4HMB4GH"
#export AWS_SECRET_ACCESS_KEY="5WFVta/SmHcO7AOMNW+/y2OSJK4Utukg0AroRy7m"

export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2

aws resourcegroupstaggingapi get-resources --output yaml

