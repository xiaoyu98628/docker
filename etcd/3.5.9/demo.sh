# 使用docker run 部署 etcd 集群

# 创建网络
docker network create --driver bridge etcd-node

# 部署节点
docker run -d \
-p 2379:2379 \
-p 2380:2380 \
--name etcd-node1 \
--network=etcd-node \
gcr.io/etcd-development/etcd:v3.5.9 \
etcd \
-name node1 \
-advertise-client-urls http://etcd-node1:2379 \
-initial-advertise-peer-urls http://etcd-node1:2380 \
-listen-client-urls http://0.0.0.0:2379 -listen-peer-urls http://0.0.0.0:2380 \
-initial-cluster-token etcd-cluster \
-initial-cluster "etcd-node1=http://etcd-node1:2380,etcd-node2=http://etcd-node2:2380,etcd-node3=http://etcd-node3:2380" \
-initial-cluster-state new


docker run -d \
-p 12379:2379 \
-p 12380:2380 \
--name etcd-node2 \
--network=etcd-node \
gcr.io/etcd-development/etcd:v3.5.9 \
etcd \
-name node2 \
-advertise-client-urls http://etcd-node2:2379 \
-initial-advertise-peer-urls http://etcd-node2:2380 \
-listen-client-urls http://0.0.0.0:2379 -listen-peer-urls http://0.0.0.0:2380 \
-initial-cluster-token etcd-cluster \
-initial-cluster "etcd-node1=http://etcd-node1:2380,etcd-node2=http://etcd-etcd-node2:2380,etcd-node3=http://etcd-node3:2380" \
-initial-cluster-state new

docker run -d \
-p 22370:2379 \
-p 22380:2380 \
--name etcd-node3 \
--network=etcd-node \
gcr.io/etcd-development/etcd:v3.5.9 \
etcd \
-name node3 \
-advertise-client-urls http://etcd-node3:2379 \
-initial-advertise-peer-urls http://etcd-node3:2380 \
-listen-client-urls http://0.0.0.0:2379 -listen-peer-urls http://0.0.0.0:2380 \
-initial-cluster-token etcd-cluster \
-initial-cluster "etcd-node1=http://etcd-node1:2380,etcd-node2=http://etcd-node2:2380,etcd-node3=http://etcd-node3:2380" \
-initial-cluster-state new

# 测试是否安装成功
docker exec etcd-node1 etcd --version
docker exec etcd-node1 etcdctl version


# 增
docker exec etcd-node1 etcdctl --endpoints=etcd-node1:2379,etcd-node2:2379,etcd-node3:2379 put abc 123
# --endpoints 参数指定了etcd服务器的地址，这里是三个etcd容器的地址
# 或
docker exec etcd-node1 etcdctl put abc 123

# 查
docker exec etcd-node1 etcdctl get abc
docker exec etcd-node2 etcdctl get abc
docker exec etcd-node3 etcdctl get abc
# 或
docker exec etcd-node1 etcdctl --endpoints=etcd-node1:2379 get abc
docker exec etcd-node1 etcdctl --endpoints=etcd-node2:2379 get abc
docker exec etcd-node1 etcdctl --endpoints=etcd-node3:2379 get abc

# 删
docker exec etcd-node1 etcdctl del abc
# 或
docker exec etcd-node1 etcdctl --endpoints=etcd-node1:2379 del abc
docker exec etcd-node1 etcdctl --endpoints=etcd-node2:2379 del abc
docker exec etcd-node1 etcdctl --endpoints=etcd-node3:2379 del abc
