# SPECIAL STAT SPLIT 2.5.1 — specification

Frozen upstream: Gen1Recomp `60cf07fb0a1ffce0ec6d5d0d2f78a921a6d0b7da` (v0.1.75).

## Inter-mod and link contracts

- Preserve legacy root exports.
- Publish `exports.specialStatSplit` with `apiVersion = 1`; consumers feature-detect the API version, not the release number.
- Gameplay config is exactly `{ specialStats = vanilla|gen2, moveCategories = gen1|gen4 }`.
- Register `link_fields["special_stat_split_rules"].rev` as `special=<...>;move=<...>` at load time.
- Do not include presentation-only toggles in the link revision.
- Do not hook/replace Gen1Recomp's `link.fingerprint`; let the engine hash the merged public link surface.
- Expose read-only diagnostic snapshots for troubleshooting.

## Integrated Move Category Readout

- Own option: `move_category_readout`, label `MOVE CATEGORY READOUT`, default ON, live presentation-only.
- Replace only the exact vanilla `TYPE/` label during `battle.phase == moveSelect`.
- Damaging move: explicit `move.category` first, active TypeChart category second, physical fallback for unknown types.
- Status/power-0 move: leave `TYPE/`.
- Do not alter move type, power, category, damage math or battle state.
- Standalone `move_category` is optional and may coexist. No manifest conflict; wrappers must produce only one visible label.
- Hot reload must update the integrated dispatcher without stacking another Special Stat Split Font wrapper.
- Preserve `github = ZyranCZ/Special-Stat-Split` for native launcher update checks.

## Special-stat mode

When enabled, derive separate Sp. Atk and Sp. Def from Generation II–V Kanto base stats while retaining one shared `dvs.special` and one shared `statExp.special`. Route ordinary special-category damage through attacker Sp. Atk and defender Sp. Def. Preserve existing Growth/X Special -> Sp. Atk and Amnesia/Psychic drop -> Sp. Def behavior, Transform/Haze/screens/save/UI lifecycle contracts and exact upstream floor ordering.

## Move-category mode

Expose two restart-required category eras:

- `GEN I (BY TYPE)` — force canonical original moves to have no explicit category so Gen1Recomp's type-based fallback decides the damage side.
- `GEN IV+ (BY MOVE)` — assign the audited individual category to all 165 canonical original moves; when Crystal 251 supplies Gen II moves, extend ownership through canonical slots 166..251.

The modern table is called GEN IV+ because the complete 165-row audit proves category equality across Generations IV, V, VI, VII, VIII and IX for this move pool.

## Canonical move ownership

Patch only a move that matches both its numeric slot 1..165 and the exact Gen1Recomp ROM-manifest identity for that slot. Skip noncanonical reused-index records. Use official `mod.DELETE` in GEN I mode to clear an earlier explicit category.

Priority semantics remain normal Gen1Recomp semantics: priority 150 owns the result over earlier patches; later/higher-priority patches may supersede it.

## Preserve

Do not modernize move elemental type, power, PP, accuracy, priority, target, secondary effect, fixed-damage behavior, Counter/Bide/OHKO logic, trapping, recharge, critical-hit logic, STAB or type effectiveness. These are independent mechanics.

Do not introduce Dark or other new types in this mod. Do not advertise a full Gen II/III preset, because historically correct Bite and other type migrations would require broader type/chart behavior than a category toggle.

## Data/audit requirements

Package and verify:

- 251-species Gen II–V split base-stat data, authoritative over optional Crystal exports.
- 251-entry Gen I+II modern category table (slots 166..251 activate only with matching Crystal content).
- 165-entry exact Gen1Recomp move-ID table.
- 165-row Gen IV–IX category parity audit.
- Historical non-category move-change audit from Gen IV onward.
- 18 Gen I -> Gen IV+ damaging category flips.
- Four Gen I -> Gen II elemental-type migrations.

## Release gate

Automated reference + Lua runtime contracts must pass, with exact frozen-upstream suites rerun whenever the pinned source snapshot is available. Collision regression must prove earlier-category deletion, fake reused-index skipping and legacy `HI_JUMP_KICK` identity. Final release requires a live single-player/UI compatibility smoke. Dedicated two-peer link certification is optional and must not be claimed unless it is actually performed.

## Optional Crystal 251 extension

When `CRYSTAL_251` is absent, all standalone ownership and calculation rules remain unchanged. When present, canonical #001–251 split bases still come from this mod's own audited table; Crystal's split-base export is non-authoritative fallback/diagnostic data. GEN IV+ move categories extend through canonical indices 166..251. Crystal's private move table and its type-based damage dispatcher must agree with the selected per-move category without altering elemental type.


## Modern UI presentation rules

**ModernUI Override** MUST be a live presentation-only toggle defaulting **ON**. When the required Modern UI renderer capabilities are present it MUST preserve Modern UI's built-in ordinary Party and Summary presenters and change only the legacy Special-stat text areas. It MUST NOT replace those complete screens with the generic external adapter presenter. OFF MUST leave Modern UI completely untouched. A new Modern UI release number alone MUST NOT disable the shim; only an incompatible API/renderer capability change may make it fail closed.

**ModernUI BattleWIP Override** MUST be a separate live presentation-only toggle defaulting **OFF**. It controls provisional compatibility that exists only for Gen1 Modern UI's experimental BATTLE UI (WIP), including the battle Party stat-row repaint and the level-up correction bridge.

Only when **ModernUI BattleWIP Override = ON**, split stats are active, and the experimental Battle UI decorates/suppresses the native `BattleState.StatBox`, Special Stat Split may present both Sp. Atk and Sp. Def through public Gen1Recomp hook seams. Detection must be based on downstream `ui.state.decorate` replacing Special Stat Split's exact source-owned draw plus the absence of that native draw in the current frame. It must not read foreign private options, modify Modern UI code, mutate level-up state/input, or draw a duplicate card when the native StatBox remains visible. With the experimental Battle UI disabled, the normal native five-stat StatBox is authoritative.

Ordinary exact-layout compatibility MUST require Modern UI public compatibility API v1 plus the renderer/helper capabilities used by the surgical shim. Release numbers MUST NOT be used as an allowlist. Compatible future releases should continue automatically; missing/incompatible capabilities must fail closed. If Modern UI later publishes a cleaner supported data-extension seam for its existing layouts, migrate to that seam and retire the private-runtime override.
