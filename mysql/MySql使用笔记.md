# MySql命令行登录

**本地登录MySQL**

```bash
# -u 指定账户名称，-p回车后会要求输入密码
$ mysql -u root -p
```

**指定端口号登录**

```bash
# -P 大写P后跟端口号
$ mysql -u -p -P 3306
```

**指定IP地址和端口号登录**

```bash
# -h 后跟IP地址
$ mysql -h 127.0.0.1 -u root -p -P 3306
```

# 通过Docker 安装

**运行mysql 挂载数据卷**

```bash
# 启动MySql镜像
# 挂载数据文件在 /home/mysql/data 目录
$ docker run -d -p 3306:3306 --name mysql  \
    -v /usr/local/mysql/conf:/etc/mysql/conf.d \
    -v /usr/local/mysql/data:/var/lib/mysql \
    -v /usr/local/mysql/logs:/var/log/mysql \
    -v /etc/localtime:/etc/localtime \
    -e MYSQL_ROOT_PASSWORD=Allan967 \
    --restart=always \
    mysql:8.0.24

# 以下是挂载MySql配置文件（可选）
# -v /home/mysql/conf:/etc/mysql/conf.d \
```

# MySql配置文件详解



