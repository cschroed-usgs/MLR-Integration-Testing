#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
CERT_DIR=$DIR/configuration/config/certificates

echo "CERT DIR: $CERT_DIR"

mkdir -p $CERT_DIR
rm -f $CERT_DIR/*

openssl genrsa -out $CERT_DIR/ssl.key 2048
openssl req -nodes -newkey rsa:2048 -keyout $CERT_DIR/ssl.key -out $CERT_DIR/ssl.csr \
    -subj "/C=US/ST=Wisconsin/L=Middleon/O=US Geological Survey/OU=WMA/CN=mlr-int"
openssl x509 -req \
  -days 9999 -in $CERT_DIR/ssl.csr -signkey $CERT_DIR/ssl.key  -out $CERT_DIR/ssl.crt

openssl genrsa -out $CERT_DIR/water-auth.key 2048
openssl req -nodes -newkey rsa:2048 -keyout $CERT_DIR/water-auth.key -out $CERT_DIR/water-auth.csr \
    -subj "/C=US/ST=Wisconsin/L=Middleon/O=US Geological Survey/OU=WMA/CN=water-auth"
openssl x509 -req \
  -days 9999 -in $CERT_DIR/water-auth.csr -signkey $CERT_DIR/water-auth.key  -out $CERT_DIR/water-auth.crt