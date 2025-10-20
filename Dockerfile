FROM node:24-alpine
LABEL org.opencontainers.image.authors="houthacker@pm.me"
WORKDIR /autotune
RUN apk add --no-cache jq git openssh sudo coreutils bash curl dcron
RUN git clone --branch v0.7.1 https://github.com/openaps/oref0.git /autotune/oref0
WORKDIR /autotune/oref0
RUN npm run global-install

WORKDIR /converter
COPY package*.json ./
RUN npm install

COPY . .
RUN npm install -g

# Create log directory for cron
RUN mkdir -p /var/log/autotune && \
    chmod 755 /var/log/autotune

# Copy entrypoint script
COPY bin/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
