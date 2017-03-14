# Container Service Wordpress Sample


## Prerequisite:
1. Setup Armada Cluster.
2. Setup Kubernetes with Armada Cluster and have the Kubernetes dashboard ready.

## References:
- This WordPress example is based on Kubernetes's open source example "mysql-wordpress-pd" at <https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd>

## Getting Started with WordPress on Kubernetes:

1. Get the "mysql-wordpress-pd" example from Kubernetes's Github, you can use the following commands.

```bash
$ git clone https://github.com/kubernetes/kubernetes.git
$ cd kubernetes/examples/mysql-wordpress-pd/
```

2. Create a new file called `password.txt` in the same directory and put your desired MySQL password inside `password.txt` (Could be any string with ASCII characters).

3. We need to make sure `password.txt` does not have any trailing newline. Use the following command to remove possible newlines.

```bash
$ tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt
```

4. Install persistent volume on your cluster's local storage.

```bash
$ kubectl create -f local-volumes.yaml
```

5. Create the secret for your MySQL password. We will use the password inside `password.txt`.

```bash
$ kubectl create secret generic mysql-pass --from-file=password.txt
```

6. Create the service for MySQL and claim its persistent volume.

```bash
$ kubectl create -f mysql-deployment.yaml
```

7. Create the service for WordPress and claim its persistent volume.

```bash
$ kubectl create -f wordpress-deployment.yaml
```

8. When all your pods are running, run the following commands to check your pod names.

```bash
$ kubectl get pods
```

9. Access the external link: **http://[IP]:[port number]**. You can obtain your cluster's IP address using

```bash
$ kubectl get nodes
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; You will also need to run the following command to get your NodePort number.

```bash
$ kubectl get svc wordpress 
```

Congratulation. Now you can use the link **http://[IP]:[port number]** to access your WordPress site.