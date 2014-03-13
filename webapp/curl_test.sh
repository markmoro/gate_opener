#!/bin/bash    

TOKEN=$(curl -s  http://localhost:8080/token)
CMD='open'

DIGEST=$(echo  -n "$TOKEN$CMD" | openssl sha1 -hmac "$HASH_KEY")

curl -s --data "d=$DIGEST" http://localhost:8080/open

echo