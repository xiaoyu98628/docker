# RabbitMQ 容器问题说明

## 1 容器挂载路径权限问题
需要给 `./RabbitMQ版本/logs`、`./RabbitMQ版本/data` 文件夹赋予权限
```shell
chmod -R 777 ./3.11/logs
chmod -R 777 ./3.11/logs
```
重启即可
