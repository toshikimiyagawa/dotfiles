# Handoff: 43-herdr-bg-indicator

## Your scope

Implementation phase only (Tier 1; only `spec.md` is frozen).
Implement exactly the "決まり" section of `specs/43-herdr-bg-indicator/spec.md`, with tests B1–B8 in `test/test_herdr_bg_watch.sh`. Do not touch anything under `specs/` except creating `evidence.json`.
If the spec needs changes, stop and report to the orchestrating agent.

## Done when

- [ ] `.config/herdr/bin/herdr-bg-watch` (`#!/bin/sh`, POSIX) implements the loop, the matching, the TTL report and clear, the exit after 3 consecutive `pane list` failures, the lock, and the env overrides.
- [ ] `.zshrc` starts the watcher inside the existing herdr block with `nohup ... &!`.
- [ ] `config.toml` puts `$bg` right after `state_icon` and has a comment.
- [ ] `test/test_herdr_bg_watch.sh` covers B1–B8 using fakes. It must never call the real herdr: set `HERDR_BG_WATCH_HERDR`, and use a lock path under a temp `TMPDIR`. `bash test/run.sh` passes.
- [ ] `sh -n`, and `dash -n` if available; `zsh -n .zshrc`; `herdr config check` (read-only).
- [ ] `specs/43-herdr-bg-indicator/evidence.json` uses the format of `specs/31-acn-claude-repo-list/evidence.json`, with the manual checks marked `pending-manual`.

## Notes

- The real `herdr pane list` JSON has panes at `.result.panes[]`, each with `pane_id` and `agent` (e.g. `"claude"`).
- `herdr agent read <pane> --source recent --lines 40` prints plain text.
- The tests run inside a herdr pane on this machine (HERDR_* env is set). Make sure they cannot reach the real herdr or start a real watcher, and unset `HERDR_PANE_ID` where needed.
- Do not start the real watcher, reload the herdr config, or push. The orchestrator does the manual checks.
- Comments are in Japanese. Match the surrounding style.

## If the spec is ambiguous or insufficient

Stop and report. Do not redesign.
