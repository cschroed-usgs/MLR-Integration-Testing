#!/bin/bash -e

# This shell script requires one parameter. The parameter needs to be the name of
# a test (e.g. gateway, waterauth, validator, etc)
if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

TEST_NAME=$1
OUTPUT_FILE="$(pwd)/tests/output/${TEST_NAME}/jmeter-output/jmeter-testing-${TEST_NAME}.jtl"

if [ ! -f $OUTPUT_FILE ]; then
  echo "The test results at $OUTPUT_FILE do not exist"
  exit 1
fi

cut -d ',' -f8 $OUTPUT_FILE | \
        while read result
        do
                if [[ "$result" == "false" ]]; then
                        echo "Failure detected"
                        exit 1
                fi
        done

echo "All tests passed"
exit 0
