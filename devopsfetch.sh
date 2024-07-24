#!/bin/bash

# Function to display help
display_help() {
    echo "Usage: $0 [option] [argument]"
    echo ""
    echo "Options:"
    echo "  -p [port]                   Display services running on a specific port"
    echo "  -d, --docker                Display Docker container statuses"
    echo "  -n, --nginx                 Display Nginx configurations"
    echo "  -u, --user                  Display user login sessions"
    echo "  -t, --time [YYYY-MM-DD]     Display system logs for a specific date"
    echo "  -h, --help                  Show this help message and exit"
    echo ""
    echo "Examples:"
    echo "  $0 -p 5000                  Display services running on port 5000"
    echo "  $0 --docker                 Display Docker container statuses"
    echo "  $0 --nginx                  Display Nginx configurations"
    echo "  $0 --user                   Display user login sessions"
    echo "  $0 --time 2024-07-23        Display system logs for July 23, 2024"
}

# Function to fetch and display services running on specific ports
fetch_port_info() {
    port_filter=$1
    echo "+------------+------+-----------+"
    echo "|    USER    | PORT |  SERVICE  |"
    echo "+------------+------+-----------+"

    if [ -z "$port_filter" ]; then
        netstat -tuln | awk 'NR>2 {print $4}' | grep -Eo '[0-9]+$' | sort -u | while read -r port; do
            user=$(lsof -i :"$port" | awk 'NR==2 {print $3}')
            service=$(lsof -i :"$port" | awk 'NR==2 {print $1}')
            printf "| %-10s | %-4s | %-9s |\n" "$user" "$port" "$service"
        done
    else
        netstat -tuln | awk 'NR>2 {print $4}' | grep -Eo '[0-9]+$' | grep -w "$port_filter" | sort -u | while read -r port; do
            user=$(lsof -i :"$port" | awk 'NR==2 {print $3}')
            service=$(lsof -i :"$port" | awk 'NR==2 {print $1}')
            if [ -z "$user" ]; then
                echo "No services found on port $port_filter"
            else
                printf "| %-10s | %-4s | %-9s |\n" "$user" "$port" "$service"
            fi
        done
    fi

    echo "+------------+------+-----------+"
}

# Function to fetch and display Docker container statuses
fetch_docker_status() {
    echo "+-----------------------+------------------+----------------+"
    echo "| Container Name        | Status           | Ports          |"
    echo "+-----------------------+------------------+----------------+"

    docker ps --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" | while IFS=$'\t' read -r name status ports; do
        printf "| %-21s | %-16s | %-14s |\n" "$name" "$status" "$ports"
    done

    echo "+-----------------------+------------------+----------------+"
}

# Function to fetch and display Nginx configurations
fetch_nginx_config() {
    echo "+------------------------------+-----------------+---------------------------------+"
    echo "|         Server Domain        |      Proxy      |       Configuration File        |"
    echo "+------------------------------+-----------------+---------------------------------+"

    nginx_dir="/etc/nginx"
    sites_enabled="$nginx_dir/sites-enabled"
    sites_available="$nginx_dir/sites-available"
    conf_d="$nginx_dir/conf.d"

    for config_file in "$sites_enabled"/* "$sites_available"/* "$conf_d"/*; do
        if [ -f "$config_file" ]; then
            server_name=$(grep -m 1 "server_name" "$config_file" | awk '{print $2}' | tr -d ';')
            proxy=$(grep -m 1 "proxy_pass" "$config_file" | awk '{print $2}' | tr -d ';')
            printf "| %-28s | %-15s | %-31s |\n" "$server_name" "$proxy" "$config_file"
        fi
    done

    echo "+------------------------------+-----------------+---------------------------------+"
}

# Function to fetch and display user login sessions
fetch_user_sessions() {
  echo "+----------+----------+-----------+------------------+-----------------+"
  echo "| Username | Terminal | Host   | Login Time    | Session Duration|"
  echo "+----------+----------+-----------+------------------+-----------------+"

  # Loop through logged-in users
  who | awk '{print $1}' while read -r username; do
    # Get processes for the user using ps -U
    user_processes=$(ps -U "$username" -o etime=)

    # Check if there are any processes for the user
    if [[ -z "$user_processes" ]]; then
      printf "| %-8s | %-8s | %-9s | %-16s | %-15s |\n" "$username" "-" "-" "-" "-"
      continue
    fi

    # Calculate total uptime for user processes
    total_uptime=$(echo "$user_processes" | awk '{sum += $1} END {print sum}')

    # Format and print user information with session duration
    printf "| %-8s | %-8s | %-9s | %-16s | %-15s |\n" "$username" "-" "-" "$(who | grep "$username" | awk '{print $4, $3}')" "$(human_readable_time $total_uptime)"
  done

  echo "+----------+----------+-----------+------------------+-----------------+"
}

# Function to convert seconds to human-readable format (optional)
human_readable_time() {
  seconds=$1
  minutes=$((seconds / 60))
  hours=$((minutes / 60))
  days=$((hours / 24))
  minutes=$((minutes % 60))
  hours=$((hours % 24))
  seconds=$((seconds % 60))

  if [[ $days -gt 0 ]]; then
    printf "%dd %dh %dm\n" "$days" "$hours" "$minutes"
  elif [[ $hours -gt 0 ]]; then
    printf "%dh %dm %ds\n" "$hours" "$minutes" "$seconds"
  else
    printf "%dm %ds\n" "$minutes" "$seconds"
  fi
}


# Function to fetch and display system logs for a specific date
fetch_logs_by_date() {
    date_filter=$1
    start_date="${date_filter} 00:00:00"
    end_date="${date_filter} 23:59:59"

    echo "Displaying system logs from $start_date to $end_date"
    echo "-----------------------------------------------------------------------"
    
    # Fetch logs using journalctl and filter by date
    journalctl --since="$start_date" --until="$end_date"
}

# Main script execution
if [ "$1" == "-p" ]; then
    fetch_port_info "$2"
elif [ "$1" == "-d" ] || [ "$1" == "--docker" ]; then
    fetch_docker_status
elif [ "$1" == "-n" ] || [ "$1" == "--nginx" ]; then
    fetch_nginx_config
elif [ "$1" == "-u" ] || [ "$1" == "--user" ]; then
    fetch_user_sessions
elif [ "$1" == "-t" ] || [ "$1" == "--time" ] && [ -n "$2" ]; then
    fetch_logs_by_date "$2"
elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
else
    echo "Invalid option. Use -h or --help for usage instructions."
fi
