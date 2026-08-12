# Gold / Gen 2 compatibility audit — official gen2check status

## Official command

```sh
python3 tools/modkit.py gen2check <mod-path> --notes
```

**Current status: BLOCKED in this workspace, not falsely marked PASS.** The original v2.5.2 baseline package does not include the engine's `tools/modkit.py`, and the current upstream checkout could not be cloned into the execution container because `github.com` was not resolvable there. Current upstream source and the official tool/docs were still inspected through the GitHub connector, but that is not equivalent to executing `gen2check`.

A second attempt to clone the current `dev` tree failed with the same DNS-resolution error. Version 2.6.3 therefore ships with the manual/static equivalent audit plus headless Gold contracts and records the official command as an unexecuted verification item rather than claiming a false PASS.

## Manual finding matrix

| Finding area | v2.5.2 purpose | Gold equivalent / risk | Action in checkpoint | Status |
|---|---|---|---|---|
| Gen 1 `src.pokemon.Stats` / split attach | emulate SpA/SpD | Gold already owns split stats | early generation boundary; not loaded on Gold | RESOLVED BY ARCHITECTURE |
| Gen 1 `src.battle.Damage` alias | route one legacy SPECIAL | Gold has native SpA/SpD operands | not loaded; Gold-specific category bridge uses native Gen2 Damage | RESOLVED BY ARCHITECTURE |
| Gen 1 EXP workaround | feed shared Special Stat Exp | Gold already native | not loaded | RESOLVED BY ARCHITECTURE |
| Gen 1 X SPECIAL / move-effect patches | map legacy Special stages | Gold effects are native | not loaded | RESOLVED BY ARCHITECTURE |
| Gen 1 Transform patch | attach derived split stats | Gold split stats are native | not loaded | RESOLVED BY ARCHITECTURE |
| Gen 1 SaveData stripper | keep derived fields out of Gen1 save | dangerous on native Gold stats | not loaded | RESOLVED BY ARCHITECTURE |
| Gen 1 Summary / StatBox | present emulated split | duplicate Gold native UI | not loaded | RESOLVED BY ARCHITECTURE |
| Crystal 251 private bridge | supply Johto content/private damage in Gen1 | Johto is native in Gold | Gold backend ignores Crystal gameplay bridge | NOT APPLICABLE ON GOLD |
| Gen1 Modern UI shim | repair single-Special assumptions | Gold native UI is different | not installed on Gold | NOT APPLICABLE ON GOLD |
| Move registry 1..251 | modern category ownership | native Gold has full canonical move pool | separate Gold identity table + collision guard | HEADLESS PASS; LIVE 251/251 AUDIT REQUIRED |
| Gold category consumers | type-derived category in multiple paths | GEN IV+ must be coherent everywhere | shared scoped resolver; see `GOLD_CATEGORY_CONSUMERS.md` | HEADLESS PASS / STATICALLY VERIFIED |
| Gold readout | Gen1 TYPE-token wrapper does not apply | different Gold UI | public `battle.overlay` top-border category title | LIVE PASS / HEADLESS PASS |
| Link fingerprint | requested Special option is a Gold no-op | false mismatch risk | effective `special=native_gen2` | HEADLESS PASS; LIVE LINK FUTURE |
| Engine version gate | must not reject future engine versions | release churn | no `game_version` added | VERIFIED |
| Gold manifest claim | claim only verified scope | Gold live boot/UI exercised | final `games: ["gen1", "gold"]`; no Silver/Crystal claim | VERIFIED |

## What a future official rerun should establish

When an executable current upstream checkout is available, run the official command and record **every MK400–MK410 ERROR/WARN and every `unresolved:` site**. Any fatal finding or unexplained warning/unresolved site should be treated as a concrete compatibility regression to fix. Version 2.6.3 does not claim that this command was executed in the present workspace.
