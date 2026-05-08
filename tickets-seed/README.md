# Synthetic ticket seed data

50 realistic tickets across the categories a sole IT analyst sees every week.
Loaded into osTicket on first build via `scripts/Import-SeedTickets.ps1` (Week 1).

## Why these tickets exist

A queue with no tickets in it is a fancy screenshot. A queue with 50 well-chosen tickets — each linked to a runbook, KB article, and PowerShell script — is *operations*. The seed set is intentionally weighted toward the categories that matter for the JDs Garfield is targeting:

- MFA / Conditional Access (every modern helpdesk)
- Outlook / Exchange Online (top ticket volume)
- Hardware + imaging (Tier 1 bread and butter)
- M365 license + app access (admin work, not user work)
- Mac-specific (closes the recurring Mac gap)
- Printer/peripheral (legacy but unavoidable)
- Network / VPN (the "is the internet down" calls)
- Phishing / security incident (the cyber differentiator)

## Format

Each ticket is a Markdown file with YAML frontmatter:

```yaml
---
id: T###
priority: P1 | P2 | P3
category: <one of the 8 categories above>
requester: <fictional UPN>
requester_role: <role + context>
expected_runbook: <path to the runbook this ticket exercises>
expected_script: <path to the PowerShell script if applicable>
ai_triage_target_category: <category the AI agent should classify this as>
created: <ISO 8601>
---
```

Body uses three sections: **Subject**, **Body** (what the user actually wrote — realistic, sometimes confused), and **Notes for the analyst** (resolution path).

## Distribution target

| Category | Count | Files |
|---|---|---|
| Password / MFA | 10 | T001-T010 |
| Outlook / Email | 8 | T011-T018 |
| Hardware | 7 | T019-T025 |
| M365 license / app | 6 | T026-T031 |
| Mac-specific | 6 | T032-T037 |
| Printer / peripheral | 5 | T038-T042 |
| Network / VPN | 4 | T043-T046 |
| Phishing / security | 4 | T047-T050 |

## See also

- [`tickets-seed/T001-mfa-locked-after-travel.md`](T001-mfa-locked-after-travel.md) — first seed ticket
- [Import-SeedTickets.ps1](../scripts/Import-SeedTickets.ps1) — loader (Week 1)
