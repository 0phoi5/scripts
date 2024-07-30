#!/usr/bin/env bash

# login_server_info.sh
# Authour: Jack Collins
# Last updated: 30/07/2024
# Usage: Place in /etc/profile.d/.
#        Displays brief, useful information about a system on
#        any user logging in to an interactive shell,
#        designed to be seen directly after the motd.

# Keep the shell clean for non-interactive sessions
if echo "$-" | grep i > /dev/null
then

# Gather information
        info_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        info_deployment=$(hostnamectl | awk '/Deployment/ {print $NF}')
        info_uptime=$(uptime -p | cut -d ' ' -f 1 --complement)
        info_uptime_seconds=$(cat /proc/uptime | grep -o '^[0-9]\+')
        info_distro=$(cat /etc/os-release | awk -F'"' '/^VERSION=/ {print $2}')
        info_version=$(uname -r)

# Interpret found services and compile in to single variable
ora_dbs=$(ps -e -o cmd | grep ora_pmon_ | grep -v grep | cut -d"_" -f3 | sort | tr '\n' ' ' | sed 's/ *$//g')

        if [ ! -z "$ora_dbs" ]
        then
                services="Oracle ($ora_dbs)"
        fi

        if systemctl list-units | grep -wc tomcat.service > /dev/null
        then
                services="$services Tomcat"
        fi

        if systemctl list-units | grep -wc splunk.service > /dev/null
        then
                services="$services Splunk"
        fi

        if test -f /usr/bin/ansible-tower-service > /dev/null
        then
                services="$services Ansible-Tower"
        fi

        if [ -z "$services" ]
        then
                services="No DBs, Tomcat, Splunk or Tower found."
        fi

# Remove leading spaces on services variable
        services=$(echo $services | sed 's/^ *//g')

# Display
printf "\n  IP :             $info_ip\n"

case "$info_deployment" in
        POC|TEST|Training)
                printf "  Deployment :     \e[1;42m $info_deployment \e[0m\n"
#               PS1="\e[1;42m $info_deployment \e[0m$PS1"
                ;;
        NONPROD|DEVTEST|PREPROD|DEV|TEST|SIT|CIT|UAT)
                printf "  Deployment :     \e[1;43m $info_deployment \e[0m\n"
#               PS1="\e[1;43m $info_deployment \e[0m$PS1"
                ;;
        PROD|LIVE)
                printf "  Deployment :     \e[1;41m $info_deployment \e[0m\n"
#               PS1="\e[1;41m $info_deployment \e[0m$PS1"
                ;;
        DR)
                printf "  Deployment :     \e[1;45m $info_deployment \e[0m\n"
#               PS1="\e[1;45m $info_deployment \e[0m$PS1"
                ;;
        *)
                printf "  Deployment :     $info_deployment \n"
#               PS1=" $info_deployment $PS1"
                ;;
esac

        if [ "$info_uptime_seconds" -gt 3024000 ]
        then
                alert_uptime="\e[1;41m[ !! ]\e[0m"
        fi

printf "  Distro :         $info_distro - $info_version\n"
printf "  Uptime :         $info_uptime $alert_uptime\n"
printf "  Services :       Ansible Automation Server\n\n"

fi
