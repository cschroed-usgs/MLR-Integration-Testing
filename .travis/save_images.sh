#!/bin/bash -e

for img in $(docker image ls --format "{{ .Repository }}:{{ .Tag }}"); do
  echo "Saving ${img} to ${HOME}/docker/${img//[\/:]/.}.tar.gz"
  docker save $img | gzip -c > "$HOME/docker/${img//[\/:]/.}.tar.gz"
done

if [ ! -f "$HOME/docker/jmeter.tar.gz" ]; then
  docker-compose -f docker-compose-jmeter-servers.yml build
  docker save "jmeter-base:latest" | gzip -c > "$HOME/docker/jmeter.tar.gz"
fi
