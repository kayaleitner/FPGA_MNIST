# Custom Dockerfile for ARM cross compile

# Download base image dockcross/linux-armv7a
# FROM dockcross/linux-armv7a
FROM arm32v7/ubuntu:trusty

LABEL AUTHOR="Benjamin Kulnik"
LABEL MAINTAINER="Benjamin Kulnik <benjamin.kulnik@student.tuwien.ac.at>"

ARG DEBIAN_FRONTEND="noninteractive"


# set the variables as per $(pyenv init -)
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    PATH="/opt/pyenv/shims:/opt/pyenv/bin:$PATH" \
    PYENV_ROOT="/opt/pyenv" \
    PYENV_SHELL="bash"


# Upgrade System
RUN apt-get update  && \
    apt-get upgrade -y 

# Install SWIG Dependencies
RUN apt-get install -y build-essential libpcre3-dev

# Install all PyEnv Dependencies
RUN apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    zlib1g-dev \
    libbz2-dev \
    libffi-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    # libssl1.0-dev \ 
    liblzma-dev \
    libssl-dev \
    llvm \
    make \
    netbase \
    pkg-config \
    tk-dev \
    wget \
    xz-utils \
    cmake \
    && apt-get autoremove && apt-get autoclean  \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD pysetup/requirements.txt /
ADD pysetup/python-versions.txt /


# The CC, CXX flags and so on must be removed to compile python
RUN unset CC && unset CXX && unset CPP && unset LD && unset AR && unset AS
ENV CC=gcc \
    CPP=cpp \
    CXX=g++ \
    LD=ld \
    AR=ar \
    AS=as
     

# Create the pyenv versions
RUN git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT \
    && for version in `cat /python-versions.txt`; do pyenv install $version; done \
    && pyenv global `cat /python-versions.txt` 
    #&& find $PYENV_ROOT/versions -type d '(' -name '__pycache__' -o -name 'test' -o -name 'tests' ')' -exec rm -rf '{}' + \
    #&& find $PYENV_ROOT/versions -type f '(' -name '*.pyo' -o -name '*.exe' ')' -exec rm -f '{}' + \
    #&& rm -rf /tmp/*

# Install all requirements
RUN pip install --no-cache-dir -r /requirements.txt \
    && find $PYENV_ROOT/versions -type d '(' -name '__pycache__' -o -name 'test' -o -name 'tests' ')' -exec rm -rf '{}' + \
    && find $PYENV_ROOT/versions -type f '(' -name '*.pyo' -o -name '*.exe' ')' -exec rm -f '{}' + \
    && rm -rf /tmp/*

# Install SWIG
RUN mkdir swig && \
    cd swig && \
    wget http://prdownloads.sourceforge.net/swig/swig-4.0.1.tar.gz && \
    tar -xf swig-4.0.1.tar.gz && \
    cd swig-4.0.1 && \
    ./configure && \
    make && \
    sudo make install && \
    make clean

# RESTORE ENVIRONMENT VARS
ENV AS=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-as \
    AR=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ar \
    CC=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-gcc \
    CPP=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-cpp \
    CXX=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-g++ \
    LD=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-ld \
    FC=${CROSS_ROOT}/bin/${CROSS_TRIPLE}-gfortran