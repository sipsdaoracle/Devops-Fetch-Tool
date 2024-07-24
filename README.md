# Welcome to the Devops-Fetch-Tool wiki!

## Installation and Configuration

### Prerequisites
* The script must be run as root or with sudo privileges.
* The following dependencies are required: nginx, docker, jq, iproute2, and net-tools. 
* The script will automatically install these dependencies if they are not already present on the system.

## Installation Steps
Download the install.sh script and the devopsfetch.sh script.
Run the install.sh script as root or with sudo:

`sudo ./install.sh`

### The installation process will perform the following tasks:
* Install the required dependencies.
* Copy the devopsfetch.sh script to /usr/local/bin.
* Create a systemd service to run the devopsfetch.sh script continuously.
* Set up log rotation for the generated logs.
* Create a configuration file at /etc/devopsfetch.conf.

### Configuration
* The configuration file located at /etc/devopsfetch.conf allows you to customize the script's behavior. You can modify the following settings:
* MONITOR_INTERVAL: The interval (in seconds) at which the script will run and collect data.
* LOG_FILE: The path to the log file where the script's output will be stored.
* CHECK_PORTS, CHECK_DOCKER, CHECK_NGINX, CHECK_USERS: Enables or disables specific checks.
* MAX_PORTS, MAX_DOCKER_IMAGES, MAX_DOCKER_CONTAINERS, MAX_NGINX_DOMAINS, MAX_USERS: The maximum number of entries to display for each check.


## Usage
The devopsfetch.sh script provides several command-line options to interact with the monitoring tool. Here are the available options and their usage examples:


1. Display services running on a specific port:
`./devopsfetch.sh -p [PORT]`

Example:

2. Display Docker container statuses:
`./devopsfetch.sh -d
./devopsfetch.sh --docker`

Example:

3. Display Nginx configurations:
`./devopsfetch.sh -n
./devopsfetch.sh --nginx`

4. Display user login sessions:
`./devopsfetch.sh -u
./devopsfetch.sh --user`

5. Display system logs for a specific date:

`./devopsfetch.sh -t [YYYY-MM-DD]
./devopsfetch.sh --time [YYYY-MM-DD]`

6. Display help:
`./devopsfetch.sh -h
./devopsfetch.sh --help`



## Logging and Log Retrieval
The DevOpsFetch script uses a systemd service to run continuously in the background. The script's output is logged to the file specified in the /etc/devopsfetch.conf configuration file (default: /var/log/devopsfetch.log).

To view the logs, you can use the following command:

`journalctl -u devopsfetch.service`


### Log Rotation
Log rotation is set up to manage the size and number of log files. The log rotation configuration is located at /etc/logrotate.d/devopsfetch:


```/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    size 10M
}
```

## Troubleshooting
If you encounter any issues with the DevOpsFetch script, please check the following:

Ensure that the script is running as root or with sudo privileges.
Verify that the required dependencies are installed. The install.sh script should handle this automatically, but you can check the status of the packages manually.
Check the log file (/var/log/devopsfetch.log) for any error messages or clues about the issue.


