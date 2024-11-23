FROM docker.io/ubuntu:latest

MAINTAINER Dwedia

# update apt repository
RUN apt update

# Upgrade packages
RUN apt upgrade -y

# Install packages
RUN apt install -y vim ansible git rsync apt-transport-https ca-certificates curl gnupg

# create /etc/apt/keyrings folder
RUN mkdir -p /etc/apt/keyrings

#Install kubernetes repo gpg key
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
RUN chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring

# Add kubernetes Repo
RUN echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
RUN chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

# Update apt repo and install kubectl
RUN apt update
RUN apt install -y kubectl

# Set workdir
WORKDIR /root

# clone k3s-ansible
RUN git clone https://github.com/techno-tim/k3s-ansible /root/k3s-ansible

# Copy ansible.cfg file in to container
COPY files/* /root/k3s-ansible/

# Set custom stop signal (if needed)
STOPSIGNAL SIGKILL

# keep container alive
CMD sleep infinity

