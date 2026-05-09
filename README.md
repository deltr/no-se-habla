# No Se Habla

A WoW addon for **Project Epoch** (WotLK 3.3.5a) that suppresses non-English chat in public channels and replaces it with a clickable `[suppressed]` stub. Hover the stub to peek, click it to reveal the original message in chat.

## Install

```
git clone https://github.com/deltr/no-se-habla.git "<WoW>/Interface/AddOns/No Se Habla"
```

Or download the zip and extract so the folder layout is:

```
Interface/AddOns/No Se Habla/
  ├── No Se Habla.toc
  ├── NoSeHabla.lua
  └── README.md
```

`/reload` (or restart the client) and you should see `[No Se Habla] loaded` on login.

## What it filters

Public channels only: **Say**, **Yell**, **Emote**, and numbered/world channels (Trade, General, World, LookingForGroup). Whisper, Guild, Officer, Party, Raid, and Battleground are left alone.

A message is suppressed if **any** of three detectors fire:

1. **Script-based** — message has ≥30% non-Latin letters (Cyrillic, CJK, Hangul, Arabic, Hebrew, Thai, Greek). Threshold tunable.
2. **Transliterated Russian** — distinctive Russian-in-Latin words (`vseh`, `dlya`, `kacha`, `nabor`, ...). ≥2 hits flag the message.
3. **English density** — for messages with ≥7 word tokens, if fewer than 10% of tokens are distinctive English function words, flag. Catches Spanish, Portuguese, Dutch, French, German, Italian, etc. without per-language wordlists.

Chat hyperlinks (`[Quest Name]`, `[Item]`, `[Spell]`) are stripped before language analysis — they're game content, not language, so a message linking quests doesn't count their display text against the English-density check.

## Slash commands

| Command | What it does |
|---|---|
| `/nsh` or `/nsh status` | Show enabled state, threshold, cache size |
| `/nsh on` / `/nsh off` / `/nsh toggle` | Enable/disable filtering |
| `/nsh threshold <0-100>` | Tune the script-based detector ratio |
| `/nsh last [N]` | Print the last N suppressed messages |

`/nosehabla` works as an alias.

## Reveal behavior

When a message is suppressed, the chat line becomes:

```
[5] [Sender]: [suppressed]
```

- **Hover** the `[suppressed]` link → `GameTooltip` shows the original (truncated to ~240 chars).
- **Click** → the full original is reprinted into chat as `[shown] Sender: <original>`. Nothing is lost; the cache holds the last 200 suppressed messages.

## False positives

If a legitimate English message gets suppressed, click `[suppressed]` to see what it was, then either:

- `/nsh off` to disable the addon entirely, or
- Open an issue with the message text — the English-marker list can be tuned.

The detection model deliberately favors a few false positives over letting verbose foreign recruitment spam through. Trade chat shorthand (`pst`, `lf3m`, `wts`, `lvl`, etc.) is recognized as English.

## License

MIT. Use it, fork it, change it.
