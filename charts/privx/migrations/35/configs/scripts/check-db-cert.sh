#!/usr/bin/env bash

set -euo pipefail

# Check if the certificate file path is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 /path/to/certificate.pem"
    exit 1
fi

# Path to the db certificate file provided as an argument
certificate_file="$1"

# modify_string converts input patterns to the output formats as follows:
# 'additional_params = "sslrootcert=/some/other/dir alpha=val1"' -> 'additional_params = "sslrootcert=/opt/privx/etc/privx-db-trust-anchor.pem alpha=val1"'
# 'additional_params = "alpha=val1 sslrootcert=/some/other/dir"' -> 'additional_params = "alpha=val1 sslrootcert=/opt/privx/etc/privx-db-trust-anchor.pem"'
# 'additional_params = ""' -> 'additional_params = "sslrootcert=/opt/privx/etc/privx-db-trust-anchor.pem"'
# 'additional_params="randomstring"' -> 'additional_params = "randomstring sslrootcert=/opt/privx/etc/privx-db-trust-anchor.pem'
# 'additional_params = "alpha=val1"' -> 'additional_params = "alpha=val1 sslrootcert=/opt/privx/etc/privx-db-trust-anchor.pem"'
function modify_string() {
    local input_str="$1"
    local pattern="sslrootcert="
    local pattern_to_replace=${pattern}'([^ \"]+)'
    local replacement="/opt/privx/etc/privx-db-trust-anchor.pem"

    if [[ "$input_str" =~ $pattern_to_replace ]]; then
       modified_str="${input_str//${BASH_REMATCH[1]}/$replacement}"
    elif [[ "$input_str" =~ (additional_params = \".*)\" ]]; then
        modified_str="${BASH_REMATCH[1]} $pattern$replacement\""
    else
        modified_str="$input_str"
    fi
    echo "$modified_str"
}

# add_correct_sslrootcert_dir_to_shared_config goes through the content of the
# shared-config.toml file and adds sslrootcert value to
# the db.additional_params section or replaces an existing value to the hardcoded
# /opt/privx/etc/privx-db-trust-anchor.pem
function add_correct_sslrootcert_dir_to_shared_config() {
    input_file="/opt/privx/etc/shared-config.toml"

    temp_file=${input_file}.tmp

    # Read input file line by line
    while IFS= read -r line; do
        if [[ $line == *"additional_params"* ]]; then
            modified_line=$(modify_string "$line")
            echo "$modified_line" >> "$temp_file"
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$input_file"

    mv "$temp_file" "$input_file"
}

# Check if the certificate file exists
if [ -f "$certificate_file" ]; then
    cert_contents="BEGIN CERTIFICATE"

    # Check if the file is a certificate. If it isn't then don't do anything
    # but if it is then it means that a db server certitificate is provided
    # and hence the path (sslrootcert) to it should be set in the variable
    # db.additional_params in shared-config.toml file if SSLMODE is either
    # verify-full or verify-ca.
    if grep -qF "$cert_contents" "$certificate_file"; then
        if [ "$SSLMODE" = "verify-full" ] || [ "$SSLMODE" = "verify-ca" ]; then
            echo "Adding sslrootcert=/opt/privx/etc/privx-db-trust-anchor.pem to shared-config.toml"
            add_correct_sslrootcert_dir_to_shared_config
        else
            echo "DB certificate found but db.sslmode=\"$SSLMODE\" in shared-config.toml. It should preferrably be \"verify-full\" or \"verify-ca\" instead."
        fi
    else
        echo "No valid DB certificate found hence no changes required for sslrootcert in db.additional_params in shared-config.toml file."
    fi
else
    echo "Certificate file not found. Nothing to change in shared-config.toml"
fi
