#!/bin/bash

# Find all wp-config.php files
WP_CONFIG_FILES=$(find ~/webapps -name wp-config.php)

if [ -z "$WP_CONFIG_FILES" ]; then
    echo "No wp-config.php files found in ~/webapps"
    exit 1
fi

# Function to process a single wp-config.php file
process_wp_config() {
    local WP_CONFIG_PATH="$1"
    echo "Processing: $WP_CONFIG_PATH"

    # Extract database credentials from wp-config.php
    local DB_HOST=$(grep DB_HOST "$WP_CONFIG_PATH" | awk -F "['\"]" '{print $4}')
    local DB_USER=$(grep DB_USER "$WP_CONFIG_PATH" | awk -F "['\"]" '{print $4}')
    local DB_PASS=$(grep DB_PASSWORD "$WP_CONFIG_PATH" | awk -F "['\"]" '{print $4}')
    local DB_NAME=$(grep DB_NAME "$WP_CONFIG_PATH" | awk -F "['\"]" '{print $4}')

    # Verify that all variables are set
    if [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ]; then
        echo "Failed to extract all database credentials from $WP_CONFIG_PATH"
        return
    fi

    echo "Database: $DB_NAME"

    # Delete completed actions
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DELETE FROM wp_actionscheduler_actions WHERE status = 'complete';"

    # Delete failed actions
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DELETE FROM wp_actionscheduler_actions WHERE status = 'failed';"

    # Clean up the logs
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DELETE FROM wp_actionscheduler_logs WHERE action_id NOT IN (SELECT action_id FROM wp_actionscheduler_actions);"

    echo "Cleanup completed for $DB_NAME"
    echo "-----------------------------"
}

# Process each wp-config.php file
echo "Found $(echo "$WP_CONFIG_FILES" | wc -l) WordPress installations"
echo

while IFS= read -r config_file; do
    process_wp_config "$config_file"
done <<< "$WP_CONFIG_FILES"

echo "All WordPress installations processed."