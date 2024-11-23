#!/bin/bash

# This will reboot all the servers in the kubernetes cluster!
ansible-playbook reboot.yml -i ~/inventory/hosts.ini
