# Mongo 容器问题说明

## 1 容器挂载路径权限问题
需要给 `./Mongo版本/logs` , `./Mongo版本/data` 文件夹赋予权限
```shell
chmod -R 777 ./6.0/logs ./6.0/data
```
重启即可

## 2 `system.sessions`文档没权限访问
授权
```
db.grantRolesToUser('userName',[{role:"<role>",db:"<database>"}])
// 例如
db.grantRolesToUser('root',[{role:"__system",db:"admin"}])
```

# Mongo-Express 容器问题说明

## 1 Mongo-Express 登陆账号密码
```text
username: admin
password: pass
```
