#!/bin/bash
# Nagios Plugin Bash Script - check_crl.sh
#
# This script does a simple curl of a targeted HTTP CRL URL and pipes the content into OpenSSL for
# examination. The primary purpose is to check the nextUpdate value of the CRL. In a PKI, the CRL
# must be monitored for expiration. If it expires, the PKI may cease to function as CRL checks may
# fail during SSL sessions.
#

# Check the input provided to the script, throw usage if missing
if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]]; then
        echo "Invalid arguments passed to $0."
        echo "  Usage:"
        echo "  $0 <CDP URL> <CRL FORMAT> <WARNING DAYS> <CRITICAL DAYS>"
        echo "CRITICAL - Invalid arguments passed to $0"
        exit 2
fi

# get that CRL from the input CDP URL
sslOut=$(curl --silent $1 | openssl crl -inform $2 -lastupdate -nextupdate | grep nextUpdate | sed -e 's#nextUpdate=##')

# use date to convert the openssl output to a datetime object expressed in seconds
crlDate=$(date --date="$sslOut" +%s)

# magic math
nowDate=$(date +%s)
dateDiff=$(expr $crlDate - $nowDate)
expDays=$(expr $dateDiff / 86400)

# if the date is less than the warning or critical days, exit 0
if [[ $expDays -gt $3 ]] && [[ $expDays -gt $4 ]]; then
        echo "OK - $expDays days until CRL expires"
        exit 0
fi

# if the date is less than the warning days but more than the critical days, exit 1
if [[ $expDays -le $3 ]] && [[ $expDays -gt $4 ]]; then
        echo "WARNING - $1 expires in $expDays days"
        exit 1
fi

# if the date is less than the warning and critical days, exit 2
if [[ $expDays -lt $3 ]] && [[ $expDays -le $4 ]]; then
        echo "CRITICAL - CRL $1 is expired!"
        exit 2
fi
