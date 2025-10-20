#!/bin/sh
set -e

# Default to not running on startup unless explicitly set
RUN_ON_STARTUP=${RUN_ON_STARTUP:-false}

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@"
}

# Function to run autotune job
run_autotune_job() {
    log "Starting autotune job..."
    /bin/sh -c "nightscout-autotune" 2>&1 | tee -a /var/log/autotune/autotune.log
    log "Autotune job completed"
}

# If no CRON_SCHEDULE is set, run once and exit (original behavior)
if [ -z "${CRON_SCHEDULE}" ]; then
    log "No CRON_SCHEDULE set, running in one-shot mode"
    run_autotune_job
    exit 0
fi

log "Starting autotune in cron mode with schedule: ${CRON_SCHEDULE}"

# Create cron job script that includes all environment variables
cat > /usr/local/bin/autotune-cron-job.sh << 'EOF'
#!/bin/sh
# Export all environment variables for the cron job
export NS_HOST="${NS_HOST}"
export AUTOTUNE_DAYS="${AUTOTUNE_DAYS}"
export UAM_AS_BASAL="${UAM_AS_BASAL}"
export NS_API_SECRET="${NS_API_SECRET}"
export NS_TOKEN="${NS_TOKEN}"
export NS_PROFILE="${NS_PROFILE}"
export MIN_5MIN_CARBIMPACT="${MIN_5MIN_CARBIMPACT}"
export AUTOSENS_MIN="${AUTOSENS_MIN}"
export AUTOSENS_MAX="${AUTOSENS_MAX}"
export INSULIN_TYPE="${INSULIN_TYPE}"
export OPENAPS_WORKDIR="${OPENAPS_WORKDIR}"
export HTML_EXPORT="${HTML_EXPORT}"

# Execute the autotune script
/bin/sh -c "nightscout-autotune" >> /var/log/autotune/autotune.log 2>&1
EOF

chmod +x /usr/local/bin/autotune-cron-job.sh

# Create crontab entry
echo "${CRON_SCHEDULE} /usr/local/bin/autotune-cron-job.sh" > /etc/crontabs/root

# Run immediately on startup if requested
if [ "${RUN_ON_STARTUP}" = "true" ]; then
    log "RUN_ON_STARTUP=true, executing initial run..."
    run_autotune_job
fi

# Start cron in foreground
log "Starting cron daemon..."
log "Next scheduled runs will be logged to /var/log/autotune/autotune.log"
log "Cron schedule: ${CRON_SCHEDULE}"

# Ensure log file exists
touch /var/log/autotune/autotune.log

# Start crond in background mode (to avoid setpgid issues with foreground mode)
crond -l 2

# Keep container alive by tailing the log file
exec tail -f /var/log/autotune/autotune.log
