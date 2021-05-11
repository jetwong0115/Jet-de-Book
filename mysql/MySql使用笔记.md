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

**主从复制配置文件模板 my_ext.cnf**

```bash
[mysqld]
## 设置server_id，一般设置为IP，注意要唯一
server_id=100
## 复制过滤：也就是指定哪个数据库不用同步（mysql库一般不同步）
binlog-ignore-db=mysql
## 开启二进制日志功能，可以随便取，最好有含义（关键就是这里了）
log-bin=replicas-mysql-bin
## 为每个session分配的内存，在事务过程中用来存储二进制日志的缓存
binlog_cache_size=1M
## 主从复制的格式（mixed,statement,row，默认格式是statement）
binlog_format=mixed
## 二进制日志自动删除/过期的天数。默认值为0，表示不自动删除。
expire_logs_days=7
## 跳过主从复制中遇到的所有错误或指定类型的错误，避免slave端复制中断。
## 如：1062错误是指一些主键重复，1032错误是因为主从数据库数据不一致
slave_skip_errors=1062
```



