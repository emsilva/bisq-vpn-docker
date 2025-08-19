# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

# Install dependencies
RUN apt-get update && apt-get install -y \
    # Desktop environment
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    # VNC server
    tigervnc-standalone-server \
    tigervnc-common \
    # noVNC for web access
    novnc \
    websockify \
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

# Copy custom noVNC configuration
COPY config/novnc-index.html /usr/share/novnc/index.html

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

# VNC configuration
RUN echo "bisqvnc" | vncpasswd -f > /home/bisq/.vnc/passwd && \
    chmod 600 /home/bisq/.vnc/passwd

# Copy and set up xstartup script
COPY config/xstartup.sh /home/bisq/.vnc/xstartup
RUN chmod +x /home/bisq/.vnc/xstartup

# Copy configuration files and scripts
COPY config/monitor-resize.sh /home/bisq/monitor-resize.sh
COPY config/start-bisq.sh /home/bisq/start-bisq.sh
COPY config/start-vnc.sh /home/bisq/start-vnc.sh
COPY config/disable-screensaver.sh /home/bisq/disable-screensaver.sh
RUN chmod +x /home/bisq/monitor-resize.sh /home/bisq/start-bisq.sh /home/bisq/start-vnc.sh /home/bisq/disable-screensaver.sh

# Copy s6-overlay configuration
COPY config/s6-overlay/ /etc/s6-overlay/
COPY config/cont-init.d/ /etc/cont-init.d/

# Copy XFCE configuration files
RUN mkdir -p /home/bisq/.config/xfce4/xfconf/xfce-perchannel-xml
COPY config/xfce4-screensaver.xml /home/bisq/.config/xfce4/xfconf/xfce-perchannel-xml/
COPY config/xfce4-power-manager.xml /home/bisq/.config/xfce4/xfconf/xfce-perchannel-xml/

# Prevent xfce4-screensaver from starting
RUN /home/bisq/disable-screensaver.sh

# Fix permissions
RUN chown -R bisq:bisq /home/bisq

# Expose ports (these will be accessed through gluetun network)
EXPOSE 5901 6080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD netstat -tuln | grep 5901 || exit 1

# Use s6-overlay as init system
ENTRYPOINT ["/init"]