# Reset Outlook profile (Windows)

**Use when:** Outlook stuck on "loading profile," repeated password prompts, search index corrupted, mailbox rebuilt server-side, or after a tenant migration.

**Time:** ~10 minutes
**Risk:** Low — local profile only; mailbox data lives on Exchange Online and re-downloads.
**Permissions:** Local admin not required.

---

## Before you start

1. Confirm the user can sign in to Outlook on the web (`outlook.office.com`). If they can't, the issue is account-side, not profile-side — stop here and check Conditional Access / MFA.
2. Note the account's primary SMTP address.
3. Warn the user: re-cache will re-download mail (~1-3 GB depending on retention). Wired or fast Wi-Fi recommended.

## Procedure

1. Close Outlook completely (check Task Manager for `OUTLOOK.EXE`).
2. Open **Control Panel** → **Mail (Microsoft Outlook)**. If you don't see it, switch the view to "Small icons."
3. Click **Show Profiles…**
4. Select the broken profile (usually `Outlook`) → **Remove** → confirm.
5. Click **Add…** → name it `Outlook` → **OK**.
6. In the auto-account-setup dialog, enter the user's UPN → **Next**. Modern Auth should complete sign-in.
7. Set **Always use this profile** → **OK**.
8. Launch Outlook. First sync may take 5-30 min depending on mailbox size.

## If auto-setup fails

- Manual setup → **Exchange** → enter UPN → let autodiscover finish.
- If autodiscover fails, run `Test-OutlookConnectivity` (Outlook → File → Test E-mail AutoConfiguration) and check the AutoDiscover XML response.
- Re-check the user's Conditional Access state in Entra ID — a blocked sign-in surfaces as a profile error in Outlook 2021 and earlier.

## Related runbooks / scripts

- [`scripts/Reset-OutlookProfile.ps1`](../../scripts/Reset-OutlookProfile.ps1) — automates steps 1-7 for remote users
- [KB: Re-enable a Conditional-Access blocked sign-in](../m365/conditional-access-blocked-signin.md)

## Why this article exists

Profile corruption is the #1 Outlook ticket category by volume in our queue. ~70% of these resolve with a profile reset; the rest are CA / autodiscover / mailbox-side. Reset first, then escalate.
