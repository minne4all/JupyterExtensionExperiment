#!/bin/bash
set -e

NOTEBOOKS_A="/etc/skel/Experiment_notebooks_A"
NOTEBOOKS_B="/etc/skel/Experiment_notebooks_B"
TARGET_DIR="/home/jovyan/Experiment_notebooks"
LOG_DIR="/home/jovyan/logs"
CONDITION_FILE="$LOG_DIR/condition.txt"

# Copy logs directory if it doesn't exist yet
if [ ! -d "$LOG_DIR" ]; then
    cp -r /etc/skel/logs "$LOG_DIR"
    chown -R jovyan:users "$LOG_DIR"
fi

# Only assign notebooks and set up condition if not already done
if [ ! -d "$TARGET_DIR" ]; then
    HASH=$(echo $JUPYTERHUB_USER | cksum | awk '{print $1}')
    if (( $HASH % 2 == 0 )); then
        cp -r "$NOTEBOOKS_A" "$TARGET_DIR"
        echo "A" > "$CONDITION_FILE"

        # Disable extension for condition A
        EXT_DIR="/home/jovyan/.jupyter/lab/user-settings/@exploratoryjupyterextension/log-plugin"
        mkdir -p "$EXT_DIR"
        echo '{ "enabled": false }' > "$EXT_DIR/plugin.jupyterlab-settings"
        chown -R jovyan:users "$EXT_DIR"
    else
        cp -r "$NOTEBOOKS_B" "$TARGET_DIR"
        echo "B" > "$CONDITION_FILE"
    fi
    chown -R jovyan:users "$TARGET_DIR" "$CONDITION_FILE"
fi

exec "$@"
