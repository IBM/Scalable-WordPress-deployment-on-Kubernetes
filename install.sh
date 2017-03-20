#!/bin/bash
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb http://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
sudo apt-get update
sudo apt-get install cf-cli
cf --version
curl "http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.1_amd64.tar.gz" | tar zxvf -
sudo ./Bluemix_CLI/install_bluemix_cli
bx login -u tommyliseto@gmail.com -p THISis123!
bx plugin repo-add Bluemix https://plugins.ng.bluemix.net
bx plugin install container-service -r Bluemix
bx cs init
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
bx cs cluster-create --name wordpress
bx cs workers wordpress
bx cs cluster-config wordpress
export KUBECONFIG=/home/travis/.bluemix/plugins/container-service/clusters/wordpress/kube-config-prod-dal10-wordpress.yml
kubectl get secrets --namespace=default