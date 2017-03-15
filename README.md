# Container Service Wordpress Sample

This tutorial demonstrates how to deploy WordPress and MySQL on Kubernetes cluster with the capability of IBM Bluemix Container Service. The WordPress uses MySQL as the backend and stores sensitive data into the persistent disks.

With IBM® Bluemix® Container Service, you can deploy and manage your own Kubernetes cluster in the cloud that lets you automate the deployment, operation, scaling, and monitoring of containerized apps over a cluster of independent compute hosts called worker nodes. 


## Prerequisite

Create a Kubernetes cluster with IBM Bluemix Container Service. 

If you have not setup the Kubernetes cluster, please follow the [Creating a Kubernetes cluster](https://github.com/IBM/container-service-wordpress-sample/blob/master/creating-a-kubernetes-cluster.md) tutorial.

## References
- This WordPress example is based on Kubernetes's open source example "mysql-wordpress-pd" at <https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd>

## Objectives

This scenario provides instructions for the following tasks:

- Create local persistent volumes to defibe persistent disks.
- Create a secret to protect sensitive data.
- Create and deploy the WordPress frondend with one pod.
- Create and deploy the MySQL database with one pod.


## Time required

20 minutes

## Audience

This tutorial is intended for software developers and network administrators who have never deployed an application on Kubernetes cluster before.


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
    persistentvolume "local-pv-1" created
    persistentvolume "local-pv-2" created
    ```

5. Create the secret for your MySQL password. We will use the password inside `password.txt`.

    ```bash
    $ kubectl create secret generic mysql-pass --from-file=password.txt
    secret "mysql-pass" created
    ```

6. Create the service for MySQL and claim its persistent volume.

    ```bash
    $ kubectl create -f mysql-deployment.yaml
    service "wordpress-mysql" created
    persistentvolumeclaim "mysql-pv-claim" created
    deployment "wordpress-mysql" created
    ```

7. Create the service for WordPress and claim its persistent volume.

    ```bash
    $ kubectl create -f wordpress-deployment.yaml
    service "wordpress" created
    persistentvolumeclaim "wp-pv-claim" created
    deployment "wordpress" created
    ```

8. When all your pods are running, run the following commands to check your pod names.

    ```bash
    $ kubectl get pods
    NAME                               READY     STATUS    RESTARTS   AGE
    wordpress-3772071710-58mmd         1/1       Running   0          17s
    wordpress-mysql-2569670970-bd07b   1/1       Running   0          1m
    ```

9. Access the external link: 

    If you do not have a SoftLayer account and you do not have a LoadBalancer endpoint. You can go to the WordPress service in your Kubernetes dashboard and press edit (or you can run kubectl edit services wordpress on your terminal). Under `spec`, change `type: LoadBalancer` to `type: NodePort` (You could also change your NodePort number under `spec`/`ports`/`0`/`nodePort` ).

    You can obtain your cluster's IP address using

    ```bash
    $ kubectl get nodes
    NAME             STATUS    AGE
    169.47.220.142   Ready     23h
    ```

    You will also need to run the following command to get your NodePort number.

    ```bash
    $ kubectl get svc wordpress 
    NAME        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
    wordpress   10.10.10.57   <nodes>       80:32340/TCP   2m
    ```

    Congratulation. Now you can use the link **http://[IP]:[port number]** to access your WordPress site.
    
    9.1. (Optional) If you do not want to use an external link, you can open WordPress on your local machine with limited functionality. First, create a proxy on your local machine by running
    ```bash
    kubectl proxy 
    ```
    > **Note 1:** The default port number is 8001. You could use --port=[port number] to specify a port.
    > 
    > **Note 2:** You also can add & at the end to run the proxy in the background.
    > 
    > **Note 3:** If you are not sure kubectl proxy is running, use the command ps to check your current process status.

    Now you can use `http://localhost:8001/api/v1/proxy/namespaces/default/pods/[your Wordpress pod name]` to open Wordpress on your local browser. 
    
    > **Note:** If you use a different port, make sure to change 8001 to your own port number.


## Troubleshooting

If you accidentally created a password with newlines and you can not authorized your MySQL service, you can delete your current secret using

```bash
$ kubectl delete secret mysql-pass
secret "mysql-pass" deleted
```

If you want to delete your services, you can run
```bash
$ kubectl delete deployment,service -l app=wordpress
deployment "wordpress" deleted
deployment "wordpress-mysql" deleted
service "wordpress" deleted
service "wordpress-mysql" deleted
```

If you want to delete your persistent volume, you can run the following commands
```bash
$ kubectl delete pvc -l app=wordpress
persistentvolumeclaim "mysql-pv-claim" deleted
persistentvolumeclaim "wp-pv-claim" deleted
$ kubectl delete pv local-pv-1 local-pv-2
persistentvolume "local-pv-1" deleted
persistentvolume "local-pv-2" deleted
```

If you have your proxy running, you can open your Kubernetes dashboard via `http://localhost:[port number]/ui`  (Default port is 8001)