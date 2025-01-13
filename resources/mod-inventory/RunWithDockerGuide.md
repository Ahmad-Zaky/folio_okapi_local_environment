# Introduction

a step by step guidance to run your module within Docker container, taking `mod-inventory` as an example.

## Usage

1. build the Dockerfile.
    ```bash
    docker build -t mod-inventory .
    ```

2. run the container.
    ```bash
    docker run -d \
        --name mod-inventory \
        -p 8081:8081 \
        --add-host=host.docker.internal:host-gateway \
        -e DB_DATABASE=okapi_modules \
        -e DB_HOST=host.docker.internal \
        -e DB_MAXPOOLSIZE=5 \
        -e DB_PASSWORD=folio_admin \
        -e DB_PORT=5432 \
        -e DB_QUERYTIMEOUT=60000 \
        -e DB_USERNAME=folio_admin \
        -e KAFKA_HOST=host.docker.internal \
        -e KAFKA_PORT=9092 \
        -e JDK_JAVA_OPTIONS="-Dport=8081 -Dhttp.port=8081" \
        mod-inventory
    ```
3. review logs.
    ```bash
    docker logs mod-inventory
    ```
4. stop, remove (container and volume), and remove image after finishing, to rebuild again on any changes into `Dockerfile`.
    ```bash
    docker stop mod-inventory && docker rm -v mod-inventory && docker rmi mod-inventory:latest
    ```