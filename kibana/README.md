# Kibana 容器问题说明

## 1 Kibana连接Elasticsearch问题
打开 `./kibana版本/.env` 文件 修改即可
```dotenv
# 在 .env 文件中找到 kibana 对应的配置修改
KIBANA_ELASTICSEARCH_USERNAME="kibana_system或kibana"
KIBANA_ELASTICSEARCH_PASSWORD="Elasticsearch生成的密码"
```
