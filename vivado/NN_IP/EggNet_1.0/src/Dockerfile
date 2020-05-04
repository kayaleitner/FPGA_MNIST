# For more information, please refer to https://aka.ms/vscode-docker-python
FROM ghdl/ext:latest

LABEL project="EggNetHdl"
LABEL author="Benjamin Kulnik"

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE 1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED 1

# Install pip requirements
ADD requirements.txt .
RUN python -m pip install -r requirements.txt

WORKDIR /vivado_src
ADD . /vivado_src

# Switching to a non-root user, please refer to https://aka.ms/vscode-docker-python-user-rights
RUN useradd appuser && chown -R appuser /vivado_src
USER appuser

# Expose ports so the debugger can connect
EXPOSE 80/tcp
EXPOSE 80/udp


# During debugging, this entry point will be overridden. For more information, please refer to https://aka.ms/vscode-docker-python-debug
CMD ["python", "run.py"]
