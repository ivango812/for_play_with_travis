#!/bin/bash

sudo cp /tmp/mongod.conf /etc/mongod.conf
sudo systemctl restart mongod
