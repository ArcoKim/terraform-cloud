#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
echo 'ec25678!' | passwd --stdin ec2-user

yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
aws s3 cp s3://skills-arco06/web/v1.tar .
tar -xvf v1.tar -C /var/www/html/
mv /var/www/html/v1/* /var/www/html
rm -rf /var/www/html/v1