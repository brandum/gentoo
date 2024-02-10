#!/usr/bin/env bash

# location of files after executing script 'get-gentoo-iso.sh'
folder=~/Downloads/gentoo-iso-latest

# ask for fingerprint
echo "What is the Key fingerprint?"
echo "Check at https://www.gentoo.org/downloads/signatures/"
read fingerprint

# receive the keys
gpg --keyserver hkps://keys.gentoo.org --recv-keys "$fingerprint"

echo ""

# verify the iso
gpg --verify "$folder"/*.asc
