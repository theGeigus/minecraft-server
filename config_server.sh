#!/bin/bash

# This file contains the configuration for all server script files (e.g. *_server.sh).
# Allows all variables to be set in one convienient location instead of within each file.
# Any blank or incorrect option will dbe interpreted as 'NO' (if applicable)

### SERVER NEEDS TO BE RESTARTED TO APPLY CHANGES ###

# Used as the name of the screen, can be anything but needs to be unique if running multiple servers.
SERVER_NAME="minecraft-server"

# Directory path to server folder location, default should automatically get the server path, but you can change this if you want your server and script files in seperate locations
# Default is: $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )
SOURCE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# What action to take when all players leave. Options are 'NO', 'PAUSE', and 'SHUTDOWN' (Default is 'PAUSE'). Option 'PAUSE' toggles day/weather cycle on players leaving and joining.
NO_PLAYER_ACTION="PAUSE"

# Show server announcements. Options are 'YES', 'NO', and 'ONCE' (Default is 'YES'). Option 'ONCE' only shows each player the announcement a single time, resets when announcement is changed.
DO_ANNOUNCEMENTS="YES"

# Show admin announcements. Sends info such as server updates to admins (specified below). Options are 'YES', 'NO', and 'ONCE' (Default is 'ONCE').
DO_ADMIN_ANNOUNCEMENTS="ONCE"

# List all players that will recieve admin announcements. Player names should be seperated by spaces.
ADMIN_LIST="Geigus"


### The following lines are planned, but are not yet functional ###

# Enable daily automatic world backups
WORLD_BACKUP="YES"

# Directory worlds will be backed up to - recommended to use a directory located in a drive different than your server
BACKUP_PATH="/home/$USER/Backups/$SERVER_NAME"

# Number of daily backups to keep
BACKUP_NUM=5
