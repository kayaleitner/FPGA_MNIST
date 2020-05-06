# How To: Docker

[Docker](https://www.docker.com/) is an app that can be used to create a local development environment in form of a virutal machiner (or a container, what ever). So by using docker it is not needed to install development tools directly on the host machine but instead they can be installed inside a container or even more conviently, a pre-configured docker container from [docker-hub](https://hub.docker.com/) can be used.

In particular interest for this project are the `ghdl` docker images, e.g. the GHDL Extensions image [ghdl/ext](https://hub.docker.com/r/ghdl/ext). Here important tools like VUnit, GtkWave, ghdl-language-server and of course ghdl are preinstalled and ready to use.

## Basic Commands

To build the image use the command

```shell script
docker build -t eggnet/vhdl path/to/dockerfile
```

All commands should be run from a terminal:

```shell script
docker run --rm -it -v $(pwd):/vivado_src ghdl/ext:latest /bin/bash
```

This command does the following

| Command                 | Description                                                                                           |
| ----------------------- | ----------------------------------------------------------------------------------------------------- |
| `--rm`                  | Tells docker to delete the contasiner when it is now longer in use                                    |
| `-it`                   | `-i` stands for interactive, so commands are constantly read from stdin                               |
| `-it`                   | `-t` stands for tty, this will spawn some sort of terminal                                            |
| `-v $(pwd):/vivado_src` | this mounts the currend directory (pwd) from the host to the folder `/vivado_src` in the container    |
| `/bin/bash`             | This is the command that will be exectuted                                                            |
| `docker run`            | the default docker run command                                                                        |
| `ghdl/ext:latest`       | Tells docker to use this image as a basis, will be automatically fetched if it is not stored locally. |

## Docker Integration with VS Code

Docker can be integrated with VS Code and there is also a GHDL Langauge Server Plugin.
