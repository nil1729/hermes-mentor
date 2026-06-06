FROM node:24-slim AS node-base

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Copy Node.js 24 from official image (avoids SSL issues with external downloads)
COPY --from=node-base /usr/local/bin/node /usr/local/bin/node
COPY --from=node-base /usr/local/include/node /usr/local/include/node
COPY --from=node-base /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    ffmpeg \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

RUN /root/.local/bin/uv pip install boto3 --python /usr/local/lib/hermes-agent/venv/bin/python

ENV PATH="/root/.local/bin:/usr/local/bin:/usr/lib/node_modules/.bin:${PATH}"

# Install agent-browser + Chromium
RUN npm install -g agent-browser \
    && npx --yes agent-browser install --with-deps
ENV TZ=Asia/Kolkata

WORKDIR /root

# Config goes to a staging dir (volume mounts over /root/.hermes)
COPY config.yaml /root/.hermes-config/config.yaml
COPY SOUL.md /root/.hermes-config/SOUL.md
COPY MEMORY.md /root/.hermes-config/MEMORY.md
COPY entrypoint.sh /root/entrypoint.sh

CMD ["/root/entrypoint.sh"]
