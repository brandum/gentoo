#!/usr/bin/env bash

# download page for gentoo files
base_site="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/"

# check if wget is installed, exit if not
if command -v wget &> /dev/null; then
    # if installed get filename of latest iso file
    iso_file=$(wget -q -O - "$base_site" | grep -o 'href="[^"]*\.iso"' | awk -F'"' '{print $2}')
    # and get filename of latest asc file
    asc_file=$(wget -q -O - "$base_site" | grep -o "href=\"[^\"]*$iso_file.asc\"" | awk -F'"' '{print $2}')
else
    echo "Error: wget is not installed."
    exit 1
fi

# construct download links
iso_link="$base_site$iso_file"
asc_link="$base_site$asc_file"

# check if iso_file and asc_file are not empty
if [[ -n "$iso_file" && -n "$asc_file" ]]; then
    # download iso and asc files
    folder="gentoo-iso-latest"
    cd ~/Downloads
    wget --no-clobber -P "$folder" "$iso_link" "$asc_link"
else
    echo "Error: Failed to retrieve iso or asc file links."
    exit 1
fi



