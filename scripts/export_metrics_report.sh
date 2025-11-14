#!/bin/bash
# Export metrics from PostgreSQL to CSV report

USERNAME=$1
PGHOST=${2:-localhost}
PGUSER=${3:-postgres}
PGDATABASE=${4:-zabbix_metrics}
OUTPUT_FILE=${5:-"${USERNAME}_metrics_report.csv"}

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username> [pg_host] [pg_user] [pg_database] [output_file]"
    echo "Example: $0 user1"
    exit 1
fi

TABLE_NAME="${USERNAME}_zabbix"

echo "Exporting metrics for: $USERNAME"
echo "Output file: $OUTPUT_FILE"

read -sp "PostgreSQL password: " PGPASSWORD
export PGPASSWORD
echo ""

psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -c \
  "COPY (SELECT id, timestamp, metric_type, metric_value, created_at FROM $TABLE_NAME ORDER BY timestamp DESC) TO STDOUT WITH CSV HEADER;" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Metrics exported successfully to $OUTPUT_FILE"
    echo "Total lines: $(wc -l < "$OUTPUT_FILE")"
else
    echo "✗ Export failed"
    exit 1
fi

