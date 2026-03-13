#!/bin/bash
set -e

# ==============================================================================
# Ansible Setup Script for AWS EC2 (Ubuntu)
# Automates Master and Node configuration based on user instructions.
# ==============================================================================

# Variables
USER_NAME="devops"
USER_PASS="devops"

echo "=========================================="
echo " Ansible Setup Tool"
echo "=========================================="
echo "Run this script on the Master and all Nodes."
echo "------------------------------------------"
echo "1) Configure this machine as MASTER"
echo "2) Configure this machine as a NODE"
echo "3) Exit"
echo "=========================================="
read -p "Enter your choice (1-3): " ROLE

if [ "$ROLE" == "3" ]; then exit 0; fi

# ------------------------------------------------------------------------------
# Function: Common Configuration (Run on both Master and Nodes)
# ------------------------------------------------------------------------------
configure_common() {
    echo "--- Configuring User and SSH ---"
    
    # 1. Create devops user
    if id "$USER_NAME" &>/dev/null; then
        echo "User $USER_NAME already exists."
    else
        echo "Creating user $USER_NAME..."
        sudo useradd -m -s /bin/bash "$USER_NAME"
        echo "$USER_NAME:$USER_PASS" | sudo chpasswd
    fi

    # 2. Configure Sudoers
    echo "Configuring sudoers for $USER_NAME..."
    echo "$USER_NAME ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USER_NAME" > /dev/null
    sudo chmod 440 "/etc/sudoers.d/$USER_NAME"

    # 3. Configure SSHD
    echo "Updating SSH configuration..."
    sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    # 4. Handle Ubuntu 24.04 specific cloud-init overrides
    CLOUD_CFG="/etc/ssh/sshd_config.d/60-cloudimg-settings.conf"
    if [ -f "$CLOUD_CFG" ]; then
        echo "Updating cloud-init SSH settings..."
        sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' "$CLOUD_CFG"
    fi

    sudo systemctl restart ssh
    echo "Common configuration complete."
}

# ------------------------------------------------------------------------------
# Role: Master
# ------------------------------------------------------------------------------
if [ "$ROLE" == "1" ]; then
    # Set Hostname
    echo "Setting hostname to Ansiblemastermachine..."
    sudo hostnamectl set-hostname Ansiblemastermachine
    
    # Common Config
    configure_common

    # Install Ansible
    echo "Installing Ansible..."
    sudo apt update
    sudo apt install -y software-properties-common
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt install -y ansible

    # Configure Hosts File
    echo "------------------------------------------"
    read -p "How many nodes do you have? " NODE_COUNT
    
    HOSTS_FILE="/etc/ansible/hosts"
    echo "[ansiblegroup]" | sudo tee "$HOSTS_FILE" > /dev/null
    
    declare -a NODE_IPS
    for ((i=1; i<=NODE_COUNT; i++)); do
        read -p "Enter Private IP for Node $i: " IP
        NODE_IPS+=($IP)
        echo "$IP" | sudo tee -a "$HOSTS_FILE" > /dev/null
    done

    # Generate SSH Key for devops user
    echo "Generating SSH keys for $USER_NAME..."
    sudo -u "$USER_NAME" ssh-keygen -t rsa -N "" -f "/home/$USER_NAME/.ssh/id_rsa" <<< n || true

    # Trust Relationship
    echo "Establishing trust relationship with nodes..."
    echo "Note: You will be asked for the password '$USER_PASS' for each node."
    
    # Attempt to install sshpass to automate password entry if possible
    sudo apt install -y sshpass &>/dev/null || true

    for IP in "${NODE_IPS[@]}"; do
        echo "Connecting to $IP..."
        if command -v sshpass &>/dev/null; then
            sudo -u "$USER_NAME" sshpass -p "$USER_PASS" ssh-copy-id -o StrictHostKeyChecking=no "$USER_NAME@$IP"
        else
            sudo -u "$USER_NAME" ssh-copy-id -o StrictHostKeyChecking=no "$USER_NAME@$IP"
        fi
    done

    echo "=========================================="
    echo " MASTER SETUP COMPLETE!"
    echo " Ansible Version: $(ansible --version | head -n 1)"
    echo " You can now test with: sudo -u $USER_NAME ansible all -m ping"
    echo "=========================================="

# ------------------------------------------------------------------------------
# Role: Node
# ------------------------------------------------------------------------------
elif [ "$ROLE" == "2" ]; then
    configure_common
    echo "=========================================="
    echo " NODE SETUP COMPLETE!"
    echo " This machine is ready to be controlled by the Master."
    echo "=========================================="
fi
