---
description: 记录Docker使用的相关基础笔记
---

# Docker使用笔记

## 安装Docker

**安装准备**

> 环境准备
>
> centos 7 或以上、linux内核3.10以上
>
> 查看centOS版本：cat /etc/redhat-release
>
> 查看Liunx内核版本：uname -a

1. 先卸载旧版本

   ```text
   $ sudo yum remove docker \
                     docker-client \
                     docker-client-latest \
                     docker-common \
                     docker-latest \
                     docker-latest-logrotate \
                     docker-logrotate \
                     docker-engine
   ```

2. 安装需要的工具包

   ```text
   $ sudo yum install -y yum-utils
   ```

3. 设置镜像创库

   ```text
   $ sudo yum-config-manager \
       --add-repo \
       http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
   ```

4. 更新yum软件包索引

   ```text
   $ yum makecache fast
   ```

5. 安装Docker

   ```text
   $ sudo yum install docker-ce docker-ce-cli containerd.io
   ```

6. 启动Docker

   ```text
   # 开机自动启动
   $sudo systemctl enable docker
   # 启动docker
   $ sudo systemctl start docker
   ```

7. 验证成功

   ```text
   $ docker --version

   $ docker run hello-world
   ```

8. 删除Docker
   1. 移除yum包

      ```text
      $ sudo yum remove docker-ce docker-ce-cli containerd.io
      ```

   2. 删除所有Docker 内容

      ```text
      $ sudo rm -rf /var/lib/docker
      ```

## 配置Docker远程访问

### 制作证书及秘钥

> 我们需要使用OpenSSL制作CA机构证书、服务端证书和客户端证书，以下操作均在安装Docker的Linux服务器上进行。

* 首先创建一个目录用于存储生成的证书和秘钥；

```bash
$ mkdir ~/docker-ca && cd ~/docker-ca
```

* 创建CA证书私钥，期间需要输入两次密码，生成文件为`ca-key.pem`；

```bash
$ openssl genrsa -aes256 -out ca-key.pem 4096
```

* 根据私钥创建CA证书，期间需要输入上一步设置的私钥密码，生成文件为`ca.pem`；

```bash
$ openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -subj "/CN=*" -out ca.pem
```

* 创建服务端私钥，生成文件为`server-key.pem`；

```bash
$ openssl genrsa -out server-key.pem 4096
```

* 创建服务端证书签名请求文件，用于CA证书给服务端证书签名，生成文件`server.csr`；

```bash
$ openssl req -subj "/CN=*" -sha256 -new -key server-key.pem -out server.csr
```

* 创建CA证书签名好的服务端证书，期间需要输入CA证书私钥密码，生成文件为`server-cert.pem`；

```bash
$ openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem
```

* 创建客户端私钥，生成文件为`key.pem`；

```bash
$ openssl genrsa -out key.pem 4096
```

* 创建客户端证书签名请求文件，用于CA证书给客户证书签名，生成文件`client.csr`；

```bash
$ openssl req -subj "/CN=client" -new -key key.pem -out client.csr
```

* 为了让秘钥适合客户端认证，创建一个扩展配置文件`extfile-client.cnf`；

```bash
$ echo extendedKeyUsage = clientAuth > extfile-client.cnf
```

* 创建CA证书签名好的客户端证书，期间需要输入CA证书私钥密码，生成文件为`cert.pem`；

```bash
$ openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf
```

* 删除创建过程中多余的文件；

```bash
$ rm -rf ca.srl server.csr client.csr extfile-client.cnf
```

* 最终生成文件如下，有了它们我们就可以进行基于TLS的安全访问了。

```markup
ca.pem CA证书
ca-key.pem CA证书私钥
server-cert.pem 服务端证书
server-key.pem 服务端证书私钥
cert.pem 客户端证书
key.pem 客户端证书私钥
```

### 配置Docker支持TLS

* 用vim编辑器修改docker.service文件；

```bash
# 打开docker.service
$ vi /usr/lib/systemd/system/docker.service
```

* 修改docker.service文件

  ```bash
  # ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
  ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
  ```

* 修改daemon.json

  ```bash
  # 打开daemon.json
  # 修改为下面json
  $ vim /etc/docker/daemon.json
  ```

  ```javascript
  {
    "hosts": ["tcp://0.0.0.0:2375", "unix:///var/run/docker.sock"],
    "tls": true,
    "tlscacert": "/root/docker-ca/ca.pem",
    "tlscert": "/root/docker-ca/server-cert.pem",
    "tlskey": "/root/docker-ca/server-key.pem",
    "tlsverify": true
  }
  ```

* 重启daemon和docker

  ```bash
  $ systemctl daemon-reload && systemctl restart docker
  ```

## 镜像基本命令

**帮助命令**

```text
$ docker --version
$ docker --info
$ docker --help
```

## 容器命令

**新建容器并启动**

```bash
$ docker run [可选参数] image
# 常见的坑。docker容器使用后台运行，就必须要有一个前台进程，docker没发现没有应用，就会自动停止
# Nginx，容器启动后，发现自己没有提供服务，就会立即停止，就没有程序了。
# 参数说明
--name="name"    #容器名字
-d                         #后台方试运行
--it                     #使用交互方式运行，进入容器查看内容
-P                        #(大写)指定容器端口 -P 8080:8080

-p                        #(小写)随机指定端口

# Nginx 运行样例
$ docker run -d --name nginx -p 3344:80 \
    -v ~/app/nginx/nginx.conf:/etc/nginx/nginx.conf \
    -v ~/app/nginx/logs:/var/log/nginx nginx
```

**退出容器**

```bash
$ exit #直接容器停止并退出

$ control + P + Q        #容器不停止退出
```

**删除容器**

```text
$ docker rm 容器id
$ docker rm -f 容器id #强制删除容器，包括运行中的容器
$ docker rm -f $(docker ps -qa) # 强制删除所有容器
```

**启动和停止容器**

```text
$ docker start 容器id
$ docker restart 容器id
$ docker stop 容器id
$ docker kill 容器id    # 强制停止运行中的容器。
```

**容器查看命令**

```bash
# 查看荡起所有运行的容器
$ docker ps 
# 查看所有容器，包括停止的
$ docker ps -a
```

## 进入镜像命令

**进入命令**

```text
$ docker exec -it 容器id /bin/bash

$ docker exec -it 容器id /bin/sh
```

## 查看数据卷命令

```text
$ docker inspect [容器id]
```

## 可视化Portainer

```bash
# 拉取portainer 2.0.0版本
$ docker pull portainer/portainer-ce:2.1.1

# 运行portainer
$ docker run -d -p 9000:9000 --name portainer \
--restart=always -v /var/run/docker.sock:/var/run/docker.sock \
--privileged=true \
portainer/portainer-ce:2.1.1
```

## 通过Dockerfile构建Springboot应用

#### 编写Dockerfile

```text
FROM openjdk:8-jdk-alpine
LABEL maintainer="JetWong<3508047@qq.com>"
# 定义springboot应用工作目录
WORKDIR /root/app/mega-service
# 创建logs目录
RUN mkdir /root/app/mega-service/logs
# 指定数据卷目录
VOLUME ["/root/app/mega-service/logs"]
# 设置时区
RUN echo 'Asia/Shanghai' >/etc/timezone
# 把bulid目录下jar复制到工作目录中
COPY ./bulid/*.jar /root/app/mega-service/app.jar
# copy arthas
COPY --from=hengyunabc/arthas:latest /root/app/arthas /root/app/arthas
EXPOSE 8080
ENTRYPOINT java $JAVA_OPTS -jar app.jar
```

#### 通过Dockerfile构建镜像

```text
$ docker build -t registry.cn-shenzhen.aliyuncs.com/chaineffect/mega-service:1.0.0 .
```

#### 推送镜像到阿里云仓库

1. 登录阿里云Docker仓库

```text
$ sudo docker login --username=jetwong0115@gmail.com registry.cn-shenzhen.aliyuncs.com
```

2.将镜像推送到仓库

```bash
# registry.cn-shenzhen.aliyuncs.com/chaineffect/mega-service:1.0.0
# 域名/命名空间/仓库:版本号
$ sudo docker tag fac8c36662da registry.cn-shenzhen.aliyuncs.com/chaineffect/mega-service:1.0.0

$ sudo docker push registry.cn-shenzhen.aliyuncs.com/chaineffect/mega-service:1.0.0
```

3. 从仓库拉取镜像

```text
$ sudo docker pull registry.cn-shenzhen.aliyuncs.com/chaineffect/mega-service:1.0.0
```

4. 运行镜像

```text
$ docker run -d --name mega-service -p 8080:8080 \
--restart=always \
-e JAVA_OPTS="-Xms128m -Xmx128m -Dspring.profiles.active=dev" \
-v /root/app/mega-service/logs:/root/app/mega-service/logs \
registry.cn-shenzhen.aliyuncs.com/chaineffect/mega-service:1.0.0
```

## Docker 安装 MinIO

```text
$ docker run -d -p 9000:9000 --name minio \
  -e "MINIO_ACCESS_KEY=hello" \
  -e "MINIO_SECRET_KEY=Allan967" \
  -v /root/minio/data:/data \
  -v /root/minio/config:/root/.minio \
  minio/minio server /data
```

## Docker 安装MySql

**获取镜像**

```text
$ docker pull mysql:5.7
$ docker run -d --name mysql -p 3306:3306 mysql:5.7
```

**运行mysql 挂载数据卷**

```bash
#    启动MySql镜像
# 挂载数据文件在 /home/mysql/data 目录
$ docker run -d -p 3306:3306 --name mysql  \
    -v /root/mysql/conf:/etc/mysql/conf.d \
    -v /root/mysql/data:/var/lib/mysql \
    -v /root/mysql/logs:/var/log/mysql \
    -v /etc/localtime:/etc/localtime \
    -e MYSQL_ROOT_PASSWORD=Allan967 \
    --restart=always \
    mysql:5.7

# 以下是挂载MySql配置文件（可选）
# -v /home/mysql/conf:/etc/mysql/conf.d \
```

## Docker 安装Nginx

**拉取镜像**

```text
$ docker search nginx
$ docker pull nginx
```

**复制配置文件**

```text
# 运行Nginx
$ docker run -d --name nginx -p 80:80 nginx

# 复制Nginx配置文件到本地目录
$ docker cp nginx:/etc/nginx/nginx.conf ~/nginx/conf/nginx.conf

# 删除容器
$ docker rm -f [nginx容器id]
```

**运行Nginx**

```text
# 重新运行Nginx镜像，并挂载配置文件和日志文件到本地目录
$ docker run -d --name nginx -p 80:80 -p 443:443 \
--restart=always --privileged=true \
-v ~/nginx/html:/usr/share/nginx/html \
-v ~/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
-v ~/nginx/conf/cert:/etc/nginx/cert \
-v ~/nginx/logs:/var/log/nginx \
-v /etc/localtime:/etc/localtime \
nginx
```

## Docker 安装Redis

拉取镜像

```text
$ docker pull redis:5.0.9
```

复制配置文件

```text
$ docker run -d --name redis -p 6379:6379 redis
```

```text
$ docker run -d -p 6379:6379 --restart always --name redis \
-v ~/redis/conf/redis.conf:/etc/redis/redis.conf \
-v ~/redis/data:/data \
redis:5.0.9 redis-server /etc/redis/redis.conf \
--requirepass "Allan967" --appendonly yes
```

## Docker Compose 相关

**Docker Compose 安装**

```text
$ sudo curl -L https://get.daocloud.io/docker/compose/releases/download/1.26.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

$ sudo chmod +x /usr/local/bin/docker-compose

$ docker-compose --version
```

**Docker Compose 后台运行**

```text
$ docker-compose -f xxx.yml up -d
```

## Docker swarm

## ![](Docker%20使用笔记.assets/截屏2020-10-22%2015.04.30.png)

### 初始化一个swarm

```bash
# 初始化一个manager节点
# 可以通过join-token命令再加入改节点
# ip 可以使用私网地址，通过ip addr命令可以查看
$ docker swarm init --advertise-addr [ip]
```

