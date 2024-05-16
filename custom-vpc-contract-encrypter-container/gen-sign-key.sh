#!/bin/bash

echo 'generate signing key start'
openssl genrsa -aes128 -passout pass:test1234 -out private.pem 4096
openssl rsa -in private.pem -passin pass:test1234 -pubout -out public.pem
echo 'generate signing key end'
