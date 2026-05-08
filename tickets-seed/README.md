# Synthetic ticket seed data

50 realistic tickets across the categories a sole IT analyst sees every week.
Loaded into osTicket on first build (`docker compose up`) so the queue is never empty.

## Categories (target distribution)

| Category | Count | Example |
|---|---|---|
| Password / MFA | 10 | "Locked out of M365 after travel" |
| Outlook / Email | 8 | "Outlook stuck loading profile" |
| Hardware | 7 | "Laptop won't charge — Dell Latitude 5540" |
| M365 license / app access | 6 | "New hire missing Power BI license" |
| Mac-specific | 6 | "FileVault recovery key needed" |
| Printer / peripheral | 5 | "Can't add the conf-room printer on Mac" |
| Network / VPN | 4 | "VPN connects but no internal DNS" |
| Phishing / security | 4 | "User clicked a link, what now?" |

## Format
Each ticket is a Markdown file: subject, body, requester role, expected priority, suggested runbook/script.

Loader: `scripts/Import-SeedTickets.ps1` (Week 1).
