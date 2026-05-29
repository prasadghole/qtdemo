FROM ubuntu:noble
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install foundational tools (All packages explicitly on one line)
RUN apt-get update && apt-get install -y make ninja-build build-essential gcc-aarch64-linux-gnu g++-aarch64-linux-gnu cmake git pkg-config && rm -rf /var/lib/apt/lists/*

# 2. Configure Multiarch for ARM64 (Ubuntu Ports)
RUN dpkg --add-architecture arm64

# 3. Rewrite the sources configuration for dual architectures
RUN echo "\
Types: deb\n\
URIs: http://archive.ubuntu.com/ubuntu/ http://security.ubuntu.com/ubuntu/\n\
Suites: noble noble-updates noble-backports noble-security\n\
Components: main universe restricted multiverse\n\
Architectures: amd64\n\
\n\
Types: deb\n\
URIs: http://ports.ubuntu.com/ubuntu-ports/\n\
Suites: noble noble-updates noble-backports noble-security\n\
Components: main universe restricted multiverse\n\
Architectures: arm64\n\
" > /etc/apt/sources.list.d/ubuntu.sources

# 4. Install both native and cross-compiled Qt5 dependencies (Single line)
RUN apt-get update && apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools qtbase5-dev:arm64 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace