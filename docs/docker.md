# Docker

## Why docker?

While working with virsh is completely fine for winapps you have to setup and optimise you vm manually. Docker on the other hand setups most of the stuff automatically and makes the vm highly portable between linux distros.

# Requirements

Since docker manages the dependencies of the container automatically you only need to install docker or podman itself. (Podman is recommended because of the faster container startup times)

Note: This will only work on linux systems since some kernel interfaces (like kvm) are needed by the vm. Because of this performance can vary in kernel versions (newer will likely perform better).

# Setup docker container