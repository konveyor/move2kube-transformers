#!/bin/bash

SIGNATURE="$( cat contract.txt | openssl dgst -sha256 -sign private.pem -passin pass:test1234 | openssl enc -base64)"
echo "${SIGNATURE}" | tr -d '\n'
