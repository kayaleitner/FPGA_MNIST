# For more information, please refer to https://aka.ms/vscode-docker-python
# This is a modified version based on the GHDL docker image
FROM ghdl/ext:latest

LABEL project="EggNetHdl"
LABEL author="Benjamin Kulnik"

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE 1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED 1

# Install pip requirements
ADD requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt

WORKDIR /vivado_src
ADD . /vivado_src

# Switching to a non-root user, please refer to https://aka.ms/vscode-docker-python-user-rights
RUN useradd appuser && chown -R appuser /vivado_src
USER appuser

# Expose ports so the python debugger can attach
EXPOSE 5678/tcp
EXPOSE 5678/udp


# During debugging, this entry point will be overridden. For more information, please refer to https://aka.ms/vscode-docker-python-debug
CMD ["python", "run.py"]
