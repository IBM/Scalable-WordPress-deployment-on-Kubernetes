[![Build Status](https://travis-ci.org/IBM/Scalable-WordPress-deployment-on-Kubernetes.svg?branch=master)](https://travis-ci.org/IBM/Scalable-WordPress-deployment-on-Kubernetes)
![IBM Cloud Deployments](https://metrics-tracker.mybluemix.net/stats/8201eec1bc017860952416f1cc5666ce/badge.svg)

*Read this in other languages: [한국어](README-ko.md).*

# Scalable WordPress deployment on Kubernetes Cluster

This journey showcases the full power of Kubernetes clusters and shows how can we deploy the world's most popular website framework on top of world's most popular container orchestration platform. We provide a full roadmap for hosting WordPress on a Kubernetes Cluster. Each component runs in a separate container or group of containers.

WordPress represents a typical multi-tier app and each component will have its own container(s). The WordPress containers will be the frontend tier and the MySQL container will be the database/backend tier for WordPress.

In addition to deployment on Kubernetes, we will also show how you can scale the front WordPress tier, as well as how you can use MySQL as a service from IBM Cloud to be used by WordPress frontend.

![kube-wordpress](images/kube-wordpress-code.png)

## Included Components
- [WordPress (Latest)](https://hub.docker.com/_/wordpress/)
- [MySQL (5.6)](https://hub.docker.com/_/mysql/)
- [Kubernetes Clusters](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov)
- [IBM Cloud Compose for MySQL](https://console.ng.bluemix.net/catalog/services/compose-for-mysql)
- [IBM Cloud DevOps Toolchain Service](https://console.ng.bluemix.net/catalog/services/continuous-delivery)
- [IBM Cloud Container Service](https://console.ng.bluemix.net/catalog/?taxonomyNavigation=apps&category=containers)

## Prerequisite

Create a Kubernetes cluster with either [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube) for local testing, with [IBM IBM Cloud Container Service](https://github.com/IBM/container-journey-template), or [IBM Cloud Private](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/README.md) to deploy in cloud. The code here is regularly tested against [Kubernetes Cluster from IBM Cloud Container Service](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov) using Travis.

## Objectives

This scenario provides instructions for the following tasks:

- Create local persistent volumes to define persistent disks.
- Create a secret to protect sensitive data.
- Create and deploy the WordPress frontend with one or more pods.
- Create and deploy the MySQL database (either in a container or using IBM Cloud MySQL as backend).

## Deploy to IBM Cloud
If you want to deploy the WordPress directly to IBM Cloud, click on `Deploy to IBM Cloud` button below to create an IBM Cloud DevOps service toolchain and pipeline for deploying the WordPress sample, else jump to [Steps](##steps)

[![Create Toolchain](https://metrics-tracker.mybluemix.net/stats/8201eec1bc017860952416f1cc5666ce/button.svg)](https://console.ng.bluemix.net/devops/setup/deploy/)

Please follow the [Toolchain instructions](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions_new.md) to complete your toolchain and pipeline.

## Steps
1. [Setup MySQL Secrets](#1-setup-mysql-secrets)
2. [Create local persistent volumes](#2-create-local-persistent-volumes)
3. [Create Services and Deployments for WordPress and MySQL](#3-create-services-and-deployments-for-wordpress-and-mysql)
  - 3.1 [Using MySQL in container](#31-using-mysql-in-container)
  - 3.2 [Using Bluemix MySQL](#32-using-bluemix-mysql-as-backend)
4. [Accessing the external WordPress link](#4-accessing-the-external-wordpress-link)
5. [Using WordPress](#5-using-wordpress)

# 1. Setup MySQL Secrets

> *Quickstart option:* In this repository, run `bash scripts/quickstart.sh`.

Create a new file called `password.txt` in the same directory and put your desired MySQL password inside `password.txt` (Could be any string with ASCII characters).


We need to make sure `password.txt` does not have any trailing newline. Use the following command to remove possible newlines.

```bash
tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt
```

# 2. Create Local Persistent Volumes
To save your data beyond the lifecycle of a Kubernetes pod, you will want to create persistent volumes for your MySQL and Wordpress applications to attach to.

#### For "lite" IBM Bluemix Container Service
Create the local persistent volumes manually by running
```bash
kubectl create -f local-volumes.yaml
```
#### For paid IBM Bluemix Container Service OR Minikube
Persistent volumes are created dynamically for you when the MySQL and Wordpress applications are deployed. No action is needed.

# 3. Create Services and deployments for WordPress and MySQL

### 3.1 Using MySQL in container

> *Note:* If you want to use Bluemix Compose-MySql as your backend, please go to [Using Bluemix MySQL as backend](#32-using-bluemix-mysql-as-backend).

Install persistent volume on your cluster's local storage. Then, create the secret and services for MySQL and WordPress.

```bash
kubectl create secret generic mysql-pass --from-file=password.txt
kubectl create -f mysql-deployment.yaml
kubectl create -f wordpress-deployment.yaml
```


When all your pods are running, run the following commands to check your pod names.

```bash
kubectl get pods
```

This should return a list of pods from the kubernetes cluster.

```bash
NAME                               READY     STATUS    RESTARTS   AGE
wordpress-3772071710-58mmd         1/1       Running   0          17s
wordpress-mysql-2569670970-bd07b   1/1       Running   0          1m
```

Now please move on to [Accessing the External Link](#4-accessing-the-external-wordpress-link).

### 3.2 Using Bluemix MySQL as backend

Provision Compose for MySQL in Bluemix via https://console.ng.bluemix.net/catalog/services/compose-for-mysql

Go to Service credentials and view your credentials. Your MySQL hostname, port, user, and password are under your credential uri and it should look like this

![mysql](images/mysql.png)

Modify your `wordpress-deployment.yaml` file, change WORDPRESS_DB_HOST's value to your MySQL hostname and port (i.e. `value: <hostname>:<port>`), WORDPRESS_DB_USER's value to your MySQL user, and WORDPRESS_DB_PASSWORD's value to your MySQL password.

And the environment variables should look like this

```yaml
    spec:
      containers:
      - image: wordpress:4.7.3-apache
        name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: sl-us-dal-9-portal.7.dblayer.com:22412
        - name: WORDPRESS_DB_USER
          value: admin
        - name: WORDPRESS_DB_PASSWORD
          value: XMRXTOXTDWOOPXEE
```

After you modified the `wordpress-deployment.yaml`, run the following commands to deploy WordPress.

```bash
kubectl create -f wordpress-deployment.yaml
```

When all your pods are running, run the following commands to check your pod names.

```bash
kubectl get pods
```

This should return a list of pods from the kubernetes cluster.

```bash
NAME                               READY     STATUS    RESTARTS   AGE
wordpress-3772071710-58mmd         1/1       Running   0          17s
```

# 4. Accessing the external WordPress link

> If you have a paid cluster, you can use LoadBalancer instead of NodePort by running
>
>`kubectl edit services wordpress`
>
> Under `spec`, change `type: NodePort` to `type: LoadBalancer`
>
> **Note:** Make sure you have `service "wordpress" edited` shown after editing the yaml file because that means the yaml file is successfully edited without any typo or connection errors.

You can obtain your cluster's IP address using

```bash
$ bx cs workers <your_cluster_name>
OK
ID                                                 Public IP        Private IP     Machine Type   State    Status   
kube-hou02-pa817264f1244245d38c4de72fffd527ca-w1   169.47.220.142   10.10.10.57    free           normal   Ready 
```

You will also need to run the following command to get your NodePort number.

```bash
$ kubectl get svc wordpress
NAME        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
wordpress   10.10.10.57   <nodes>       80:30180/TCP   2m
```

Congratulation. Now you can use the link **http://[IP]:[port number]** to access your WordPress site.


> **Note:** For the above example, the link would be http://169.47.220.142:30180

You can check the status of your deployment on Kubernetes UI. Run `kubectl proxy` and go to URL 'http://127.0.0.1:8001/ui' to check when the WordPress container becomes ready.

![Kubernetes Status Page](images/kube_ui.png)

> **Note:** It can take up to 5 minutes for the pods to be fully functioning.



**(Optional)** If you have more resources in your cluster, and you want to scale up your WordPress website, you can run the following commands to check your current deployments.
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
As you can see, we now have 2 pods that are running the WordPress frontend.

> **Note:** If you are a free tier user, we recommend you only scale up to 10 pods since free tier users have limited resources.

# 5. Using WordPress

Now that WordPress is running you can register as a new user and install WordPress.

![wordpress home Page](images/wordpress.png)

After installing WordPress, you can post new comments.

![wordpress comment Page](images/wordpress_comment.png)


# Troubleshooting

If you accidentally created a password with newlines and you can not authorize your MySQL service, you can delete your current secret using

```bash
kubectl delete secret mysql-pass
```

If you want to delete your services, deployments, and persistent volume claim, you can run
```bash
kubectl delete deployment,service,pvc -l app=wordpress
```

If you want to delete your persistent volume, you can run the following commands
```bash
kubectl delete -f local-volumes.yaml
```

If WordPress is taking a long time, you can debug it by inspecting the logs
```bash
kubectl get pods # Get the name of the wordpress pod
kubectl logs [wordpress pod name]
```


# References
- This WordPress example is based on Kubernetes's open source example [mysql-wordpress-pd](https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd) at https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd.

# Privacy Notice

Sample Kubernetes Yaml file that includes this package may be configured to track deployments to [IBM Cloud](https://www.bluemix.net/) and other Kubernetes platforms. The following information is sent to a [Deployment Tracker](https://github.com/IBM/metrics-collector-service) service on each deployment:

* Kubernetes Cluster Provider (`IBM Cloud, Minikube, etc`)
* Kubernetes Machine ID
* Kubernetes Cluster ID (Only from IBM Cloud's cluster)
* Kubernetes Customer ID (Only from IBM Cloud's cluster)
* Environment variables in this Kubernetes Job.

This data is collected from the Kubernetes Job in the sample application's yaml file. This data is used by IBM to track metrics around deployments of sample applications to IBM Cloud to measure the usefulness of our examples so that we can continuously improve the content we offer to you. Only deployments of sample applications that include code to ping the Deployment Tracker service will be tracked.

## Disabling Deployment Tracking

Please comment out/remove the Metric Kubernetes Job portion at the end of the `wordpress-deployment.yaml` file.


# License
[Apache 2.0](LICENSE)
