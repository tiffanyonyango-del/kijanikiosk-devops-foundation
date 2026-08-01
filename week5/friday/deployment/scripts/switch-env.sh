#!/bin/bash

set -e

TARGET_ENV="$1"

STATE_DIR="/opt/kijanikiosk/state"
ACTIVE_FILE="$STATE_DIR/.active-env"
PREVIOUS_FILE="$STATE_DIR/.previous-env"

NGINX_ACTIVE="/etc/nginx/kijanikiosk-active-env.conf"

if [[ "$TARGET_ENV" != "blue" && "$TARGET_ENV" != "green" ]]; then
    echo "Usage: $0 [blue|green]"
    exit 1
fi

CURRENT_ENV=$(cat "$ACTIVE_FILE")

echo "Current environment : $CURRENT_ENV"
echo "Target environment  : $TARGET_ENV"

if [[ "$CURRENT_ENV" == "$TARGET_ENV" ]]; then
    echo "Already running $TARGET_ENV."
    exit 0
fi

if [[ "$TARGET_ENV" == "green" ]]; then

    EXPECTED_VERSION="1.4.0"

    cat <<EOF | sudo tee "$NGINX_ACTIVE" >/dev/null
upstream kk-api-green {
    server 127.0.0.1:3001;
}

upstream kk-api-active {
    server 127.0.0.1:3001;
}
EOF

else

    EXPECTED_VERSION="1.3.0"

    cat <<EOF | sudo tee "$NGINX_ACTIVE" >/dev/null
upstream kk-api-blue {
    server 127.0.0.1:3000;
}

upstream kk-api-active {
    server 127.0.0.1:3000;
}
EOF

fi

echo "Testing nginx..."

sudo nginx -t

echo "Reloading nginx..."

sudo systemctl reload nginx

echo "Checking application health..."

MAX_RETRIES=10
RETRY=1

while [ "$RETRY" -le "$MAX_RETRIES" ]; do

    RESPONSE=$(curl -s http://localhost/health || true)

    echo "Health check $RETRY/$MAX_RETRIES: $RESPONSE"

    if echo "$RESPONSE" | grep -q "\"status\":\"healthy\"" &&
       echo "$RESPONSE" | grep -q "\"version\":\"$EXPECTED_VERSION\""; then

        echo "Expected version $EXPECTED_VERSION is serving through nginx."

        echo "$CURRENT_ENV" | sudo tee "$PREVIOUS_FILE" >/dev/null
        echo "$TARGET_ENV" | sudo tee "$ACTIVE_FILE" >/dev/null

        echo "Switch completed successfully."

        exit 0
    fi

    sleep 1
    RETRY=$((RETRY + 1))

done

echo "ERROR: Expected version $EXPECTED_VERSION was not detected through nginx."

exit 1