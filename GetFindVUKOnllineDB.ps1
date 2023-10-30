# Set the target directory
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	# The user is not an administrator: use the local directory
	$target = "$env:APPDATA\aacs"
}
else {
	# The user is an administrator: use the global directory
	$target = "$env:ALLUSERSPROFILE\aacs"

	# Verify if VLC is install
	$vlcPath = "$env:PROGRAMFILES\VideoLAN\VLC"

	if (Test-Path -Path $vlcPath) {
		# Verify if there is the AACS DLL in the VLC directory
		$vlcDllPath = "$vlcPath\libaacs.dll"

		Write-Host "[*] Verify if the libaacs DLL is in the VLC directory…"
		if (-not (Test-Path -Path $vlcDllPath)) {
			Write-Host "[!] Library AACS is missing!"
			# Check if Windows is in 32 bits or in 64 bits
			if ([Environment]::Is64BitOperatingSystem) {
				Write-Host "[+] Downloading the 64 bits version…"
				$libaacsUrl = "https://vlc-bluray.whoknowsmy.name/files/win64/libaacs.dll"
			} else {
				Write-Host "[+] Downloading the 32 bits version…"
				$libaacsUrl = "https://vlc-bluray.whoknowsmy.name/files/win32/libaacs.dll"
			}

			# Download the AACS DLL in the VLC directory
			Invoke-WebRequest -Uri $libaacsUrl -OutFile $vlcDllPath
		}
	}
}

# Check if Java is installed, for the Blu-ray menus
try {
	$javaVersion = & java -version 2>&1
	Write-Host "[*] Java is installed.`n`t-> Version: $javaVersion."
}
catch {
	Write-Host "[!] Java seem to not be installed. You will need to install it to show the Blu-ray menus."
}

# If the target directory is missing, create it
if (-not (Test-Path -Path $target -PathType Container)) {
	Write-Host "[!] Directory ""$target"" is missing!"
	Write-Host "[+] Creating ""$target""…"
	$null = New-Item -Path $target -ItemType Directory -ErrorAction Stop
}

Write-Host "[*] We will use the directory:`n`t-> $target"

# Set the database Web site URL
$databaseWebSite = "http://fvonline-db.bplaced.net/"

# Get the database last update
Write-Host "[+] Get the database last update on the website:`n`t-> $databaseWebSite"
$pageContent = (Invoke-WebRequest -Uri $databaseWebSite).Content

if ($pageContent -match "LastUpdate:\s*(\d{4}-\d{2}-\d{2}\s*\d{2}:\d{2}:\d{2})") {
	$lastUpdate = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd HH:mm:ss", $null)
	Write-Host "[*] The last update of the Web database is $($lastUpdate.ToString('yyyy-MM-dd HH:mm:ss'))."
}
else {
	$lastUpdate = [DateTime]::ParseExact("1970-01-01", "yyyy-MM-dd", $null)
}

# Get the local database last update
if (Test-Path -Path "$target\lastupdate.txt") {
	$fileContent = Get-Content -Path "$target\lastupdate.txt"
	$localUpdate = [DateTime]::ParseExact($fileContent, "yyyy-MM-dd HH:mm:ss", $null)
	Write-Host "[*] The last update of the local database is $($localUpdate.ToString('yyyy-MM-dd HH:mm:ss'))."
}
else {
	$localUpdate = [DateTime]::ParseExact("1970-01-01", "yyyy-MM-dd", $null)
}

# Check if the database on the website is newer than the local database
if ($lastUpdate -gt $localUpdate) {
	# Get the list of zip file links from the website
	Write-Host "[+] Get the list of zip file links from the website…"
	$links = (Invoke-WebRequest -UseBasicParsing -Uri $databaseWebSite).Links | Where-Object { $_.href -like "http://*/fv_download.php?lang=*" } | Select-Object -ExpandProperty href

	# Create a temporary directory
	$tempdir = Join-Path $env:TEMP $(New-Guid)
	New-Item -Type Directory -Path $tempdir | Out-Null

	# For each link
	foreach ($link in $links) {
		# Download the zip file
		Write-Host "[+] Downloading the file:`n`t-> ""$link""…"
		Invoke-WebRequest -UseBasicParsing -Uri $link -OutFile "$tempdir\keydb.zip"

		# Unzip the file
		Write-Host "[+] Unzip the file:`n`t-> ""$tempdir\keydb.zip""…"
		Expand-Archive -Path "$tempdir\keydb.zip" -DestinationPath $tempdir

		# Add the contents of the keydb.cfg file to the KEYDB.cfg
		Write-Host "[+] Add the content of the KEYDB file to the local KEYDB.cfg…"
		Add-Content -Path "$target\KEYDB.cfg.tmp" -Value (Get-Content -Path "$tempdir\keydb.cfg")

		# Remove the downloaded and extracted files
		Remove-Item -Path "$tempdir\*" -Force
	}

	# Remove the temporary directory
	Remove-Item -Path $tempdir -Force

	# Delete the actual KEYDB.cfg
	if (Test-Path -Path "$target\KEYDB.cfg") {
		Write-Host "[+] Delete the actual KEYDB.cfg…"
		Remove-Item -Path "$target\KEYDB.cfg"
	}

	# Rename the temporary KEYDB.cfg
	Write-Host "[+] Rename the temporary KEYDB.cfg file…"
	Rename-Item -Path "$target\KEYDB.cfg.tmp" -NewName "$target\KEYDB.cfg"

	# Save the database last update into the "lastupdate.txt" file
	$lastUpdateFormatted = $lastUpdate.ToString("yyyy-MM-dd HH:mm:ss")
	Set-Content -Path "$target\lastupdate.txt" -Value $lastUpdateFormatted
}

Write-Host "[*] All is done!"