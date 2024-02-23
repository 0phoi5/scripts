#!/bin/bash
############
# Authour: Jack Collins (jackcollins.me.uk)
# Purpose: A monitoring script to check a .jks filestore for expired, or due to expire, certs.
#          Can be used by SCOM, Check_MK, etc. or simply run from a cron job or systemd timer, if given added functionality to send an email alert, for example.
# Last update: 23/02/23
############

# Path to keystore
KEYSTORE="/path/to/keystore.jks"

# Get current date
CURRENT_DATE=$(date +%s)

# Get expiry dates of keystore certs
echo -e "\n" | keytool -list -v -keystore "$KEYSTORE" 2>/dev/null | grep 'until:' | awk '{print $(NF-5),$(NF-4),$(NF-3),$(NF-2),$(NF-1),$NF}' | while IFS= read -r EXPIRY_DATE; do
	SINCE_EPOCH=$(date -d "$EXPIRY_DATE" +%s)

	# Check if expired
	if (( SINCE_EPOCH - CURRENT_DATE <= 0 ))
 	then
		echo "A certificate in $KEYSTORE has expired!"
		exit 1
	else
		if (( SINCE_EPOCH - CURRENT_DATE <= 2678400 ))
  		then
			if (( SINCE_EPOCH - CURRENT_DATE <= 604800 ))
   			then
				echo "A certificate in $KEYSTORE is due to expire within a week!"
				exit 1
			else
				echo "A certificate in $KEYSTORE is due to expire within a month."
				exit 2
			fi
		else
			echo "All certificates within $KEYSTORE are due to expire in more than a month's time."
			exit 0
		fi
        fi
done
