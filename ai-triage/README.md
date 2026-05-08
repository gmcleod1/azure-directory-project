# AI Triage Agent

Reads incoming osTicket tickets via REST API, classifies them, suggests a KB article, drafts a first-touch response, and posts an internal note for the analyst to review before sending.

**This is not auto-reply.** The analyst always approves before the response goes out.

## Inputs
- osTicket API key (read + post-internal-note scope)
- Anthropic API key (Claude)
- KB index built from `../kb/` Markdown files

## Outputs (per ticket)
- Suggested category + priority
- Top 3 KB matches (similarity score)
- Draft response (plain text + HTML)
- Internal note posted to the ticket

## Design
- Polls every 60s (or webhook when osTicket exposes one)
- Prompt cached: system prompt + KB index → cache hit on every triage call
- Logs to `../reports/triage-log.jsonl` for the weekly manager report

## Status
Skeleton only. Implementation in Week 3.

## Files (planned)
- `agent.py` — main loop
- `osticket_client.py` — REST wrapper
- `kb_indexer.py` — builds embedding index from `../kb/`
- `prompts/triage.md` — Claude system prompt
- `tests/` — pytest smoke tests
