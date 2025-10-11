存放各种docker image构建脚本或者快速启动的docker-compose文件。

### 快速使用
1. 进入项目根目录，复制并改名 `compose.yml` 和 `.env`
    ```shell
   cp ./compose.sample.yml ./compose.yml
   cp ./sample.env ./.env
   ```
2. 复制并改名对应镜像的 `compose.yml` 和 `.env`
    ```shell
    cp ./镜像名/版本号/compose.sample.yml ./镜像名/版本号/compose.yml
    cp ./镜像名/版本号/sample.env ./镜像名/版本号/.env
    # 例如
    cp ./php/8.2/compose.sample.yml ./php/8.2/compose.yml
    cp ./php/8.2/sample.env ./php/8.2/.env
    ```
3. 在根目录引入你想使用的镜像的 compose.yml
    ```yaml
   # 例如
   include :
   - php/8.2/compose.yml
   # ... 其余不变
    ```
4. 启动服务
    ```shell
   docker compose up -d
   ```
