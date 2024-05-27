# Docker

## Why docker?

While working with `virsh` is completely fine for winapps, you have to set up and optimize you vm manually. Docker on the other hand sets up most of the stuff automatically and also makes the VM highly portable between Linux distros.

# Requirements

Since Docker manages the dependencies of the container automatically you only need to install Docker itself.

You can try using Podman too because of their faster container startup times, but note that Podman and Docker are not always fully interchangeable. In case you want to follow this guide using podman, you will have to install the `docker` CLI to be able to run `docker compose` commands. You'll also have to enable the Podman socket. Refer to the podman docs for how to do that.

See:
- [Podman installation docs](https://podman.io/docs/installation)
- [Docker installation docs](https://docs.docker.com/engine/install)
- [Using `docker compose` with Podman](https://www.redhat.com/sysadmin/podman-docker-compose) (slightly outdated)

> [!NOTE]
> This will only work on Linux systems since some kernel interfaces (like KVM) are needed by the VM. Because of this performance can vary depending on kernel version (newer will likely perform better).

# Setup docker container

The easiest way to set up a Windows VM is by using docker compose. A compose file that looks like this is already shipped with winapps:

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

Now you can tune the ram/usage by changing `RAM_SIZE` & `CPU_CORES`. You can also specify the windows versions you want to use. You might also want to take a look at the [repo of the Docker image](https://github.com/dockur/windows) for further information.

This compose file uses Windows 11 by default. You can use Windows 10 by changing the `VERSION` to `tiny10`.

> [!NOTE]
> We use a stripped-down Windows installation by default. This is recommended, but you can still opt for stock windows by changing the version to one of the versions listed in the README of the images repository linked above.

> [!NOTE]
> Older versions than Windows 10 are not officially supported by us. However they might still work with some additional tuning.

You can now just run:
```shell
docker compose up -d
```
to run the VM in the background.

After this just open http://127.0.0.1:8006 in your web browser and wait for the Windows installation to finish.

> [!WARNING]
> Make sure to change the `RDP_IP` in your winapps config to `127.0.0.1`.

Now you should be ready to go and try to connect to your VM with winapps.

For stopping the VM just use:
```shell
docker compose stop
```

For starting again afterwards use:
```shell
docker compose start
```

(All compose commands have to be run from the directory where the `compose.yaml` is located.)
