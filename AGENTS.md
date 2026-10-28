# dotfiles

macOS の設定ファイルを git 管理しているリポジトリ。

## 概要

このリポジトリは個人の macOS 開発環境設定を管理する dotfiles。
Zsh (zimfw)、Neovim (lazy.nvim)、Ghostty、Karabiner-Elements などの設定を含む。

`~/.config` は `.config` ディレクトリ自体を1つのシンボリックリンクとしてホームに張る（配下を丸ごと git 管理）。同期したくないもの（`.config/1Password/`、`.config/iterm2/`、`.config/op/` など）は `.gitignore` に都度追記するブロックリスト運用。コミット前に `git status` で意図しないファイルが含まれていないか確認する。

## 作業時の注意

- 設定変更は実際のホームディレクトリへのシンボリックリンク経由で反映される（`~/.config` はディレクトリ単位でリンク）
- 既存マシンで個別リンクから移行する場合は `./migrate-config.sh` を一度実行する（非破壊。退避ディレクトリを残す）
- Neovim の設定は lazy.nvim を使用しており、`.config/nvim/` 配下に格納
- Karabiner のカスタムルールは `.config/karabiner/assets/complex_modifications/` に JSON で定義

---

# SDD (Spec-Driven Development)

This project follows Spec-Driven Development (SDD).
Read the canonical rules before any work:
- `vendor/ai-sdd-guide/rules/core.md`
- `vendor/ai-sdd-guide/rules/workflow.md`
- `vendor/ai-sdd-guide/rules/subagents.md`
- `vendor/ai-sdd-guide/rules/conventions.md`
- `vendor/ai-sdd-guide/orchestration/rules/orchestration.md`
- `vendor/ai-sdd-guide/catalog/rules/catalog.md`

## Human touchpoints
Humans take part only in the initial question (Tier + spec unknowns), escalation, and PR
review/merge. Run every other step autonomously through to the PR; never merge. See
`vendor/ai-sdd-guide/orchestration/rules/orchestration.md` (Human touchpoints, Autonomous flow,
Escalation conditions).

## Design phases (superpowers required)
Use superpowers skills (brainstorming → writing-plans) for spec/plan/tasks.
Capture output into `specs/<feature>/`. Freeze only after an independent spec-reviewer returns
APPROVE (Claude Code: `spec-reviewer` subagent; other agents:
`vendor/ai-sdd-guide/integration/prompts/spec-reviewer-prompt.md`).

## Implementation phase (any agent, no superpowers needed)
Implement exactly the frozen `specs/<feature>/tasks.md`. No more, no less.
Every acceptance criterion must map to a passing test.
Implement in a fresh agent context, not the one that froze the spec.
If the spec is wrong or insufficient: stop and report to the orchestrating agent. Do not redesign.

## Verify phase (superpowers required)
Run the `sdd-reviewer` subagent/prompt against the diff to confirm the implementation
matches the frozen spec. See `vendor/ai-sdd-guide/orchestration/rules/orchestration.md`
for agent-specific instructions (Claude Code / Codex / Gemini CLI).

## Hard rules
- Do not modify files under `specs/` to fit an implementation.
- Do not expand scope beyond approved tasks.
- Do not disable SDD hooks or CI.

Human-facing docs: `vendor/ai-sdd-guide/docs/`
Templates: `vendor/ai-sdd-guide/templates/`
Claude hooks: `.claude/settings.json` (copy from `vendor/ai-sdd-guide/integration/settings.json.example`)
Codex hooks: `.codex/config.toml` (copy from `vendor/ai-sdd-guide/integration/codex/config.toml.example`)
Subagents: `.claude/agents/` (copy from `vendor/ai-sdd-guide/integration/agents/`)

## CLAUDE.md
CLAUDE.md is a symlink to this file. Do not replace it with a regular file.

(If you change the submodule path, update all paths above to match.)
