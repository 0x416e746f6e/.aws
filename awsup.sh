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

# Check if the config or credentials files already exist
CONFIG_FILE="${TARGET_DIR}/config"
CREDENTIALS_FILE="${TARGET_DIR}/credentials"
LOGIN_FILE="${TARGET_DIR}/login.sh"

# Get the current date for the backup folder
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="${TARGET_DIR}/backup-${DATE}"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "🚫 Git is not installed. Please install Git and try again."
    exit 1
fi

handle_file_backup() {
    mkdir -p "${BACKUP_DIR}"

    # Only backup the files, not subdirectories
    mv "${TARGET_DIR}"/* "${BACKUP_DIR}/"
    echo "ℹ️ ${TARGET_DIR} has been backed up to ${BACKUP_DIR}."
}

# Backup the existing .aws directory
handle_file_backup

# Clone the repository
git clone "${REPO_URL}" "${TARGET_DIR}"
rm -rf ~/.aws/.git

echo "✅ Installation complete!"

echo "ℹ️ Starting setup..."
. ${LOGIN_FILE} --setup
