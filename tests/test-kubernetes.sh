#!/bin/bash

# This script is intended to be run by Travis CI. If running elsewhere, invoke
# it with: TRAVIS_PULL_REQUEST=false [path to script]
# CLUSTER_NAME must be set prior to running (see environment variables in the
# Travis CI documentation).

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

kubeclt_clean() {
    echo "Cleaning cluster"
    kubectl delete --ignore-not-found=true svc,pvc,deployment -l app=wordpress
    kubectl delete --ignore-not-found=true secret mysql-pass
    kubectl delete --ignore-not-found=true -f local-volumes.yaml
    kuber=$(kubectl get pods -l app=wordpress)
    while [ ${#kuber} -ne 0 ]
    do
        sleep 5s
        kubectl get pods -l app=wordpress
        kuber=$(kubectl get pods -l app=wordpress)
    done
}

kubectl_config() {
    echo "Configuring kubectl"
    #shellcheck disable=SC2091
    $(bx cs cluster-config "$CLUSTER_NAME" | grep export)
}

kubectl_deploy() {
    kubeclt_clean

    echo "Running scripts/quickstart.sh"
    "$(dirname "$0")"/../scripts/quickstart.sh

    echo "Waiting for pods to be running..."
    i=0
    while [[ $(kubectl get pods -l app=wordpress | grep -c Running) -ne 2 ]]; do
        if [[ ! "$i" -lt 24 ]]; then
            echo "Timeout waiting on pods to be ready"
            test_failed "$0"
        fi
        sleep 10
        echo "...$i * 10 seconds elapsed..."
        ((i++))
    done
    echo "All pods are running"
}

verify_deploy() {
    echo "Verifying deployment was successful"
    IPS=$(bx cs workers "$CLUSTER_NAME" | awk '{ print $2 }' | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
    for IP in $IPS; do
        if ! curl -sS http://"$IP":8080/version; then
            test_failed "$0"
        fi
    done
}

main(){
    is_pull_request "$0"

    if ! kubectl_config; then
        test_failed "$0"
    elif ! kubectl_deploy; then
        test_failed "$0"
    elif ! verify_deploy; then
        test_failed "$0"
    else
        test_passed "$0"
    fi
}

main
