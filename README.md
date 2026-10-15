# azure-directory-project

> A simulated 25-user IT operation — built, scripted, ticketed, and documented.
> What a real Tier 1 / sole IT analyst week looks like, end-to-end.

![status: in progress](https://img.shields.io/badge/status-in--progress-yellow)
![scope: hybrid AD + M365](https://img.shields.io/badge/scope-hybrid%20AD%20%2B%20M365-blue)
![license: MIT](https://img.shields.io/badge/license-MIT-green)

---

## Why this exists

Most help-desk portfolio projects show isolated skills: a PowerShell snippet here, an AD lab screenshot there. Hiring managers are left to imagine how the candidate would actually run a queue.

This repo skips that step. It's a **simulated production environment** for a fictional 25-user company ("SmallCo Manufacturing") with:

- Hybrid identity (on-prem AD + M365 Dev Tenant + Entra Connect)
- A live ticketing system (osTicket) with a synthetic ticket backlog
- A PowerShell toolkit where every script is mapped to a real ticket category
- A Python/Claude AI agent that triages incoming tickets, suggests KB articles, and drafts responses
- A knowledge base spanning Windows, macOS, M365, and network issues
- A weekly manager-facing operations report with real metrics

If you want to know how I'd handle the first 90 days as your Tier 1 analyst — read the runbooks, look at the closed tickets, and run a script.

---

## The fictional company

**SmallCo Manufacturing**
- 25 users across Operations, Engineering, Finance, Sales, and Leadership
- 1 IT analyst (sole-charge — me)
- 30 endpoints (mix of Windows 11 + macOS), 1 file server, 1 print server, M365 E5 tenant
- Office in Atlanta, GA + 5 remote users
- Existing tools: Microsoft 365, Microsoft Defender, osTicket, Intune, Autopilot

Full architecture: [`docs/architecture/overview.md`](docs/architecture/overview.md)

---

## Repo layout

```
azure-directory-project/
├── docs/
│   ├── architecture/     # Diagrams, design decisions, "why this shape"
│   └── diagrams/         # PNG/SVG assets
├── scripts/              # PowerShell toolkit (one script per ticket category)
│   └── tests/            # Pester smoke tests
├── runbooks/             # Step-by-step procedures (linked from closed tickets)
├── kb/                   # Knowledge base — what end users see
│   ├── windows/
│   ├── macos/
│   ├── m365/
│   └── network/
├── ai-triage/            # Python + Claude agent that reads osTicket and drafts responses
├── reports/              # Weekly manager reports (auto-generated)
└── tickets-seed/         # Synthetic ticket dataset for osTicket
```

---

## Build progress

- [ ] **Week 1** — osTicket up + 10 seeded tickets + 5 KB articles + this README
- [ ] **Week 2** — AD DS + M365 tenant + Entra Connect + first 5 PowerShell scripts
- [ ] **Week 3** — AI triage agent wired to osTicket API
- [ ] **Week 4** — Remaining scripts/KB + weekly report generator + walkthrough video

---

## What I'd do differently in production

(Filled in as the build progresses — this is where judgment shows up.)

---

## License

MIT — see [`LICENSE`](LICENSE).
