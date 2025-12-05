# Elasticsearch 容器问题说明

## 1 容器挂载路径权限问题
需要给 `./Elasticsearch版本/logs` 文件夹赋予权限
```shell
chmod -R 777 ./8.4.0/logs
chmod -R 777 ./9.1.2/logs
```
重启即可

## 2 Elasticsearch账号密码设置
```shell
# 自动生成密码
./bin/elasticsearch-setup-passwords auto
# 手动设置密码
./bin/elasticsearch-setup-passwords interactive
```
执行后会自动生成密码
```
Changed password for user apm_system
PASSWORD apm_system = {密码}

Changed password for user kibana_system
PASSWORD kibana_system = {密码}

Changed password for user kibana
PASSWORD kibana = {密码}

Changed password for user logstash_system
PASSWORD logstash_system = {密码}

Changed password for user beats_system
PASSWORD beats_system = {密码}

Changed password for user remote_monitoring_user
PASSWORD remote_monitoring_user = {密码}

Changed password for user elastic
PASSWORD elastic = {密码}
```
