#!/bin/bash    

TOKEN=$(curl -s  http://192.168.1.177/token)
CMD='open'

DD=$TOKEN$CMD
echo "$DD"

DIGEST=$(echo  -n "$DD" | openssl sha1 -hmac "$HASH_KEY")

echo $DIGEST
RES=$(curl -s --data "d=$DIGEST" http://192.168.1.177/open)
echo $RES

echo
