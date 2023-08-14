# docker 部署 etcd 3.5.9 集群  

#### 文件说明

```gitignore
# 忽略文件
!.gitignore
# 集群所需的 yaml 文件
!compose-cluster.sample.yml
# 单机所需的 yaml 文件
!compose-standalone.sample.yml
# 镜像文件
!etcd-amd64-v3.5.9.tar
!etcd-arm64-v3.5.9.tar
# 说明文件
!README.md
```

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

|                              参数名 | 说明              |
|---------------------------------:|:----------------|
|                        ETCD_NAME | 当前节点名称          |
|       ETCD_ADVERTISE_CLIENT_URLS | 告知集群自己的客户端地址    |
|          ETCD_LISTEN_CLIENT_URLS | 设置监听客户端通讯的URL列表 |
| ETCD_INITIAL_ADVERTISE_PEER_URLS | 告知集群自己集群通讯地址    |
|            ETCD_LISTEN_PEER_URLS | 用于监听伙伴通讯的URL列表  |
|       ETCD_INITIAL_CLUSTER_TOKEN | 集群的初始化集群记号      |
|             ETCD_INITIAL_CLUSTER | 集群成员            |
|       ETCD_INITIAL_CLUSTER_STATE | 初始化集群状态         |

### etcd 基本使用
```shell
# 测试是否安装成功
docker exec etcd-node-1 etcd --version
docker exec etcd-node-1 etcdctl version

# 检查集群的健康状态
docker exec etcd-node-1 etcdctl endpoint health --cluster -w table

# 增
docker exec etcd-node-1 etcdctl --endpoints=etcd-node-1:2379,etcd-node-2:2379,etcd-node-3:2379 put abc 123
# --endpoints 参数指定了etcd服务器的地址，这里是三个etcd容器的地址
# 或
docker exec etcd-node-1 etcdctl put abc 123

# 查
docker exec etcd-node-1 etcdctl get abc
docker exec etcd-node-2 etcdctl get abc
docker exec etcd-node-3 etcdctl get abc
# 或
docker exec etcd-node-1 etcdctl --endpoints=etcd-node-1:2379 get abc
docker exec etcd-node-1 etcdctl --endpoints=etcd-node-2:2379 get abc
docker exec etcd-node-1 etcdctl --endpoints=etcd-node-3:2379 get abc

# 删
docker exec etcd-node-1 etcdctl del abc
# 或
docker exec etcd-node-1 etcdctl --endpoints=etcd-node-1:2379 del abc
docker exec etcd-node-1 etcdctl --endpoints=etcd-node-2:2379 del abc
docker exec etcd-node-1 etcdctl --endpoints=etcd-node-3:2379 del abc

# 查看全部的key
docker exec etcd-node-1 etcdctl get --prefix ""
```