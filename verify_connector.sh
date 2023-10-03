#!/bin/bash

curl -H "Accept:application/json" localhost:8083/connectors | jq
curl -H "Accept:application/json" localhost:8083/connectors/inventory-connector | jq
