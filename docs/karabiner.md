# Karabiner-Elements 設定

設定ファイル: `.config/karabiner/karabiner.json`

---

## Simple Modifications (グローバル)

キーの物理的な入れ替え。全キーボードに適用される基本マッピング。

| 変更前 | 変更後 | 目的 |
|--------|--------|------|
| `Caps Lock` | `Left Control` | Caps Lock を Ctrl として使う |
| `Left Command` | `Left Option` | 左⌘ → 左 Option に |
| `Left Control` | `Left Command` | 左 Ctrl → 左 ⌘ に |
| `Left Option` | `Right Command` | 左 Option → 右 ⌘ に |

### キーボードデバイスごとの Simple Modifications

キーボードデバイスには追加のキー入れ替えが設定されている。

| 変更前 | 変更後 |
|--------|--------|
| `fn` キー | `Left Command` |
| `Left Command` | `Right Command` |
| `Left Control` | `fn` キー |
| `Right Command` | `Right Option` |
| `Right Option` | `Caps Lock` |
| `Right Shift` | `Left Shift` |

---

## Complex Modifications (カスタムルール)

### ルール 1: Home/End キーをシェル向けに変換

| キー | 変換先 | 効果 |
|------|--------|------|
| `Home` | `Ctrl+A` | 行頭へ移動 |
| `End` | `Ctrl+E` | 行末へ移動 |

### ルール 2: 日本語入力の IME 切り替え (US キーボード向け)

`to_if_alone_timeout_milliseconds: 300` — 単独押し判定タイムアウト。

| キー | 単独押し | 組み合わせ押し |
|------|----------|----------------|
| `Right Command` | 英数 (EISUU) | Right Command のまま |
| `Right Option` | かな (KANA) | Left Shift として動作 |
| `Escape` | Escape | Left Control として動作 |
| `Tab` | Tab | Left Control として動作 |

> US キーボードで英数/かな切り替えをコマンドキーで実現するためのルール。

---

## Complex Modifications Assets

`assets/complex_modifications/` にインポート済みのルールファイルが保存されている。

### 1744414411.json — 英かな/⌘ for Japanese

Karabiner-Elements の公式サンプルをベースにしたルール。

| ルール | 内容 |
|--------|------|
| 左⌘単独押し → 英数、右⌘単独押し → かな | US キーボードで英数/かな切り替え |
| 英数/かな + 他キー → ⌘ として動作 | JIS キーボード向けの逆パターン |
| **⌘W を2連打でのみタブを閉じる** | 誤操作防止。1回目は無効、2回目で `⌘W` を発火 |
| **⌘Q を2連打でのみアプリを終了** | 誤操作防止。1回目は無効、2回目で `⌘Q` を発火 |

### 1744501662.json — Personal rules (@ccmvn)

US キーボードでドイツ語ウムラウトを入力するためのルール。

| キー操作 | 出力 |
|----------|------|
| `Option+A` | Ä |
| `Option+O` | Ö |
| `Option+U` | Ü |

英語入力ソース (`^en$`) のみで動作。

---

## Fn キー設定

| キー | 動作 |
|------|------|
| `F6` | Launchpad を開く |

---

## 仮想 HID キーボード

`keyboard_type_v2: "ansi"` — ANSI キーボードとして動作。
