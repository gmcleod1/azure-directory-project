# Setup — Local osTicket Stack

Brings up the SmallCo Manufacturing ticket queue locally. ~10 minutes.

## Prerequisites

- **Docker Desktop** (Windows or macOS): https://www.docker.com/products/docker-desktop/
  - Windows: requires WSL2; the installer enables it for you.
  - After install, launch Docker Desktop once and let it finish initializing before continuing.
- ~2 GB free RAM, ~1 GB free disk.

## 1. Configure secrets

```powershell
# from the repo root
Copy-Item .env.example .env
```

Open `.env` and replace the three placeholder values with strong random strings.
Quick PowerShell generator:

```powershell
1..3 | ForEach-Object { -join ((48..57)+(65..90)+(97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_}) }
```

`.env` is gitignored — it never gets pushed.

## 2. Bring up the stack

```powershell
docker compose up -d
docker compose logs -f osticket    # Ctrl+C once you see "Apache started"
```

First boot pulls ~500 MB of images and runs DB init — give it 60-90 seconds.

## 3. Run the osTicket install wizard

Open **http://localhost:8080** in your browser. You'll see the osTicket installer.

Use these inputs:

| Field | Value |
|---|---|
| Helpdesk Name | `SmallCo Manufacturing IT` |
| Default Email | `helpdesk@smallco.example` |
| Admin User First/Last | `Garfield McLeod` (or your preferred admin identity) |
| Admin Email | your real email — used for password recovery |
| Admin Username | `gmcleod` |
| Admin Password | a strong password — store in your password manager |
| MySQL Hostname | `db` |
| MySQL Database | `osticket` |
| MySQL Username | `osticket` |
| MySQL Password | the value of `MARIADB_PASSWORD` from your `.env` |

Click **Install Now**. You should see "osTicket installed successfully."

## 4. Lock down the installer

The installer warns to delete `setup/` after install. Run:

```powershell
docker compose exec osticket rm -rf /var/www/html/setup
```

## 5. Verify

- Staff portal: **http://localhost:8080/scp** — log in with the admin account from step 3
- End-user portal: **http://localhost:8080**

You're now running the same kind of ticket queue you'd inherit on day one of any helpdesk role.

## Common operations

```powershell
docker compose down              # stop, keep ticket data
docker compose up -d             # start again
docker compose logs -f           # tail logs from both services
docker compose down -v           # WIPE everything (ticket data gone)
docker compose pull              # update to newer osTicket image (after editing version in compose)
```

## Backups

Ticket data lives in two named Docker volumes: `smallco-it-ops_db_data` and `smallco-it-ops_osticket_data`. To back up the database:

```powershell
docker compose exec db sh -c 'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" osticket' > backups/osticket-$(Get-Date -Format yyyy-MM-dd).sql
```

(Backups folder is gitignored.)

## Troubleshooting

- **Port 8080 already in use** → edit the `ports` line in `docker-compose.yml` to `"8081:80"` and restart.
- **DB connection refused on first install** → the DB container is still initializing. Wait 30 seconds, refresh.
- **`WSL 2 is not installed`** on Windows → run `wsl --install` from an elevated PowerShell, reboot, retry.
