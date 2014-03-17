#!/bin/bash    

TOKEN=$(curl -s  http://192.168.1.177/token)
CMD='open'

echo $TOKEN

DIGEST=$(echo  -n "$TOKEN$CMD" | openssl sha1 -hmac "$HASH_KEY")

RES=$(curl -s --data "d=$DIGEST" http://192.168.1.177/open)
echo $RES

echo
