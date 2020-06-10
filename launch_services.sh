#!/bin/bash

# Useful for environments where the Docker engine is not running on the host
# (like Docker Machine). If you are running Docker natively, don't worry about
# this
DOCKER_ENGINE_IP="${DOCKER_ENGINE_IP:-127.0.0.1}"

SERVICE_NAMES="mlr-gateway \
  mlr-legacy \
  mlr-notification \
  mlr-legacy-transformer \
  mlr-ddot-ingester \
  mlr-validator \
  mlr-wsc-file-exporter \
  mlr-legacy-db \
  water-auth-server"

get_healthy_services () {
  docker ps -f "name=${SERVICE_NAMES// /|}" -f "health=healthy" --format "{{ .Names }}"
}

fetch_reference_lists () {
  if [ ! -d remote-references ]; then
    aws s3 sync s3://prod-owi-resources/resources/Application/mlr/ci/configuration/mlr-validator/remote-references/ remote-references
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0  ]; then
      rm -rf remote-references
      echo "Failed to download reference lists from S3"
      exit 1
    fi
  fi
}

launch_services () {
  docker-compose -f docker-compose-services.yml up --no-color --detach --renew-anon-volumes
}

destroy_services () {
  docker-compose -f docker-compose-services.yml down --volumes
}

create_s3_bucket () {
  curl --request PUT "http://${DOCKER_ENGINE_IP}:8080/mock-bucket-test"
}

echo "Launching MLR services..."
{
  fetch_reference_lists
  launch_services
  EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "Could not launch MLR services"
    destroy_services
    exit $EXIT_CODE
  fi

  HEALTHY_SERVICES="$(get_healthy_services)"
  read -r -a SERVICE_NAMES_ARRAY <<< "$SERVICE_NAMES"
  read -d '' -r -a HEALTHY_SERVICES_ARRAY <<< "$HEALTHY_SERVICES"
  count=1
  limit=240
  until [[ ${#HEALTHY_SERVICES_ARRAY[@]} -eq ${#SERVICE_NAMES_ARRAY[@]} ]]; do
    echo "Testing service health. Attempt $count of $limit"

    sleep 1
    count=$((count + 1))

    UNHEALTHY_SERVICES_ARRAY=()
    for SERVICE_NAME in "${SERVICE_NAMES_ARRAY[@]}"; do
      skip=
      for HEALTHY_SERVICE in "${HEALTHY_SERVICES_ARRAY[@]}"; do
        [[ "${SERVICE_NAME}" == "${HEALTHY_SERVICE}" ]] && { skip=1;break; }
      done
      [[ -n $skip ]] || UNHEALTHY_SERVICES_ARRAY+=("$SERVICE_NAME")
    done

    # Did we hit our testing limit? If so, bail.
    if [ $count -eq $limit ]; then
      echo "Docker containers coult not reach a healthy status in $limit tries"
      echo "Services still not healthy: ${UNHEALTHY_SERVICES_ARRAY[*]}"
      destroy_services
      exit 1
    fi

    # Update the healthy services
    HEALTHY_SERVICES="$(get_healthy_services)"
    read -d '' -r -a HEALTHY_SERVICES_ARRAY <<< "$HEALTHY_SERVICES"
    echo "Services still not healthy: ${UNHEALTHY_SERVICES_ARRAY[*]}"

  done

  echo "All services healthy: ${HEALTHY_SERVICES_ARRAY[*]}"
  echo "Creating test s3 bucket..."
  create_s3_bucket
  EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "Could not create S3 bucket"
    destroy_services
    exit $EXIT_CODE
  fi

  echo "Bucket created successfully"

  exit 0
  } || {
  echo "Something went horribly wrong"
  destroy_services
  exit 1
}
