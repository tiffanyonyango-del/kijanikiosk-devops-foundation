#!/bin/bash
set -e

echo "Applying Terraform..."

cd ~/Friday-Multipass
terraform apply -auto-approve

echo "Generating inventory..."

terraform output -raw api_ip > /tmp/api_ip
terraform output -raw payments_ip > /tmp/payments_ip
terraform output -raw logs_ip > /tmp/logs_ip

cat > ~/ansible/inventory.ini <<EOF
[api]
api ansible_host=$(cat /tmp/api_ip)

[payments]
payments ansible_host=$(cat /tmp/payments_ip)

[logs]
logs ansible_host=$(cat /tmp/logs_ip)

[all:vars]
ansible_user=ubuntu
EOF

echo "Running Ansible..."

cd ~/ansible
ansible-playbook -i inventory.ini playbook.yml

echo "Pipeline completed successfully."
