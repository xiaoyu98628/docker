# MySQL 容器问题说明

## 1 容器挂载路径权限问题
需要给 `./MySQL版本/logs` 文件夹赋予权限
```shell
chmod -R 777 ./8/logs
chmod -R 777 ./9/logs
```
重启即可

## 2 mysql 密码问题
当前mysql容器提供两个账户，`root账户`，默认在容器内部访问 `admin账户` 默认权限不足
```dotenv
# +--------------+
# mysql Related Configuration
# +--------------+
MYSQL_ROOT_PASSWORD=root
MYSQL_ROOT_HOST=localhost
MYSQL_USER=admin
MYSQL_PASSWORD=admin
```
打开 `./MySQL版本/.env` 文件 修改即可
- `MYSQL_ROOT_PASSWORD` 默认账户 `root` 对应的密码
- `MYSQL_ROOT_HOST` 默认账户 `root` 对应的访问权限
- `MYSQL_USER` 新建账户 `admin` 用户名
- `MYSQL_PASSWORD` 新建账户 `admin` 对应的密码

## 3 权限问题
如需修改权限，对照下面命令修改
```sql
-- privileges：用户的操作权限，如SELECT，INSERT，UPDATE等，如果要授予所的权限则使用ALL
-- database_name：数据库名
-- table_name：表名，如果要授予该用户对所有数据库和表的相应操作权限则可用*表示，如*.*
GRANT privileges ON database_name.table_name TO 'username'@'host';

-- 例子：
GRANT SELECT,INSERT ON test.user TO 'admin'@'%';
GRANT ALL ON *.* TO 'admin'@'%';
GRANT ALL ON test.* TO 'admin'@'%';

-- 刷新权限
FLUSH PRIVILEGES; 
```
## 4 windows 下文件权限导致 mysql 配置文件不生效导致 php7.2 和 php7.3 连接 mysql 密码问题
1、配置文件权限问题：成功创建容器进入容器修改配置文件权限及用户和用户组 `chown -R mysql:mysql /etc/mysql`, `chown -R 755 /etc/mysql`， 重启 mysql 容器  
2、连接问题：原因是因为 在 MySQL 8.0 及更高版本中，默认的认证插件从 mysql_native_password 更改为 caching_sha2_password。如果你的 MySQL 服务器不再使用 mysql_native_password 插件，php7.3 及低版本中可能会因为不支持 caching_sha2_password 而无法连接数据库。  
解决办法：修改密码；例如`ALTER USER 'admin'@'%' IDENTIFIED WITH mysql_native_password BY 'admin';`
