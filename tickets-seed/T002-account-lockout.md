---
id: T002
priority: P3
category: Identity / Account
requester: marcus.lee@smallco.local
requester_role: Sales Rep
created: 2026-10-14
---

# Subject
Locked out of my computer

# Body
I'm locked out. plz help

(osTicket #361171, submitted through the web portal. The ticket gave no detail beyond this, so the analyst first confirmed the account state.)

# Problem
Marcus Lee (Sales) reports he is locked out and cannot work. The ticket has no error text or details. Impact: one user blocked from work. Urgency: medium. No other users are affected.

# Diagnosis
1. Confirm the account state on the domain controller:
   ```powershell
   Get-ADUser marcus.lee -Properties LockedOut,BadLogonCount,LastBadPasswordAttempt
   ```
   Key output: `LockedOut : True`, `BadLogonCount : 5`, `LastBadPasswordAttempt : 10/14/2026 11:38:08 PM`. The account is enabled, so this is a lockout and not a disabled account.
2. Find the lockout event in the Security log to see when and from which machine:
   ```powershell
   Get-WinEvent -FilterHashtable @{LogName='Security';Id=4740} -MaxEvents 1
   ```
   Key output: Event ID 4740, Account `marcus.lee`, TimeCreated `10/14/2026 11:38:08 PM`, CallerComputer `SC-DC01`.
3. Check the lockout policy to see how long it lasts without help:
   ```powershell
   Get-ADDefaultDomainPasswordPolicy | Select LockoutThreshold,LockoutDuration,LockoutObservationWindow
   ```
   Key output: `LockoutThreshold : 5`, `LockoutDuration : 00:30:00`, `LockoutObservationWindow : 00:30:00`.

Root cause: five failed password attempts inside the 30-minute observation window reached the domain lockout threshold of 5, so the account locked.

Lab note: in this lab the five bad attempts were generated from the DC with a script, which is why CallerComputer shows SC-DC01. On a real ticket, CallerComputer shows the user's PC, or a phone or mapped drive holding an old password, and that machine should be checked as the source.

# Resolution
1. Verify the caller's identity (known phone number or manager confirmation) before unlocking.
2. Unlock the account:
   ```powershell
   Unlock-ADAccount marcus.lee
   ```
3. Confirm the fix:
   ```powershell
   Get-ADUser marcus.lee -Properties LockedOut | Select SamAccountName,LockedOut
   ```
   Output: `marcus.lee   LockedOut False`.
4. Ask Marcus to sign in. If he still cannot, reset his password with `Set-ADAccountPassword`, as in T003.
5. In osTicket #361171, claimed the ticket, added an internal note ("Account locked after 5 failed attempts (event 4740). Identity verified. Unlocked with Unlock-ADAccount.") and replied to Marcus asking him to try signing in and to report back if it recurs.

# Prevention / Follow-up
- Ask Marcus to check for old saved passwords on his phone, mapped drives and Outlook, which commonly cause repeat lockouts.
- If lockouts repeat, find the source machine from the 4740 event.
- No policy change needed. The 5-attempt, 30-minute policy is working as designed.

# Screenshots
- docs/screenshots/16-t002-locked-account.png (LockedOut True, BadLogonCount 5)
- docs/screenshots/17-t002-event-4740.png (lockout event)
- docs/screenshots/18-t002-unlock-verified.png (Unlock-ADAccount, LockedOut False)
- docs/screenshots/19-t002-ticket-submitted.png (ticket as filed by Marcus)
- docs/screenshots/20-t002-ticket-worked.png (claimed, internal note and reply)
