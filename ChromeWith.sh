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
sudo cp /Applications/Google\ Chrome.app/Contents/Info.plist /Applications/Google\ Chrome.app/Contents/Info.plist.${1}.backup
sudo cp /Applications/Google\ Chrome.app/Contents/Resources/en.lproj/InfoPlist.strings /Applications/Google\ Chrome.app/Contents/Resources/en.lproj/InfoPlist.strings.${1}.backup

cat /Applications/Google\ Chrome.app/Contents/Info.plist|sed -e 's,<string>Google Chrome</string>,<string>Chrome for '${1}'</string>,g'>/tmp/Chrome.${1}.Info.plist
sudo cp /tmp/Chrome.${1}.Info.plist /Applications/Google\ Chrome.app/Contents/Info.plist

cat /Applications/Google\ Chrome.app/Contents/Resources/en.lproj/InfoPlist.strings|sed -e 's,CFBundleDisplayName = "Google Chrome",CFBundleDisplayName = "Chrome for '$1'",g'>/tmp/Chrome.${1}.InfoPlist.strings
cat /tmp/Chrome.${1}.InfoPlist.strings|sed -e 's,CFBundleName = "Chrome",CFBundleName = "Chrome for '$1'",g'>/tmp/Chrome.${1}.InfoPlist.strings2
sudo cp /tmp/Chrome.${1}.InfoPlist.strings2 /Applications/Google\ Chrome.app/Contents/Resources/en.lproj/InfoPlist.strings

nohup /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --user-data-dir=$locationOfUnencryptedDirectory >> /dev/null& 


sudo cp /Applications/Google\ Chrome.app/Contents/Info.plist.${1}.backup /Applications/Google\ Chrome.app/Contents/Info.plist
sudo rm /Applications/Google\ Chrome.app/Contents/Info.plist.${1}.backup 
sudo cp /Applications/Google\ Chrome.app/Contents/Resources/en.lproj/InfoPlist.strings.${1}.backup /Applications/Google\ Chrome.app/Contents/Resources/en.lproj/InfoPlist.strings
sudo rm /Applications/Google\ Chrome.app/Contents/Resources/en.lproj/InfoPlist.strings.${1}.backup 
