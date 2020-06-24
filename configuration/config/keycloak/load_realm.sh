#!/bin/sh

# Waits until the keycloak server is fully up and running and then uses the CLI to 
# import the MLR realm and add users
cd ~/keycloak/bin
until curl "mlr-keycloak:9080" | grep -q "html"; do sleep 4; done

# Check if MLR realm already exists before adding (can happen on container restart)
status_code=$(curl --write-out %{http_code} --silent --output /dev/null http://mlr-keycloak:9080/auth/realms/mlr/)

if [[ "$status_code" -eq 404 ]] ; then
    ./kcadm.sh config credentials --server http://mlr-keycloak:9080/auth --realm master --user admin --password admin
    ./kcadm.sh create realms --server http://mlr-keycloak:9080/auth -f /tmp/local_realm.json
else
    echo "Realm 'mlr' already exists; Skiping import."
    exit 0
fi
