#!/bin/bash

# Verify if the AACS library is install
if ! ldconfig --print-cache | grep --quiet libaacs
then
	echo "[!] The library libaacs seem to not be install on your system."
	echo -e "\t-> Check with your package manager to install it."
fi

# Set the target directory
if [ "$(id -u)" -ne 0 ]
then
	# The user is not root: use the local directory
	target="$HOME/.config/aacs"
else
	# The user is root: use the global directory
	target="/etc/xdg/aacs"
fi

# If the target directory is missing, create it
if ! [ -d "$target" ]
then
	echo "[!] Directory \"${target}\" is missing!"
	echo "[+] Creating \"${target}\"…"
	mkdir -p "$target" || exit 1
fi

echo -e "[*] We will use the directory:\n\t-> $target"

# Set the database Web site URL
databaseWebSite="http://fvonline-db.bplaced.net/"

# Get the database last update
echo -e "[+] Get the database last update on the website:\n\t-> $databaseWebSite"
pageContent=$(wget -qO- $databaseWebSite)

lastUpdate=$(echo "$pageContent" | grep -o 'LastUpdate: [^<]*' | awk -F': ' '{print $2}')

echo "[*] The last update of the Web database is $lastUpdate."

# Get the local database last update
if [ -f "$target/lastupdate.txt" ]
then
	localUpdate=$(cat "$target/lastupdate.txt")
	echo "[*] The last update of the local database is $localUpdate."
else
	localUpdate="1970-01-01"
fi

# Convert the dates in Unix timestamp
lastUpdateUnix=$(date --date="$lastUpdate" +%s)
localUpdateUnix=$(date --date="$localUpdate" +%s)

# Check if the database on the website is newer than the local database
if [ $lastUpdateUnix -gt $localUpdateUnix ]
then
	# Get the list of zip file links from the website
	echo "[+] Get the list of zip file links from the website…"
	links=$(wget -qO- $databaseWebSite | grep -o 'http://[^"]*fv_download.php?lang=[^"]*')

	# Create a temporary directory
	tempdir=$(mktemp -d)

	# For each link
	for link in $links; do
		# Download the zip file
		echo -e "[+] Downloading the file\n\t-> ""$link""…"
		wget --output-document="$tempdir/keydb.zip" $link

		# Unzip the file
		echo -e "[+] Unzip the file\n\t-> ""$tempdir/keydb.zip""…"
		unzip -o "$tempdir/keydb.zip" -d "$tempdir/"

		# Add the contents of the keydb.cfg file to the KEYDB.cfg
		echo "[+] Add the content of the KEYDB file to the local KEYDB.cfg…"
		cat "$tempdir/keydb.cfg" >> "$target/KEYDB.cfg.tmp"

		# Remove the downloaded and extracted files
		rm -f "$tempdir/*"
	done

	# Remove the temporary directory
	rmdir -rf "$tempdir"

	# Delete the actual KEYDB.cfg
	if [ -f "$target/KEYDB.cfg" ]
	then
		echo "[+] Delete the actual KEYDB.cfg…"
	fi

	# Rename the temporary KEYDB.cfg
	echo "[+] Rename the temporary KEYDB.cfg file…"
	mv "$target/KEYDB.cfg.tmp" "$target/KEYDB.cfg"
fi

echo "[*] All is done!"