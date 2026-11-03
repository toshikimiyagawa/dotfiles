# Handoff: 49-ghq-preview-down

## Your scope

Implementation phase only (Tier 1; only `spec.md` is frozen, there is no plan/tasks).
Implement exactly the "決まり" section of `specs/49-ghq-preview-down/spec.md` in `.zshrc` (function `ghq-fzf_change_directory` and the comment right above its body), plus the new test `test/test_zshrc_ghq_fzf.sh` (Z1–Z4). Do not touch anything under `specs/` except creating `evidence.json`.
If the spec needs changes, stop and report to the orchestrating agent.

## Done when

- [ ] `.zshrc`: `ghq-fzf_change_directory` calls fzf with `--preview-window "down,$(( (LINES * 7 / 10 < LINES - 12 ? LINES * 7 / 10 : LINES - 12) - 2 ))"` and `--preview "eza -a --icons=always --oneline $(ghq root)/{}"` (keep `local src=$(...)`); the comment says 下 instead of 右.
- [ ] `test/test_zshrc_ghq_fzf.sh` covers Z1–Z4, uses `test/lib.sh`, and `bash test/run.sh` passes.
- [ ] `zsh -n .zshrc` passes.
- [ ] `specs/49-ghq-preview-down/evidence.json` records the real test runs (format: `specs/47-acn-claude-pane-id/evidence.json`; `commit_sha` is the HEAD at the time; `test_count` is the real PASS count). Mark the manual check in SAC-3 (press `^q` in a real terminal) as `pending-manual`.

## Reference files

- spec: `specs/49-ghq-preview-down/spec.md`
- target: `.zshrc` (function `ghq-fzf_change_directory`)
- test helpers and style: `test/lib.sh`, `test/run.sh`, `test/test_acn_claude.sh`
- the same change in acn-devcontainer: `~/ghq/github.com/toshikimiyagawa/acn-devcontainer/.devcontainer/home/.zshrc` and `specs/19-ghq-preview-down/spec.md`

## Notes

- Tests run under bash 3.2 (macOS). Load the function by extracting its definition from the repo's `.zshrc` (not `~/.zshrc`) and sourcing it in `zsh`. Put fake `fzf`, `ghq`, `eza` at the head of PATH; the fake fzf records its arguments.
- For Z2, `$(ghq root)` is expanded by the fake `ghq` when the function runs, and fzf's `{}` is NOT substituted by the fake fzf, so the test must replace `{}` with a temp directory name itself before running the recorded `--preview` command with `sh -c` (real eza). Skip Z2 with a message when real eza is absent; skip the whole test with a message when zsh is absent.
- `.zshrc` may be blocked from editing by organization settings (see spec). If the edit is denied, stop and report to the orchestrating agent; do not work around it.
- Comments are in Japanese. Match the surrounding style.
- Do not push. Do not commit; leave the changes in the working tree for the orchestrating agent.

## If the spec is ambiguous or insufficient

1. Stop immediately.
2. Report the reason to the orchestrating agent.
3. Do not redesign.
