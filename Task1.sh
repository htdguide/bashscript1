#!/bin/bash

LOG_FILE="user_creation_log_$(date +"%Y-%m-%d_%H-%M-%S").txt"

log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" | tee -a "$LOG_FILE"
}

# Function to create a user
create_user() {
    local username="$1"
    local password="$2"

    sudo useradd -m -s /bin/bash "$username"
    if [ $? -eq 0 ]; then
        log_message "User $username created."
    else
        log_message "Error: User creation failed for $username"
        return 1
    fi
    echo "$username:$password" | sudo chpasswd
    if [ $? -eq 0 ]; then
        log_message "Password set for $username."
    else
        log_message "Error: Password setting failed for $username"
        return 1
    fi
    sudo passwd --expire "$username"
}

# Function to add a user to groups
add_to_groups() {
    local username="$1"
    local groups="$2"

    IFS=';' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        # Check if group exists, if not, create it
        if ! getent group "$group" > /dev/null 2>&1; then
            sudo groupadd "$group"
            if [ $? -eq 0 ]; then
                log_message "Group $group created."
            else
                log_message "Error: Group creation failed for $group"
                continue
            fi
        fi
        sudo usermod -aG "$group" "$username"
        if [ $? -eq 0 ]; then
            log_message "User $username added to group $group."
        else
            log_message "Error: Failed to add user $username to group $group"
        fi
    done
}

# Function to create a shared folder
create_shared_folder() {
    local username="$1"
    local shared_folder="$2"

    if [[ -n "$shared_folder" && ! -d "$shared_folder" ]]; then
        sudo mkdir -p "$shared_folder"
        if [ $? -eq 0 ]; then
            log_message "Shared folder $shared_folder created."
        else
            log_message "Error: Shared folder creation failed for $shared_folder"
            return 1
        fi
        # Create a new group for the shared folder if it doesn't exist
        shared_folder_group="${username}_shared"
        if ! getent group "$shared_folder_group" > /dev/null 2>&1; then
            sudo groupadd "$shared_folder_group"
            if [ $? -eq 0 ]; then
                log_message "Group $shared_folder_group created."
            else
                log_message "Error: Group creation failed for $shared_folder_group"
                return 1
            fi
        fi
        sudo chown "$username":"$shared_folder_group" "$shared_folder"
        if [ $? -eq 0 ]; then
            log_message "Ownership set for $shared_folder."
        else
            log_message "Error: Failed to set ownership for $shared_folder"
        fi
        sudo chmod 770 "$shared_folder"
        if [ $? -eq 0 ]; then
            log_message "Permissions set for $shared_folder."
        else
            log_message "Error: Failed to set permissions for $shared_folder"
        fi
        # Add the user to the shared folder group
        sudo usermod -aG "$shared_folder_group" "$username"
        if [ $? -eq 0 ]; then
            log_message "User $username added to group $shared_folder_group for shared folder access."
        else
            log_message "Error: Failed to add user $username to group $shared_folder_group for shared folder access"
        fi
    fi
}

# Function to process CSV data
process_csv_data() {
    local file="$1"
    # Read the CSV file line by line
    while IFS=, read -r email birth_date groups shared_folder
    do
        # Skip the header line and comment lines
        if [[ "$email" == "email" || "$email" == \#* ]]; then
            continue
        fi

        # Extract username from email
        local username=$(echo $email | cut -d'@' -f1)

        # Set password based on birth date
        local password=$(echo $birth_date | tr -d '-')

        # Create user
        create_user "$username" "$password" || continue

        # Add user to groups
        add_to_groups "$username" "$groups"

        # Create shared folder
        create_shared_folder "$username" "$shared_folder"

        # Print summary of user environment
        log_message "User environment summary for $username:"
        log_message "Username: $username"
        log_message "Home directory: /home/$username"
        if [[ -n "$shared_folder" ]]; then
            log_message "Shared folder: $shared_folder"
            log_message "Shared folder link: $(readlink -f "$shared_folder")"
        fi
        # Additional information such as alias can be added if required

        log_message "User $username created and configured."
    done < "$file"
}

# Function to get confirmation from the user
confirm_action() {
    read -p "Do you want to proceed? (yes/no): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if command-line arguments are provided
if [[ $# -eq 1 ]]; then
    # Check if argument is a URI or a local file
    if [[ $1 == http* || $1 == ftp* ]]; then
        # Download the file from the URI
        wget -O users.csv "$1" || { echo "Error downloading file from $1"; exit 1; }
        CSV_FILE="users.csv"
    elif [[ -f "$1" ]]; then
        CSV_FILE="$1"
    else
        echo "Invalid input. Please provide a valid URI or local file path."
        exit 1
    fi
else
    # Ask for user input
    read -p "Enter the URI or local file path for the CSV data: " input
    if [[ $input == http* || $input == ftp* ]]; then
        # Download the file from the URI
        wget -O users.csv "$input" || { echo "Error downloading file from $input"; exit 1; }
        CSV_FILE="users.csv"
    elif [[ -f "$input" ]]; then
        CSV_FILE="$input"
    else
        echo "Invalid input. Please provide a valid URI or local file path."
        exit 1
    fi
fi

# Print information about the input file
log_message "Processing CSV data from file: $CSV_FILE"

# Count the number of users to be added
USER_COUNT=$(grep -v '^#' "$CSV_FILE" | grep -vc '^email')
log_message "Number of users to be added: $USER_COUNT"

# Ask for confirmation before proceeding
if ! confirm_action; then
    echo "Operation cancelled."
    exit 0
fi

# Process the CSV data
process_csv_data "$CSV_FILE"

echo "User creation and configuration completed. See $LOG_FILE for details."
