[![Build Status](https://travis-ci.org/IBM/Scalable-WordPress-deployment-on-Kubernetes.svg?branch=master)](https://travis-ci.org/IBM/Scalable-WordPress-deployment-on-Kubernetes)

*다른 언어로 보기: [English](README.md).*

# 쿠버네티스 클러스터에 스케일링 가능한 워드프레스 구축하기

이 과정은 세계에서 가장 널리 이용되고 있는 컨테이너 오케스트레이션 플랫폼인 쿠버네티스의 여러 뛰어난 기능과 세계에서 가장 많이 이용되고 있는 웹사이트 프레임워크인 워드프레스를 쿠버네티스 상에 간단하게 배포하는 방법을 소개합니다. 단계별 가이드를 통해 IBM Bluemix 컨테이너 서비스의 쿠버네티스 클러스터에 워드프레스를 호스팅하는 방법 등을 안내합니다. 각 구성요소는 개별 컨테이너 또는 여러 컨테이너 그룹에서 실행됩니다.

워드프레스는 전형적인 멀티-티어(multi-tier) 앱으로, 각 구성요소마다 자체 컨테이너가 있습니다. 워드프레스 컨테이너는 프론트-엔드 티어가 되고, MySQL 컨테이너는 워드프레스의 데이터베이스/백엔드 티어가 됩니다.

쿠버네티스에서의 배포 외에도, 프론트 워드프레스 티어(front WordPress tier)를 스케일링하는 방법과 워드프레스 프론트 티어가 사용하는 MySQL을 Bluemix에서 DBaaS (Database as a Service)형태로 제공하는 Bluemix Compose for MySQL를 활용하여 사용하는 방법 또한 소개하겠습니다.

![kube-wordpress](images/kube-wordpress-code.png)

## 포함된 구성요소
- [워드프레스 (최신 버전)](https://hub.docker.com/_/wordpress/)
- [MySQL (5.6)](https://hub.docker.com/_/mysql/)
- [쿠버네티스 클러스터(Kubernetes Clusters)](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov)
- [Bluemix 컨테이너 서비스(Bluemix Container Service)](https://console.ng.bluemix.net/catalog/?taxonomyNavigation=apps&category=containers)
- [Bluemix Compose for MySQL](https://console.ng.bluemix.net/catalog/services/compose-for-mysql)
- [Bluemix DevOps 툴체인 서비스](https://console.ng.bluemix.net/catalog/services/continuous-delivery)

## 전제조건

로컬 테스트 환경에서는 [미니큐브(Minikube)](https://kubernetes.io/docs/getting-started-guides/minikube)를, 클라우드 환경에서는 [IBM Bluemix 컨테이너 서비스(Bluemix Container Service)](https://github.com/IBM/container-journey-template)를 활용하여 쿠버네티스 클러스터를 생성하십시오. 여기 제공되는 코드는  [Bluemix 컨테이너 서비스의 쿠버네티스 클러스터(Kubernetes Cluster from Bluemix Container Service)](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov) 환경에서 Travis로 정기적인 테스트를 수행합니다.

## 목적

본 시나리오는 아래 작업의 진행을 위한 설명을 제공합니다.

- 로컬 PersistentVolume(PV) 생성을 통한 영구적 디스크의 정의.
- 비밀번호 생성을 통한 데이터의 보호.
- 한 개 이상의 pod를 이용한 워드프레스 프론트엔드의 생성 및 배포.
- MySQL 데이터베이스의 생성 및 배포(컨테이너 내에서의 생성 및 배포, 또는 Bluemix  MySQL을 백엔드로 사용한 생성 및 배포).

## Bluemix에 배포하기
드프레스를 Bluemix에 직접 배포하려면, 아래의 ‘Deploy to Bluemix’ 버튼을 클릭하여 워드프레스 샘플 배포를 위한 Bluemix DevOps 서비스 툴체인과 파이프라인을 생성합니다. 그렇지 않은 경우,  [단계](##단계) 로 이동합니다.

[![Create Toolchain](https://github.com/IBM/container-journey-template/blob/master/images/button.png)](https://console.ng.bluemix.net/devops/setup/deploy/)

 [툴체인 가이드를](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions_new.md) 참고하여 툴체인과 파이프라인을 생성하십시오.
## 단계
1. [MySQL 비밀키 설치](#1-mysql-비밀키-설치)
2. [워드프레스 및 MySQL의 서비스 및 배포 생성](#2-워드프레스-및-mysql의-서비스-및-배포-생성)
  - 2.1 [컨테이너에서 MySQL 사용하기](#21-컨테이너에서-mysql-사용하기)
  - 2.2 [Bluemix MySQL 사용하기](#22-bluemix-mysql-사용하기)
3. [외부 워드프레스 링크 이용하기](#3-외부-워드프레스-링크-이용하기)
4. [워드프레스 사용하기](#4-워드프레스-사용하기)

# 1. MySQL 비밀키 설치

> *빠른 시작을 위한 옵션:* Git 저장소 내의  `bash scripts/quickstart.sh`를 실행합니다.

동일한 디렉토리에  `password.txt` 라는 이름의 신규 파일을 생성하고, 원하는 MySQL 암호를 `password.txt`에 기록하십시오(ASCII 형식의 문자열 가능).


 `password.txt` 에 줄바꿈 문자가 있어서는 안됩니다. 다음 명령을 이용하면 줄바꿈 문자를 제거할 수 있습니다.

```bash
tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt
```

# 2. 워드프레스와 MySQL의 서비스 생성 및 배포하기

### 2.1 컨테이너에서 MySQL 사용하기

> *참고:* Bluemix Compose-MySql을 백엔드로 이용하려는 경우,  [Bluemix MySQL을 백엔드로 사용하기](#22-using-bluemix-mysql-as-backend)로 이동하십시오.

클러스터의 로컬 스토리지에 PersistentVolume(PV)를 설치하십시오. 그런 다음, MySQL 비밀 번호를 설정하고, MySQL 및 워드프레스의 서비스를 생성하십시오.

```bash
kubectl create -f local-volumes.yaml
kubectl create secret generic mysql-pass --from-file=password.txt
kubectl create -f mysql-deployment.yaml
kubectl create -f wordpress-deployment.yaml
```


Pod가 모두 실행 중일 때, 다음 명령을 실행하여 pod 목록을 확인하십시오.

```bash
kubectl get pods
```

다음 명령 이용 시, pod 목록이 쿠버네티스 클러스터로부터 반환됩니다.

```bash
NAME                               READY     STATUS    RESTARTS   AGE
wordpress-3772071710-58mmd         1/1       Running   0          17s
wordpress-mysql-2569670970-bd07b   1/1       Running   0          1m
```

이제,  [외부 링크 (external link) 이용하기](#3-외부-워드프레스-링크-이용하기)로 이동하십시오.

### 2.2 Bluemix MySQL을 백엔드로 사용하기

 https://console.ng.bluemix.net/catalog/services/compose-for-mysql을 통해 Bluemix에 Compose for MySQL을 프로비저닝 하십시오.

서비스 신임정보로 이동하여 사용자 신임정보를 확인하십시오. 아래의 그림과 같이 사용자의 MySQL 호스트네임, 포트, 사용자, 암호 등이 사용자 신임정보 uri 밑에 있습니다.

![mysql](images/mysql.png)

`wordpress-deployment.yaml` 파일을 수정합니다. WORDPRESS_DB_HOST 값을 사용자의 MySQL 호스트네임과 포트(`value: <hostname>:<port>`)로, WORDPRESS_DB_USER 값을 여러분의 MySQL 사용자로,  WORDPRESS_DB_PASSWORD 값을 사용자의 MySQL 암호로 변경하십시오.

환경 변수는 다음과 같습니다.

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

`wordpress-deployment.yaml`수정 후에는 다음 명령들을 실행하여 워드프레스를 배포합니다.

```bash
kubectl create -f local-volumes.yaml
kubectl create -f wordpress-deployment.yaml
```

모든 pods가 실행 중일 때, 다음 명령을 실행하여 pod 이름들을 확인하십시오.

```bash
kubectl get pods
```

명령 실행을 통해 pod 목록이 쿠버네티스 클러스터로부터 반환됩니다.

```bash
NAME                               READY     STATUS    RESTARTS   AGE
wordpress-3772071710-58mmd         1/1       Running   0          17s
```

# 3. 외부 워드프레스 링크 이용하기

>(유료 계정만 해당됨!!) 유료 계정이 있는 경우, 다음 명령을 실행하여 로드밸런서(LoadBalancer)를 생성할 수 있습니다.
>
>`kubectl edit services wordpress`
>
>  `spec`아래의 `type: NodePort` 를 `type: LoadBalancer`로 변경하십시오.
>
> **참고:** yaml 파일 수정 후에  `service "wordpress" edited` 가 나타나야 yaml 파일이 오타나 연결 오류 없이 성공적으로 수정되었다는 뜻입니다.  

다음 명령을 실행하여 클러스터의 IP 주소를 확인할 수 있습니다.

```bash
$ kubectl get nodes
NAME             STATUS    AGE
169.47.220.142   Ready     23h
```

또한, 다음 명령을 실행하여 NodePort 번호를 확인해야 합니다.

```bash
$ kubectl get svc wordpress
NAME        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
wordpress   10.10.10.57   <nodes>       80:30180/TCP   2m
```

축하합니다. 지금부터는  **http://[IP]:[port number]** 링크를 이용하여 워드프레스 사이트에 접속할 수 있습니다.


> **참고:** 위 예제의 링크는  http://169.47.220.142:30180 입니다.

쿠버네티스 UI에서 deployment를 확인할 수 있습니다.  'kubectl proxy' 를 실행하고 URL 'http://127.0.0.1:8001/ui' 로 이동하여 워드프레스 컨테이너가 언제 준비되는지 확인하십시오.  
![Kubernetes Status Page](images/kube_ui.png)

> **참고:** pod가 완전한 기능을 하기 전까지 최대 5분이 소요될 수 있습니다.



**(선택사항)** 클러스터에 리소스가 추가적으로 있는 상황에서 워드프레스 웹사이트를 확장하려면, 다음 명령을 실행하여 현재 배포 현황을 확인할 수 있습니다.
```bash
$ kubectl get deployments
NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
wordpress         1         1         1            1           23h
wordpress-mysql   1         1         1            1           23h
```

이제, 다음 명령을 통해 워드프레스 프론트엔드의 스케일 아웃을 할 수 있습니다.
```bash
$ kubectl scale deployments/wordpress --replicas=2
deployment "wordpress" scaled
$ kubectl get deployments
NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
wordpress         2         2         2            2           23h
wordpress-mysql   1         1         1            1           23h
```
보이는 것과 같이 워드프레스 프론트엔드을 실행 중인 pods는 2개입니다.

> **참고:** 무료 티어(free tier) 사용자에게는 리소스가 제한적이므로 최대 10개까지만 pods를 확장할 것을 권장합니다.

# 4. 워드프레스 사용하기

워드프레스가 실행되었고, 이제 신규 사용자로 등록 및 워드프레스 설치를 진행할 수 있습니다.

![wordpress home Page](images/wordpress.png)

워드프레스가 설치되면 새로운 코멘트를 포스팅할 수 있습니다.

![wordpress comment Page](images/wordpress_comment.png)


# 문제 해결

줄바꿈을 통해 실수로 암호를 생성하여 MySQL 서비스에 권한을 부여할 수 없는 경우, 다음 명령을 사용하여 현재 비밀키를 삭제할 수 있습니다.

```bash
kubectl delete secret mysql-pass
```

If you want to delete your services, deployments, and persistent volume claim, you can run
```bash
kubectl delete deployment,service,pvc -l app=wordpress
```

PersistentVolume (PV)를 삭제하려면, 다음 명령을 실행하십시오.
```bash
kubectl delete -f local-volumes.yaml
```

# 참조
- •	이 워드프레스 예제는 [mysql-wordpress-pd](https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd) 웹사이트의 쿠버네티스의  https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd 오픈 소스 예제를 기반으로 작성되었습니다.



# 라이센스
[Apache 2.0](LICENSE)
