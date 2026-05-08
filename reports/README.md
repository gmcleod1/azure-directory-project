# Weekly Operations Reports

Manager-facing reports auto-generated from osTicket data each Friday.
Demonstrates SLA discipline and metric ownership — what a Tier 1 lead would actually present.

## Report contents
- Ticket volume by category (week-over-week)
- First-Contact-Resolution rate (target: >65%)
- Mean Time To Resolution by priority
- Top 5 KB articles served by the AI agent
- Open ticket aging buckets (0-1d / 1-3d / 3-7d / 7d+)
- Notable incidents + lessons learned

## Cadence
Generator: `scripts/New-WeeklyReport.ps1` (Week 4)
Output: `reports/{YYYY}-W{NN}.md`
First sample: `reports/2026-W19.md`
