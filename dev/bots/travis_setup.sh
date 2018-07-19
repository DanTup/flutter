#!/bin/bash
set -e

echo $KEY_FILE | base64 --decode > ../gcloud_key_file.json

set -x

# rename the SDK directory to include a space
echo "Renaming Flutter checkout directory to 'flutter sdk'"
cd ..
mv flutter flutter\ sdk
cd flutter\ sdk
echo "SDK directory is: $PWD"

# disable analytics on the bots and download Flutter dependencies
./bin/flutter config --no-analytics

# run pub get in all the repo packages
./bin/flutter update-packages
