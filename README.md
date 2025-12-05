存放各种docker image构建脚本或者快速启动的docker-compose文件。

### 快速使用
1. clone 项目
    ```shell
    git clone https://github.com/xiaoyu98628/docker.git
    # 或者
    git clone https://gitee.com/xiaoyu98628/docker.git
   ```
2. 进入项目根目录，复制并改名 `compose.yml` 和 `.env`
    ```shell
   cp ./compose.sample.yml ./compose.yml
   cp ./sample.env ./.env
   ```
3. 复制并改名对应镜像的 `compose.yml` 和 `.env`
    ```shell
    cp ./镜像名/版本号/compose.sample.yml ./镜像名/版本号/compose.yml
    cp ./镜像名/版本号/sample.env ./镜像名/版本号/.env
    # 例如
    cp ./php/8.2/compose.sample.yml ./php/8.2/compose.yml
    cp ./php/8.2/sample.env ./php/8.2/.env
    ```
4. 在根目录引入你想使用的镜像的 compose.yml
    ```yaml
   # 例如
   include :
     - php/8.2/compose.yml
   # ... 其余不变
    ```
5. 启动服务
    ```shell
   # 批量启动
   docker compose up -d
   
   #  单独构建
   docker compose build --no-cache [镜像名]
   
   # 单独启动
   docker compose up -d [镜像名]
   ```
