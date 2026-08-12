# Special Stat Split v2.6.4 — Gold / Gen 2 status

Port source baseline: Special Stat Split **2.5.2**, authoritative ZIP SHA-256 `0c61c8ae4eb537f5f45e586a4d965c4f5ae333e41289403e72144e86870b5e16`.

Current upstream UI re-audit anchor: `bryanthaboi/gen1recomp` `dev` commit `01aab1d763c2e2d6878a0a25d606c02b3f569818` (2026-08-12). Gold battle/category architecture was originally audited against `ae6cac89e12ea7a844bcf7e11be9d079abbd9365`; the relevant `phase = "moves"` + public `battle.overlay` presentation seam remains present on the newer source.

## Status legend

- **VERIFIED** — direct artifact/config/source fact checked.
- **STATICALLY VERIFIED** — checked against current upstream source shape, not a running Gold game.
- **HEADLESS PASS** — automated runtime-like contract passed with source-shaped stubs.
- **LIVE PASS** — verified in a real game runtime.
- **NEEDS LIVE TEST** — implementation exists, but a real runtime is still required.
- **BLOCKED** — required verification cannot be executed in this workspace.
- **NOT APPLICABLE** — intentionally absent because Gold already owns the mechanic.

## Completed

| Area | Status | Result |
|---|---|---|
| Authoritative ZIP SHA / v2.5.2 manifest | VERIFIED | exact expected hash/version/permissions/dependencies; original ZIP untouched |
| Packaged v2.5.2 baseline suite before edits | HEADLESS PASS | complete bundled suite passed; frozen external checkout unavailable |
| Early generation boundary | HEADLESS PASS | generation 2 branches before all historical Gen 1-only requires |
| Gen 1 behavior after refactor | HEADLESS PASS | complete packaged suite passes after every shared-code correction |
| Gen 1 move identity contract | HEADLESS PASS | remains exactly 165/165; first accidental 251 expansion was detected, reverted and retested before Gold work resumed |
| Gold canonical identity extension | HEADLESS PASS | separate 166..251 identity map; custom numeric-index collision skipped |
| Gold native Special stats policy | HEADLESS PASS / STATICALLY VERIFIED | no Gen 1 stat/EXP/effect/save/UI backend loaded; requested Special setting maps to effective `native_gen2` |
| GEN IV+ normal damage routing | HEADLESS PASS / STATICALLY VERIFIED | both type->category flip directions use correct operand pair while native formula remains authoritative |
| Reflect / Light Screen category | HEADLESS PASS | same scoped category as damage calculation |
| Damage-kind history / Counter-Mirror Coat basis | HEADLESS PASS | stored kind follows effective per-move category |
| AI expected damage | HEADLESS PASS / STATICALLY VERIFIED | direct `Damage.calc` path receives the same per-move category |
| Smart-AI history | HEADLESS PASS / STATICALLY VERIFIED | used/last move category modernized; native type heuristic retained |
| Error/reentrancy restore | HEADLESS PASS | scoped category is restored after thrown error; no leak to next attack |
| Type-based Gold mode | HEADLESS PASS | bridge inactive; canonical explicit modern categories removed; FIRE/GHOST return to native Gold type categories |
| Gold link effective revision | HEADLESS PASS | requested VANILLA/GEN II Special modes share `special=native_gen2`; move mode remains distinguishing gameplay field |
| API v1 preservation / API v2 | HEADLESS PASS | v1 remains version 1; Gold-safe no-op legacy stat helpers; v2 exposes requested/effective config/native stat access |
| Gold move readout | LIVE PASS / HEADLESS PASS | live v0.1.78 tuning confirmed the top-border title approach; final field width is normalized across categories without replacing Gold move rows |
| Full packaged suite after Gold work | HEADLESS PASS | all historical Gen 1/Crystal/reference contracts plus Gold static/runtime contracts pass |

## Deliberately not done yet

| Release gate | Status | Why |
|---|---|---|
| Official `modkit.py gen2check --notes` | BLOCKED | current upstream executable checkout/tool cannot be cloned into the container; connector inspection is not an execution substitute |
| Current generated Gold 251/251 registry audit | NEEDS LIVE TEST | generated move registry comes from the Gold runtime/imported data; checkpoint diagnostics report observed count and warn if not 251 |
| Real Gold boot / battle entry | LIVE PASS | user booted Pokémon Gold v0.1.78 with the Gold-targeted checkpoint and reached a normal wild battle |
| Native Summary / Party / level-up visual negative test | PARTIAL LIVE PASS | user confirmed split Special stats display correctly in the Gold Pokémon Summary; Party and level-up presentation still need live confirmation |
| Growth / Amnesia / Psychic / X SPECIAL / Transform exact-once runtime | NEEDS LIVE TEST | Gold code is intentionally untouched; must still be smoke-tested live |
| Save/restart/load with Gold DVs/Stat Exp/SpA/SpD | NEEDS LIVE TEST | no Gold save runtime available |
| Counter / Mirror Coat real battle | NEEDS LIVE TEST | history basis is covered headlessly; end-to-end effect behavior still needs live confirmation |
| Held items / weather / STAB / effectiveness / crit live non-regression | NEEDS LIVE TEST | native formula/type remain untouched by construction; live integration still required |
| Optional mod combinations on Gold | NEEDS LIVE TEST | Crystal/Gen1 Modern UI are N/A; other Gold-capable mods need real combination tests |
| Gold link play | NOT APPLICABLE / FUTURE until current upstream capability is explicitly confirmed and tested |
| `games` Gold manifest opt-in | VERIFIED | final release declares `games: ["gen1", "gold"]`; Silver/Crystal are not claimed |
| Version bump to 2.6.0 | VERIFIED | Gold feature release identity applied after user live UI approval |
| 2.6.3 Gen 3 UI compatibility | LIVE PASS | inline foreign-UI presentation confirmed in real Gold; final font/colour/pixel alignment/bold weight accepted |
| 2.6.4 Gen 3 UI duplicate suppression | LIVE PASS basis + regression PASS | native category readout is mutually exclusive with the observed Gen 3 UI footer in Gen 1 and Gold; widescreen legacy-label leak removed |

## Current automated command

```sh
bash tools/run_all.sh
```

The current run passes the original reference/math/category/source/runtime/Crystal contracts plus:

- `tools/verify_gold_backend.py`
- `tests/gold_backend_contract.lua`

The Gold contract covers Fire Punch and Shadow Ball opposite-direction category flips, screen/damage-kind consistency, AI, smart-AI history, collision protection, error-safe restore, API/link semantics, the full selected-move border-tab readout (Physical/Special/Status/Fixed/OHKO/Reactive), SELECT-reorder coexistence, and hot reload back to native type-based behavior.

## Release decision

**Special Stat Split 2.6.4 is the live-verified Gold release baseline.** Native Gold mechanics remain inherited from 2.6.0, while the Gen 3 Inspired UI inline move-category row is now LIVE PASS. Silver/Crystal remain undeclared.
## 2.6.4 Gen 3 UI duplicate suppression

- Gen 3 UI footer presentation remains mechanically identical to the accepted 2.6.3 alignment/weight implementation.
- Once a compatible `TYPE … PP` footer is active, the native Gold top-border category tab is suppressed instead of being drawn behind the replacement panel.
- On Gen 1, the native `TYPE/` -> `PHYS/` / `SPEC/` Font shim is suppressed while Gen 3 UI owns the move footer, including protection from a downstream standalone Move Category wrapper.
- This removes the legacy category text that becomes visible outside the replacement panel in widescreen layouts.

## 2.6.3 Gen 3 UI integration

- Gen 3 Inspired UI Overhaul v1.4.0 release metadata / Gold support: STATICALLY VERIFIED via GitHub release.
- Optional mod id `gen3_battle_ui`: inherited from the committed prior package; used as capability-detection key.
- Inline TYPE/PP row bridge: HEADLESS PASS.
- PHYSICAL / SPECIAL / STATUS routing: HEADLESS PASS.
- Duplicate suppression / fail-safe / renderer restoration: HEADLESS PASS.
- Real v1.4.0 visual smoke on Gold: NEEDS LIVE TEST.

LIVE RESULT: Gen 3 UI v1.4.0 move footer successfully displays the Special Stat Split category inline; final styling was accepted after colour/font matching, integer pixel snap and 1px bold overdraw.

