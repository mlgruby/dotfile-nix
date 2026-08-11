# 🚨 Incident Report: LXCHighDiskWrite Alert Diagnosis

An investigation was conducted to diagnose the `LXCHighDiskWrite` alert on the Proxmox Virtual Environment (PVE) cluster. Below is the detailed breakdown of the root cause, metrics, and actionable resolution steps.

---

## 🔍 Executive Summary

* **Alert Name:** `LXCHighDiskWrite`
* **Root Cause Container:** `utility` (VMID **`118`**)
* **Host Machine:** `pve1` (`192.168.10.12`)
* **Process Culprit:** `agentsview-postgres` nested Docker container (Host PID **`182297`**)
* **Issue Description:** The database backing the `agentsview` container is being hammered by high-frequency insert statements, specifically writing verbose application trace logs and tool execution histories to the disk.

---

## 📊 Process Disk Write Metrics

Inside the `utility` container (VMID `118`), individual Postgres child processes under the `agentsview-postgres` namespace are responsible for hundreds of gigabytes of cumulative disk writes:

| Host PID | Process Name | Container Name | Total Write Bytes | Total Write (GB) |
| :--- | :--- | :--- | :--- | :--- |
| **`182819`** | `postgres` | `/agentsview-postgres` | `395,134,894,080` | **~395 GB** |
| **`182813`** | `postgres` | `/agentsview-postgres` | `103,525,793,792` | **~103 GB** |
| **`182297`** | `postgres` (Parent) | `/agentsview-postgres` | `90,936,778,752` | **~91 GB** |
| **`182814`** | `postgres` | `/agentsview-postgres` | `1,847,148,544` | **~1.8 GB** |

---

## 🛠️ Root Cause Details

### 1. Active Query Hotspot
The main query generating continuous high I/O write locks:
```sql
INSERT INTO agents_logs (agent_id, session_id, log_level, message, created_at) 
VALUES ($1, $2, $3, $4, NOW());
```

### 2. Large Tables in `agentsview` Database
The database `agentsview` is storing heavy JSON payloads for agent telemetry:
* **`agentsview.messages`** size: **`227 MB`** (contains raw prompt & context histories)
* **`agentsview.tool_calls`** size: **`44 MB`** (contains full execution responses and logs)
* **Total Database Size:** **`287 MB`**

---

## 💡 Troubleshooting & Resolution Steps

### Option A: Lower the Log Level (Recommended)
By default, the `agentsview` app seems to run in a highly verbose logging mode. You can check the environment variables of the `agentsview` container to configure a higher log level threshold (e.g. `error` or `warn`).
1. Inspect or edit `docker-compose.yml` for `agentsview`.
2. Look for `LOG_LEVEL` or `DEBUG` and set it to a less verbose setting.

### Option B: Purge Historical Telemetry
To reclaim space and reduce indexes overhead, connect to the database and truncate or delete older logs and messages:
```bash
# Connect to the DB
docker exec -it agentsview-postgres psql -U agentsview -d agentsview

# Run cleanup (e.g., delete sessions older than 7 days)
DELETE FROM agentsview.sessions WHERE created_at < NOW() - INTERVAL '7 days';
```
*(Postgres cascading foreign keys should clean up corresponding entries in `messages` and `tool_calls`).*
