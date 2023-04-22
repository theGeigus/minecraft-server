#!/bin/bash

# Change directory and import variables
cd "$(dirname "${BASH_SOURCE[0]}")" ||  echo "Something broke, could not find directory?"
source ./config_server.sh

#--- STOP SERVER ---

# Check if server is running, exit if false
CHECK=$(screen -ls | grep -o $SERVER_NAME)
if [ "$CHECK" == "$SERVER_NAME" ]
then
	echo "Shutting down server!"

	screen -Rd "$SERVER_NAME" -X stuff "list \r"
	inotifywait -qq -e MODIFY serverLog > /dev/null
			# Check if any players are currently online
			if [ "$(tail -3 serverLog | grep -o 'There are 0')" != "There are 0" ]
			then
			read -r -p "There are players still online. Are you sure you want to shut down now? [y/N] " VAL
				if [[ ! "$VAL" =~ ^([yY][eE][sS]|[yY])$ ]]
				then
					echo Canceled
					exit 0
				else
					echo "Continuing shutdown."
				fi
			fi

	# Send the server a stop message
	screen -Rd $SERVER_NAME -X stuff "stop \r"

	sleep 2
else
	echo "Server failed to shutdown - Server was not running!"
	exit 0
fi

# Check if the server was actually closed
CHECK=$(screen -ls | grep -o "$SERVER_NAME")
if [ "$CHECK" == "$SERVER_NAME" ]
then
	echo "Server failed to shutdown - Attempting to quit shutdown"

	# Tell screen to quit
	screen -Rd "$SERVER_NAME" -X stuff "^A :quit \r" > /dev/null

	sleep 2

	# Check if server shut down
	CHECK=$(screen -ls | grep -o "$SERVER_NAME")
	if [ "$CHECK" == "$SERVER_NAME" ]
	then
		echo "One more try - Attempting to terminate screen"
		screen -Rd "$SERVER_NAME" -X stuff "^C" > /dev/null

		if [ "$CHECK" == "$SERVER_NAME" ]
        	then
                	echo "Server has been terminated successfully"
        	else
                	echo "Server has been terminated successfully"
        	fi

	else
		echo "Server has been quit successfully"
	fi
else
	echo "Server has shut down successfully!"
fi
