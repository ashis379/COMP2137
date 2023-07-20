#!/bin/bash

#For target1-mgmt (172.16.1.10)

# Defining the target machine details firstly
target1_mgmt="remoteadmin@target1-mgmt"

# Function to run commands on a remote machine using SSH
function run_ssh_command() {
    ssh_command="$1"
    ssh "$2" "$ssh_command"
}

# Task 1: Modify target1-mgmt (172.16.1.10)
target1_hostname="loghost"
target1_new_ip="192.168.16.3"


# Changing the system hostname and ip address
run_ssh_command "sudo hostnamectl set-hostname $target1_hostname" "$target1_mgmt"
run_ssh_command "sudo ip addr add $target1_new_ip/24 dev eth1" "$target1_mgmt"

# Adding a machine named 'webhost' to /etc/hosts file with host number 4 on the LAN
run_ssh_command "echo '192.168.16.4 webhost' | sudo tee -a /etc/hosts" "$target1_mgmt"

# Installing ufw if necessary
run_ssh_command "sudo apt-get update && sudo apt-get install -y ufw" "$target1_mgmt"

# Allowing connections to port 514/udp from the mgmt network
run_ssh_command "sudo ufw allow from 172.16.1.0/24 to any port 514 proto udp" "$target1_mgmt"

# Configuring rsyslog to listen for UDP connections
run_ssh_command "sudo sed -i 's/#module(load=\"imudp\")/module(load=\"imudp\")/' /etc/rsyslog.conf" "$target1_mgmt"
run_ssh_command "sudo sed -i 's/#input(type=\"imudp\" port=\"514\")/input(type=\"imudp\" port=\"514\")/' /etc/rsyslog.conf" "$target1_mgmt"

# Restarting the rsyslog service
run_ssh_command "sudo systemctl restart rsyslog" "$target1_mgmt"



# For target2-mgmt (172.16.1.11)

# Defining the target machine details
target2_mgmt="remoteadmin@target2-mgmt"

# Function to run commands on a remote machine using SSH
function run_ssh_command() {
    ssh_command="$1"
    ssh "$2" "$ssh_command"
}

# Task 1: Modifying target2-mgmt (172.16.1.11)
# Changing the system hostname to "webhost"
target2_hostname="webhost"
run_ssh_command "sudo hostnamectl set-hostname $target2_hostname" "$target2_mgmt"

# Changing the IP address of target2-mgmt (eth1 interface) to "192.168.16.4"
target2_new_ip="192.168.16.4"
run_ssh_command "sudo ip addr add $target2_new_ip/24 dev eth1" "$target2_mgmt"

# Adding a machine named 'loghost' to /etc/hosts file with host number 3 on the LAN
run_ssh_command "echo '192.168.16.3 loghost' | sudo tee -a /etc/hosts" "$target2_mgmt"

# Installing ufw if necessary and allowing connections to port 80/tcp from anywhere
run_ssh_command "sudo apt-get update && sudo apt-get install -y ufw" "$target2_mgmt"
run_ssh_command "sudo ufw allow 80/tcp" "$target2_mgmt"

# Installing apache2 in its default configuration
run_ssh_command "sudo apt-get install -y apache2" "$target2_mgmt"

# Configuring rsyslog on webhost to send logs to loghost
run_ssh_command "echo '*.* @loghost' | sudo tee -a /etc/rsyslog.conf" "$target2_mgmt"
run_ssh_command "sudo systemctl restart rsyslog" "$target2_mgmt"

