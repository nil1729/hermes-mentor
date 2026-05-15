FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    ripgrep \
    ffmpeg \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

RUN /root/.local/bin/uv pip install boto3 --python /usr/local/lib/hermes-agent/venv/bin/python

# Install agent-browser + Chromium (amd64 has Chrome for Testing builds)
RUN npm install -g agent-browser && agent-browser install --with-deps

ENV PATH="/root/.local/bin:${PATH}"
ENV TZ=Asia/Kolkata

WORKDIR /root

# Config goes to a staging dir (volume mounts over /root/.hermes)
COPY config.yaml /root/.hermes-config/config.yaml
COPY SOUL.md /root/.hermes-config/SOUL.md
COPY MEMORY.md /root/.hermes-config/MEMORY.md
COPY entrypoint.sh /root/entrypoint.sh

CMD ["/root/entrypoint.sh"]
