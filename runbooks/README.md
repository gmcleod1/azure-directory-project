# Runbooks

Step-by-step procedures the analyst follows on real tickets. Each runbook:

- Names the ticket category it serves
- Lists prerequisites and risk level
- Walks the procedure in numbered steps
- Links to any PowerShell script that automates it
- Closes with a "why this exists" paragraph (judgment > rote steps)

The first runbook is **not** "how to reset a password." It's the boring stuff that actually breaks SLAs:

- New hire onboarding (24-hour window)
- Departing user offboarding (same-day, license reclaim)
- Mass mailbox export for legal hold
- Conditional Access lockout recovery
- Bulk Intune re-enrollment after Autopilot reset

(Filled in across Weeks 1-4.)
