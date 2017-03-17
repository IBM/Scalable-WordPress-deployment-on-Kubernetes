#!/bin/bash
curl -L "https://cli.run.pivotal.io/stable?release=macosx64-binary&source=github" | tar -zx
mv cf /usr/local/bin
cf --version
curl "http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/Bluemix_CLI_0.5.0_amd64.tar.gz" | tar -zxv
./Bluemix_CLI/install_bluemix_cli
bx login
bx plugin repo-add Bluemix https://plugins.ng.bluemix.net
bx plugin install container-service -r Bluemix
bx cs init
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl