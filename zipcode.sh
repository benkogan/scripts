#!/usr/bin/env bash

curl --silent "http://ipinfo.io/" | grep -E '(postal|})' | sed -e 's/"postal": "//' -e 's/}//' -e 's/"//' | tr -d '\n  '

