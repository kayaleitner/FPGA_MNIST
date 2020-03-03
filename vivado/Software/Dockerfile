# Custom Dockerfile for ARM cross compile

# Download base image dockcross/linux-armv7a
FROM dockcross/linux-armv7a

LABEL AUTHOR="Benjamin KULNIK"

ENV key=value

RUN \
    sudo apt-get update && \
    sudo apt-get upgrade && \
    sudo apt-get install -y python3.6
RUN sudo python3.6 -m pip install
RUN sudo pip3 install numpy
