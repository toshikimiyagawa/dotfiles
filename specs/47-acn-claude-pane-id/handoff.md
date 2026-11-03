# Handoff: 47-acn-claude-pane-id

## Your scope

Implementation phase only (Tier 1; only `spec.md` is frozen, there is no plan/tasks).
Implement exactly the "決まり" section of `specs/47-acn-claude-pane-id/spec.md` in `.config/herdr/bin/acn-claude`, plus the tests P1–P6 in `test/test_acn_claude.sh` and the update of the existing T2/T3/T4/T7/T8 expectations. Do not touch anything under `specs/` except creating `evidence.json`.
If the spec needs changes, stop and report to the orchestrating agent.

## Done when

- [ ] All four `exec claude` sites in `acn-claude` (dir argument, container, workspace, get) use `exec env CLAUDE_MOBILE_PANE_ID=<quoted $HERDR_PANE_ID> claude` inside herdr, and plain `exec claude` outside herdr. Build the string once and reuse it.
- [ ] `test/test_acn_claude.sh` covers P1–P6 with the existing fakes, existing expectations are updated, and `bash test/run.sh` passes.
- [ ] `sh -n .config/herdr/bin/acn-claude` passes (and `dash -n` if dash exists).
- [ ] `specs/47-acn-claude-pane-id/evidence.json` records the test run. Use the format of `specs/43-herdr-bg-indicator/evidence.json` (`command_type` from [test, lint, build, other]). Mark SAC-3 (claude-mobile list shows the right conversation for two panes in the same folder) as `pending-manual`.

## Reference files

- spec: `specs/47-acn-claude-pane-id/spec.md`
- current script: `.config/herdr/bin/acn-claude`
- tests and helpers: `test/test_acn_claude.sh`, `test/lib.sh`, `test/run.sh`

## Notes

- `acn-claude` runs under `/bin/sh`. On macOS that is bash 3.2 in sh mode; CI runs on ubuntu, where it is dash. Stay POSIX.
- Tests run on macOS and on ubuntu CI. Keep them bash 3.2 compatible, and do not depend on a real fzf, ghq, ssh or container.
- `~/.config` is a symlink to this repo, so edits take effect immediately for the user. Keep the script working at every commit.
- Comments are in Japanese. Match the surrounding style.
- Do not push. Do not open herdr panes. Do not commit; leave the changes in the working tree for the orchestrating agent.

## If the spec is ambiguous or insufficient

1. Stop immediately.
2. Report the reason to the orchestrating agent.
3. Do not redesign.
