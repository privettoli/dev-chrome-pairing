#!/bin/bash

# Ensuring the script will fail if any of the commands fail
set -e 
set -o pipefail

# Installing gpg if not installed
command -v gpg >/dev/null 2>&1 || { echo >&2 "I require gpg to work, but it's not installed. Installing gpg…"; brew install gpg; }

# Check if macOS, then ask for username
# Experimental
# if [ $(uname -s) == 'Darwin' ]; then
# 	$1=((osascript <<EOT
#     tell app "System Events"
#       text returned of (display dialog "Enter your username:" default answer "" buttons {"OK"} default button 1)
#     end tell))
# EOT
# fi

# Ensuring the cache would not last long
mkdir -p $HOME/.gnupg
printf "default-cache-ttl 60\nmax-cache-ttl 60" > $HOME/.gnupg/gpg-agent.conf

# Parsing the attributes to work within the script
username=$1

locationOfChromeUsers=$HOME/ChromeUsers
locationOfUnencryptedDirectory=$locationOfChromeUsers/$username
locationOfEncryptedArchive=$locationOfChromeUsers/encrypted/$username.tar.gz.dat

if [[ ! $(gpg -k | grep $username) ]]; then
	echo "Creating new Google Chrome profile for $username"
elif [[ -f $locationOfEncryptedArchive ]]; then
	# Decrypt user folder from $locationOfEncryptedArchive (if present) to $locationOfUnencryptedDirectory
 	gpg --yes --output /tmp/gpg --decrypt $locationOfEncryptedArchive
 	echo Preparing the space, may take a while
 	tar -xzf /tmp/gpg -C /
fi

# Clearing passwords cache of gpg (double-check)
echo RELOADAGENT | gpg-connect-agent

# todo Go background / minimize the terminal window

# Run a new process with correct user folder
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --user-data-dir=$locationOfUnencryptedDirectory

