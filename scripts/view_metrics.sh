#!/bin/bash
# View collected metrics from PostgreSQL

USERNAME=$1
PGHOST=${2:-localhost}
PGUSER=${3:-postgres}
PGDATABASE=${4:-zabbix_metrics}

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username> [pg_host] [pg_user] [pg_database]"
    echo "Example: $0 user1"
    exit 1
fi

TABLE_NAME="${USERNAME}_zabbix"

echo "Viewing metrics for: $USERNAME"
echo "Table: $TABLE_NAME"
echo ""

read -sp "PostgreSQL password: " PGPASSWORD
export PGPASSWORD
echo ""

psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -c \
  "SELECT id, timestamp, metric_type, metric_value FROM $TABLE_NAME ORDER BY timestamp DESC LIMIT 20;"

