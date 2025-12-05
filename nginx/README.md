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
> 这是一个可以自动申请（并自动更新）免费ssl证书的nginx镜像。证书申请和更新使用的是开源工具acme.sh。当前你也可以把它当普通镜像使用。使用方法如下  
> 或参考 acme 官方文档 [https://github.com/acmesh-official/acme.sh/wiki/How-to-issue-a-cert](https://github.com/acmesh-official/acme.sh/wiki/How-to-issue-a-cert)
1. env 配置说明（下面是按照nginx1.21版本，如需修改版本请手动修改对应的版本号）
    ```dotenv
    # +--------------+
    # Nginx1.21 Related Configuration
    # +--------------+
    NGINX_REGISTER_ACME_MAIL_1_21=
    NGINX_RELOAD_CMD_1_21="nginx -s reload"
    NGINX_SSL_DOMAINS_1_21=
    NGINX_SSL_SERVER_1_21=letsencrypt
    NGINX_SSL_BASE_DIR_1_21=/usr/panel/ssl/nginx/nginx1.21
    NGINX_SSL_DNS_1_21=

    # 参数说明
    # NGINX_REGISTER_ACME_MAIL_1_21 申请ssl证书所需的邮箱
    # NGINX_RELOAD_CMD_1_21 自动更新后自动执行nginx命令 推荐使用 nginx -s reload
    # NGINX_SSL_DOMAINS_1_21 需要申请ssl证书的域名，但是需要申请证书的域名http可以正常访问,如果为空或者不填，这就是个普通的nginx镜像，不会启动证书acme
    # NGINX_SSL_SERVER_1_21 证书服务商 默认使用：zerossl，还可以使用letsencrypt，buypass，ssl等等或者letsencrypt的测试地址：https://acme-staging-v02.api.letsencrypt.org/directory 具体使用请看：https://github.com/acmesh-official/acme.sh/wiki/%E8%AF%B4%E6%98%8E
    # NGINX_SSL_BASE_DIR_1_21 证书存放位置，不建议修改，如果修改了nginx配置文件中以及挂载也需要修改
    # NGINX_SSL_DNS_1_21 域名采用dns验证，可选参数为：dns_ali，dns_aws，dns_cf，dns_dp，，。。。更多参数请查看：https://github.com/acmesh-official/acme.sh/wiki/dnsapi例如1： 为空时，请查看控制台日志中的dns记录，并手动为域名添加解析；例如2： -e dns=“dns_ali” -e Ali_Key=“sdfsdfsdfljlbjkljlkjsdfoiwje” -e Ali_Secret=“jlsdflanljkljlfdsaklkjflsa” 使用云厂商api，请添加对应的key、secret等"添加域名解析"授权参数
    ```
2. 需手动配置ssl证书
   > 上面配置修改好，启动nginx容器，找到你需要配置ssl证书的配置文件，根据3和4步骤修改相应的配置即可
3. `ssl` 证书存放位置
   ```
   ./panel/ssl/nginx/nginx1.21/站点名称/证书
   ```
4. `nginx.conf` 配置文件修改
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
      ssl_certificate /usr/panel/ssl/nginx/nginx1.21/站点名称/xxx; # 公钥
      ssl_certificate_key /usr/panel/ssl/nginx/nginx1.21/站点名称/xxx; # 私钥

      #ssl验证相关配置
      ssl_session_timeout  5m;    #缓存有效期
      ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;    #加密算法
      ssl_protocols TLSv1 TLSv1.1 TLSv1.2;    #安全链接可选的加密协议
      ssl_prefer_server_ciphers on;   #使用服务器端的首选算法
      
      ...
   }
   ```
5. 修改完成配置文件，重启（重载）即可
   ```shell
   # 方式一：重启 docker compose restart 服务ID
   docker compose restart nginx1.21
   # 方式二：重载 docker exec 容器ID nginx -s reload
   docker exec nginx1.21 nginx -s reload
   ```
