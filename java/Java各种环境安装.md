# yum 安装java

链接：https://segmentfault.com/a/1190000015389941

```shell
$ yum install java-1.8.0-openjdk-devel.x86_64
```

# Tomcat安装

## 环境变量配置

```shell
TOMCAT_HOME=/usr/local/tomcat8
CATALINA_HOME=/usr/local/tomcat8
CATALINA_BASE=/usr/local/tomcat8
CATALINA_TMPDIR=/usr/local/tomcat8/temp
PATH=$PATH:$HOME/bin:$JAVA_HOME/bin:$TOMCAT_HOME/bin:
```

# Nginx安装

## 启动、停止、重启

