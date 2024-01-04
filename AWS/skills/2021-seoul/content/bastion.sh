#!/bin/bash
sed -i 's/#Port 22/Port 37722/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
echo 'ec21234!' | passwd --stdin ec2-user