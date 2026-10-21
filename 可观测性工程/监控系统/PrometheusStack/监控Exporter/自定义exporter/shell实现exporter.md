用 shell 适合一些简单的指标导出（通常是不需要进行计算的指标）

```bash
#!/usr/bin/env bash

generate_metrics() {
    STATS=$(cat /proc/fs/cifs/Stats)
    mids=$(echo "$STATS" | awk -F': *' '/Operations \(MIDs\)/ {print $2}')
    vfs_max=$(echo "$STATS" | awk '/Total vfs operations/ {
        for (i=1;i<=NF;i++) if ($i=="time:") print $(i+1)
    }')
    vfs_total=$(echo "$STATS" | awk '/Total vfs operations/ {print $4}')
    session_recon=$(echo "$STATS" | awk '/session.*share reconnects/ {print $1}')
    share_recon=$(echo "$STATS" | awk '/session.*share reconnects/ {print $3}')
    cat <<EOF
# HELP cifs_operations_mids Current outstanding SMB operations (MIDs)
# TYPE cifs_operations_mids gauge
cifs_operations_mids{node_name="${NODE_NAME}"} ${mids:-0}

# HELP cifs_session_reconnects_total Total CIFS session reconnects
# TYPE cifs_session_reconnects_total counter
cifs_session_reconnects_total{node_name="${NODE_NAME}"} ${session_recon:-0}

# HELP cifs_share_reconnects_total Total CIFS share reconnects
# TYPE cifs_share_reconnects_total counter
cifs_share_reconnects_total{node_name="${NODE_NAME}"} ${share_recon:-0}

# HELP cifs_vfs_operations_total Total VFS operations on CIFS mounts
# TYPE cifs_vfs_operations_total counter
cifs_vfs_operations_total{node_name="${NODE_NAME}"} ${vfs_total:-0}

# HELP cifs_vfs_operations_max Peak simultaneous VFS operations
# TYPE cifs_vfs_operations_max gauge
cifs_vfs_operations_max{node_name="${NODE_NAME}"} ${vfs_max:-0}
EOF
}

handle_request() {
    # shellcheck disable=SC2155
    local body=$(generate_metrics)
    local length=${#body}
    
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: text/plain; version=0.0.4\r\n"
    printf "Content-Length: %d\r\n" "$length"
    printf "Connection: close\r\n"
    printf "\r\n"
    printf "%s" "$body"
}

export -f generate_metrics
export -f handle_request

socat TCP-LISTEN:9780,reuseaddr,fork EXEC:"bash -c 'handle_request'"

```

