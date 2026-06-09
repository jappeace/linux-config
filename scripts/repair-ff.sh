#!/bin/bash

# sometimes my computer clock resets and firefox marks all extensions
# as invalid because the signatures appear crazy.
# there is no way in the ui to repair this.
#
# this script deletes the certificate cache and forces firefox to recheck them
# which repairs the problem after the computer clock is corrected.

# Define the base Firefox directory for the user
FIREFOX_DIR="/home/jappie/.mozilla/firefox"

echo "Searching for cert9.db files in $FIREFOX_DIR..."

# Check if the Firefox directory exists
if [ -d "$FIREFOX_DIR" ]; then
    # Find and delete the files, printing the paths of the ones being removed
    # Note: Firefox must be completely closed before running this!
    find "$FIREFOX_DIR" -name "cert9.db" -type f -print -delete

    echo "Cleanup complete. Firefox will generate fresh certificate databases on its next launch."
else
    echo "Error: Firefox directory not found at $FIREFOX_DIR."
    echo "Double-check the path or ensure Firefox has been run at least once."
fi
