#!/bin/bash
# Remote server setup

useradd -m -d /home/willhay -s /bin/zsh willhay
read -sp "Set passwd for willhay: " PASSWD
chpasswd willhay:$PASSWD --stdin

# Set up ssh
mkdir /home/willhay/.ssh
touch /home/willhay/.ssh/authorized_keys
chown -R willhay:willhay /home/willhay/.ssh
chmod 700 /home/willhay/.ssh
chmod 600 /home/willhay/.ssh/authorized_keys

# Make superuser
usermod -a -G sudo willhay

