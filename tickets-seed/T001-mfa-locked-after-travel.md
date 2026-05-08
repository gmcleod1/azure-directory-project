---
id: T001
priority: P2
category: Password / MFA
requester: jane.harris@smallco.example
requester_role: Sales — travels frequently
expected_runbook: runbooks/conditional-access-lockout-recovery.md
expected_script: scripts/Reset-MfaMethods.ps1
ai_triage_target_category: "Identity / MFA"
created: 2026-05-08T08:14:00-04:00
---

# Subject
Can't sign in to anything after landing in Berlin

# Body
Hi IT,

I just got off a 9-hour flight to Berlin for the Hannover Messe trade show. I'm trying to sign in to Outlook and Teams on my laptop and it keeps saying "Your sign-in was blocked." I tried my phone and same thing.

My MFA app is asking me for a new code each time but it never works. I've got a customer dinner in 4 hours and I need to pull up the contract docs from SharePoint before then.

Can you help ASAP?

— Jane

# Notes for the analyst
This is a textbook Conditional Access "atypical travel" block. The user is fine — Entra is doing its job. Resolution path:

1. Check Sign-in logs for Jane's UPN: filter on the failed attempt → confirm the block reason is "atypical travel" or "anonymous IP / impossible travel"
2. If yes: temporarily exclude Jane from the geo-block CA policy OR have her re-register MFA from a trusted device first
3. Document the exception in the change log; revert the policy exclusion when she returns
4. Reach out via SMS (her cell is in AD) — email is what's blocked

# Why this is a good seed ticket
- Hits the most common modern-helpdesk scenario: MFA + Conditional Access + traveling user
- Forces the analyst to use Sign-in logs (not just AD)
- Has a real time pressure that mirrors production stakes
- The "wrong" fix (just disable MFA) is tempting; the runbook teaches the right fix
