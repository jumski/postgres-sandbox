#!/bin/bash

log() { echo -e "-- $@"; }
fail() { log "$@" && exit 1; }

execute() {
  sql="$@"
  log "$sql"
  echo "$sql" | bin/psql
  echo
}

execute_file_in_schema() {
  schema_name=$1
  path=$2
  sql=$(cat $path)
  log "Execute $path"
  log "$sql"
  echo "SET search_path TO $schema_name; $sql" | bin/psql
  echo
}

docker_up() {
  docker_output=$(docker-compose up -d 2>&1)

  if [ $? = 0 ]; then
    log Database up and running
  else
    fail Docker Failed: $docker_output
  fi
}
