# Nginx 容器问题说明

## 1 项目存放位置以及修改
打开项目跟目录的`.env` 文件，修改即可
 ```
 PROJECT_DIRECTORY=你的项目存放位置
 ```
为什么这样做
1. `.env` 文件中的 `PROJECT_DIRECTORY` 配置项，会被 `compose.yml` 文件中的 `volumes` 配置项所引用，从而实现项目跟目录的映射
2. 方便nginx和php挂载同一项目

## 2 添加新的站点
新增的 `.conf` 文件应放在 `/config/nginx/vhost/nginx版本` 文件夹下

## 3 切换PHP版本
比如切换为PHP8.3，打开 `/config/nginx/vhost/nginx版本` 下对应的Nginx站点配置文件，找到 `include enable-php-82.conf` 改成 `include enable-php-83.conf` 即可  
例如：
```
location ~ [^/]\.php(/|$) {
   ...
   include enable-php-82.conf;
   ...
}
```
改为：
```
location ~ [^/]\.php(/|$) {
   ...
   include enable-php-83.conf;
   ...
}
```
> 注意：修改了nginx配置文件，使之生效必须要 **重启 Nginx 容器** 或者 **在容器中执行 `nginx -s reload`**

## 4 站点根目录挂载说明
为什么站点根目录在Nginx和PHP-FPM都需要挂载？
```
# php 挂载目录
- "./www:/var/www/html"
# nginx 挂载目录
- "./www:/usr/share/nginx/html"
```
我们知道，Nginx配置都有这样一项：
```
fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
```
其中，`$document_root` 就是server块下 `root` 所指的路径：
```
server {
   ...
   root /var/www/html;
   ...
}
```
这里 `$document_root` 就是/var/www/html。  
如果Nginx和PHP-FPM在同一主机，Nginx会通过9000端口（或套接字文件）把这个目录值和脚本URI传给PHP-FPM。  
PHP-FPM再通过9000端口（或套接字文件）接收Nginx发过来的目录值和脚本URI，发给PHP解析。  
PHP收到后，就到指定的目录下查找PHP文件并解析，完成后再通过9000端口（或套接字文件）返回给Nginx。  
**如果Nginx和PHP-FPM在同一个主机里面，PHP就总能找到Nginx指定的目录。**     
**但是，如果他们在不同的容器呢？**   
未做任何处理的情况，Nginx容器中的站点根目录，PHP-FPM容器肯定不存在。 所以，这里需要保证Nginx和PHP-FPM都挂载了宿主机的 `./www`。 （当然，你也可以指定别的目录）

## 5 配置https
Nginx 镜像只负责读取证书和提供 Web 服务，证书申请与续期由根目录的 `acme` 服务负责。

1. 先使用 `acme` 服务申请证书，证书会安装到：
   ```text
   /usr/config/acme/certs/站点名称/
   ```
   宿主机对应：
   ```text
   ./config/acme/certs/站点名称/
   ```
2. Webroot 模式需要所有站点都能访问统一 challenge 目录：
   ```nginx
   location ^~ /.well-known/acme-challenge/ {
       root /usr/share/nginx/html;
       default_type text/plain;
       try_files $uri =404;
   }
   ```
3. `nginx.conf` 配置文件修改
   ```
   server {
      listen       80;
      listen  [::]:80;
      server_name  xxx; # 域名
   
      # 跳转  实现 http 强转 https
      rewrite ^(.*)$ https://${server_name}$1 permanent;
      
      ...
   }
   
   server {
      listen       443 ssl;
      listen  [::]:443 ssl;
      server_name  xxx; # 域名和上面的域名一致
   
      #ssl证书地址
      ssl_certificate /usr/config/acme/certs/站点名称/fullchain.pem; # 公钥
      ssl_certificate_key /usr/config/acme/certs/站点名称/key.pem; # 私钥

      #ssl验证相关配置
      ssl_session_timeout  5m;    #缓存有效期
      ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;    #加密算法
      ssl_protocols TLSv1 TLSv1.1 TLSv1.2;    #安全链接可选的加密协议
      ssl_prefer_server_ciphers on;   #使用服务器端的首选算法
      
      ...
   }
   ```
4. 修改完成配置文件，重启（重载）即可
   ```shell
   # 方式一：重启 docker compose restart 服务ID
   docker compose restart nginx1.21
   # 方式二：重载 docker exec 容器ID nginx -s reload
   docker exec nginx1.21 nginx -s reload
   ```
