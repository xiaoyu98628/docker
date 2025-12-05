# PHP 容器问题说明

## 1 php项目挂载
打开项目跟目录的`.env` 文件，修改即可
 ```
 PROJECT_DIRECTORY=你的项目存放位置
 ```
为什么这样做
1. `.env` 文件中的 `PROJECT_DIRECTORY` 配置项，会被 `compose.yml` 文件中的 `volumes` 配置项所引用，从而实现项目跟目录的映射
2. 方便nginx和php挂载同一项目

## 2 安装PHP扩展常用命令
1. 方法一：
    * `docker-php-source`
      > 此命令，实际上就是在PHP容器中创建一个`/usr/src/php`的目录，里面放了一些自带的文件而已。我们就把它当作一个从互联网中下载下来的PHP扩展源码的存放目录即可。事实上，所有PHP扩展源码扩展存放的路径： `/usr/src/php/ext` 里面。
    * `docker-php-ext-install`
      > 这个命令，就是用来启动 PHP扩展 的。我们使用pecl安装PHP扩展的时候，默认是没有启动这个扩展的，如果想要使用这个扩展必须要在php.ini这个配置文件中去配置一下才能使用这个PHP扩展。而 `docker-php-ext-enable` 这个命令则是自动给我们来启动PHP扩展的，不需要你去php.ini这个配置文件中去配置。
    * `docker-php-ext-enable`
      > 这个命令，是用来安装并启动PHP扩展的。命令格：`docker-php-ext-install "源码包目录名"`
    * `docker-php-ext-configure`
      > 一般都是需要跟 docker-php-ext-install搭配使用的。它的作用就是，当你安装扩展的时候，需要自定义配置时，就可以使用它来帮你做到。
    * [**Docker容器里 PHP安装扩展**](readme/php-install-extensions.md)
2. 方法二：
    * 快速安装 PHP 扩展
      ```shell
       docker exec -it php82 sh
       install-php-extensions redis
       ```
    * [**支持快速安装扩展列表**](https://github.com/mlocati/docker-php-extension-installer?tab=readme-ov-file#supported-php-extensions)
      > <a href="https://github.com/mlocati/docker-php-extension-installer" target="_blank">**此扩展来自 docker-php-extension-installer 参考示例文件**</a>
    >**注意：以上两种方式是在容器内安装扩展，容器删除，扩展也会随之删除，建议在镜像层安装扩展，在.env文件里添加对应的扩展，然后重新 `docker compose build php72` 构建镜像即可**
    ```dotenv
    # +--------------+
    # PHP Related Configuration
    # +--------------+
    #
    # +--------------------------------------------------------------------------------------------+
    # Default installed:
    #
    # Core,ctype,curl,date,dom,fileinfo,filter,ftp,hash,iconv,json,libxml,mbstring,mysqlnd,openssl,pcre,PDO,
    # pdo_sqlite,Phar,posix,readline,Reflection,session,SimpleXML,sodium,SPL,sqlite3,standard,tokenizer,xml,
    # xmlreader,xmlwriter,zlib
    #
    # Available PHP_EXTENSIONS:
    #
    # pdo_mysql,pcntl,mysqli,exif,bcmath,opcache,gettext,gd,sockets,shmop,intl,bz2,soap,zip,sysvmsg,sysvsem,
    # sysvshm,xsl,calendar,tidy,snmp,
    # amqp,apcu,rdkafka,redis,swoole,memcached,xdebug,mongodb,protobuf,grpc,xlswriter,igbinary,imagick,psr,
    # phalcon,mcrypt,yaml
    #
    # You can let it empty to avoid installing any extensions,
    # +--------------------------------------------------------------------------------------------+
    PHP_EXTENSIONS=pdo_mysql,opcache,redis,gd,mongodb
    ```

## 3 composer 的使用
1. composer 查看全局设置
   ```shell
   composer config -gl
   ```
2. 设置composer镜像为国内镜像,全局模式
   ```shell
   # phpcomposer镜像源
   composer config -g repo.packagist composer https://packagist.phpcomposer.com
   # 阿里云composer镜像源
   composer config -g repo.packagist composer https://mirrors.aliyun.com/composer
   # 腾讯云composer镜像源
   composer config -g repo.packagist composer https://mirrors.cloud.tencent.com/composer
   ```
3. 恢复composer默认镜像
   ```shell
   composer config -g --unset repos.packagist
   ```

## 4 配置xdebug
[**phpstorm 配置 xdebug**](readme/xdebug.md)

## 5 PHP慢日志没有记录问题
在Linux系统中，PHP-FPM使用 SYS_PTRACE 跟踪worker进程，但是docker容器默认又不启用这个功能，所以就导致了这个问题。  
**解决**：
1. 如果用命令行，在命令上加上： `--cap-add=SYS_PTRACE`
2. 如果用compose.yml文件，在服务中加上：
   ```yaml
    php82:
      # ...
      cap_add:
          - SYS_PTRACE
      # ...
   ```

## 6 supervisor的使用
1. supervisor的主配置文件路径：`./php版本/config/supervisor/supervisord.conf`
   > **注意**：supervisor的配置文件默认是不全的，不过在大部分默认的情况下，上面说的基本功能已经满足。
2. 子进程配置文件路径：`./php版本/config/supervisor/supervisor.d/php-fpm.ini`
   > **注意**：默认子进程配置文件为ini格式，可复制ini.sample文件修改。
3. 常用命令
    ```shell
    supervisorctl status              //查看所有进程的状态
    supervisorctl update              //配置文件修改后使用该命令加载新的配置
    supervisorctl reload              //重新启动配置中的所有程序
    supervisorctl stop 项目名          //停止项目
    supervisorctl start 项目名         //启动项目
    supervisorctl restart 项目名       //重启项目
    ```
   > 把`项目名`换成`all`可以管理配置中的所有进程，直接输入`supervisorctl`进入`supervisorctl`的shell交互界面，此时上面的命令不带`supervisorctl`可直接使用
4. [部分配置文件说明](readme/supervisor.md)

