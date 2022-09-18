# Go Web Hello World

## File Descriptions
| File                                                   | Description                                                                 | Task No |
|--------------------------------------------------------|-----------------------------------------------------------------------------|---------|
| [main.go](./main.go)                                   | source code of `go-web-hello-world`                                         | Task 3  |
| [dockerfile](./dockerfile)                             | dockerfile of `go-web-hello-world`                                          | Task 6  |
| [admin.conf](./admin.conf)                             | config file of single node k8s cluster                                      | Task 9  |
| [deployment.yaml](./deployment.yaml)                   | k8s deployment config `go-web-hello-world`                                  | Task 10 |
| [service.yaml](./service.yaml)                         | k8s service config `go-web-hello-world`                                     | Task 10 |
| [recommended.yaml](./recommended.yaml)                 | k8s config file for deploying kubernetes dashboard                          | Task 11 |
| [dashboard-adminuser.yaml](./dashboard-adminuser.yaml) | k8s config file for generating admin user and token of kubernetes dashboard | Task 12 |


## Task Steps

### Task 0: Install ubuntu server on virtual box
#### references: 
* https://www.bilibili.com/video/BV1uP4y1p77V

#### steps:
1. update NAT network and port forwards on virtual box `Preferences`
2. install ubuntu image
3. edit IPv4 configuration
   * Subnet: 10.0.2.0/24
   * Address: 10.0.2.20
   * Gateway: 10.0.2.1
   * Name Servers: 223.5.5.5
4. update **Mirror Address**
   *  http://mirrors.163.com/ubuntu
5. setup profile 
   * username: ubuntu
   * password: ubuntu
6. ssh to guest
    ```bash
    ssh -p 22222 ubuntu@127.0.0.1
    ```


### Task 1: Update system

```bash
sudo apt update
sudo apt upgrade
```


### Task 2: install gitlab-ce version in the host
#### references:
* https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-gitlab-on-ubuntu-18-04
* **Note**: Using the URL provided in the `demo.md` will redirect to the .cn domain, which provides instructions for installing `gitlab-jh` (Gitlab 极狐) instead of `gitlab-ce`

#### steps:
```bash
## install dependencies
sudo apt update
sudo apt install ca-certificates curl openssh-server postfix

## Install GitLab
cd /tmp
curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
sudo bash /tmp/script.deb.sh
sudo apt install gitlab-ce

## sudo ufw status

## update config
sudo vim /etc/gitlab/gitlab.rb
# update external_url https://example.com to http://127.0.0.1 in vim

## reload configuration
sudo gitlab-ctl reconfigure

## gitlab password for root user
sudo cat /etc/gitlab/initial_root_password 
# keiL2ojWivJD8D8l2rwLa5vWLZSJarHjy60emeU6enQ=
```

### Task 3: create a demo group/project in gitlab
#### steps:
1. visit _Gitlab_ through http://127.0.0.1:28080
2. use the password showed above to log in with account: _root_
3. create a user **Username**: xulingjia, **Password**: xulingjia
   * login to update password 
4. click **menu** to create `group`
5. create `project` within group page

### Task 4: build the app and expose ($ go run) the service to 28081 port
#### references:
* https://askubuntu.com/questions/742078/uninstalling-go-golang
* https://askubuntu.com/questions/1377307/how-to-install-the-latest-version-of-golang-in-ubuntu
* https://www.howtogeek.com/howto/ubuntu/see-where-a-package-is-installed-on-ubuntu/
1. install `go` on guest machine
    ```bash
    # do not use sudo apt install golang
    sudo add-apt-repository ppa:longsleep/golang-backports
    sudo apt update
    sudo apt install golang-1.19 
    
    dpkg -L golang-1.19-go
    sudo vim /etc/profile
    # add the following line to /etc/profile
    export PATH=$PATH:/usr/lib/go-1.19/bin
   
    source /etc/profile
    go version      
    ```
2. git clone go app
    ```bash
   cd ~
   mkdir -p projects/demo
   cd projects/demo
   
   git clone http://127.0.0.1/demo/go-web-hello-world.git 
    ```
   
3. create hello world 
    ```bash
   touch main.go
      
   vim main.go  # put the following go code to main.go
   go run main.go
    ```
    ```go
   package main

    import (
        "fmt"
        "net/http"
    )
 
    func main() {
        http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
            fmt.Fprintln(w, "Go Web Hello World!")
        })
 
        http.ListenAndServe(":8081", nil)
    }
    ```
4. curl on host machine
    ```bash
    curl http://127.0.0.1:28081
    # Output: Go Web Hello World!
   ```

### Task 5: install docker
#### references:
* https://docs.docker.com/install/linux/docker-ce/ubuntu/

#### steps:
1. Install docker
   ```bash
   sudo apt-get remove docker docker-engine docker.io containerd runc
   sudo apt-get update
   
   sudo apt-get install \
       ca-certificates \
       curl \
       gnupg \
       lsb-release
       
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
     
   sudo apt-get update
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
   
   ## run docker hello-world image
   sudo service docker start
   sudo docker run hello-world  
   ```
2. add docker mirror registry
   ```bash
   sudo vim /etc/docker/daemon.json # put the following json to daemon.json 
   
   # restart docker service
   sudo systemctl daemon-reload
   sudo systemctl restart docker 
   ```
   
   ```json
   {
     "registry-mirrors": ["https://hub-mirror.c.163.com"]
   }
   ```
   

### Task 6: run the app in container
#### references:
* https://recoverit.wondershare.com/computer-problems/increase-virtualbox-disk-size.html

#### steps:
1. create docker file under project folder
   ```dockerfile
   FROM golang:1.19.1
   
   ADD main.go main.go
   
   CMD go run main.go
   ```
2. build docker image
   ```bash
   sudo docker build -t go-web-hello-world:v0.1 .
   ```
3. run docker container
   * error:
      >ubuntu@ubuntu:~/projects/demo/go-web-hello-world$ sudo docker run -p 8082:8081 --name go-web-hello-world go-web-hello-world:v0.1
      docker: Error response from daemon: driver failed programming external connectivity on endpoint go-web-hello-world (c227b181cc483da043bb359eff2a5eef1c0191caf7d40cef640368b0aa595044): Error starting userland proxy: listen tcp4 0.0.0.0:8082: bind: address already in use.
   * troubleshooting:
      ```bash
      sudo lsof -i:8082
      
      # output      
      COMMAND     PID              USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
      ruby      14802               git    7u  IPv4  86395      0t0  TCP localhost:8082->localhost:45388 (ESTABLISHED)
      ruby      14802               git   13u  IPv4  76326      0t0  TCP localhost:8082 (LISTEN)
      prometheu 15241 gitlab-prometheus   13u  IPv4  86394      0t0  TCP localhost:45388->localhost:8082 (ESTABLISHED)
      ```

       Code snippet of /etc/gitlab/gitlab.rb
       ```ruby
       ##! Specifies where Prometheus metrics endpoints should be made available for Sidekiq processes.
       # sidekiq['metrics_enabled'] = true
       # sidekiq['exporter_log_enabled'] = false
       # sidekiq['exporter_tls_enabled'] = false
       # sidekiq['exporter_tls_cert_path'] = ""
       # sidekiq['exporter_tls_key_path'] = ""
       # sidekiq['listen_address'] = "localhost"
       # sidekiq['listen_port'] = 8082
       ```
   * Solution
     * Option 1: Use 8083 for port mapping 
         ```bash
         sudo docker run -p 8083:8081 --name go-web-hello-world go-web-hello-world:v0.1
         ``` 
     * Option 2: Update listen_port of Prometheus to 8083 
         ```ruby
         update sidekiq['listen_port'] = 8083
         ```

### Task 7: push image to dockerhub
#### reference
* https://techtutorialsite.com/docker-push-images-to-dockerhub/

#### steps:
1. login to docker hub
    ```bash
    sudo docker login -u xulingjia
    ```

2. tag docker image
    ```bash
    sudo docker tag go-web-hello-world:v0.1 xulingjia/go-web-hello-world:v0.1
    
    # check images
    sudo docker images
    ```

3. push image to docker hub
    ```bash
    sudo docker push xulingjia/go-web-hello-world:v0.1
    ```

4. check on docker hub website
   * https://hub.docker.com/repository/docker/xulingjia/go-web-hello-world


### Task 8: document the procedure in a MarkDown file
#### steps:
1. add this file to git
    ```bash
    vim README.md
    
    git add README.md
    git commit -m "update README.md"
    git push 
    ```

### Task 9: install a single node Kubernetes cluster using kubeadm
#### references:
* https://phoenixnap.com/kb/install-kubernetes-on-ubuntu
* https://skyao.io/learning-kubernetes/docs/installation/kubeadm/ubuntu.html
* https://blog.csdn.net/qf0129/article/details/124220666
* https://www.tecmint.com/disable-swap-partition-in-centos-ubuntu/
* https://www.bilibili.com/video/BV16L4y1j7Uj
* https://www.bilibili.com/video/BV1uY411E7se
* https://www.kubernetesquestions.com/questions/58183796
* https://developer.aliyun.com/mirror/kubernetes

#### steps:
1. preparation
    1. disable swap 
        ```bash
        sudo vim /etc/fstab # comment the line with swap 
        
        ## reboot virtual machine
        sudo reboot
        
        ## check swap
        free -m
        ```
    2. config network for kubernetes
         ```bash
         cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
         br_netfilter
         EOF
        
         cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
         net.bridge.bridge-nf-call-ip6tables = 1
         net.bridge.bridge-nf-call-iptables = 1
         EOF
         sudo sysctl --system
         ```
    3. update docker cgroup driver
         ```bash
         sudo vim /etc/docker/daemon.json
         ## add "exec-opts": ["native.cgroupdriver=systemd"]
        
         sudo systemctl restart docker
         sudo docker info # check `Cgroup Driver`
         ```

2. install kubernetes and tools
    ```bash
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg  https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] http://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    
    sudo apt-get install kubelet=1.23.5-00 kubeadm=1.23.5-00 kubectl=1.23.5-00
    
    ```

3. kube init
    ```bash
    sudo kubeadm init \
      --kubernetes-version v1.23.5 \
      --pod-network-cidr=10.244.0.0/16 \
      --apiserver-advertise-address=10.0.2.20 \
      --image-repository registry.aliyuncs.com/google_containers \
      --ignore-preflight-errors=NumCPU
    ```

    There was an error about number of CPUs is less than 2, so we add `--ignore-preflight-errors=NumCPU ` into the `kube init` command

    > [preflight] Running pre-flight checks
    error execution phase preflight: [preflight] Some fatal errors occurred:
    	[ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
    [preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
   
4. save `kubeadm join` command   
    ```bash
    kubeadm join 10.0.2.20:6443 --token 85b1c9.w0m9u5y59yab07r0 \
    	--discovery-token-ca-cert-hash sha256:f13ad41452d072bf692651026db3e430cbd3aa5bf94f41e57ff04a186a6fea37
    ``` 
5. update kube config and check it into git
    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    cp .kube/config projects/demo/go-web-hello-world/
    git add config
    git commit -m "add kube config"
    git push
    ```
6. update kube network config
    ````bash
    wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl apply -f kube-flannel.yml
    kubectl get pod -A -w
    
    # output
    NAMESPACE      NAME                             READY   STATUS    RESTARTS   AGE
    kube-flannel   kube-flannel-ds-mv7l8            1/1     Running   0          18s
    kube-system    coredns-6d8c4cb4d-cjrwp          1/1     Running   0          3m43s
    kube-system    coredns-6d8c4cb4d-vj9qq          1/1     Running   0          3m43s
    kube-system    etcd-ubuntu                      1/1     Running   1          4m
    kube-system    kube-apiserver-ubuntu            1/1     Running   1          3m58s
    kube-system    kube-controller-manager-ubuntu   1/1     Running   0          3m59s
    kube-system    kube-proxy-plztc                 1/1     Running   0          3m44s
    kube-system    kube-scheduler-ubuntu            1/1     Running   1          3m56s  
    ```

### Task 10: deploy the hello world container
#### references:
* https://blog.csdn.net/wucong60/article/details/81458409
* https://blog.csdn.net/wucong60/article/details/81586272
* https://blog.csdn.net/qq_34556414/article/details/108471790


#### steps:
1. enable master as a working node
    ```bash
    kubectl taint nodes --all node-role.kubernetes.io/master-
    ```
2. create `deployment.yaml`
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: go-web-hello-world-deployment
      labels:
        app: go-web-hello-world
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: go-web-hello-world
      template:
        metadata:
          labels:
            app: go-web-hello-world
        spec:
          containers:
            - name: go-web-hello-world
              image: xulingjia/go-web-hello-world:v0.1
              ports:
                - containerPort: 8081
                  protocol: TCP
    ```

3. create `service.yaml`
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-hello-world-service
    spec:
      selector:
        app: go-web-hello-world
      type: NodePort
      ports:
        - protocol: TCP
          port: 8081
          targetPort: 8081
          nodePort: 31080
    ```

4. apply config files
    ```bash
    kubectl apply -f deployment.yaml
    kubectl apply -f service.yaml
   
    ## check kube deployment & service after apply   
    kubectl get deployment
    kubectl get service
    ```

5. curl on host machine
    ```bash
    curl http://127.0.0.1:31080
    # Output: Go Web Hello World
    ```

### Task 11: install kubernetes dashboard
#### references:
* https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
* https://www.bilibili.com/video/BV1yB4y1w7sK

#### steps:
1. get dashboard kube file
    ```bash
    wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
    ```

2. update `recommended.yaml` to expose the service to NodePort 31081
    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
      name: kubernetes-dashboard
      namespace: kubernetes-dashboard
    spec:
      type: NodePort
      ports:
        - port: 443
          targetPort: 8443
          nodePort: 31081
      selector:
        k8s-app: kubernetes-dashboard
    ```
3. kube apply dashboard kube file
    ```bash
    kubectl apply -f recommended.yaml
    
    kubectl get service -A
    
    # Output
    NAMESPACE              NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
    default                go-web-hello-world-service   NodePort    10.104.249.96    <none>        8081:31080/TCP           33m
    default                kubernetes                   ClusterIP   10.96.0.1        <none>        443/TCP                  89m
    kube-system            kube-dns                     ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   89m
    kubernetes-dashboard   dashboard-metrics-scraper    ClusterIP   10.101.191.204   <none>        8000/TCP                 7m11s
    kubernetes-dashboard   kubernetes-dashboard         NodePort    10.97.74.195     <none>        443:31081/TCP            7m12s
    ```
4. Check dashboard on https://127.0.0.1:31081/ (accept https warning) 

### Task 12: generate token for dashboard login in task 11
#### references:
* https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
* https://blog.csdn.net/zhangkaiadl/article/details/122125364
* https://www.bilibili.com/video/BV1yB4y1w7sK

#### steps:
1. create `dashboard-adminuser.yaml`
    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: admin-user
      namespace: kubernetes-dashboard
        
    ---
    
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: admin-user
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
      - kind: ServiceAccount
        name: admin-user
        namespace: kubernetes-dashboard
    ```
2. kube apply `dashboard-adminuser.yaml`
    ```bash
    kubectl apply -f dashboard-adminuser.yaml
    ```

3. create token
    ```bash
    kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
    
    # output
    eyJhbGciOiJSUzI1NiIsImtpZCI6InhxZ1A4ZF9QWFdXSUh3NjlNZkRhdXlZamJ6SU9iYkl6b2pSM3VCZnJkY3MifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLTU0cGpxIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI0ZTc1YTg4YS1kYTQ1LTQ1MTItYTY4Ni0yYzhjODY1YWYwY2IiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.DX6mEUPG2pWs3lG3y5F3bL6mdyUG3gG2YjE3vUfZz5MkZAlz2JZ1vasAmP8N6ROHXRCQJNxulmdE5kZC-LSxvoLNPLl5vJNduOD3YNnqpSGx9pxYZi8evUYXKsxdwNstNSQsTTmXDn2M__7sOxDjVVo2C2Oz3NJ77O6OdlmWqNl_qTFV90-2h7tCng6vByynEHUaWubsxGER86LVngiW6Tg2nUpFREk-dDBJFKt9DlCwtBTxUUTBDSp5vc79yty9YQBzmbdCfshbgAyEvJJcGK4vamwPNuFjjXWOTn6y8vrOs3iIrMolgOA7znKZRHvORIfRj8KOcEHLZQfjCKKxaw
    ```
4. put token into website and login

