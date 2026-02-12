# docker build -t cellranger:10.0.0 .
# Use a clean Ubuntu base
FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies (Cell Ranger needs these to run its internal tools)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    bzip2 \
    ca-certificates \
    libncursesw5 \
    libncurses5 \
    locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set locale (required for some Cell Ranger sub-tools)
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create a directory for the software
WORKDIR /opt

# Copy the pre-downloaded tarball from your host to the container
# Note: You must have cellranger-10.0.0.tar.gz in the same folder as this Dockerfile
COPY cellranger-10.0.0.tar.gz /opt/

# Extract and remove the tarball to save space
RUN tar -xzvf cellranger-10.0.0.tar.gz && \
    rm cellranger-10.0.0.tar.gz

# Set the PATH
ENV PATH="/opt/cellranger-10.0.0:${PATH}"

# Final check
RUN cellranger --version

# Default command
CMD ["cellranger"]