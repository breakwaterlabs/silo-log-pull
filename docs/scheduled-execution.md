# Scheduled Execution Guide

This guide covers automating silo-log-pull to run on a schedule.

## Linux: Cron

Add to crontab for daily execution at 2 AM:

```bash
crontab -e
```

**Container:**
```
0 2 * * * cd /path/to/silo-log-pull/app && docker run --rm -v $(pwd)/data:/data silo-log-pull
```

**Python:**
```
0 2 * * * cd /path/to/silo-log-pull/app && python3 silo_batch_pull.py
```

## Linux: systemd

Create a service file:

```bash
sudo nano /etc/systemd/system/silo-log-pull.service
```

**Container version:**
```ini
[Unit]
Description=Silo Log Pull Service
After=network.target

[Service]
Type=oneshot
User=youruser
WorkingDirectory=/path/to/silo-log-pull/app
ExecStart=/usr/bin/docker run --rm -v /path/to/silo-log-pull/app/data:/data silo-log-pull

[Install]
WantedBy=multi-user.target
```

**Python version:**
```ini
[Unit]
Description=Silo Log Pull Service
After=network.target

[Service]
Type=oneshot
User=youruser
WorkingDirectory=/path/to/silo-log-pull/app
ExecStart=/usr/bin/python3 silo_batch_pull.py

[Install]
WantedBy=multi-user.target
```

Create a timer:

```bash
sudo nano /etc/systemd/system/silo-log-pull.timer
```

```ini
[Unit]
Description=Run Silo Log Pull Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now silo-log-pull.timer
```

Check status:
```bash
systemctl status silo-log-pull.timer
systemctl list-timers
```

## Windows: Task Scheduler

1. Open Task Scheduler
2. Create a new task

**Container (Rancher Desktop):**
- Program: `C:\Program Files\Rancher Desktop\resources\resources\win32\bin\docker.exe`
- Arguments: `run --rm -v C:\silo-log-pull\app\data:/data silo-log-pull`
- Start in: `C:\silo-log-pull\app`

**Python:**
- Program: Path to `python.exe` (e.g., `C:\Users\YourUser\AppData\Local\Programs\Python\Python3XX\python.exe`)
- Arguments: `silo_batch_pull.py`
- Start in: `C:\silo-log-pull\app`

Alternatively, create a batch file (`run_silo.bat`):
```batch
@echo off
cd /d C:\silo-log-pull\app
python silo_batch_pull.py
```

Then schedule the batch file in Task Scheduler.

## Non-Interactive Mode

For automated runs, disable interactive prompts by setting in `silo_config.json`:
```json
"non_interactive": true
```

Or via environment variable:
```bash
export SILO_NON_INTERACTIVE=true
```
