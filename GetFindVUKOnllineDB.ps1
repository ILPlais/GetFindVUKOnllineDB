# Set the target directory
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	# The user is not an administrator: use the local directory
	$target = "$env:APPDATA\aacs"
}
else {
	# The user is an administrator: use the global directory
	$target = "$env:ALLUSERSPROFILE\aacs"
}

# If the target directory is missing, create it
if (-not (Test-Path -Path $target -PathType Container)) {
	Write-Host "Directory ""$target"" is missing!"
	Write-Host "Creating ""$target""…"
	$null = New-Item -Path $target -ItemType Directory -ErrorAction Stop
}
else {
	# Delete the existing KEYDB.cfg file
	Remove-Item -Path "$target\KEYDB.cfg" -ErrorAction SilentlyContinue
}

# Get the list of zip file links from the website
$links = (Invoke-WebRequest -UseBasicParsing -Uri "http://fvonline-db.bplaced.net/").Links | Where-Object { $_.href -like "http://*/fv_download.php?lang=*" } | Select-Object -ExpandProperty href

# Create a temporary directory
$tempdir = Join-Path $env:TEMP $(New-Guid)
New-Item -Type Directory -Path $tempdir | Out-Null

# For each link
foreach ($link in $links) {
	# Download the zip file
	Write-Host "Downloading the file: ""$link""…"
	Invoke-WebRequest -UseBasicParsing -Uri $link -OutFile "$tempdir\keydb.zip"

	# Unzip the file
	Write-Host "Unzip the file: ""$tempdir\keydb.zip""…"
	Expand-Archive -Path "$tempdir\keydb.zip" -DestinationPath $tempdir

	# Add the contents of the keydb.cfg file to the KEYDB.cfg
	Add-Content -Path "$target\KEYDB.cfg" -Value (Get-Content -Path "$tempdir\keydb.cfg")

	# Remove the downloaded and extracted files
	Remove-Item -Path "$tempdir\*" -Force
}

# Remove the temporary directory
Remove-Item -Path $tempdir -Force