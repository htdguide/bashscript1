# User and Backup Script Project

## Author Details
- **Nikita Mogilevskii** 

## Project Details

### Task 1: User Creation Script

#### Summary
This script automates the process of creating multiple user accounts on a Linux system from a CSV file. It sets user passwords, adds users to specified groups, creates shared folders, and ensures users change their password on first login. The script handles both local files and web-based resources for input CSV data.

#### Pre-requisites
- Linux operating system with `bash` shell.
- `sudo` privileges.
- `wget` installed for downloading CSV from web resources.
- The CSV file must have the following columns: `email, birth_date, groups, shared_folder`.

#### Instructions
1. **Download and prepare the script:**
    ```sh
    wget -O Task1.sh [URL to the script]
    chmod +x Task1.sh
    dos2unix Task1.sh
    ```
2. **Run the script with a local CSV file:**
    ```sh
    sudo ./Task1.sh /path/to/local/users.csv
    ```
3. **Run the script with a CSV file from a URI:**
    ```sh
    sudo ./Task1.sh http://example.com/users.csv
    ```
4. **If no arguments are provided, the script will prompt for input:**
    ```sh
    sudo ./Task1.sh
    ```

### Task 2: Backup Script

#### Summary
This script compresses a given directory into a `.tar.gz` archive and uploads it to a specified remote server using `scp`. The script accepts the target directory as an argument or prompts for it if no argument is provided. It also handles network and directory validation errors.

#### Pre-requisites
- Linux operating system with `bash` shell.
- `scp` installed for file transfer.
- `ssh` access to the remote server.
- Ensure the user has write permissions to the target directory on the remote server.

#### Instructions
1. **Download and prepare the script:**
    ```sh
    wget -O Task2.sh [URL to the script]
    chmod +x Task2.sh
    dos2unix Task2.sh
    ```
2. **Run the script with a target directory as an argument:**
    ```sh
    ./Task2.sh /path/to/local/directory
    ```
3. **If no arguments are provided, the script will prompt for input:**
    ```sh
    ./Task2.sh
    ```

#### Example Commands
- **With a local CSV file for Task 1:**
    ```sh
    sudo ./Task1.sh /mnt/data/users.csv
    ```
- **With a CSV file URL for Task 1:**
    ```sh
    sudo ./Task1.sh http://example.com/users.csv
    ```
- **With a directory argument for Task 2:**
    ```sh
    ./Task2.sh /home/user/documents
    ```
- **Without arguments (prompted for input) for Task 2:**
    ```sh
    ./Task2.sh
    ```
