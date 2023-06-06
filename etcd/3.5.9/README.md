## docker 部署 etcd 3.5.9 集群  

#### 两种方式  
一种使用 docker run 方式，命令在 demo.sh 文件中  
另一种使用 docker-compose 编排方式

#### 导入镜像命令
该文件下面有两个 .tar 文件 一个是 amd64 架构和 arm64 架构的镜像包  
这两个是官方镜像包，需要会科学上网才能 pull ，否则会链接超时

```shell
docker load -i ./etcd-amd64-v3.5.9.tar
docker load -i ./etcd-amd64-v3.5.9.tar
```

#### etcd 参数详解  
|                          参数名 | 说明                                          |
|-----------------------------:|:--------------------------------------------|
|                        -name | 设置成员节点的别名，建议为每个成员节点配置可识别的命名                 |
|       -advertise-client-urls | 广播到集群中本成员的监听客户端请求的地址                        |
| -initial-advertise-peer-urls | 广播到集群中本成员的Peer监听通信地址                        |
|          -listen-client-urls | 客户端请求的监听地址列表                                |
|            -listen-peer-urls | Peer消息的监听服务地址列表                             |
|       -initial-cluster-token | 启动集群的时候指定集群口令，只有相同token的几点才能加入到同一集群         |
|             -initial-cluster | 所有集群节点的地址列表                                 |
|       -initial-cluster-state | 初始化集群状态，默认为new，也可以指定为exi-string表示要加入到一个已有集群 |