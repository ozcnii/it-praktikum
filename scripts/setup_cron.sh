#!/bin/bash
# Setup cron job for automatic metric collection

USERNAME=$1
METRIC_TYPE=$2

if [ -z "$USERNAME" ] || [ -z "$METRIC_TYPE" ]; then
    echo "Usage: $0 <username> <metric_type>"
    echo "Example: $0 user1 cpu"
    exit 1
fi

COLLECT_SCRIPT="/srv/team22/${USERNAME}_zabbix/collect_metrics.sh"
CRON_JOB="*/5 * * * * $COLLECT_SCRIPT"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$COLLECT_SCRIPT"; then
    echo "Cron job already exists for $USERNAME"
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added for $USERNAME (runs every 5 minutes)"
fi

