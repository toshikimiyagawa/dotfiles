# Handoff: 31-acn-claude-repo-list

## Your scope

Implementation phase only (Tier 1; only `spec.md` is frozen, there is no plan/tasks).
Implement exactly the "決まり" section of `specs/31-acn-claude-repo-list/spec.md` in `.config/herdr/bin/acn-claude`, plus the tests T1–T8 in `test/test_acn_claude.sh`. Do not touch anything under `specs/` except creating `evidence.json`.
If the spec needs changes, stop and report to the orchestrating agent.

## Done when

- [ ] `acn-claude` behaves as specified.
- [ ] `test/test_acn_claude.sh` covers T1–T8 using fake ssh/fzf/ghq/claude, and `bash test/run.sh` passes.
- [ ] `sh -n .config/herdr/bin/acn-claude` passes.
- [ ] `specs/31-acn-claude-repo-list/evidence.json` records the test run. Use the format of `specs/*/evidence.json` in toshikimiyagawa/acn-devcontainer (e.g. `~/ghq/github.com/toshikimiyagawa/acn-devcontainer/specs/89-share-host-ssh/evidence.json`), with `command_type` from [test, lint, build, other]. Mark the manual parts of SAC-2 and SAC-3 as `pending-manual`.

## Reference files

- spec: `specs/31-acn-claude-repo-list/spec.md`
- current script: `.config/herdr/bin/acn-claude`
- test helpers: `test/lib.sh`, `test/run.sh`

## Notes

- `acn-claude` runs under `/bin/sh`. On macOS that is bash 3.2 in sh mode; CI runs on ubuntu, where it is dash. Stay POSIX.
- Tests run on macOS and on ubuntu CI. Keep them bash 3.2 compatible, and do not depend on a real fzf, ghq, ssh or container.
- `~/.config` is a symlink to this repo, so edits take effect immediately for the user. Keep the script working at every commit.
- Comments are in Japanese. Match the surrounding style.
- Do not push. Do not open herdr panes.

## If the spec is ambiguous or insufficient

1. Stop immediately.
2. Report the reason to the orchestrating agent.
3. Do not redesign.
