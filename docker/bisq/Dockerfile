# syntax=docker/dockerfile:1
# Pin to specific Ubuntu 22.04 LTS digest for reproducibility
FROM ubuntu:22.04@sha256:f9d633ff6640178c2d0525017174a688e2c1aef28f0a0130b26bd5554491f0da

# Image metadata following OCI standards
LABEL org.opencontainers.image.title="Bisq VPN Container" \
      org.opencontainers.image.description="Bisq decentralized Bitcoin exchange running through VPN with noVNC web interface" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.authors="Bisq VPN Container Project" \
      org.opencontainers.image.url="https://github.com/bisq-network/bisq" \
      org.opencontainers.image.documentation="https://github.com/emsilva/bisq-vpn-docker" \
      org.opencontainers.image.source="https://github.com/emsilva/bisq-vpn-docker" \
      org.opencontainers.image.vendor="Open Source" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.created="2025-01-19T00:00:00Z" \
      org.opencontainers.image.base.name="ubuntu:22.04" \
      maintainer="bisq-vpn-docker"

# Additional custom labels
LABEL bisq.version="${BISQ_VERSION:-1.9.21}" \
      s6.overlay.version="3.2.1.0" \
      vnc.password="bisqvnc" \
      vnc.port="5901" \
      novnc.port="6080" \
      container.type="desktop" \
      security.vpn="required"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

# Set shell to bash with pipefail option  
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Desktop environment
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    # VNC server
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    # noVNC for web access
    novnc \
    python3-websockify \
    # Java runtime for Bisq
    openjdk-11-jre \
    # Utilities
    wget \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    supervisor \
    sudo \
    xdg-utils \
    # Network tools for debugging
    net-tools \
    iputils-ping \
    dnsutils \
    # Window management for fullscreen
    wmctrl \
    # Clipboard synchronization
    autocutsel \
    # xz-utils for s6-overlay
    xz-utils \
    # aria2c for robust downloads
    aria2 \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install s6-overlay for better process management
ARG S6_OVERLAY_VERSION=3.2.1.0
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && rm /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && rm /tmp/s6-overlay-x86_64.tar.xz

# Create user for running Bisq with explicit UID/GID 1000
RUN groupadd -g 1000 bisq && \
    useradd -m -u 1000 -g 1000 -s /bin/bash bisq && \
    echo "bisq:bisq" | chpasswd && \
    usermod -aG sudo bisq && \
    echo "bisq ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Download and install Bisq (use build arg for version)
ARG BISQ_VERSION=1.9.21
ENV BISQ_VERSION=${BISQ_VERSION}

# Download Bisq using aria2c with BuildKit cache mount for persistence
RUN --mount=type=cache,target=/cache \
    echo "Downloading Bisq v${BISQ_VERSION} using aria2c..." && \
    aria2c \
        --dir=/cache \
        --out=Bisq-64bit-${BISQ_VERSION}.deb \
        --continue=true \
        --max-connection-per-server=16 \
        --split=16 \
        --min-split-size=1M \
        --max-tries=10 \
        --retry-wait=5 \
        --timeout=60 \
        --connect-timeout=30 \
        --summary-interval=10 \
        --download-result=hide \
        --console-log-level=warn \
        "https://github.com/bisq-network/bisq/releases/download/v${BISQ_VERSION}/Bisq-64bit-${BISQ_VERSION}.deb" && \
    echo "Downloaded $(ls -lh /cache/Bisq-64bit-${BISQ_VERSION}.deb)" && \
    echo "Installing Bisq package..." && \
    dpkg -i /cache/Bisq-64bit-${BISQ_VERSION}.deb && \
    echo "Verifying Bisq installation..." && \
    ls -la /opt/bisq/ && \
    test -f /opt/bisq/bin/Bisq && \
    echo "Bisq v${BISQ_VERSION} installation complete at /opt/bisq/bin/Bisq"

# Copy custom noVNC configuration and favicon
COPY config/novnc-index.html /usr/share/novnc/index.html
COPY config/bisq-favicon.ico /usr/share/novnc/bisq-favicon.ico
COPY config/bisq-favicon.png /usr/share/novnc/bisq-favicon.png

# Create directories with correct ownership
RUN mkdir -p /home/bisq/.vnc \
    /home/bisq/.config/xfce4 \
    /home/bisq/Desktop \
    /var/log/supervisor \
    /home/bisq/.local/share/Bisq && \
    chown -R bisq:bisq /home/bisq/.vnc \
    /home/bisq/.config \
    /home/bisq/Desktop \
    /home/bisq/.local \
    /var/log/supervisor \
    /var/run

# Copy configuration files and scripts
COPY config/xstartup.sh /home/bisq/.vnc/xstartup
COPY config/monitor-resize.sh /home/bisq/monitor-resize.sh
COPY config/start-bisq.sh /home/bisq/start-bisq.sh
COPY config/start-vnc.sh /home/bisq/start-vnc.sh
COPY config/disable-screensaver.sh /home/bisq/disable-screensaver.sh

# Set up VNC and script permissions
RUN echo "bisqvnc" | vncpasswd -f > /home/bisq/.vnc/passwd && \
    chmod 600 /home/bisq/.vnc/passwd && \
    chmod +x /home/bisq/.vnc/xstartup && \
    chmod +x /home/bisq/monitor-resize.sh /home/bisq/start-bisq.sh /home/bisq/start-vnc.sh /home/bisq/disable-screensaver.sh

# Copy s6-overlay configuration
COPY config/s6-overlay/ /etc/s6-overlay/
COPY config/cont-init.d/ /etc/cont-init.d/

# Copy XFCE configuration files
RUN mkdir -p /home/bisq/.config/xfce4/xfconf/xfce-perchannel-xml
COPY config/xfce4-screensaver.xml /home/bisq/.config/xfce4/xfconf/xfce-perchannel-xml/
COPY config/xfce4-power-manager.xml /home/bisq/.config/xfce4/xfconf/xfce-perchannel-xml/

# Final setup and permissions
RUN /home/bisq/disable-screensaver.sh && \
    chown -R bisq:bisq /home/bisq

# Expose ports (these will be accessed through gluetun network)
EXPOSE 5901 6080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD netstat -tuln | grep 5901 || exit 1

# Use s6-overlay as init system
# Note: Starting as root is intentional for s6-overlay process supervision
# Individual services run as non-root user 'bisq' via s6 configuration
ENTRYPOINT ["/init"]