#!/usr/bin/env bash

PORT=$1

echo 'hello server' | nc localhost $PORT
