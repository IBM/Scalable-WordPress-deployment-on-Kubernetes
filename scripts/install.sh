#!/bin/bash
set -x
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb http://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
sudo apt-get update
sudo apt-get install cf-cli
cf --version
curl "http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.2_amd64.tar.gz" | tar zxvf -
echo "https://api.ng.bluemix.net" | sudo ./Bluemix_CLI/install_bluemix_cli
set +x
echo "1" | bx login -a https://api.ng.bluemix.net -u $user -p $password 
set -x
bx plugin repo-add Bluemix https://plugins.ng.bluemix.net
bx plugin install container-service -r Bluemix
bx cs init
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
bx cs workers wordpress
bx cs cluster-config wordpress
$(bx cs cluster-config wordpress | grep -v "Downloading" | grep -v "OK" | grep -v "The")
kubectl get secrets --namespace=default
kubectl delete --ignore-not-found=true -f local-volumes.yaml
kubectl delete --ignore-not-found=true secret mysql-pass
kubectl delete --ignore-not-found=true svc,pvc,deployment -l app=wordpress

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