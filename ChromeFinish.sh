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

username=`echo $1 | tr -d '[:space:]'`
email=$username@corelogic.com

# End the script if user's SSH keys are not present
echo Checking SSH keys are present...
locationOfSshKeys=$HOME/.ssh/$username.rsa
if [ ! -f $locationOfSshKeys ]; then
	echo "Couldn't find SSH keys of that user '$username' under path $locationOfSshKeys"
	exit -1
fi

locationOfChromeUsers=$HOME/ChromeUsers
locationOfUnencryptedDirectory=$locationOfChromeUsers/$username
locationOfEncryptedArchive=$locationOfChromeUsers/encrypted/$username.tar.gz.dat

# If no gpg keys are present for this user, create one
if [[ ! $(gpg -k | grep $username) ]]
	then echo "Key-Type: RSA
      Key-Length: 2048
      Name-Real: $username
      Name-Email: $email
      Expire-Date: 0
      %ask-passphrase
      %commit
      %echo done" > /tmp/gpg && gpg --batch --generate-key /tmp/gpg
      rm -r /tmp/gpg
fi

# Encrypted directory contains all encrypted users
mkdir -p $locationOfChromeUsers/encrypted

# Archive the folder to /tmp/gpg
echo Archiving the Chrome settings
tar cz $locationOfUnencryptedDirectory > /tmp/gpg

echo Encrypting them to $locationOfEncryptedArchive
rm -f $locationOfEncryptedArchive
gpg --output $locationOfEncryptedArchive --encrypt --recipient $email /tmp/gpg

echo Clearing $locationOfUnencryptedDirectory
# Clearing passwords cache of gpg (double-check)
echo RELOADAGENT | gpg-connect-agent
rm -r /tmp/gpg
# Deleting unencrypted user data
rm -r $locationOfUnencryptedDirectory

echo "Have a wonderful evening! Drive safe."

