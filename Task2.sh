#!/bin/bash

# Function to display script usage
usage() {
    echo "Usage: $0 [<source_directory>]"
    exit 1
}

# Function to handle errors
handle_error() {
    local error_message="$1"
    echo "Error: $error_message"
    exit 1
}

# Check if a directory is passed as a command line argument
if [ $# -eq 1 ]; then
    SOURCE_DIR="$1"
elif [ $# -eq 0 ]; then
    # Ask the user for the source directory
    read -p "Enter the path to the source directory: " SOURCE_DIR
    if [ -z "$SOURCE_DIR" ]; then
        handle_error "Source directory not provided."
    fi
else
    usage
fi

# Check if source directory exists and is a directory
if [ ! -d "$SOURCE_DIR" ]; then
    handle_error "'$SOURCE_DIR' is not a valid directory."
fi

# Get the base name of the source directory
SOURCE_BASENAME=$(basename "$SOURCE_DIR")

# Create a timestamp for the backup file
BACKUP_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Compress the source directory into a tarball
BACKUP_FILE="$SOURCE_BASENAME"_"$BACKUP_TIMESTAMP".tar.gz
tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$SOURCE_BASENAME"
if [ $? -ne 0 ]; then
    handle_error "Failed to create backup archive."
fi

# Ask the user for the IP address or URL of the remote server
read -p "Enter the IP address or URL of the remote server: " REMOTE_HOST
if [ -z "$REMOTE_HOST" ]; then
    handle_error "IP address or URL of the remote server not provided."
fi

# Ask the user for the port number of the remote server
read -p "Enter the port number of the remote server [22]: " REMOTE_PORT
REMOTE_PORT=${REMOTE_PORT:-22}

# Ask the user for the target directory to save the compressed tarball archive
read -p "Enter the target directory to save the compressed tarball archive on the remote server: " REMOTE_TARGET_DIR
if [ -z "$REMOTE_TARGET_DIR" ]; then
    handle_error "Target directory not provided."
fi

# Remote destination to upload the backup
REMOTE_DEST="$REMOTE_HOST:$REMOTE_PORT:$REMOTE_TARGET_DIR"

# Check if remote destination is valid
if ! ssh "$REMOTE_DEST" true > /dev/null 2>&1; then
    handle_error "Remote destination '$REMOTE_DEST' is not accessible."
fi

# Upload the backup file to the remote destination using scp
scp "$BACKUP_FILE" "$REMOTE_DEST"
if [ $? -eq 0 ]; then
    echo "Backup successfully uploaded to $REMOTE_DEST"
else
    handle_error "Failed to upload backup to $REMOTE_DEST"
fi

# Clean up the local backup file
rm "$BACKUP_FILE"
