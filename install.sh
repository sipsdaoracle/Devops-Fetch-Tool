#!/bin/bash

# Define colors for output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    echo -e "${GREEN}Installing dependencies...${NC}"
    apt update

    # Check and install each dependency
    for cmd in nginx docker jq ip ip a netstat; do
        if command_exists $cmd; then
            echo -e "${GREEN}$cmd is already installed.${NC}"
        else
            pkg=""
            case $cmd in
                nginx)
                    pkg="nginx"
                    ;;
                docker)
                    pkg="docker.io"
                    ;;
                jq)
                    pkg="jq"
                    ;;
                ip)
                    pkg="iproute2"
                    ;;
                netstat)
                    pkg="net-tools"
                    ;;
            esac

            if [ -n "$pkg" ]; then
                echo -e "${GREEN}Installing $pkg...${NC}"
                if ! apt install -y $pkg; then
                    echo -e "${RED}Failed to install $pkg. Exiting.${NC}"
                    exit 1
                fi
            fi
        fi
    done
}

# Function to copy the main script
copy_main_script() {
    echo -e "${GREEN}Copying devopsfetch.sh script to /usr/local/bin...${NC}"
    if [ -f "devopsfetch.sh" ]; then
        cp devopsfetch.sh /usr/local/bin/devopsfetch.sh
        chmod +x /usr/local/bin/devopsfetch.sh
    else
        echo -e "${RED}Error: devopsfetch.sh script not found.${NC}"
        exit 1
    fi
}

# Function to create systemd service
create_systemd_service() {
    echo -e "${GREEN}Creating systemd service...${NC}"
    cat << EOF > /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOps Fetch Monitoring Service
After=network.target

[Service]
ExecStart=/bin/bash -c 'while true; do /usr/local/bin/devopsfetch.sh -p -d -n -u >> /var/log/devopsfetch.log; sleep 300; done'
Restart=always
User=root
Environment=MONITOR_INTERVAL=300
Environment=LOG_FILE=/var/log/devopsfetch.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable devopsfetch.service
    systemctl start devopsfetch.service
}

# Function to set up log rotation
setup_log_rotation() {
    echo -e "${GREEN}Setting up log rotation...${NC}"
    cat << EOF > /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    size 10M
}
EOF
}

# Function to create a configuration file
create_config_file() {
    echo -e "${GREEN}Creating configuration file...${NC}"
    cat << EOF > /etc/devopsfetch.conf
# DevOpsFetch Configuration File

# Monitoring interval in seconds
MONITOR_INTERVAL=300

# Log file path
LOG_FILE="/var/log/devopsfetch.log"

# Enable/disable specific checks (true/false)
CHECK_PORTS=true
CHECK_DOCKER=true
CHECK_NGINX=true
CHECK_USERS=true

# Maximum number of entries to display for each check
MAX_PORTS=10
MAX_DOCKER_IMAGES=5
MAX_DOCKER_CONTAINERS=5
MAX_NGINX_DOMAINS=10
MAX_USERS=10
EOF
}

# Main installation process
main() {
    install_dependencies
    copy_main_script
    create_systemd_service
    setup_log_rotation
    create_config_file

    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "${GREEN}DevOpsFetch is now installed and running as a systemd service.${NC}"
    echo -e "${GREEN}You can customize settings in /etc/devopsfetch.conf${NC}"
    echo -e "${GREEN}Logs are stored in /var/log/devopsfetch.log${NC}"
    echo -e "${GREEN}To view the logs, use: journalctl -u devopsfetch.service${NC}"
    echo -e "${GREEN}The monitoring is now running in the background.${NC}"
}

# Run the main installation process
main
