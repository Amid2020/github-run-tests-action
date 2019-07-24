#!/bin/bash
set -e

EVENT_TIME="${CI_TIMESTAMP}"
if [[ -z "${EVENT_TIME}" ]]; then
    EVENT_TIME="$(date +%s)000"
fi

if [[ -z "${MABL_API_KEY}" ]]; then
    echo "No MABL_API_KEY provided"
    exit 1
fi

if [[ -z "${MABL_API_HOST}" ]]; then
    MABL_API_HOST="api.mabl.com"
fi

DEPLOYMENT_JSON="{ \"event_time\" : ${EVENT_TIME}, \"revision\" : \"${GITHUB_SHA}\", \"properties\" : { \"branch\" : \"${GITHUB_REF}\", \"committer\" : \"${GITHUB_ACTOR}\" }"
if [[ -n "${ENVIRONMENT_ID}" ]]; then
    DEPLOYMENT_JSON="${DEPLOYMENT_JSON}, \"environment_id\" : \"${ENVIRONMENT_ID}\""
fi
if [[ -n "${APPLICATION_ID}" ]]; then
    DEPLOYMENT_JSON="${DEPLOYMENT_JSON}, \"application_id\" : \"${APPLICATION_ID}\""
fi
DEPLOYMENT_JSON="${DEPLOYMENT_JSON} }"


TARGET_URL="https://${MABL_API_HOST}/events/deployment"

echo "Sending deployment to mabl with @ ${TARGET_URL}..."
response=$(curl -s ${TARGET_URL} \
-u "key:${MABL_API_KEY}" \
-H "Content-Type:application/json" \
-d "${DEPLOYMENT_JSON}")

DEPLOYMENT_EVENT_ID=$(echo "${response}" | jq '.id' -r)
status_code=$(echo "${response}" | jq '.code' -r)

if ! [ "${status_code}" == "null" ]; then
    echo "WARNING: Deployment event notification failed with status code ${status_code}"
    echo "response from mabl API: ${response}"
    exit 20
else
    echo "Deployment event notification successful"
    mkdir "${HOME}/mabl"
    echo "${DEPLOYMENT_EVENT_ID}" > "${HOME}/mabl/deployment_event_id"
fi
