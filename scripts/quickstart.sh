#!/bin/bash
set -x
kubectl delete --ignore-not-found=true svc,pvc,deployment -l app=wordpress
kubectl delete --ignore-not-found=true secret mysql-pass
kubectl delete --ignore-not-found=true -f local-volumes.yaml

kuber=$(kubectl get pods -l app=wordpress)
if [ ${#kuber} -ne 0 ]; then
	sleep 120s
fi

echo 'password' > password.txt
tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt
kubectl create -f local-volumes.yaml
kubectl create secret generic mysql-pass --from-file=password.txt
kubectl create -f mysql-deployment.yaml
kubectl create -f wordpress-deployment.yaml
kubectl get pods
kubectl get nodes
kubectl get svc wordpress
kubectl get deployments
kubectl scale deployments/wordpress --replicas=2
