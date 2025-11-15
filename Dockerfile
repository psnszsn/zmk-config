FROM docker.io/zmkfirmware/zmk-build-arm:4.1-branch

WORKDIR /app

COPY config/west.yml config/west.yml

# West Init
RUN west init -l config
# West Update
RUN west update
# West Zephyr export
RUN west zephyr-export
