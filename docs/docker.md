# Docker

## Why docker?

While working with virsh is completely fine for winapps you have to setup and optimise you vm manually. Docker on the other hand setups most of the stuff automatically and makes the vm highly portable between linux distros.

# Requirements

Since docker manages the dependencies of the container automatically you only need to install docker or podman itself. (Podman is recommended because of the faster container startup times. Note that podman and docker are interchangeable so no instructions will change depending on which one you use)

Note: This will only work on linux systems since some kernel interfaces (like kvm) are needed by the vm. Because of this performance can vary in kernel versions (newer will likely perform better).

# Setup docker container

The easiest way to setup a windows vm is by using docker compose. Just create a `docker-compose.yml` with following content:

```yaml
name: "winapps"

volumes:
  data:

services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "win11"
      RAM_SIZE: "8G"
      CPU_CORES: "4"
    privileged:true
    ports:
      - 8006:8006
      - 3389:3389/tcp
      - 3389:3389/udp
    stop_grace_period: 2m
    restart: on-failure
    volumes:
      - data:/storage
```

Now you can tune the ram/usage by changing RAM_SIZE/CPU_CORES. You can also specify the windows versions you want to use.

Note: Older versions than Windows 10 are not officially supported. However they might still work with some additional tuning.