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
