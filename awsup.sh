#!/usr/bin/env bash
#
# https://github.com/0x416e746f6e/.aws
#
#

set -eo pipefail
echo "🆙 Starting awsup..."

# Set the target directory
TARGET_DIR="${HOME}/.aws"
REPO_URL="https://github.com/0x416e746f6e/.aws.git"
REPO_BRANCH="main"

# Check if the config or credentials files already exist
CONFIG_FILE="${TARGET_DIR}/config"
CREDENTIALS_FILE="${TARGET_DIR}/credentials"

# Get the current date for the directory names
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="${TARGET_DIR}/backup-${DATE}"
TEMP_DIR="$( pwd )/awsup-${DATE}"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "🚫 Git is not installed. Please install Git and try again."
    exit 1
fi

# Backup the existing .aws directory
handle_file_backup() {
    echo "🔄 Backing up ${TARGET_DIR} to ${BACKUP_DIR}..."
    mkdir -p "${BACKUP_DIR}"

    # Only backup the files, not subdirectories
    for item in "${TARGET_DIR}"/*; do
        if [ -f "${item}" ]; then
            mv "${item}" "${BACKUP_DIR}"
        fi
    done
}

handle_file_backup

handle_installation() {
    echo "🔄 Downloading and installing..."

    mkdir -p "${TEMP_DIR}"
    pushd "${TEMP_DIR}" > /dev/null 2>&1

    git clone "${REPO_URL}" > /dev/null 2>&1
    cd .aws
    git checkout "${REPO_BRANCH}" > /dev/null 2>&1
    rm -rf .git
    cp -r ./* "${TARGET_DIR}/"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|/Users/anton/|$HOME/|g" "${TARGET_DIR}/credentials"
    else
        sed -i "s|/Users/anton/|$HOME/|g" "${TARGET_DIR}/credentials"
    fi

    popd > /dev/null 2>&1

    rm -rf "${TEMP_DIR}"

    echo "✅ Installation complete! To finish setup, run:"
    echo "✨    . ~/.aws/helper.sh --setup"
}

handle_installation
