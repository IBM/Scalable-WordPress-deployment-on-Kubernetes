#!/bin/bash -e

# shellcheck disable=SC1090
source "$(dirname "$0")"/../pattern-ci/scripts/resources.sh

kubectl_deploy() {
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
    kubectl get pods
    echo "All pods are running"
}

verify_deploy(){
    echo "Verifying deployment..."
    kubectl get services
    sleep 60
    if ! curl -sS "$(minikube service --url wordpress)"; then
        test_failed "$0"
    fi
}

main(){
    if ! kubectl_deploy; then
        test_failed "$0"
    elif ! verify_deploy; then
        test_failed "$0"
    else
        test_passed "$0"
    fi
}

main
