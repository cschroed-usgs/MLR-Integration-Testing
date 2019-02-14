#!/bin/bash

for archive in $HOME/docker/*; do
  docker load -i $archive || true
done
