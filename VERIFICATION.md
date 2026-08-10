# Verification report — v2.5.1


## 2.5.1 release-metadata hotfix gate — PASS (automated)

- Verified source baseline: final assistant-delivered `special_stat_split_v2.5.0.zip`, SHA-256 `599f73249c8b26922dc94ef78b3d3ce5469acbff51457b5e4a69fd84f04df6a7`.
- Manifest and `main.lua` identity moved to `2.5.1`; `experimental=false`, `affects_link=true` and the exact v0.1.75 game-version pin are retained.
- Inherited public `specialStatSplit` API reports `apiVersion = 1` and aliases the legacy implementation functions rather than duplicating battle logic.
- `getGameplayConfig()` returns a defensive copy; diagnostics expose link registration and detected integrations without mutating them.
- All four gameplay combinations produce distinct deterministic `link_fields.rev` strings; source contract rejects any Special Stat Split wrapper around `link.fingerprint`.
- The normal runtime suite passes across GEN II/VANILLA × GEN IV+/GEN I combinations, readout/standalone combinations, Modern UI capability guards and Crystal 251 contracts.
- Frozen upstream fingerprint execution is wired into `tools/run_all.sh` when the pinned Gen1Recomp source root is supplied. It was not executable in this build environment because that external frozen source tree was not locally available.
- User-reported in-game functional/UI smoke: **PASS** for the final promotion. Dedicated real two-peer link QA was **not performed and is not claimed as certified**; an optional matrix is retained in `OPTIONAL_LINK_QA_2.5.1.md`.
## PASS — Party layout choice

The option schema defaults to `2 ROWS`; `1 ROW` renders exactly `ATK / DEF / SPD / SPATK / SPDEF`. Both modes are exercised against the real Modern UI 0.8.4 renderer, including a narrow panel, with shared adaptive font sizing and no intentional ellipsis. Summary regression remains unchanged.


Frozen target: Gen1Recomp `v0.1.75`, commit `60cf07fb0a1ffce0ec6d5d0d2f78a921a6d0b7da`.

## 2.4.2 source / Modern UI 0.8.4 gate

- Source baseline: exact assistant-delivered `special_stat_split_v2.4.1.zip`, SHA-256 `befbc6c997fc6f464ddf076589a6272e76f6084910246538b3116e0cc904fb54`.
- Audited Modern UI asset: exact uploaded/official `gen1_modern_ui-0.8.4.zip`, SHA-256 `c6c9804a025cfb254f155c617bfa81c1431a86aa4b74c9e6e57dfb6dcddeb67e`.
- Modern UI compatibility API remains v1.
- `drawParty`, `drawMonDetail`, `displayStats`, and the Summary stat-page renderer used by the ordinary shim are unchanged from 0.8.3.
- The ordinary surgical shim is no longer release-number allowlisted. It is verified against 0.8.3/0.8.4 and also tested with a synthetic future 0.9.9 version exposing the same renderer capabilities.
- Full runtime suite passes against the real 0.8.4 source and regression checks also pass against 0.8.3.
- Frozen Gen1Recomp v0.1.75 source hashes and integration suite pass.


## Source baseline discipline — PASS

- Final promotion input was the accepted `special_stat_split_v2.4.2-test7` package, SHA-256 `c8e9402c222aef37539f683078b729cfd2e97a9895a5029d3d24c110c332fef7`.
- Internal pre-edit identity was verified as `2.4.2-test7` in `manifest.json`, the `main.lua` version header and packaged runtime/source contracts.
- The final promotion changes no executable gameplay/UI logic in `main.lua`; its only `main.lua` change is the version comment.
- The final package changes release metadata, test expectations and documentation from test7 to `2.4.2`.


## Integrated Move Category Readout — PASS

- Option `MOVE CATEGORY READOUT` exists and defaults ON.
- ON/OFF is presentation-only and read live; no restart is required.
- GEN IV+ mode follows explicit merged `move.category`; GEN I mode follows TypeChart fallback.
- Damaging Fire Punch regression: GEN IV+ -> `PHYS/`; GEN I -> `SPEC/`.
- Status/power-0 records retain `TYPE/`.
- Outside `moveSelect` / after `battle.ended`, vanilla `TYPE/` is retained.
- Standalone `move_category` coexistence is tested with both wrappers active; the final label is emitted once and no manifest conflict is declared.
- A module-level dispatcher sentinel prevents Special Stat Split hot reload from stacking another copy of its own Font wrapper.

## Launcher update metadata — PASS

- Manifest keeps `github = ZyranCZ/Special-Stat-Split`.
- Mod id remains `special_stat_split`; release version is `2.4.2`.
- `move_category` is optional only; the combined mod's update source remains the Special Stat Split repository.

## Crystal 251 interoperability contract

The packaged test suite now includes `tests/crystal251_contract.lua`. It verifies:

- canonical unequal Johto split bases (Togetic 80/105; Espeon 130/95; Umbreon 60/130);
- deliberately wrong/equal Crystal exports (Togetic 99/99 and Espeon 99/99) are ignored in favor of the mod-owned canonical table;
- registry and private-runtime category synchronization for Gen II moves;
- Fire/Normal/Flying/Poison/Electric/Dark/Ghost category inversions that would fail under Crystal's native type-based dispatcher;
- the Crystal damage bridge keeps the elemental type intact;
- the temporary dispatcher override is restored after both normal calls and forced errors;
- standalone GEN II/GEN IV, GEN II/GEN I, VANILLA/GEN IV and VANILLA/GEN I contracts still pass independently.

`verify_gen4_move_categories.py` now validates **251/251** category rows with totals 106 Physical / 52 Special / 93 Status. The separate generation-history audit remains intentionally scoped to the 165 original Gen I moves.

## Reference/stat data — PASS

- **251/251** National Dex #001–251 species exactly once.
- **502/502** Gen II–V Sp. Atk/Sp. Def values cross-checked.
- Shared Special DV/Stat Exp behavior and split-stat formula contracts pass.

## Move category data — PASS

- 251/251 Gen I+II modern category entries exactly once.
- Counts: 106 Physical / 52 Special / 93 Status.
- Slots 166..251 are applied only when Crystal 251 supplies the matching canonical records.
- 165/165 exact Gen1Recomp registry identity entries.
- Exact legacy-ID sentinels include `PSYCHIC_M`, `HI_JUMP_KICK`, `THUNDERPUNCH` and `SONICBOOM`.
- 18 Gen I -> GEN IV+ damaging category flips confirmed.

## Generation history audit — PASS

- 165/165 original moves compared across Gen IV, V, VI, VII, VIII and IX.
- Zero category differences among those six later generations for this move pool.
- Four Gen I -> Gen II elemental-type migrations documented separately.
- Packaged non-category changelog contains 83 field changes affecting 51 original moves from Gen IV onward.

## Collision contracts — PASS

The runtime registry stub deliberately injects an earlier wrong Fire Punch category and a fake custom move that reuses index 7. Tests prove:

- GEN IV+ overwrites the earlier canonical category with the audited value.
- GEN I mode removes an earlier canonical explicit category via `mod.DELETE` and restores by-type fallback.
- The fake reused-index custom move is skipped.
- Exact `HI_JUMP_KICK` registry identity is recognized despite modern naming differences.

## Damage/math contracts — PASS

- All stat stages -6..+6 and clamp behavior.
- Exact floor-sensitive SpA/SpD vectors.
- Light Screen, Volcano Badge operand ordering, faithful crit bypass, modern-clean crit stage path and physical control vector.
- Fire Punch demonstrates Attack/Defense routing in modern mode.
- Hyper Beam demonstrates Sp. Atk/Sp. Def routing when split stats are enabled.
- All four combinations of Special-stat mode x category mode execute successfully.

## Engine category-use audit — PASS

The frozen Lua target was searched globally. Explicit `move.category` is consumed by `src/battle/Damage.lua`; no additional trainer-AI or hidden move-effect category consumer was found. The ordinary damage function gives the explicit field precedence over type fallback.

## Frozen upstream integration

The complete frozen integration suite was rerun for v2.4.2 against the exact Gen1Recomp v0.1.75 source snapshot and passed its source-hash, battle/stat, save, and lifecycle contracts.

## Manual release state

- Final 2.5.1 in-game functional/UI smoke: **PASS (user-reported)**.
- Integrated Move Category readout and Modern UI presentation paths: **PASS in the user's live smoke**, with automated coexistence/capability coverage retained.
- Dedicated two-peer live link battle: **NOT PERFORMED / NOT CLAIMED AS CERTIFIED**. Link-config protection remains a best-effort safeguard based on the public Gen1Recomp v0.1.75 fingerprint surface.

The release is not being reclassified as a full modern battle engine. v2.5.1 preserves the audited split-stat/category/Crystal gameplay paths and the completed Modern UI Party/Summary presentation while adding API/diagnostic/link-config infrastructure.

## PASS — Modern UI Party/Summary surgical override contract (current code)

- The previous generic Party/Summary adapter is not registered. Modern UI remains the owner of the complete built-in presenters.
- The ordinary override requires compatibility API v1 plus the needed renderer/helper capabilities; release numbers themselves do not gate compatibility.
- The Modern UI renderer is resolved through guarded capability discovery from its public `getScaleTokens` export. The shim first checks the familiar runtime upvalue and can fall back to capability-based upvalue discovery; required renderer/helper functions are verified before any wrapper is installed.
- Party: the real upstream `drawParty` and `drawMonDetail` run first. Only the finished lower text block is repainted: row 1 is ATTACK / DEFENSE / SPEED, row 2 is SPEC. ATTACK / SPEC. DEFENSE, followed by the same move/PP list using Modern UI's own helpers. Party list, icons, selected sprite, type, HP bar, frame, spacing, theme and interaction remain upstream-rendered.
- Summary page 1: the real upstream `drawSummary` runs first. Every viewport stacks SP. ATTACK and SP. DEFENSE on separate rows, then repaints ID/OT below them using Modern UI's native fallback values and label/value spacing.
- `ModernUI Override = OFF` leaves ordinary Modern UI Party/Summary output untouched. VANILLA Special mode likewise performs no split-stat repaint.
- Battle Party is gated separately by `ModernUI BattleWIP Override`; with that option OFF, the surgical Party row does not alter battle presentation.
- Hot-reload restoration prevents wrapper stacking.

## PASS — Modern Battle UI level-up correction contract (current code, gated by BattleWIP)

- Public-hook only: `ui.state.decorate` + `render.hud`; no foreign source replacement and no Modern UI private-function patch.
- Real-hook contract: the supported Modern UI 0.8.3/0.8.4 priority-100 `ui.state.decorate` is executed beneath Special Stat Split's priority-200 observer. With experimental BATTLE UI (WIP) ON it replaces the exact source-owned split StatBox draw.
- Exact-identity guard: only replacement of Special Stat Split's own `splitStatBoxDraw` is treated as a candidate; an unrelated draw wrapper is not enough.
- Native-draw guard: the source split draw marks the frame when it actually executes. HIDE ORIGINAL UI OFF therefore produces no duplicate correction even while Modern UI's decorator remains installed.
- Default-off guard: turning BATTLE UI (WIP) OFF and running a fresh decoration pass restores the source split draw and retires the candidate; no correction overlay is produced.
- Hook priority/order contract: correction HUD is priority 200, calls downstream first, and paints only afterward.
- Exact-state guard: only the active `BattleState.StatBox` can trigger the correction.
- Split-mode guard: VANILLA Special produces no correction.
- Dependency guard: with Modern UI absent, no level-up compatibility hooks are installed.
- Correct visible rows: ATTACK / DEFENSE / SPEED / SP. ATK / SP. DEF; the correction card never emits a legacy SPECIAL row.
- Full 251-stat / 251-move / Crystal / save / frozen-upstream regression suite remains PASS.


## PASS — Modern UI override ownership / future-version guards (2.4.2)

- `ModernUI Override` exists as an exact-label toggle and defaults **true/ON**; OFF prevents ordinary Party/Summary ownership by Special Stat Split.
- `ModernUI BattleWIP Override` exists as an exact-label toggle and defaults **false/OFF**; OFF prevents battle Party ownership and produces no level-up correction card even when the real Modern UI 0.8.3/0.8.4 WIP battle decorator suppresses the native StatBox.
- BattleWIP Override ON retains the behavior-detected battle Party and level-up correction paths.
- The full ordinary-override ON/OFF × BattleWIP ON/OFF matrix passes against real Modern UI 0.8.3/0.8.4.
- A synthetic future release number 0.9.9 with API v1 and compatible renderer capabilities remains supported; a synthetic compatibility API v2 is rejected and installs no unsupported compatibility hooks (fail closed).
