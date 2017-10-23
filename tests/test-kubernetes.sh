#!/bin/bash

kubeclt_clean() {
    echo -e "Deleting previous version of wordpress if it exists"
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
    echo "Cleaning done"
}

test_failed(){
    kubeclt_clean
    echo -e >&2 "\033[0;31mKubernetes test failed!\033[0m"
    exit 1
}

test_passed(){
    kubeclt_clean
    echo -e "\033[0;32mKubernetes test passed!\033[0m"
    exit 0
}

kubectl_config() {
    echo "Configuring kubectl"
    #shellcheck disable=SC2091
    $(bx cs cluster-config "$CLUSTER_NAME" | grep export)
}

kubectl_deploy() {
    kubeclt_clean

    echo "Creating password..."
    echo 'password' > password.txt
    tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt

    echo "Creating local volumes..."
    kubectl create -f local-volumes.yaml

    echo "Creating secrets..."
    kubectl create secret generic mysql-pass --from-file=password.txt

    echo "Creating MySQL Deployment..."
    kubectl create -f mysql-deployment.yaml

    echo "Creating Wordpress Deployment..."
    kubectl create -f wordpress-deployment.yaml

    echo "Waiting for pods to be running..."
    i=0
    while [[ $(kubectl get pods -l app=wordpress | grep -c Running) -ne 2 ]]; do
        if [[ ! "$i" -lt 24 ]]; then
            echo "Timeout waiting on pods to be ready. Test FAILED"
            exit 1
        fi
        sleep 10
        echo "...$i * 10 seconds elapsed..."
        ((i++))
    done

    echo "All pods are running"
}

verify_deploy() {
    # Check Wordpress is running.
    IPS=$(bx cs workers "$CLUSTER_NAME" | awk '{ print $2 }' | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

    for IP in $IPS; do
        while true
        do
            code=$(curl -o /dev/null -sw "%{http_code}\n" http://$IP:30180/wp-admin/install.php -o /dev/null)
            if [ "$code" = "200" ]; then
                echo "Wordpress is up."
                break
            fi
            if [ "$TRIES" -eq 10 ]
            then
                echo "Failed finding Wordpress. Error code is $code"
                exit 1
            fi
            TRIES=$((TRIES+1))
            sleep 5s
        done
    done
}

main() {
    if [[ "$TRAVIS_PULL_REQUEST" != false ]]; then
        echo -e "\033[0;33mPull request detected; not running Bluemix Container Service test.\033[0m"
        exit 0
    fi

    if ! kubectl_config; then
        echo "Config failed."
        test_failed
    elif ! kubectl_deploy; then
        echo "Deploy failed"
        test_failed
    elif ! verify_deploy; then
        test_failed
    else
        test_passed
    fi
}

main
