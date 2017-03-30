[![Build Status](https://travis-ci.org/IBM/wordpress-sample.svg?branch=master)](https://travis-ci.org/IBM/wordpress-sample)


# Scalable Wordpress deployment on Bluemix Container Service using Kubernetes

This project demonstrates how to deploy WordPress and MySQL on Kubernetes cluster with the capability of IBM Bluemix Container Service. The WordPress uses MySQL as the backend and stores sensitive data into the persistent disks.

WordPress represents a typical multi-tier app and each component will have its own container(s). The WordPress containers will be the frontend tier and the MySQL container will be the database/backend tier for WordPress.

![alt text][logo]

[logo]: https://github.com/IBM/wordpress-sample/blob/master/image/kube-wordpress.png

With IBM Bluemix Container Service, you can deploy and manage your own Kubernetes cluster in the cloud that lets you automate the deployment, operation, scaling, and monitoring of containerized apps over a cluster of independent compute hosts called worker nodes. 


## Prerequisite

Create a Kubernetes cluster with IBM Bluemix Container Service. 

If you have not setup the Kubernetes cluster, please follow the [Creating a Kubernetes cluster](https://github.com/IBM/container-journey-template) tutorial.

## References
- This WordPress example is based on Kubernetes's open source example "mysql-wordpress-pd" at <https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd>

## Objectives

This scenario provides instructions for the following tasks:

- Create local persistent volumes to define persistent disks.
- Create a secret to protect sensitive data.
- Create and deploy the WordPress frontend with one or more pods.
- Create and deploy the MySQL database.


## Audience

This tutorial is intended for software developers and network administrators who have never deployed an application on Kubernetes cluster before.


## Getting Started with WordPress on Kubernetes

> *Quickstart option:* In this repository, run `bash quickstart.sh` and move on to [step 9](#access-the-external-link).

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
    
### Access the external link: 

9. If you do not have a SoftLayer account and you do not have a LoadBalancer endpoint, you can create a NodePort by running 
    
    ```bash
    $ kubectl edit services wordpress
    service "wordpress" edited
    ```
    Under `spec`, change `type: LoadBalancer` to `type: NodePort` (You could also change your NodePort number under `spec`/`ports`/`nodePort`).

    > **Note:** Make sure you have `service "wordpress" edited` shown after editing the yaml file because that means the yaml file is successfully edited without any typo and connection errors.

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
 
     > **Note:** It can take up to 5 minutes for the pods to be fully functioning.
    

10. (Optional) If you have more resources in your cluster, and you want to scale up your WordPress website, you can run the following commands to check your current deployments.
    ```bash
    $ kubectl get deployments
    NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    wordpress         1         1         1            1           23h
    wordpress-mysql   1         1         1            1           23h
    ```
 
     Now, you can run the following commands to scale up for WordPress frontend.
    ```bash
    $ kubectl scale deployments/wordpress --replicas=2
    deployment "wordpress" scaled
    $ kubectl get deployments
    NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    wordpress         2         2         2            2           23h
    wordpress-mysql   1         1         1            1           23h
    ```
    As you can see, we now have 2 pods that run the WordPress frontend. 
    
    > **Note:** If you are a free tier user, we recommend you only scale up to 10 pods since free tier users have limited resources.
    >
    > **Note:** We do not recommend you to scale up MySQL unless you know how to separate the InnoDB data for each MySQL pod.


## Troubleshooting

If you accidentally created a password with newlines and you can not authorize your MySQL service, you can delete your current secret using

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