#!/bin/bash
SERVER_COUNT=3
SITES_ADDED_PER_USER=1111
STARTING_SITE_NUMBER=100000000
DATA_DIR="${DATA_DIR:-$(pwd)/tests/data}"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/tests/output}"
TESTS_DIR="${TESTS_DIR:-$(pwd)/tests/integrations}"
JMETER_DOCKER_DIR="${JMETER_DOCKER_DIR:-$(pwd)/jmeter-docker}"
DOCKER_NETWORK_NAME="${DOCKER_NETWORK_NAME:-mlr-it-net}"

execute_load_test() {
  LOAD_TEST_USERS_PER_SERVER=$1
  LOAD_TEST_USER_COUNT=$(($LOAD_TEST_USERS_PER_SERVER*$SERVER_COUNT))
  echo "Starting load test with $LOAD_TEST_USER_COUNT users (Starting Site: $STARTING_SITE_NUMBER)."
  DOCKER_OUTPUT_DIR="/tests/output/load/$LOAD_TEST_USER_COUNT"
  docker run --rm \
    --network="${DOCKER_NETWORK_NAME}" \
    -v "${OUTPUT_DIR}:/tests/output/" \
    -v "${DATA_DIR}:/tests/data/" \
    -v "${TESTS_DIR}:/tests/integrations/" \
    -v "${JMETER_DOCKER_DIR}/jmeter-master.properties:/jmeter/bin/user.properties" \
    -v "${JMETER_DOCKER_DIR}/config/rmi_keystore.jks:/jmeter/rmi_keystore.jks" \
    -e LOAD_TEST_USER_COUNT=$LOAD_TEST_USER_COUNT \
    -e MIN_SITE_NUMBER=$STARTING_SITE_NUMBER \
    jmeter-base:latest jmeter \
      -f \
      -n \
      -e -o $DOCKER_OUTPUT_DIR/jmeter-output/dash \
      -j $DOCKER_OUTPUT_DIR/jmeter-output/jmeter-gateway.log \
      -l $DOCKER_OUTPUT_DIR/jmeter-output/jmeter-testing-gateway.jtl \
      -JJMETER_OUTPUT_PATH=$DOCKER_OUTPUT_DIR/test-output \
      -t /tests/integrations/load/load.jmx \
      -Rjmeter.server.1,jmeter.server.2,jmeter.server.3
  echo "Load test completed."
  STARTING_SITE_NUMBER=$(($STARTING_SITE_NUMBER + $LOAD_TEST_USER_COUNT*$SITES_ADDED_PER_USER))
}

echo "Starting load testing."

# Note: Because we have 3 servers, the number of users specified ends up being multiplied by 3.
execute_load_test 1    #  3 Users
execute_load_test 4    # 12 Users
execute_load_test 8    # 24 Users
execute_load_test 16   # 48 Users
execute_load_test 32   # 96 Users

echo "Load testing completed."