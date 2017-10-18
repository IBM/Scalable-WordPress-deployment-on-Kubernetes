#!/bin/sh

if [ -z "$CF_ORG" ]; then
  CF_ORG="$BLUEMIX_ORG"
fi
if [ -z "$CF_SPACE" ]; then
  CF_SPACE="$BLUEMIX_SPACE"
fi


if ([ -z "$BLUEMIX_USER" ] || [ -z "$BLUEMIX_PASSWORD" ] || [ -z "$BLUEMIX_ACCOUNT" ]) && ([ -z "$API_KEY" ]); then
  echo "Define all required environment variables and rerun the stage."
  exit 1
fi

echo "Deploy pods"

echo "bx login -a $CF_TARGET_URL"

if [ -z "$API_KEY" ]; then
  if ! bx login -a "$CF_TARGET_URL" -u "$BLUEMIX_USER" -p "$BLUEMIX_PASSWORD" -c "$BLUEMIX_ACCOUNT" -o "$CF_ORG" -s "$CF_SPACE"; then
    echo "Failed to authenticate to Bluemix"
    exit 1
  fi
else
  if ! bx login -a "$CF_TARGET_URL" --apikey "$API_KEY" -o "$CF_ORG" -s "$CF_SPACE"; then
    echo "Failed to authenticate to Bluemix"
    exit 1
  fi
fi

# Init container clusters
echo "bx cs init"
if ! bx cs init; then
  echo "Failed to initialize to Bluemix Container Service"
  exit 1
fi
