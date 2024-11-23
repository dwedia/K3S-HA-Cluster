#!/bin/bash

# This will completely reset the Kubernetes cluster, removing all nodes!
ansible-playbook ./reset.yml -i ~/inventory/hosts.ini
