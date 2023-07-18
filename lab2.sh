#!/bin/bash

# Set the hostname
echo "Setting the hostname..."
sudo hostnamectl set-hostname autosrv

# Configure the network
echo "Configuring the network..."
cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    ens34:
      dhcp4: no
      addresses: [192.168.16.21/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOF


# Apply network configuration
echo "Applying network configuration..."
sudo netplan apply

# Install required software
echo "Installing SSH server..."
sudo apt-get update
sudo apt-get install -y openssh-server

# Configure SSH server
echo "Configuring SSH server..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Install Apache web server
echo "Installing Apache web server..."
sudo apt-get install -y apache2

# Install Squid web proxy
echo "Installing Squid web proxy..."
sudo apt-get install -y squid

# Configure Apache to listen on ports 80 and 443
echo "Configuring Apache to listen on ports 80 and 443..."
echo "Listen 80" | sudo tee /etc/apache2/ports.conf > /dev/null
echo "Listen 443" | sudo tee -a /etc/apache2/ports.conf > /dev/null

# Configure Squid to listen on port 3128
echo "Configuring Squid to listen on port 3128..."
echo "http_port 3128" | sudo tee /etc/squid/squid.conf > /dev/null

# Restart services
echo "Restarting services..."
sudo systemctl restart apache2
sudo systemctl restart squid

# Configure the firewall with UFW
echo "Configuring the firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'
sudo ufw allow 3128/tcp
sudo ufw --force enable

# Create user accounts
echo "Creating user accounts..."
usernames=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for username in "${usernames[@]}"
do
  sudo useradd -m "$username"
done

# Generate and add SSH keys for each user
echo "Generating and adding SSH keys for each user..."
for username in "${usernames[@]}"
do
  sudo -H -u "$username" bash -c "ssh-keygen -t rsa -b 4096 -f /home/$username/.ssh/id_rsa -q -N ''"
  sudo -H -u "$username" bash -c "ssh-keygen -t ed25519 -f /home/$username/.ssh/id_ed25519 -q -N ''"
  sudo -H -u "$username" bash -c "cat /home/$username/.ssh/id_rsa.pub >> /home/$username/.ssh/authorized_keys"
  sudo -H -u "$username" bash -c "cat /home/$username/.ssh/id_ed25519.pub >> /home/$username/.ssh/authorized_keys"
  sudo chown "$username:$username" "/home/$username/.ssh/authorized_keys"
done

# Set shell to bash for all users
echo "Setting shell to bash for all users..."
for username in "${usernames[@]}"
do
  sudo usermod --shell /bin/bash "$username"
done

# Grant sudo access to dennis
echo "Granting sudo access to dennis..."
sudo usermod -aG sudo dennis

# Add additional public key for dennis
echo "Adding additional public key for dennis..."
sudo sh -c 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/dennis/.ssh/authorized_keys'

echo "Script execution completed."
