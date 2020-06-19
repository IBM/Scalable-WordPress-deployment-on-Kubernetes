#!/bin/bash
echo 'password' > password.txt
tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt
kubectl apply -k ./