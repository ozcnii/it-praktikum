#!/bin/bash
# Test script to verify Zabbix Agent is collecting metrics

USERNAME=$1
METRIC_TYPE=$2
ZABBIX_SERVER=${3:-127.0.0.1}

if [ -z "$USERNAME" ] || [ -z "$METRIC_TYPE" ]; then
    echo "Usage: $0 <username> <metric_type> [zabbix_server]"
    echo "Example: $0 user1 cpu"
    exit 1
fi

echo "Testing Zabbix Agent metric collection..."
echo "Username: $USERNAME"
echo "Metric Type: $METRIC_TYPE"
echo "Zabbix Server: $ZABBIX_SERVER"
echo ""

# Test using zabbix_get
METRIC_KEY="${USERNAME}.${METRIC_TYPE}"
echo "Testing metric key: $METRIC_KEY"

if command -v zabbix_get &> /dev/null; then
    VALUE=$(zabbix_get -s $ZABBIX_SERVER -k $METRIC_KEY 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✓ Metric value: $VALUE"
    else
        echo "✗ Failed to get metric. Check Zabbix Agent configuration."
    fi
else
    echo "zabbix_get not found. Testing local script..."
    SCRIPT="/srv/team22/${USERNAME}_zabbix/${METRIC_TYPE}_metric.sh"
    if [ -f "$SCRIPT" ]; then
        VALUE=$(bash "$SCRIPT")
        echo "✓ Metric value: $VALUE"
    else
        echo "✗ Script not found: $SCRIPT"
    fi
fi

echo ""
echo "Checking Zabbix Agent logs..."
if [ -f /var/log/zabbix/zabbix_agentd.log ]; then
    echo "Last 10 lines of agent log:"
    tail -10 /var/log/zabbix/zabbix_agentd.log
fi

