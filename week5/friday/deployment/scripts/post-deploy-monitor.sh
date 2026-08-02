#!/bin/bash

set -e

WINDOW=${1:-60}

HEALTH_URL="http://localhost/health"
STATE_FILE="/opt/kijanikiosk/state/.active-env"

CHECK_INTERVAL=5
MAX_FAILURES=$((WINDOW / CHECK_INTERVAL))

FAILURES=0

echo "========================================"
echo "KijaniKiosk Post Deployment Monitor"
echo "Confidence Window : ${WINDOW}s"
echo "Polling Interval  : ${CHECK_INTERVAL}s"
echo "========================================"

while true
do
    ACTIVE=$(cat "$STATE_FILE")

    RESPONSE=$(curl -s "$HEALTH_URL" || true)

    if echo "$RESPONSE" | grep -q "\"status\":\"healthy\""; then

        FAILURES=0

        echo "$(date '+%H:%M:%S') [OK] ${ACTIVE} healthy"

    else

        FAILURES=$((FAILURES + 1))

        echo "$(date '+%H:%M:%S') [FAIL ${FAILURES}/${MAX_FAILURES}] Health check failed"

        if [ "$FAILURES" -ge "$MAX_FAILURES" ]; then

            echo "$(date '+%H:%M:%S') [MONITOR FAIL] ROLLBACK TRIGGERED"

            if [ "$ACTIVE" = "green" ]; then
                sudo bash /opt/kijanikiosk/scripts/switch-env.sh blue
            else
                sudo bash /opt/kijanikiosk/scripts/switch-env.sh green
            fi

            echo "$(date '+%H:%M:%S') Rollback complete."

            exit 0
        fi
    fi

    sleep "$CHECK_INTERVAL"

done