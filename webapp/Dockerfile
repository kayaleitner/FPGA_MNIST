FROM arm32v7/ubuntu:trusty


# set the variables as per $(pyenv init -)
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    PATH="/opt/pyenv/shims:/opt/pyenv/bin:$PATH" \
    PYENV_ROOT="/opt/pyenv" \
    PYENV_SHELL="bash"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
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
    zlib1g-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN git clone https://github.com/pyenv/pyenv.git ${PYENV_ROOT}

RUN echo $HOME
RUN echo ${PYENV_ROOT}
RUN echo ${PATH}

# Install 3.6.10
RUN pyenv install 3.6.10
# Set the version to use it as global
RUN pyenv global 3.6.10

COPY deploy_requirements.txt /
RUN pip install -r deploy_requirements.txt