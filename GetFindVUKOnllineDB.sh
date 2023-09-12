#!/bin/bash

# Set the target directory
target="$HOME/.config/aacs"

# If the target directory is missing, create it
if ! [ -d "$target" ]
then
	echo -e "\nDirectory \"${target}\" is missing!"
	echo "Creating \"${target}\"..."
	mkdir -p "$target" || exit 1
else
	# Delete the existing KEYDB.cfg file
	rm -f $target/KEYDB.cfg
fi

# Get the list of zip file links from the website
links=$(wget -qO- http://fvonline-db.bplaced.net/ | grep -o 'http://[^"]*fv_download.php?lang=[^"]*')

# Create a temporary directory
tempdir=$(mktemp -d)

# For each link
for link in $links; do
  # Download the zip file
  wget --output-document=$tempdir/keydb.zip $link

  # Unzip the file
  unzip $tempdir/keydb.zip -d $tempdir/

  # Add the contents of the keydb.cfg file to the KEYDB.cfg
  cat $tempdir/keydb.cfg >> $HOME/.config/aacs/KEYDB.cfg

  # Remove the downloaded and extracted files
  rm -f $tempdir/*
done

# Remove the temporary directory
rmdir $tempdir