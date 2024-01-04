#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
echo 'ec25678!' | passwd --stdin ec2-user
yum update -y
yum install -y httpd