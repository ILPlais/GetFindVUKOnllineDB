# GetFindVUKOnllineDB

This script is designed to fetch the Blu-ray database from the [FindVUK Online Database](http://fvonline-db.bplaced.net/). It performs the following operations:

1. Determines the target directory based on the user's privileges. If the user is root, it uses the global directory; otherwise, it uses the local directory.

2. Checks if the target directory exists. If it doesn't, the script creates it. If it does exist, the script removes the existing `KEYDB.cfg` file.

3. Fetches a list of zip file links from the FindVUK Online Database website.

4. Creates a temporary directory.

5. Iterates over each link, performing the following actions:
	- Downloads the zip file.
	- Unzips the file.
	- Appends the contents of the `keydb.cfg` file to the `KEYDB.cfg` in the target directory.
	- Removes the downloaded and extracted files.

6. Finally, it removes the temporary directory.

This script is useful for automating the process of updating your Blu-ray database from the FindVUK Online Database.