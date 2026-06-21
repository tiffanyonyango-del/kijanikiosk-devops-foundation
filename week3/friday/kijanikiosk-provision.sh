#!/bin/bash

# ==========================================
# KijaniKiosk Provisioning Script
# ==========================================
# This script builds the required system
# state for the KijaniKiosk environment.
#
# It is designed to be idempotent:# meaning it can run multiple times safely.
# =========================================

echo "Starting KijaniKiosk provisioning..."

# ------------------------------------------
# PHASE 0: Pre-check / system awareness
# ------------------------------------------

echo "Checking current system state..."

# (We will fill this in later if needed)

# ------------------------------------------
# PHASE 1: Users
# ------------------------------------------
echo "Starting Phase 1: Users and Group setup..."

# --- Users ---
for user in kk-api kk-payments kk-logs; do
    id "$user" &>/dev/null

    if [ $? -ne 0 ]; then
        sudo useradd -m "$user"
        echo "Created user: $user"
    else
        echo "User already exists: $user"
    fi
done

# --- Group ---
getent group kijanikiosk &>/dev/null

if [ $? -ne 0 ]; then
    sudo groupadd kijanikiosk
    echo "Created group: kijanikiosk"
else
    echo "Group already exists: kijanikiosk"
fi

echo "Phase 1 complete"
# ------------------------------------------
#PHASE 2: Group
# ------------------------------------------
echo "Starting Phase 2: Directory setup..."

BASE_DIR="/opt/kijanikiosk"

# Create main structure
sudo mkdir -p "$BASE_DIR"
sudo mkdir -p "$BASE_DIR/config"
sudo mkdir -p "$BASE_DIR/shared/logs"
sudo mkdir -p "$BASE_DIR/health"

# Ensure ownership is safe for later phases
sudo chown -R root:kijanikiosk "$BASE_DIR"

# Basic permissions (safe baseline)
sudo chmod -R 750 "$BASE_DIR"

echo "Phase 2 complete: directories created and secured"
# ------------------------------------------
# PHASE 3: Directory structure
# ------------------------------------------
echo "Starting Phase 3: systemd service setup..."

# -------------------------
# kk-api service
# -------------------------
sudo bash -c 'cat > /etc/systemd/system/kk-api.service <<EOF
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
User=kk-api
Group=kijanikiosk
ExecStart=/bin/bash -c "while true; do sleep 60; done"
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# -------------------------
# kk-payments service
# -------------------------
sudo bash -c 'cat > /etc/systemd/system/kk-payments.service <<EOF
[Unit]
Description=KijaniKiosk Payments Service
After=network.target

[Service]
User=kk-payments
Group=kijanikiosk
ExecStart=/bin/bash -c "while true; do sleep 60; done"
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# -------------------------
# kk-logs service
# -------------------------
sudo bash -c 'cat > /etc/systemd/system/kk-logs.service <<EOF
[Unit]
Description=KijaniKiosk Logs Service
After=network.target

[Service]
User=kk-logs
Group=kijanikiosk
ExecStart=/bin/bash -c "while true; do sleep 60; done"
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd so it sees new services
sudo systemctl daemon-reload

# Enable services (start on boot)
sudo systemctl enable kk-api
sudo systemctl enable kk-payments
sudo systemctl enable kk-logs

echo "Phase 3 complete: services installed and enabled"

#-------------------------------------------
# PHASE 4: Permissions
# ------------------------------------------
echo "Starting Phase 4: Firewall setup..."

# Ensure ufw exists
if ! command -v ufw &>/dev/null; then
    echo "UFW not installed - installing..."
    sudo apt-get update -y
    sudo apt-get install ufw -y
fi

# Reset firewall to clean baseline
sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH access
sudo ufw allow 22/tcp comment 'Allow SSH access'

# HTTP access
sudo ufw allow 80/tcp comment 'Allow HTTP traffic'

# Payments port (loopback allowed first idea)
sudo ufw allow from 127.0.0.1 to any port 3001 comment 'Allow local payments access'

# Block external access to payments port
sudo ufw deny 3001 comment 'Block external access to payments service'

# Enable firewall
sudo ufw --force enable

echo "Phase 4 complete: firewall configured"

# ------------------------------------------
# PHASE 5: Services (if any)
# ------------------------------------------
echo "Starting Phase 5: Health check..."

HEALTH_DIR="/opt/kijanikiosk/health"
HEALTH_FILE="$HEALTH_DIR/last-provision.json"

sudo mkdir -p "$HEALTH_DIR"

# Check services (simple port checks)
api_status="down"
payments_status="down"

# kk-api assumed port 3000
if timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null; then
    api_status="ok"
fi

# kk-payments assumed port 3001
if timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null; then
    payments_status="ok"
fi

# Write JSON output
printf '{"timestamp":"%s","kk-api":"%s","kk-payments":"%s"}\n' \
"$(date -Is)" "$api_status" "$payments_status" | sudo tee "$HEALTH_FILE" > /dev/null

# Set permissions
sudo chown kk-logs:kijanikiosk "$HEALTH_FILE"
sudo chmod 640 "$HEALTH_FILE"

echo "Phase 5 complete: health check written"

# ------------------------------------------
# PHASE 6: LOG CAPTURE (DIRTY/ CLEAN RUNS)
# ------------------------------------------

echo "Starting Phase 6: Logging setup..."

LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

# Always generate a timestamped log file
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

LOG_FILE="$LOG_DIR/provision-run-$TIMESTAMP.log"

echo "Logging to $LOG_FILE"

# Capture everything from this point onward
exec > >(tee "$LOG_FILE") 2>&1

echo "Phase 6 complete: logging active"

#------------------------------------------------
# PHASE 7:JOURNAL + LOGROTATE (SIMPLIFIED)
#------------------------------------------------

echo "Starting Phase 7: log rotation setup..."

# Enable persistent journal storage
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal 2>/dev/null

# Create simple logrotate config
sudo bash -c 'cat > /etc/logrotate.d/kijanikiosk <<EOF
/opt/kijanikiosk/shared/logs/*.log {
    daily
    rotate 3
    missingok
    notifempty
    compress
    create 640 kk-logs kijanikiosk
}
EOF'

echo "Logrotate config created"

# Validate config (safe check)
sudo logrotate --debug /etc/logrotate.d/kijanikiosk || true

echo "Phase 7 complete"

# ------------------------------------------
# PHASE 8: Final Verification
# ------------------------------------------

echo "Starting Phase 8: verification..."

FAILED=0

# Check users
for user in kk-api kk-payments kk-logs; do
    id "$user" &>/dev/null || { echo "FAIL: user $user missing"; FAILED=1; }
done

# Check directory
[ -d /opt/kijanikiosk ] || { echo "FAIL: base directory missing"; FAILED=1; }

# Check services
systemctl is-active --quiet kk-api || { echo "FAIL: kk-api not running"; FAILED=1; }
systemctl is-active --quiet kk-payments || { echo "FAIL: kk-payments not running"; FAILED=1; }
systemctl is-active --quiet kk-logs || { echo "FAIL: kk-logs not running"; FAILED=1; }

# Check health file
[ -f /opt/kijanikiosk/health/last-provision.json ] || { echo "FAIL: health file missing"; FAILED=1; }

if [ "$FAILED" -eq 0 ]; then
    echo "ALL CHECKS PASSED"
    exit 0
else
    echo "SOME CHECKS FAILED"
    exit 1
fi
