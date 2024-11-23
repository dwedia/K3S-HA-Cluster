# K3S Controller Container

This project saw the light of day, after testing Techno Tims excellent K3S with etcd setup, using ansible.

I highly recommend you check it out here: [Fully Automated K3S etcd High Availability Install on technotim.live](https://technotim.live/posts/k3s-etcd-ansible/).

I am trying to learn how to use kubernetes, and after trying and failing to set up a full K8S cluster on my 3 Raspberry Pi 4 2GB's, i found Techno Tims fantastic video on setting up a K3S cluster with ansible (find it here: [Techno Tims video on Youtube](https://youtu.be/CbkEWcUZ7zM)), I decided to give it a go.

### My environment idea
A place to run commands against my K3S cluster. For this I thought I would use the ansiblecontroller i had already set up, since this server holds the keys for my ansible user.

3 Raspberry Pis (Pi4 2gb ram), That would be the Kubernetes cluster itself.
The 3 Pis are named kube01, kube02, and kube03, and I have created dns records for them. This could offcourse be done without creating DNS records, but I am lazy and do not want to type out IP addresses all the time.

### Getting the Pi's ready for ansible management.
I created my ansible user on the on the 3 Raspberry Pi 4's with the playbook I have for getting a computer ready for being managed by ansible. The playbook can be found [here on my github repository](https://github.com/dwedia/ansiblectrl/tree/main/playbooks/getReadyForAnsible).


### First attempt, on my ansible controller
I cloned [his git repo](https://github.com/techno-tim/k3s-ansible) on to my Almalinux ansible controller, tweaked the inventory file, and ansible.cfg file, and attempted to run the deployment command...and that failed spectacularly.

```bash
[ansiblewizard@wizardstower k3s-ansible]$ ansible-playbook ./site.yml -i ./inventory/hosts.ini 
[WARNING]: Collection community.general does not support Ansible version 2.14.14
[WARNING]: Collection ansible.posix does not support Ansible version 2.14.14

PLAY [Pre tasks] ******************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************
Saturday 23 November 2024  13:58:20 +0100 (0:00:00.020)       0:00:00.020 ***** 
ok: [kube03.dragonflight.dk]
ok: [kube01.dragonflight.dk]
ok: [kube02.dragonflight.dk]
...
OUTPUT OMITED TO WHERE IT WENT WRONG
...
TASK [k3s_server : Validating arguments against arg spec 'main' - Setup k3s servers] **********************************************************************
Saturday 23 November 2024  13:58:56 +0100 (0:00:01.890)       0:00:35.914 ***** 
[WARNING]: Collection ansible.utils does not support Ansible version 2.14.14
[WARNING]: Collection ansible.utils does not support Ansible version 2.14.14
[WARNING]: Collection ansible.utils does not support Ansible version 2.14.14
fatal: [kube03.dragonflight.dk]: FAILED! => 
  msg: Failed to import the required Python library (netaddr) on wizardstower's Python /usr/bin/python3. Please read the module documentation and install it in the appropriate location. If the required library is installed, but Ansible is using the wrong Python interpreter, please consult the documentation on ansible_python_interpreter
ok: [kube01.dragonflight.dk]
fatal: [kube02.dragonflight.dk]: FAILED! => 
  msg: Failed to import the required Python library (netaddr) on wizardstower's Python /usr/bin/python3. Please read the module documentation and install it in the appropriate location. If the required library is installed, but Ansible is using the wrong Python interpreter, please consult the documentation on ansible_python_interpreter
TASK [k3s_server : Copy vip manifest to first master] *****************************************************************************************************
Saturday 23 November 2024  13:59:02 +0100 (0:00:01.280)       0:00:41.384 ***** 
[WARNING]: Collection ansible.utils does not support Ansible version 2.14.14
An exception occurred during task execution. To see the full traceback, use -vvv. The error was: ansible.errors.AnsibleFilterError: Failed to import the required Python library (netaddr) on wizardstower's Python /usr/bin/python3. Please read the module documentation and install it in the appropriate location. If the required library is installed, but Ansible is using the wrong Python interpreter, please consult the documentation on ansible_python_interpreter
fatal: [kube01.dragonflight.dk]: FAILED! => changed=false 
  msg: 'AnsibleFilterError: Failed to import the required Python library (netaddr) on wizardstower''s Python /usr/bin/python3. Please read the module documentation and install it in the appropriate location. If the required library is installed, but Ansible is using the wrong Python interpreter, please consult the documentation on ansible_python_interpreter'

PLAY RECAP ************************************************************************************************************************************************
kube01.dragonflight.dk     : ok=34   changed=4    unreachable=0    failed=1    skipped=15   rescued=0    ignored=0   
kube02.dragonflight.dk     : ok=26   changed=2    unreachable=0    failed=1    skipped=14   rescued=0    ignored=0   
kube03.dragonflight.dk     : ok=26   changed=2    unreachable=0    failed=1    skipped=14   rescued=0    ignored=0   
```

I traced the error to the fact that the netaddr galaxy module did not function with ansible-core, despite it saying it should. I atleast was not able to make it work...

### Attempt nr 2, A new Alma it is.
After a bit of frustrated pacing in my office space, I decided to see if I could find a way to install the full ansible (or ansible-community, as it is called now) package.
I did not want to mess up my existing ansible controller, since it is the main ansible controller for my homelab

I decided to create a separate VM for this. Since I mainly live in the RHEL world (but I do not want to deal with RHELs subscriptions at home), I went with alma here as well... and that went about as well as the first attempt.  
Well worse actually, since I could not find a way to install ansible-community in the RHEL world (Im sure there is one, I just havent found it yet, and lets face it... the OS on this machine is not worth holding up the project over...).  
I decided to scrap this VM, and change lanes to ubuntu instead.

### 3rd time is the charm, now with more ubuntu...
I chose the latest ubuntu LTS (24.04.1), and off the the races I went.  
I installed the ansible package from the apt repos, since this holds both the ansible-core and ansible-community edition (which it doesnt in the RHEL world repos...), cloned Techno Tims git repo, changed the inventory file and the group_vars file (as he explains in his video). 
```bash
$ sudo apt install ansible

$ ansible-community --version
Ansible community version 9.2.0

$ git clone https://github.com/techno-tim/k3s-ansible
```

To be sure it ansible used the full community version, I made `ansible` an alias for `ansible-community`.
```bash
$ alias ansible="/usr/bin/ansible-community"
```

Once I was sure the correct ansible version was being used, I installed the ansible galaxy requirements, that Techno Tim outlines in the article on his website, and ran the ansible playbook to set up the K3S cluster, and this time i just worked!
```bash
$ ansible-galaxy install -r ./collections/requirements.yml
$ ansible-playbook ./site.yml -i ./inventory/hosts.ini
```

Since kubectl is needed to control the cluster, I installed it via the snap package (It is also possible to add the kubernetes repo to apt, and install the .deb package). I usually dislike snaps, but i wanted to test it out here.
```bash
$ sudo snap install kubectl --classic
```

Kubectl needs a config file in ~/.kube/ so it knows which servers to run against. We get this file from the first K3S cluster master (kube01 in our inventory file.).
I had a bit of trouble getting the file from kube01 since it lived on the root user. I solved this, by copying it to the ansibleusers homedir, and changed the owner of the file. I was then able to use scp to copy the file over to where I wanted it.
```bash
echo "--------------------------------------------------------"
echo "move file on node to ansibleuser home dir"

ssh -i ~/.ssh/ansiblectrlKey ansibleuser@kube01.dragonflight.dk sudo cp -r /root/.kube/config /home/ansibleuser/kubeconfig

ssh -i ~/.ssh/ansiblectrlKey ansibleuser@kube01.dragonflight.dk sudo chown ansibleuser:ansibleuser /home/ansibleuser/kubeconfig

echo "--------------------------------------------------------"
echo "scp file"

mkdir -p ~/.kube

scp -i ~/.ssh/ansiblectrlKey ansibleuser@kube01.dragonflight.dk:~/kubeconfig ~/.kube/config
```

Now with kubectl installed, and its config file in place, It was time to test out if commands against my small cluster worked (and it did... :) )
```bash
$ kubectl get nodes
NAME     STATUS   ROLES                       AGE    VERSION
kube01   Ready    control-plane,etcd,master   162m   v1.30.2+k3s2
kube02   Ready    control-plane,etcd,master   162m   v1.30.2+k3s2
kube03   Ready    control-plane,etcd,master   161m   v1.30.2+k3s2
```

Now, this solution worked, but was not very portable, or recreatable, and was way to large (requiring a full VM...). So I started to pace around my office again, to see if I could find a way to make my solution portable and recreatable (as I said, I am lazy and I did not want to do this all over again, if I decided to scrap this.)

### Now for the main event! Containers to the rescue!
After pacing around my office again for a while, petting the cats for a bit, I decided to see if I could take what I learned with the full Ubuntu VM, and apply it to a Ubuntu Container instead, since if successfull this would drastically reduce the size, and I would be able to make it portable (just share the container file and compose file with other people...).


#### Container file
First I needed to identify the steps needed, and convert those steps to a container file.

I would need to do the following:
  1. Update the main OS inside the container (apt update and apt upgrade).
  2. install the packages needed.
  3. Add the kubernetes repo GPG key, and the kubernetes repo.
  4. Install kubectl.
  5. clone the techno tim repo, since this project is based off his work.
  6. copy in the files I have changed (inventory files, deploy, reboot, and reset scripts)
  7. keep the container alive.

This resulted in the following container file, which creates a container image where the above steps are taken in to account.
```bash
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
```

This container file, copies the files in the files folder in the same folder as the container file.
In the files folder, I have placed the following 5 files:
```bash
$ ll files
.rw-r--r--@ 918 ramiraz 23 Nov 09:42 ansible.cfg
.rwxr-xr-x@ 290 ramiraz 23 Nov 17:33 deploy.sh
.rwxr-xr-x@ 190 ramiraz 23 Nov 17:32 getconfig.sh
.rwxr-xr-x@ 128 ramiraz 23 Nov 17:13 reboot.sh
.rwxr-xr-x@ 140 ramiraz 23 Nov 17:14 reset.sh
```

The ansible.cfg file, that I want to overwrite Techno Tim's ansible.cfg file if any is present in his repo.
Notable changes in my ansible.cfg file are
 - The default inventory path is now /root/inventory/hosts.ini (the inventory folder gets mounted from the host).
 - The remote_user is set to ansibleuser, since that is my ansible user.

The script files, are just easier ways of working with the cluster. They are as follows:

deploy.sh:
```bash
$ cat files/deploy.sh 
#!/bin/bash

# Deploy the cluster to the nodes defined in hosts.ini
ansible-playbook site.yml -i ~/inventory/hosts.ini

# Create the ~/.kube/ folder
mkdir -p ~/.kube

# Copy kubeconfig file from k3s-ansible folder and place it in ~/.kube/config
cp ~/k3s-ansible:/kubeconfig ~/.kube/config
```

reboot.sh:
```bash
#!/bin/bash

# This will reboot all the servers in the kubernetes cluster!
ansible-playbook reboot.yml -i ~/inventory/hosts.ini
```

reset.sh:
```bash
#!/bin/bash

# This will completely reset the Kubernetes cluster, removing all nodes!
ansible-playbook ./reset.yml -i ~/inventory/hosts.ini
```

getconfig.sh:
```bash
#!/usr/bin/env bash

# Grab the .kube/config file, and copy it to the ansibleusers home folder. This is to prevent permissions issues with scp
echo "--------------------------------------------------------"
echo "move file on node to ansibleuser home dir"

ssh -i ~/.ssh/ansiblectrlKey ansibleuser@kube01.dragonflight.dk sudo cp -r /root/.kube/config /home/ansibleuser/kubeconfig
ssh -i ~/.ssh/ansiblectrlKey ansibleuser@kube01.dragonflight.dk sudo chown ansibleuser:ansibleuser /home/ansibleuser/kubeconfig

# copy the .kube/config file from the ansibleusers home folder and place it in .kube/config in the container
echo "--------------------------------------------------------"
echo "scp file"

mkdir -p ~/.kube

scp -i ~/.ssh/ansiblectrlKey ansibleuser@kube01.dragonflight.dk:~/kubeconfig ~/.kube/config
```


#### Buidling the container
I was now able to build this container with podman build (I run this with podman, but I see no reason why it cannot work with docker...).
(to make building easier, I created a small script, that calls podman build)
```bash
$ cat build.sh 
podman build -f containerfile -t kubecontroller

$ ./build.sh 
STEP 1/17: FROM docker.io/ubuntu:latest
STEP 2/17: MAINTAINER Dwedia
--> 3b31c2827270
STEP 3/17: RUN apt update
...
OMITTED VERY LONG BUILD OUTPUT
...
STEP 16/17: STOPSIGNAL SIGKILL
--> 93d62c02bbe5
STEP 17/17: CMD sleep infinity
COMMIT kubecontroller
--> 3c0bb05f7a6f
Successfully tagged localhost/kubecontroller:latest
3c0bb05f7a6f1f1bf73832a85e6e09e1611c518610a178cfd22b5a9cc1e2cdf8
```

#### Compose file
With the container image built from the container file, I could now focus on creating a compose file, for bringing the container up and down.
The compose file needs to do the following:
  1. create a network for this to live in, segregated from other containers
  2. mount the volumes (folders) needed, from the host.

With this in mind, I created the following compose file:
```bash
---
networks:
  kubecontrol:
    external: false

services:
  kubecontroller:
    container_name: kubecontroller
    image: localhost/kubecontroller
    restart: unless-stopped
    volumes:
      - ./ssh:/root/.ssh:Z
      - ./inventory:/root/inventory:Z
      - ./servicesOnKube:/root/servicesOnKube:Z
    networks:
      - kubecontrol
```

#### Starting the container
Bringing the container up now, is as simple as running podman-compose up -d (or docker compose up -d).
When running it on podman, it creates a pod for it aswell. While it doesnt really do anything for this container, its nice to be aware of.
```bash
$ podman-compose up -d
614a512864df55244d0115e6a1f06e7b27453f910aba820321357b7c8f758c70
b2503a90e3a5713645bd6fcf1e1a9a163ac6f73cb5f357da194bbdbe8f9281bb
kubecontroller
```

With podman ps, we can see that our podman container is now running
```bash
$ podman ps
CONTAINER ID  IMAGE                            COMMAND               CREATED         STATUS         PORTS       NAMES
b2503a90e3a5  localhost/kubecontroller:latest  /bin/sh -c sleep ...  30 seconds ago  Up 30 seconds              kubecontroller
```

#### Entering the container
To enter the container, we can use the podman exec command. This drops us inside the containers root folder, as the root user.
```bash
$ podman exec -it kubecontroller bash
root@b2503a90e3a5:~# pwd
/root
root@b2503a90e3a5:~# ls -la
total 40
drwx------. 1 root root 4096 Nov 23 15:50 .
dr-xr-xr-x. 1 root root 4096 Nov 23 15:50 ..
-rw-r--r--. 1 root root 3106 Apr 22  2024 .bashrc
-rw-r--r--. 1 root root  161 Apr 22  2024 .profile
drwx------. 2 root root 4096 Nov 23 08:46 .ssh
drwxr-xr-x. 5 root root 4096 Nov 23 08:18 inventory
drwxr-xr-x. 1 root root 4096 Nov 23 15:39 k3s-ansible
drwxr-xr-x. 3 root root 4096 Nov 23 12:33 servicesOnKube
```

Inside the container, we have the 3 folders we mounted from our host, and the k3s-ansible folder, we cloned from Techno Tims github repo. 
My thinking with the 3 mounted folders is this:
  - inventory: the inventory files live here. Thus preventing the deletion when the container is brought down
  - servicesOnKube: Each service we want to run on our kubernetes cluster could have a folder here, where we put their deployment,yml and service.yml file.
  - .ssh: This is where ansible inside the container will look for the ssh key it needs to be able to communicate with our cluster. This way, we can prevent the .ssh file from living inside the container (and being shared...).

Inside the k3s-ansible folder, we have 5 files copied in to the container file, during build time.

  - ansible.cfg
  - deploy.sh
  - reboot.sh
  - reset.sh
  - getconfig.sh

What these scripts do, is detailed above in the container file section.

#### First run
The first time we run the container, we will need to deploy our cluster.
This is done with the deploy.sh script, inside the k3s-ansible folder. (This will take a while).
```bash
root@b2503a90e3a5:~/k3s-ansible# ./deploy.sh 

PLAY [Pre tasks] ******************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************
Saturday 23 November 2024  16:18:56 +0000 (0:00:00.006)       0:00:00.006 ***** 
ok: [kube02.dragonflight.dk]
ok: [kube03.dragonflight.dk]
ok: [kube01.dragonflight.dk]
...
OMITTED LONG ANSIBLE OUTPUT
...
PLAY RECAP ************************************************************************************************************************************************
kube01.dragonflight.dk     : ok=73   changed=19   unreachable=0    failed=0    skipped=20   rescued=0    ignored=0   
kube02.dragonflight.dk     : ok=58   changed=11   unreachable=0    failed=0    skipped=26   rescued=0    ignored=0   
kube03.dragonflight.dk     : ok=58   changed=11   unreachable=0    failed=0    skipped=26   rescued=0    ignored=0   

Saturday 23 November 2024  16:23:21 +0000 (0:00:00.620)       0:04:24.747 ***** 
=============================================================================== 
k3s_server : Verify that all nodes actually joined (check k3s-init.service if this fails) -------------------------------------------------------- 126.21s
k3s_server : Enable and check K3s service --------------------------------------------------------------------------------------------------------- 36.65s
k3s_server_post : Wait for MetalLB resources ------------------------------------------------------------------------------------------------------ 12.21s
k3s_server : Remove manifests and folders that are only needed for bootstrapping cluster so k3s doesn't auto apply on start ------------------------ 7.27s
download : Download k3s binary arm64 --------------------------------------------------------------------------------------------------------------- 6.32s
raspberrypi : Install iptables --------------------------------------------------------------------------------------------------------------------- 4.57s
k3s_server_post : Copy metallb CRs manifest to first master ---------------------------------------------------------------------------------------- 4.10s
raspberrypi : Test for raspberry pi /proc/device-tree/model ---------------------------------------------------------------------------------------- 4.06s
k3s_server : Copy config file to user home directory ----------------------------------------------------------------------------------------------- 3.95s
Gathering Facts ------------------------------------------------------------------------------------------------------------------------------------ 3.22s
k3s_server_post : Delete outdated metallb replicas ------------------------------------------------------------------------------------------------- 3.19s
k3s_server_post : Test metallb-system webhook-service endpoint ------------------------------------------------------------------------------------- 2.83s
k3s_server_post : Test metallb-system namespace ---------------------------------------------------------------------------------------------------- 2.71s
k3s_server : Kill the temporary service used for initialization ------------------------------------------------------------------------------------ 2.19s
k3s_server : Copy K3s service file ----------------------------------------------------------------------------------------------------------------- 2.17s
Gathering Facts ------------------------------------------------------------------------------------------------------------------------------------ 2.14s
Gathering Facts ------------------------------------------------------------------------------------------------------------------------------------ 2.11s
k3s_server_post : Test metallb-system resources for Layer 2 configuration -------------------------------------------------------------------------- 1.88s
k3s_server_post : Create manifests directory for temp configuration -------------------------------------------------------------------------------- 1.85s
Gathering Facts ------------------------------------------------------------------------------------------------------------------------------------ 1.79s
```

#### Subsequent runs, with a running cluster.
If the container has been deleted, (for instance, with podman-compose down), the .kube/config file witll not be present in the correct location. 
To remedy this, we can use the getconfig.sh script. It will grab the config file, from the first kube01 master, and place it in the ~/.kube folder.
```bash
root@5a04803254e6:~/k3s-ansible# ./getconfig.sh 
--------------------------------------------------------
move file on node to ansibleuser home dir
--------------------------------------------------------
scp file
kubeconfig                                                                                                               100% 2958     1.5MB/s   00:00    
```

#### Using kubectl
We can now interact with our kubernetes cluster with the kubectl command.
```bash
root@b2503a90e3a5:~# kubectl get nodes
NAME     STATUS   ROLES                       AGE   VERSION
kube01   Ready    control-plane,etcd,master   14m   v1.30.2+k3s2
kube02   Ready    control-plane,etcd,master   13m   v1.30.2+k3s2
kube03   Ready    control-plane,etcd,master   13m   v1.30.2+k3s2
```

### Thoughts for future improvement.

I would like to learn how to write the deployment and service files for services I would like to run.
For now I have just tested this setup with the example that Techno Tim has provided in his github repo.

I would like to find out how to get persistant storage configured on my nodes.
Perhaps This could be done with nfs mounts, that they all can access?

I want to dive deeper in to the ansible playbooks and roles provided by Techno Tim, so I get a better understanding of how to set this cluster up.
