# SmallCo Manufacturing — Architecture Overview

## At a glance

| Layer | Component | Why |
|---|---|---|
| Identity | On-prem AD DS (Win Server 2022) | Production Tier 1 work happens here, not in cloud-only orgs |
| Identity | Entra ID via M365 E5 Dev Tenant | Where modern hybrid actually lives |
| Identity | Entra Connect (sync) | The thing labs usually skip |
| Endpoint | Intune + Autopilot | How fleet rolls in 2026 |
| Endpoint | Windows 11 + macOS Sonoma | Mixed fleet matches most JDs |
| Email/Collab | Exchange Online, Teams, SharePoint, OneDrive | Standard SMB stack |
| Security | Microsoft Defender for Endpoint, Conditional Access | Tier 1 sees these every day |
| Tickets | osTicket on Docker | ServiceNow/Jira proxy |
| Triage | Python + Claude agent (`ai-triage/`) | Empower-style differentiator |

## The 25 users

(Org chart and license assignments documented as the tenant fills in.)

## Design decisions

(Filled in during build — record the *why* behind each tradeoff so reviewers can see judgment, not just clicks.)
