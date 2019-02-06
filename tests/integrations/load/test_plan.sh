#!/bin/bash

DATA_DIR="${DATA_DIR:-$(pwd)/tests/data}"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/tests/output}"
TESTS_DIR="${TESTS_DIR:-$(pwd)/tests/integrations}"
JMETER_DOCKER_DIR="${JMETER_DOCKER_DIR:-$(pwd)/jmeter-docker}"
DOCKER_NETWORK_NAME="${DOCKER_NETWORK_NAME:-mlr-it-net}"
DOCKER_OUTPUT_DIR="/tests/output/load"

docker run --rm \
  --network="${DOCKER_NETWORK_NAME}" \
  -v "${OUTPUT_DIR}:/tests/output/" \
  -v "${DATA_DIR}:/tests/data/" \
  -v "${TESTS_DIR}:/tests/integrations/" \
  -v "${JMETER_DOCKER_DIR}/jmeter-master.properties:/jmeter/bin/user.properties" \
  -v "${JMETER_DOCKER_DIR}/config/rmi_keystore.jks:/jmeter/rmi_keystore.jks" \
  jmeter-base:latest jmeter \
    -f \
    -n \
    -e -o $DOCKER_OUTPUT_DIR/jmeter-output/dash \
    -j $DOCKER_OUTPUT_DIR/jmeter-output/jmeter-gateway.log \
    -l $DOCKER_OUTPUT_DIR/jmeter-output/jmeter-testing-gateway.jtl \
    -JJMETER_OUTPUT_PATH=$DOCKER_OUTPUT_DIR/test-output \
    -t /tests/integrations/load/load.jmx \
    -Rjmeter.server.1,jmeter.server.2,jmeter.server.3
