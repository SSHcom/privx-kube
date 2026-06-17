#!/usr/bin/env bash

set -euo pipefail

# Check if the certificate file path is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 /path/to/certificate.pem"
    exit 1
fi

# Path to the db certificate file provided as an argument
certificate_file="$1"

function sed_escape() {
    echo "$*" | sed -r 's/([\$\.\*\/\[\\^])/\\\1/g' | sed 's/[]]/\[]]/g'
}

# add_correct_sslrootcert_dir_to_shared_config goes through the content of the
# shared-config.toml file and adds sslrootcert value to
# the db.additional_params section or replaces an existing value to the hardcoded
# /opt/privx/etc/privx-db-trust-anchor.pem
function add_correct_sslrootcert_dir_to_shared_config() {
    local file="/opt/privx/etc/shared-config.toml"

    # get the current parameters and replace sslrootcert if found, insert otherwise
    local old_params="$(sed -nr "/\[db\]/,/\[/ \
        s/^\s*additional_params\s*=\s*\"(.*)\".*$/\1/p" $file)"
    if [[ -z "$old_params" ]]; then
        # no params set, replace entire field
        sed -r "/\[db\]/,/\[/ \
            s/^\s*additional_params\s*=\s*\"[^\"]*\"(.*)$/additional_params = \"sslrootcert=$(sed_escape $certificate_file)\"\1/g" -i $file
    elif [[ "$old_params" =~ "sslrootcert" ]]; then
        # sslrootcert set, override the value
        sed -r "/\[db\]/,/\[/ \
            s/^\s*additional_params\s*=\s*\"(.*)sslrootcert=[^ ]+([^\"]*)\"(.*)$/additional_params = \"\1sslrootcert=$(sed_escape $certificate_file)\2\"\3/g" -i $file
    else
        # other values set but no sslrootcert, append to old values
        sed -r "/\[db\]/,/\[/ \
            s/^\s*additional_params\s*=\s*\"(.*\".*)$/additional_params = \"sslrootcert=$(sed_escape $certificate_file) \1/g" -i $file
    fi
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
