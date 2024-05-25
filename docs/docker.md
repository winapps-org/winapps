# Docker

## Why docker?

While working with virsh is completely fine for winapps, however you have to setup and optimise you vm manually. Docker on the other hand setups most of the stuff automatically and also makes the vm highly portable between linux distros.

# Requirements

Since docker manages the dependencies of the container automatically you only need to install docker or podman itself. (Podman is recommended because of the faster container startup times. Note that podman and docker are interchangeable so no instructions will change depending on which one you use)

You might also want to take a look in the docs:
- [podman docs](https://docs.podman.io/)
- [docker docs](https://docs.docker.com/)

When using podman you want to make sure podman socket is enabled with:
```shell
sudo systemctl enable --now podman.socket
```

> [!NOTE]
> This will only work on linux systems since some kernel interfaces (like kvm) are needed by the vm. Because of this performance can vary in kernel versions (newer will likely perform better).

# Setup docker container

The easiest way to setup a windows vm is by using docker compose. Just create a `compose.yml` with following content:

```yaml
name: "winapps"

volumes:
  data:

services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "tiny11"
      RAM_SIZE: "4G"
      CPU_CORES: "4"
    privileged: true
    ports:
      - 8006:8006
      - 3389:3389/tcp
      - 3389:3389/udp
    stop_grace_period: 2m
    restart: on-failure
    volumes:
      - data:/storage
```

Now you can tune the ram/usage by changing RAM_SIZE/CPU_CORES. You can also specify the windows versions you want to use. You might also want to take a look at the [docker image repo](https://github.com/dockur/windows).

> [!NOTE]
> Older versions than Windows 10 are not officially supported. However they might still work with some additional tuning.

You can now just run:
```shell
docker compose up
```

After this just open http://127.0.0.1:8006 in your webbrowser and finish you windows installation as usual. 

Change the RDP_IP in your winapps config to localhost or "127.0.0.1".

RDP will be automatically enabled, however you still need to load the reg files into you vm.

Now you should be ready to go and try to connect to your vm with winapps.

For stopping the vm just use:
```shell 
docker compose stop
```

For starting again afterwards use:
```shell
docker compose start
```
