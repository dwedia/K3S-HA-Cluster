#!/bin/bash

# Deploy the cluster to the nodes defined in hosts.ini
ansible-playbook site.yml -i ~/inventory/hosts.ini

# Create the ~/.kube/ folder
mkdir -p ~/.kube

# Copy kubeconfig file from k3s-ansible folder and place it in ~/.kube/config
cp ~/k3s-ansible:/kubeconfig ~/.kube/config

