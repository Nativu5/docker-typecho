# Docker-Typecho

**限于作者水平，未能进行充足测试，可能存在某些问题。**

## 概述

### 文件结构与说明

* `./nginx` 保存 `Nginx` 相关配置文件、日志、`SSL` 证书和 `Typecho` 程序；
* `./php-fpm-pgsql` 内保存 `nat1vus/php-fpm-pgsql` 的 `dockerfile`；（部署时可以不上传）
* `./cert.sh` 实现证书的申请应用和自动更新（需要预先安装 `acme.sh` ，默认以 `DNS` 方式获取证书 ）;
* `./docker-compose.yml` 控制容器挂载卷、环境变量等；
* `./dbdata` 保存 `pgsql` 的数据库配置与文件；（容器初次运行后自动生成）

### 容器组成

* `php-fpm-pgsql` : 提供`php`支持;
* `nginx` : 作为网页服务器;
* `postgres` : 数据库;

启动顺序为：`postgres ` -> `php-fpm` -> `nginx` ；

## 关于三个镜像

### PHP-FPM

* 文档：https://github.com/docker-library/docs/blob/master/php/README.md
* 原版已经内置了 `Typecho` 所需的 `mbstring`、`curl` 等拓展；
* 为了连接数据库，需要自行构建含 `pgsql` 拓展的镜像；
* 官方推荐使用 [docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer) 自行添加所需拓展；
* 由于某些原因，为了成功构建，将镜像中的软件源进行了更换。

### Nginx

* 直接使用了原版镜像。

### PostgresSQL

* 文档：https://hub.docker.com/_/postgres

* ”Environment Variables“ 一节中详细说明了容器运行所需提供的环境变量。

  本项目用到了以下环境变量:

  * `POSTGRES_PASSWORD` 数据库 `superuser` 密码； （必需）
  * `POSTGRES_USER` 指定 `superuser` 用户名；（可选，默认值为 `postgres`）
  * `POSTGRES_DB` 指定数据库名称；（可选）

## 部署指南

0. 宿主机必须安装 `docker`, `docker-compose`, 部署时的域名必须有证书; 

1. 克隆本仓库及子模块，切换到 `docker-typecho` 目录下；
   ```bash
   git clone --recursive --depth=1 https://github.com/Nativu5/docker-typecho.git
   ```

2. 共有 3 处配置文件需要用户自行修改：

   * `.\docker-compose.yml` : 

     * `db` 一节中的数据库用户名、数据库用户密码、数据库名都可以由用户自定义；
     * 每一节都有环境变量 `TZ` ，可供设置容器时区；

   * `.\nginx\conf.d` : 需要将文件中所有 `yourdomain.com` 替换为用户自己的域名；

   * `.\cert.sh` :  首先将 `/path/to/dockercompose` 替换为 `docker-compose.yml` 所在路径；

     默认采用的是 `DNS` 验证方式申请证书，搭配的是 `DNSPOD` 的API。

     * 若用户使用 `DNSPOD` ，填入 `API ID` 和 `API Token` 即可；
     * 若用户不使用 `DNSPOD`， 可以修改脚本前 6 行自行配置 `acme.sh` 获取证书即可； 

3. 执行 `.\cert.sh` 申请证书并设置证书自动更新；

4. 在 `docker-typecho` 下执行

   ```bash
   docker-compose up
   ```

   正常情况下，所有容器都应能正常运行；

5. 使用 `Ctrl-C` 停止所有容器，然后执行：

   ```bash
   sudo chmod -R 777 ../docker_typecho
   ```

   更改权限以便稍后 `Typecho` 存取文件；

6. 然后执行：

   ```bash
   docker-compose start
   ```

   重启容器，启动成功后打开浏览器访问预先设置的域名，即可安装 `Typecho` 。

## 注意事项

* `php-fpm-pgsql` 镜像已经上传 Docker Hub, 本仓库中也已经包含了 `dockerfile` , 读者可以此自行构建；

* 配置文件默认已经开启 `https` ，故需先申请证书再使用；  

* `acme.sh` 会自动更新证书；

* 启用数据库定时备份，新建 `backup` 文件夹：

  ```
  mkdir /path/to/dockercompose/backup
  ```

  修改`vim /etc/crontab`，加入如下内容：

  ```bash
  */30 * * * * tar zcvf /path/to/dockercompose/backup/db-$(date +%y-%m-%H-%M).tar.gz /path/to/dockercompose/dbdata
  ```

  即每30分钟备份一次数据库，保存在 `/path/to/dockercompose/backup` 的 `db-日期.tar.gz` 中，

  别忘了 `systemctl enable crond && systemctl start`.

* `Typecho` 程序文件，使用的版本为当前 [Typecho](https://github.com/typecho/typecho) 仓库中 master 分支的最新版。您可以手动替换为需要的版本。

* `Typecho` 安装时需要的数据库信息都在 `docker-compose.yml` 中；

* `TZ` 环境变量控制容器时间，缺省为 `UTC`,   `docker-compose.yml` 中已经全部改为 `Asia/Shanghai`.

* 如果不修改文件夹权限，安装 `Typecho` 时可能会提示用户自行创建 `config.inc.php`；

* `Typecho` 安装卡在第三步，可能是 `PHP.ini` 中 `output_buffering` 出现问题；

