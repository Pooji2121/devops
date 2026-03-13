# Devops Automation Scripts

This repository contains robust bash scripts to automate the deployment and management of standard Devops tools (Jenkins, Tomcat, SonarQube, and PostgreSQL) on a fresh Linux server (e.g., Ubuntu on AWS EC2).

## Prerequisites
- A Linux server (Ubuntu 22.04+ recommended)
- **Minimum Specifications**: For SonarQube, your server MUST have at least **2GB RAM** (e.g., `t3.small`). An instance like `m7i-flex.large` (8GB RAM) is highly recommended.
- Sudo privileges

## 1. How to Install Services (`install_services.sh`)

This is the main installation manager. You can use it to pick and choose which tools you want to install.

### Step-by-Step Instructions
1. Clone this repository to your server:
   ```bash
   git clone https://github.com/SuhasLingam/devops.git
   cd devops
   ```
2. Make the scripts executable:
   ```bash
   chmod +x *.sh
   ```
3. Run the installer:
   ```bash
   ./install_services.sh
   ```
4. An interactive menu will appear. Type the number corresponding to the tool you want to install and press Enter.

> **Note on SonarQube**: If you choose Option 3 (SonarQube & PostgreSQL), ensure that the `sonarqube.sh` file is located in the exact same directory where you are running the command.

## 2. How to Manage the Services (`manage_services.sh`)

Once your tools are installed, you can easily stop, start, or check the status of all of them simultaneously using the management script.

### Step-by-Step Instructions
1. Make the management script executable:
   ```bash
   chmod +x manage_services.sh
   ```
2. Run the manager:
   ```bash
   ./manage_services.sh
   ```
3. Use the interactive menu to `Start all services`, `Stop all services`, or `Check status`.

---
## Tool Details & Ports

After installation and startup, access your tools at these default ports:
- **Jenkins**: `http://<your-server-ip>:8080`
- **Tomcat**: `http://<your-server-ip>:8085` *(Changed from default 8080 to prevent conflict with Jenkins)*
- **SonarQube**: `http://<your-server-ip>:9000` (Default Login: `admin` / `admin`)

## 3. How to Setup Ansible (`ansible_setup.sh`)

This script automates the Master-Node architecture for Ansible on AWS Ubuntu instances.

### Step-by-Step Instructions
1. **On the Node instances**:
   - Run `chmod +x ansible_setup.sh`
   - Run `./ansible_setup.sh` and choose **Option 2 (Node)**.
2. **On the Master instance**:
   - Run `chmod +x ansible_setup.sh`
   - Run `./ansible_setup.sh` and choose **Option 1 (Master)**.
   - Enter the number of nodes and their **Private IPs** when prompted.
   - The script will install Ansible, configure hosts, and establish trust with the nodes.
3. **Verify Connection**:
   - Switch to the devops user: `su - devops`
   - Test connectivity: `ansible all -m ping`

