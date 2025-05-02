#!/bin/bash

PORT="${LISTENING##*:}"

netstat -an | grep ":$PORT" > /dev/null
if [ $? -ne 0 ]; then
  echo "Port $PORT not listening"
  exit 1
fi

exit 0