#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
CERT_DIR=$DIR/configuration/config/certificates

echo "CERT DIR: $CERT_DIR"

mkdir -p $CERT_DIR
rm -rf $CERT_DIR/*

openssl genrsa -out $CERT_DIR/ssl.key 2048
openssl req -nodes -newkey rsa:2048 -keyout $CERT_DIR/ssl.key -out $CERT_DIR/ssl.csr \
    -subj "/C=US/ST=Wisconsin/L=Middleon/O=US Geological Survey/OU=WMA/CN=*"
openssl x509 -req \
  -days 9999 -in $CERT_DIR/ssl.csr -signkey $CERT_DIR/ssl.key  -out $CERT_DIR/ssl.crt
chmod +r $CERT_DIR/*