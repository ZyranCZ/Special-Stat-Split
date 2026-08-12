# Gold category-consumer audit

Upstream audit anchor: `bryanthaboi/gen1recomp` `dev` commit `ae6cac89e12ea7a844bcf7e11be9d079abbd9365` (2026-08-11, "G2 support").

The Gold backend must change exactly one question in GEN IV+ mode: **which stat pair is used for this move?** It must not fork Gold's damage formula or fake a different elemental type.

| Consumer | Current Gold source | GEN IV+ requirement | Implementation | Status |
|---|---|---|---|---|
| Normal damage stat pair | `Damage.calc()` calls `Damage.isPhysical(moveType, types)` | use per-move category | scoped category resolver around native `Damage.calc` | HEADLESS PASS / STATICALLY VERIFIED |
| Reflect / Light Screen selection | `Battle:hitOnce()` calls `Damage.isPhysical()` before damage | same category as actual hit | entire native `hitOnce` executes inside the same scoped resolver | HEADLESS PASS / STATICALLY VERIFIED |
| Damage history `physical` / `special` kind | `Battle:hitOnce()` calls `Damage.isPhysical()` again before `dealDamage` | store the actual per-move category | same `hitOnce` scope covers the post-calc kind write | HEADLESS PASS / STATICALLY VERIFIED |
| Counter / Mirror Coat | consume the stored damage kind/history | respond to the move's actual category | no separate formula patch; correctness comes from the stored kind above | HEADLESS PASS at history contract; NEEDS LIVE battle smoke |
| AI expected damage | `Ai` calls `Damage.calc()` directly, outside `battle.damage` | evaluate the same stat pair battle will use | `Ai.choose` arms one category immediately after `moveDef`, consumed by exactly one wrapped `Damage.calc` | HEADLESS PASS / STATICALLY VERIFIED |
| Smart-AI used-move history | `Battle:smartAiState()` derives used/last categories from type | count modern move categories | postprocess physical/special counts and last-move category | HEADLESS PASS / STATICALLY VERIFIED |
| Smart-AI type heuristic | `playerSpecialType` is deliberately a **type** heuristic | remain type-based | left untouched | HEADLESS PASS |
| STAB | native Gold move type | unchanged | no move-type rewrite | BY CONSTRUCTION / NEEDS LIVE |
| Type effectiveness / immunities | native Gold move type + type chart | unchanged | no move-type rewrite | BY CONSTRUCTION / NEEDS LIVE |
| Weather | native Gold move type / native damage path | unchanged | native `Damage.calc` retained | BY CONSTRUCTION / NEEDS LIVE |
| Held type boosters | native Gold item/type path | unchanged | native damage path retained | BY CONSTRUCTION / NEEDS LIVE |
| Crit / damage variation | native Gold damage path | unchanged | native `Damage.calc` retained | HEADLESS formula delegation; NEEDS LIVE |
| Fixed/direct damage effects | dedicated Gold effect paths | category metadata must not convert them to ordinary stat damage | no effect-function rewrite; category bridge only surrounds native hit calculation where reached | STATICALLY SAFE; NEEDS LIVE sentinels |
| Move-select presentation | Gold move list has no TYPE field; `BattleState:drawScene` raises public `battle.overlay` | expose effective category without replacing renderer | public overlay draws one `P`/`S` gutter marker for selected damaging move | HEADLESS PASS / STATICALLY VERIFIED; NEEDS LIVE visual |
| Summary / Party / level-up split stats | native Gold screens/models | no duplicate mod UI | Gold backend never loads Gen 1 Summary/StatBox/ModernUI patches | HEADLESS require-guard PASS; NEEDS LIVE visual |

## Scoped bridge invariants

- The active category is stack-scoped and restored on success **and** error.
- `Damage.isPhysical` delegates to Gold's original implementation when no scoped category is active.
- `Damage.calc` is not copied or reimplemented.
- Move `type` is never substituted to force a category.
- A custom move that merely reuses a canonical index does not inherit that canonical move's category unless its identity also matches.
- Hot reload into type-based mode disables the bridge and returns classification to native Gold type rules.

## Remaining live-sensitive consumers

The code/source audit covers the current explicit classification call sites, but live Gold still needs Counter/Mirror Coat, fixed/direct effects, held items, weather, critical hits, save/load and visual readout confirmation. A future upstream change that adds a new `Damage.isPhysical`/type-category consumer must trigger a fresh audit.
