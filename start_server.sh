#!/bin/bash

# Change directory and import variables
cd "$(dirname "${BASH_SOURCE[0]}")" || echo "Something broke, could not find directory?"
TOOLS_PATH=$(pwd)

### INITIALIZE SERVER ###

# Check for server update
if ! source server.config 2> /dev/null || [ "$AUTO_UPDATE" == 'YES' ]
then
	./update_server.sh
else
	./update_server.sh -c
fi

if ! command -v inotifywait -v screen > /dev/null
then
     echo "Dependencies are not met, please check that the following programs are installed:"
	 printf "\t- screen\n"
	 printf "\t- wget\n"
	 printf "\t- inotify-tools\n"
	 printf "\t- unzip\n"
     exit 1
fi

# Generate fortune
if [ "${DO_FORTUNE^^}" == "YES" ]
then
	if command -v fortune > /dev/null
	then
		echo "Generating fortune..."

		echo "§k~~~§rToday's fortune:§k~~~§r" > announcements.txt
		fortune -s >> announcements.txt
	else
		echo "Fortune has not been installed, so a new announcement cannot be generated. Please install fortune-mod and try again."
		sleep 2
	fi
fi

# Check if server is already running
if [ "$(screen -ls | grep -o "$SERVER_NAME")" == "$SERVER_NAME" ]
then
	echo "The server is already running"

	# Backup world(s) if someone has been online (used when start server is run automatically each day, otherwise this should never succeed)
	if [ "${WORLD_BACKUP^^}" == "YES" ]
	then
		grep -q "[^[:space:]]" .playedToday 2> /dev/null && ./backup_server.sh -a
	fi

	rm -f .playedToday

	exit 0
fi

cd "$SERVER_PATH" || echo "Something broke, could not find directory?"

echo "Starting server..."

# Clear previous log file and link it to the screen
echo "" > "$TOOLS_PATH/.server.log"
screen -dmS "$SERVER_NAME" -L -Logfile "$TOOLS_PATH/.server.log" bash -c "LD_LIBRARY_PATH=${SERVER_PATH}/ ${SERVER_PATH}/bedrock_server"
screen -Rd "$SERVER_NAME" -X logfile flush 1 # 1 sec delay to file logging as instant logging was too fast to handle properly

# Error reporting for wrong directory, we'll let it keep running for now as next step should terminate it anyway.
grep -q "No such file or directory" "$TOOLS_PATH/.server.log" &&
	echo "ERROR: Could not find Minecraft's server files. Check your path in 'server.config' or run 'update_server.sh' and try again."

# Check if server is running, exit if not.
CHECK=$(screen -ls | grep -o "$SERVER_NAME")
if [ "$CHECK" != "$SERVER_NAME" ]
then
	echo "Server failed to start!"
	exit 1
fi

# Wait for IPv4 address to be avalible
i=0
while [[ i -lt 5 ]]
do
	grep -q "IPv4" "$TOOLS_PATH/.server.log" && break
	inotifywait -qq -e MODIFY "$TOOLS_PATH/.server.log"
	((i++))
done

# An excessive number of grep uses to pull a single number (>_<)
PORT=$(grep -m 1 "IPv4" "$TOOLS_PATH/.server.log" | grep -o -P " port: \d+" | grep -o -P "\d+")

echo "Server has started successfully - You can connect at $(curl -s ifconfig.me):$PORT."

rm -f .playedToday

# Set day and weather cycle to false until a player joins
if [ "${NO_PLAYER_ACTION^^}" == "PAUSE" ]
then
	screen -Rd "$SERVER_NAME" -X stuff "gamerule dodaylightcycle false \r"
	screen -Rd "$SERVER_NAME" -X stuff "gamerule doweathercycle false \r"
fi

#--- MONITOR PLAYER CONNECTION/DISCONNECTION ---

# Loop while server is running
while [ "$(screen -ls | grep  -o "$SERVER_NAME")" == "$SERVER_NAME" ]
do
	# Wait for log update, if player connects set day and weather cycle to true
	inotifywait -qq -e MODIFY "$TOOLS_PATH/.server.log"
	if [ "$(tail -3 "$TOOLS_PATH/.server.log" | grep -o 'Player connected:')" == 'Player connected:' ]
	then

		PLAYER_NAME=$(tail -3 "$TOOLS_PATH/.server.log" | grep "Player connected" | grep -o ': .* xuid' | awk '{ print substr($0, 3, length($0)-8) }')

		echo "Player '$PLAYER_NAME' connected - Restarting time!" >> "$TOOLS_PATH/.server.log"
		
		grep -q "$PLAYER_NAME" .playedToday 2> /dev/null || echo "$PLAYER_NAME" >> "$TOOLS_PATH/.playedToday"./stop	

		# Set day and weather cycle to false if set to pause mode
		if [ "$NO_PLAYER_ACTION" == "PAUSE" ]
		then
			screen -Rd "$SERVER_NAME" -X stuff "gamerule dodaylightcycle true \r"
			screen -Rd "$SERVER_NAME" -X stuff "gamerule doweathercycle true \r"
		fi
		
		# Send player a message after they spawn to make sure they recieve it
		COUNT=0
		( while [ $COUNT -lt 5 ]
		do
			if [ "$(tail -3 "$TOOLS_PATH/.server.log" | grep -o 'Player Spawned:')" == 'Player Spawned:' ]
			then
				"$TOOLS_PATH/announce_server.sh" -p "$PLAYER_NAME"
				break
			else
				inotifywait -qq -e MODIFY "$TOOLS_PATH/.server.log"
				((COUNT+=1))
			fi
		done
		)&

	else
		# If player disconnects, check for remaining players
		if [ "$(tail -3 "$TOOLS_PATH/.server.log" | grep -o 'Player disconnected:')" == "Player disconnected:" ]
		then

			screen -Rd "$SERVER_NAME" -X stuff "list \r"

			# Wait for file update, if no players are online set day and weather cycle to be false
			inotifywait -qq -e MODIFY "$TOOLS_PATH/.server.log" > /dev/null
			if [ "$(tail -3 "$TOOLS_PATH/.server.log" | grep -o 'There are 0')" == "There are 0" ]
			then

				echo "There are no players currently online - pausing time!" >> "$TOOLS_PATH/.server.log"

				if [ "$NO_PLAYER_ACTION" == "PAUSE" ]
				then
					# Set day and weather cycle to false
					screen -Rd "$SERVER_NAME" -X stuff "gamerule dodaylightcycle false \r"
					screen -Rd "$SERVER_NAME" -X stuff "gamerule doweathercycle false \r"
				else 
					if [ "$NO_PLAYER_ACTION" == "SHUTDOWN" ]
					then
						(./stop_server.sh -t 0)
					fi
				fi
			fi
		fi
	fi
done &
