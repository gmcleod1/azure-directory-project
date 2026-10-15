# Azure Help Desk Lab: Hand-Build Guide

Build a small business IT environment in Azure by hand: Active Directory, Group Policy, a domain-joined client and an osTicket server. Then break things on purpose and write them up as tickets.

**Time:** about 6-8 hours across 2-3 sessions. **Cost:** about $1-3 per day while running. Near $0 when deallocated (disks still bill a little).

| VM | OS | Size | Private IP | Role |
|---|---|---|---|---|
| SC-DC01 | Windows Server 2022 | Standard_B2s | 10.0.1.4 | AD DS, DNS, file share |
| SC-CLIENT01 | Windows 11 Pro (or Server 2022 fallback) | Standard_B2s | 10.0.1.5 | Domain-joined user PC |
| SC-TKT01 | Ubuntu 22.04 | Standard_B1ms | 10.0.1.6 | osTicket in Docker |

Domain: `smallco.local` (NetBIOS `SMALLCO`).

**Rules for yourself**
- Screenshot every step marked 📸 as you go. Name them `NN-description.png` (list in section 9).
- Never commit passwords, your public IP or your subscription ID.
- Deallocate the VMs whenever you stop for the day.

---

## 0. Prerequisites

Run in PowerShell on your PC. Your CLI login expired, so sign in again:

```powershell
az login --tenant <your-tenant-id>
az account show --query "{name:name,state:state}" -o table
```

Set variables you will reuse. Re-paste this block at the start of every new PowerShell session:

```powershell
$rg    = "rg-smallco-lab"
$loc   = "eastus"
$myIp  = (Invoke-RestMethod https://api.ipify.org)      # your current public IP
$admin = "labadmin"
$pw    = Read-Host "Lab admin password (14+ chars, mixed)" -AsSecureString
$pwPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw))
```

Create a budget alert: Portal > Cost Management > Budgets > Add. Set $25/month with an email alert at 80%. 📸

If your home IP changes later, update the NSG rules (section 1) or you will be locked out.

---

## 1. Resource group, network, NSG

```powershell
az group create -n $rg -l $loc

az network vnet create -g $rg -n vnet-smallco `
  --address-prefix 10.0.0.0/16 `
  --subnet-name snet-lab --subnet-prefix 10.0.1.0/24

az network nsg create -g $rg -n nsg-smallco

az network nsg rule create -g $rg --nsg-name nsg-smallco -n allow-rdp `
  --priority 100 --access Allow --protocol Tcp --direction Inbound `
  --source-address-prefixes $myIp --destination-port-ranges 3389

az network nsg rule create -g $rg --nsg-name nsg-smallco -n allow-ssh `
  --priority 110 --access Allow --protocol Tcp --direction Inbound `
  --source-address-prefixes $myIp --destination-port-ranges 22

az network nsg rule create -g $rg --nsg-name nsg-smallco -n allow-osticket `
  --priority 120 --access Allow --protocol Tcp --direction Inbound `
  --source-address-prefixes $myIp --destination-port-ranges 8080

az network vnet subnet update -g $rg --vnet-name vnet-smallco -n snet-lab `
  --network-security-group nsg-smallco
```

📸 Portal: resource group overview and the NSG rules list.

---

## 2. Create the VMs

### 2.1 Domain controller

```powershell
az vm create -g $rg -n SC-DC01 `
  --image MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest `
  --size Standard_B2s `
  --admin-username $admin --admin-password $pwPlain `
  --vnet-name vnet-smallco --subnet snet-lab `
  --private-ip-address 10.0.1.4 `
  --public-ip-sku Standard --nsg '""'
```

`--nsg '""'` skips a per-VM NSG because the subnet NSG already protects it.

### 2.2 Windows client

Try Windows 11 first. It needs a Windows client license (for example Visual Studio subscription benefits). If Azure rejects it, use the fallback.

```powershell
# Option A: Windows 11 Pro
az vm create -g $rg -n SC-CLIENT01 `
  --image MicrosoftWindowsDesktop:windows-11:win11-23h2-pro:latest `
  --size Standard_B2s --license-type Windows_Client `
  --admin-username $admin --admin-password $pwPlain `
  --vnet-name vnet-smallco --subnet snet-lab `
  --private-ip-address 10.0.1.5 --public-ip-sku Standard --nsg '""'

# Option B (fallback): second Server 2022 acting as the user PC
az vm create -g $rg -n SC-CLIENT01 `
  --image MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest `
  --size Standard_B2s `
  --admin-username $admin --admin-password $pwPlain `
  --vnet-name vnet-smallco --subnet snet-lab `
  --private-ip-address 10.0.1.5 --public-ip-sku Standard --nsg '""'
```

### 2.3 Ticket server

```powershell
az vm create -g $rg -n SC-TKT01 `
  --image Ubuntu2204 --size Standard_B1ms `
  --admin-username $admin --admin-password $pwPlain `
  --authentication-type password `
  --vnet-name vnet-smallco --subnet snet-lab `
  --private-ip-address 10.0.1.6 --public-ip-sku Standard --nsg '""'
```

### 2.4 Auto-shutdown (safety net)

Time is UTC. 2300 UTC is 7 PM Eastern while daylight time lasts (until Nov 1, 2026). After that use `0000`.

```powershell
foreach ($vm in "SC-DC01","SC-CLIENT01","SC-TKT01") {
  az vm auto-shutdown -g $rg -n $vm --time 2300
}
```

### 2.5 Get public IPs

```powershell
az vm list-ip-addresses -g $rg -o table
```

Public IPs change after deallocate/start. Run this each session.

📸 Portal: VM list showing all three running.

---

## 3. Active Directory on SC-DC01

RDP in: `mstsc /v:<DC public IP>`, user `labadmin`.

### 3.1 Install the role and promote

Open PowerShell as Administrator on the DC:

```powershell
Install-WindowsFeature AD-Domain-Services, DNS, GPMC -IncludeManagementTools

Install-ADDSForest `
  -DomainName "smallco.local" `
  -DomainNetbiosName "SMALLCO" `
  -InstallDns `
  -SafeModeAdministratorPassword (Read-Host "DSRM password" -AsSecureString) `
  -Force
```

The server reboots. Log back in as `SMALLCO\labadmin` (same password as before).

### 3.2 Point the VNet at your DC for DNS

Back on your PC:

```powershell
az network vnet update -g $rg -n vnet-smallco --dns-servers 10.0.1.4
az vm restart -g $rg -n SC-CLIENT01
az vm restart -g $rg -n SC-TKT01
```

### 3.3 Verify

On the DC:

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode
Get-Service NTDS, DNS, Netlogon | Select-Object Name, Status
dcdiag /q
```

📸 `Get-ADDomain` output and Server Manager dashboard.

### 3.4 OUs, groups and users

Create `C:\Lab\users.csv` on the DC:

```csv
First,Last,Username,Dept,Title
Jane,Harris,jane.harris,Sales,Account Executive
Marcus,Lee,marcus.lee,Sales,Sales Rep
Priya,Nair,priya.nair,Finance,Accountant
Tom,Reyes,tom.reyes,Finance,AP Clerk
Dana,Whitfield,dana.whitfield,Engineering,Process Engineer
Carlos,Ortiz,carlos.ortiz,Engineering,Design Engineer
Aisha,Khan,aisha.khan,Operations,Plant Supervisor
Ben,Foster,ben.foster,Operations,Line Lead
Elena,Petrov,elena.petrov,Leadership,COO
Sam,Dawson,sam.dawson,Leadership,CFO
```

Extend to about 25 rows by repeating the pattern with new names. Then run:

```powershell
$base = "DC=smallco,DC=local"
$depts = "Sales","Finance","Engineering","Operations","Leadership"

New-ADOrganizationalUnit -Name "SmallCo" -Path $base
foreach ($d in $depts) {
  New-ADOrganizationalUnit -Name $d -Path "OU=SmallCo,$base"
  New-ADGroup -Name "GRP-$d" -GroupScope Global -Path "OU=$d,OU=SmallCo,$base"
}
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=SmallCo,$base"
New-ADOrganizationalUnit -Name "Servers"      -Path "OU=SmallCo,$base"

$initial = Read-Host "Initial user password" -AsSecureString
Import-Csv C:\Lab\users.csv | ForEach-Object {
  New-ADUser -Name "$($_.First) $($_.Last)" `
    -GivenName $_.First -Surname $_.Last `
    -SamAccountName $_.Username `
    -UserPrincipalName "$($_.Username)@smallco.local" `
    -Department $_.Dept -Title $_.Title `
    -Path "OU=$($_.Dept),OU=SmallCo,$base" `
    -AccountPassword $initial -ChangePasswordAtLogon $true -Enabled $true
  Add-ADGroupMember -Identity "GRP-$($_.Dept)" -Members $_.Username
}

Get-ADUser -Filter * -SearchBase "OU=SmallCo,$base" | Measure-Object
```

📸 Active Directory Users and Computers tree (expanded OUs) and the user count.

### 3.5 File share for drive mapping

```powershell
New-Item -ItemType Directory -Path C:\Shares\Company, C:\Shares\Wallpaper -Force
New-SmbShare -Name Company   -Path C:\Shares\Company   -FullAccess "SMALLCO\Domain Users"
New-SmbShare -Name Wallpaper -Path C:\Shares\Wallpaper -ReadAccess "Everyone"
```

Copy any JPG into `C:\Shares\Wallpaper\smallco.jpg`.

---

## 4. Group Policy

Open `gpmc.msc` on the DC. Use PowerShell where shown, GUI where not.

### 4.1 Password and lockout policy (Default Domain Policy)

```powershell
Set-ADDefaultDomainPasswordPolicy -Identity smallco.local `
  -MinPasswordLength 12 -ComplexityEnabled $true `
  -MaxPasswordAge 90.00:00:00 -MinPasswordAge 1.00:00:00 `
  -PasswordHistoryCount 10 `
  -LockoutThreshold 5 -LockoutDuration 00:30:00 -LockoutObservationWindow 00:30:00

Get-ADDefaultDomainPasswordPolicy
```

📸 Output of the last command.

### 4.2 Desktop wallpaper (users, SmallCo OU)

```powershell
New-GPO -Name "USR - Corporate Wallpaper" | New-GPLink -Target "OU=SmallCo,DC=smallco,DC=local"

Set-GPRegistryValue -Name "USR - Corporate Wallpaper" `
  -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
  -ValueName Wallpaper -Type String -Value "\\SC-DC01\Wallpaper\smallco.jpg"
Set-GPRegistryValue -Name "USR - Corporate Wallpaper" `
  -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
  -ValueName WallpaperStyle -Type String -Value "10"
```

### 4.3 Block USB storage (computers, Workstations OU)

```powershell
New-GPO -Name "CMP - Block USB Storage" | New-GPLink -Target "OU=Workstations,OU=SmallCo,DC=smallco,DC=local"

Set-GPRegistryValue -Name "CMP - Block USB Storage" `
  -Key "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" `
  -ValueName Deny_All -Type DWord -Value 1
```

### 4.4 Restrict Control Panel for Sales

```powershell
New-GPO -Name "USR - Restrict Control Panel (Sales)" | New-GPLink -Target "OU=Sales,OU=SmallCo,DC=smallco,DC=local"

Set-GPRegistryValue -Name "USR - Restrict Control Panel (Sales)" `
  -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
  -ValueName NoControlPanel -Type DWord -Value 1
```

### 4.5 Mapped drive (GUI only)

1. GPMC > Group Policy Objects > right-click > New > name `USR - Map Company Drive` > link to `SmallCo` OU.
2. Edit > User Configuration > Preferences > Windows Settings > Drive Maps > New > Mapped Drive.
3. Action `Create`, Location `\\SC-DC01\Company`, Reconnect checked, Drive `S:`, label `Company`. OK.

📸 GPMC with all GPOs linked, and the drive map editor.

### 4.6 Back up the GPOs (goes in the repo)

```powershell
New-Item -ItemType Directory C:\GPOBackup -Force
Backup-GPO -All -Path C:\GPOBackup
Get-GPOReport -All -ReportType Html -Path C:\GPOBackup\all-gpos.html
```

Copy `C:\GPOBackup` to your PC later (RDP drive redirection or copy and paste).

---

## 5. Join the client

RDP into SC-CLIENT01 as `labadmin` (local account). PowerShell as Administrator:

```powershell
# DNS must resolve the domain (the VNet DNS setting does this after the restart)
Resolve-DnsName smallco.local
Test-NetConnection 10.0.1.4 -Port 389

Add-Computer -DomainName smallco.local -Credential SMALLCO\labadmin -Restart
```

If `Resolve-DnsName` fails, run `ipconfig /all`. The DNS server must be `10.0.1.4`. Fix with `ipconfig /renew` or restart the VM.

On the DC, move the computer object into the right OU:

```powershell
Get-ADComputer SC-CLIENT01 | Move-ADObject -TargetPath "OU=Workstations,OU=SmallCo,DC=smallco,DC=local"
```

Allow domain users to RDP to the client (lab only), run on the client:

```powershell
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "SMALLCO\Domain Users"
```

Log in via RDP as `SMALLCO\jane.harris` (Sales). Change the password when prompted.

### 5.1 Verify policy applied

```powershell
gpupdate /force
gpresult /r
whoami /groups
```

Check: wallpaper set, `S:` drive present, Control Panel blocked (Jane is in Sales), USB storage denied. 📸 desktop, `gpresult /r`, File Explorer with `S:`, blocked Control Panel message.

---

## 6. osTicket on SC-TKT01

```bash
ssh labadmin@<TKT public IP>
```

Install Docker:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
exit    # log out, then ssh back in so group applies
```

Get the compose file and set secrets:

```bash
git clone https://github.com/gmcleod1/azure-directory-project.git
cd azure-directory-project
cp .env.example .env
nano .env            # replace all three placeholders; use: openssl rand -base64 24
docker compose up -d
docker compose logs -f osticket      # wait for Apache started, then Ctrl+C
```

If the repo is private, copy the two files from your PC instead:

```powershell
scp docker-compose.yml .env.example labadmin@<TKT public IP>:~/
```

In a browser on your PC open `http://<TKT public IP>:8080` and run the installer using the inputs in `SETUP.md` (use MySQL host `db`). Then lock it down:

```bash
docker compose exec osticket rm -rf /var/www/html/setup
```

Confirm `http://<TKT public IP>:8080/scp` loads and you can log in. 📸 installer success page, staff dashboard.

Optional: create the departments (Identity, Endpoint, Network) and the help topics under Admin Panel > Manage.

---

## 7. Tickets: break it, fix it, write it up

For each scenario below: cause the problem, work it as the analyst, then log it in osTicket (create the ticket as the user, resolve it as staff) and write the file.

| # | Scenario | How to cause it | Diagnosis commands | Fix |
|---|---|---|---|---|
| T002 | Account locked out | Enter a wrong password 5 times as `marcus.lee` | `Get-ADUser marcus.lee -Properties LockedOut,BadLogonCount` ; `Get-WinEvent -FilterHashtable @{LogName='Security';Id=4740}` on DC | `Unlock-ADAccount marcus.lee` |
| T003 | Forgot password | Say Tom forgot his password | `Get-ADUser tom.reyes -Properties PasswordLastSet,PasswordExpired` | `Set-ADAccountPassword tom.reyes -Reset` then `Set-ADUser tom.reyes -ChangePasswordAtLogon $true` |
| T004 | Drive not mapped | Unlink the drive-map GPO, or stop the SMB share: `Remove-SmbShare Company` | `net use`, `gpresult /r`, `Test-NetConnection SC-DC01 -Port 445`, `Get-SmbShare` on DC | Recreate share or relink GPO, then `gpupdate /force` |
| T005 | GPO not applying | Move SC-CLIENT01 to the default Computers container | `gpresult /r` (missing GPOs), `Get-ADComputer SC-CLIENT01` | `Move-ADObject` back to Workstations OU, `gpupdate /force`, reboot |
| T006 | Cannot join domain | Set the client DNS to 8.8.8.8 | `nslookup smallco.local`, `Resolve-DnsName _ldap._tcp.dc._msdcs.smallco.local`, `ipconfig /all` | Set DNS to 10.0.1.4, retry `Add-Computer` |
| T007 | New hire onboarding | Pretend a new Finance hire starts Monday | n/a | `New-ADUser` plus group add (reuse section 3.4 script), mailbox is out of scope |
| T008 | USB blocked | User says flash drive does not work | `gpresult /h C:\gp.html`, look for Block USB Storage | Explain policy, or request an exception: new OU with the policy removed (document approval) |
| T009 | Slow logon | Add a deliberately bad logon script or a broken GPP drive path | `gpresult /h`, Event Viewer > GroupPolicy operational log | Remove broken item |
| T010 | Disabled/stale account | Disable a user, ask why they cannot log in | `Get-ADUser -Properties Enabled,AccountExpirationDate` | `Enable-ADAccount` after verifying with the manager |

### Ticket write-up template

Save as `tickets-seed/T002-account-lockout.md` etc., following the T001 format (front-matter plus body). Add this analyst section:

```markdown
---
id: T002
priority: P3
category: Identity / Account
requester: marcus.lee@smallco.local
requester_role: Sales
created: 2026-10-XX
---

# Subject
Locked out of my computer

# Body
(What the user would write, in their words.)

# Problem
What the user sees and what they have already tried. Impact and urgency.

# Diagnosis
1. Step, with the exact command and the key line of output.
2. Step ...
Root cause in one sentence.

# Resolution
What you changed, with the exact commands. How you confirmed it worked with the user.

# Prevention / Follow-up
KB article, GPO or policy change, or "none needed".

# Screenshots
- docs/screenshots/NN-....png
```

Also write one runbook (`runbooks/`) and one KB article (`kb/windows/`) from the best two tickets, plus a script such as `scripts/Unlock-AdUser.ps1` for lockouts.

---

## 8. Common problems while building

| Symptom | Fix |
|---|---|
| Cannot RDP or SSH | Your public IP changed. Update the NSG rule source: `az network nsg rule update -g $rg --nsg-name nsg-smallco -n allow-rdp --source-address-prefixes <new IP>` |
| Public IP changed after restart | `az vm list-ip-addresses -g $rg -o table` |
| Client cannot find the domain | VNet DNS not set or VM not restarted since. Check `ipconfig /all` for 10.0.1.4 |
| `Install-ADDSForest` warns about static IP/DNS | Safe to ignore in this lab, the NIC is already a static Azure reservation |
| Wallpaper or drive missing | Run `gpupdate /force`, then log off and back on. User policies apply at logon |
| osTicket page does not load | NSG rule 8080 source IP, `docker compose ps`, then `docker compose logs osticket` |
| Win 11 image rejected | Use Option B (Server 2022) as the client |

---

## 9. Screenshot checklist (save to `docs/screenshots/`)

- [ ] 01-budget-alert
- [ ] 02-resource-group-and-nsg
- [ ] 03-vm-list-running
- [ ] 04-get-addomain
- [ ] 05-aduc-ou-tree
- [ ] 06-user-count
- [ ] 07-password-policy
- [ ] 08-gpmc-linked-gpos
- [ ] 09-drive-map-editor
- [ ] 10-client-joined-domain (System properties)
- [ ] 11-gpresult-client
- [ ] 12-wallpaper-and-s-drive
- [ ] 13-control-panel-blocked
- [ ] 14-osticket-installer-success
- [ ] 15-osticket-dashboard
- [ ] 16+ one or two per ticket (error, diagnosis command, fix, verification)

Do this before teardown. Taking them afterward is impossible.

---

## 10. Stop, resume, tear down

**End of session (keeps everything, near-zero cost):**

```powershell
az vm deallocate -g $rg -n SC-DC01 --no-wait
az vm deallocate -g $rg -n SC-CLIENT01 --no-wait
az vm deallocate -g $rg -n SC-TKT01 --no-wait
```

**Next session:** start the DC first, wait 3 minutes, then the others.

```powershell
az vm start -g $rg -n SC-DC01
Start-Sleep 180
az vm start -g $rg -n SC-CLIENT01 --no-wait
az vm start -g $rg -n SC-TKT01 --no-wait
az vm list-ip-addresses -g $rg -o table
```

**Before deleting:** copy `C:\GPOBackup`, `users.csv`, osTicket DB backup (see SETUP.md) and all screenshots to your PC.

**Delete everything:**

```powershell
az group delete -n $rg --yes --no-wait
az resource list -g $rg -o table     # should error: group not found, once done
```

---

## 11. Publish to GitHub

1. Add to `azure-directory-project`: `docs/screenshots/`, `docs/gpo/` (GPO backup + HTML report), the ticket files in `tickets-seed/`, the runbook, KB article and scripts.
2. Update `docs/architecture/overview.md` with a diagram of the 3 VMs and the OU structure, and change the README status.
3. Check nothing sensitive is committed: no passwords, public IPs, subscription or tenant IDs. Redact them in screenshots (blur the IP bar and the Azure account name).
4. Commit and push. For the help desk resume, describe it as: *Built a 3-VM Azure environment with Active Directory, Group Policy and osTicket; resolved and documented 9 tickets (lockouts, GPO, DNS/domain join, onboarding).*

Keep the cyber-flavored items (AI triage) off the help desk resume version, per your resume strategy.
