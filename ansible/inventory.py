#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import json
import logging
import argparse
import subprocess

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

TERRAFORM_OUTPUT_TEMPLATE = r"(?P<server_name>[a-z_]+) *= *(?P<server_ip>.+) *"

terraform_output_vars = {
    "app_external_ip": "appserver", 
    "db_external_ip": "dbserver"
}

hosts = {
    "appserver": None, 
    "dbserver": None
}
groups = {
    "app": ["appserver"], 
    "db": ["dbserver"]
}

inventory_dict = {
    "all": {
        "children": []
    },
    "_meta": {
        "hostvars": {}
    }
}

# TODO: сделать обработку входных параметров --list --host
# разбираем аргументы --list --host
# parser = argparse.ArgumentParser("inventory.py")
# parser.add_argument('--list', help="return a list of hosts and groups in JSON format")
# parser.add_argument('--host', help="return a host vars in JSON format")
# args = parser.parse_args()

# получаем выходные переменные через terraform output
tf_path = BASE_DIR + "/../terraform"
command = 'cd ' + tf_path + ' && terraform output -state=./terraform.tfstate.test_for_ansible'
result = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)


# парсим выходные параметры (имя сервера и его ip) и пишем интересующие нас в hosts
for m in re.finditer(TERRAFORM_OUTPUT_TEMPLATE, result):
    if (m.group('server_name') in terraform_output_vars):
        hosts[terraform_output_vars[m.group('server_name')]] = m.group('server_ip')

# формируем структуру групп и хостов
for group_name, group_hosts in groups.items():
    inventory_dict["all"]["children"].append(group_name)
    for host in group_hosts:
        inventory_dict[group_name] = {"hosts": group_hosts} 
for host_name, host_ip in hosts.items():
    inventory_dict["_meta"]["hostvars"][host_name] = {
        "ansible_host" : host_ip
    }

print(json.dumps(inventory_dict, indent=4))
