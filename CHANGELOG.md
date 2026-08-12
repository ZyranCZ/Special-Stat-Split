# Changelog

## 2.6.5 — Stable Gen 3 UI footer column

- Fixes horizontal category drift in **both Gen 1 and Pokémon Gold** when Gen 3 Inspired UI changes the width/position of the elemental type or PP text.
- `PHYSICAL`, `SPECIAL`, and `STATUS` now anchor their **first letter** to a fixed footer-local column derived from the stable literal `TYPE` label rather than from the variable type value or PP field.
- The Gen 1 implementation is the user-live-approved TEST F fixed-footer path; the Gold implementation uses the same fixed-column principle and is also user-live-approved.
- Keeps the 2.6.4 native-readout suppression, visible-type baseline, font/colour inheritance, antialiasing, Gen 1 55% semibold weight, and Gold 70% semibold weight.
- No battle math, category ownership, save/link behavior, native UI behavior without Gen 3 UI, or declared game support changes.

## 2.6.4 — Gen 3 UI native-readout suppression

- Fixes a widescreen-only presentation leak where the old native category readout could remain visible outside the Gen 3 UI move panel while the correct inline **PHYSICAL / SPECIAL / STATUS** footer was also shown.
- Gold / Generation II now treats the native top-border category tab and the Gen 3 UI footer as mutually exclusive; an active or runtime-observed Gen 3 UI footer suppresses the native tab.
- Red / Blue / Yellow now suppress the native `TYPE/` -> `PHYS/` / `SPEC/` draw completely while Gen 3 UI owns the move footer, preventing both the integrated shim and a downstream standalone Move Category wrapper from leaking behind the replacement UI.
- Native Gen 1 and native Gold readouts are unchanged when Gen 3 UI is absent.
- No battle math, category routing, alignment, font weight, antialiasing, save behavior, link fingerprinting, or declared game support changes.

## 2.6.3 — Gen 3 UI footer polish

- Refines the live-verified Gen 3 UI category alignment and antialiasing for the 2.6.3 release.
- Gen 3 UI category labels now inherit the visible move-type baseline and subpixel phase instead of the helper `TYPE` pass, keeping **PHYSICAL / SPECIAL / STATUS** vertically aligned with the foreign footer.
- Replaces the older hard 1-pixel bold overdraw with a smoother half-pixel semibold shoulder.
- Gold / Generation II uses a slightly stronger **70% alpha** shoulder for the requested extra boldness; Red / Blue / Yellow deliberately keep the accepted **55% alpha** weight.
- No battle math, move-category routing, save behavior, link fingerprinting, native UI behavior, or declared game support changes.

## 2.6.2 — Gen 3 UI move-category compatibility for Gen 1 + Gold

- Finalizes the live-tested Gen 3 Inspired UI move-selection integration on **Red / Blue / Yellow and Pokémon Gold**.
- Detects the foreign wide `TYPE … PP` footer from what it actually renders; no manual compatibility toggle or engine-version allowlist is required.
- Inserts **PHYSICAL**, **SPECIAL**, or **STATUS** directly between the elemental type and PP counter while leaving Gen 3 UI's move list and footer ownership intact.
- Uses the observed footer font, colour and transform, snaps the injected text to whole pixels, and applies a 1-pixel two-pass overdraw for the confirmed matching visual weight.
- Gen 1 keeps its established native `TYPE/` -> `PHYS/` / `SPEC/` readout when Gen 3 UI is absent.
- Gold keeps the already-live-tested native top-border readout when Gen 3 UI is absent.
- Gen 1 and Gold battle mechanics are unchanged from the accepted 2.6.2 test line; this release promotes the confirmed UI compatibility implementation without further gameplay changes.
- User live verification: **PASS** for Gold + Gen 3 UI and **PASS** for Gen 1 + Gen 3 UI.

## 2.6.1 — Gen 3 UI / Gold move-category integration

- Adds explicit optional compatibility with `gen3_battle_ui`, including the Gen 3 Inspired UI Overhaul v1.4.0 Gold layout.
- When Gen 3 UI is active on Gold, the native top-border category tab is suppressed after successful integration and the selected move is shown as **PHYSICAL**, **SPECIAL**, or **STATUS** directly in the existing `TYPE … PP` information row.
- The integration is capability-based rather than release-number-gated: it observes the foreign renderer's real TYPE/type/PP text positions and uses its active font, colour, transform and canvas instead of hardcoding screenshot coordinates.
- If the foreign renderer no longer exposes a recognizable TYPE/PP row, all temporary LOVE text hooks are restored and the proven native Gold category tab is used as a fail-safe.
- Adds headless coverage for separate-field and one-string TYPE/PP rendering, PHYSICAL/SPECIAL/STATUS routing, nonstandard-damage trinary presentation, duplicate suppression, fallback behavior, hook ordering and error-safe renderer restoration.
- No battle-math, save, Gen 1, Crystal 251, link-fingerprint or native Gold stat behavior changes.

## 2.6.0 — Gold / Gen 2 support

- Adds an early generation boundary so Gold never initializes the Gen 1 stat/damage/EXP/item-effect/save/UI compatibility backend.
- Leaves Gold's native Sp. Atk / Sp. Def model, Special DV/Stat Exp, X SPECIAL, Growth/Amnesia/Psychic/Transform, save schema, Summary and level-up presentation untouched.
- Adds Gold-native semantics for the existing settings: requested Special mode is a no-op over native Gen II stats; type-based move mode delegates to Gold's native type categories.
- Extends canonical move identity coverage to Gold move slots 166..251 **without changing the original Gen 1 1..165 identity table**.
- Adds a scoped, error-safe Gold category bridge for GEN IV+ per-move damage categories while preserving native move type and native Gold damage formula.
- Covers current Gold category consumers used by normal damage, Reflect/Light Screen selection, stored damage kind / Counter-Mirror Coat semantics, expected-damage AI and smart-AI move history.
- Gold live-test readout revision: the original one-letter gutter marker was not visibly useful in the real v0.1.78 battle UI. The public `battle.overlay` seam now draws a clear selected-move title tab in the move box border: `PHYSICAL`, `SPECIAL`, or `STATUS`, with `FIXED`, `OHKO`, and `REACTIVE` for non-standard damage classes. Native move names, PP rows, cursor and SELECT reordering remain untouched.
- Adds generation-aware API v2/effective configuration while preserving API v1.
- Gold link revision uses effective `special=native_gen2` to avoid false mismatches between requested VANILLA/GEN II settings.
- Adds Gold static/headless contracts to `tools/run_all.sh`, including both category-flip directions, collision guards, error restoration, AI consistency, readout behavior and type-based hot reload.
- Releases Gold support with `games: ["gen1", "gold"]`; Silver/Crystal are deliberately not claimed.
- Live Gold v0.1.78 verification covers boot, normal battle entry, native split-stat Summary presentation and the final top-border category readout.
- Final readout spacing uses a stable 10-tile title field: ` PHYSICAL `, `  STATUS  ` and ` SPECIAL  `; other special damage labels use the same total field width.

## 2.5.2

- Removes the manifest `game_version` release-number pin entirely. Gen1Recomp updates no longer disable the mod merely because the engine version changed.
- Forward-compatibility policy is now **attempt first, fix only when actually broken**: the mod relies on API/capability checks for the specific surfaces it uses instead of an engine release allowlist.
- Keeps `api = 2` because that is the structural Mod API contract, not an engine release-number pin.
- Keeps `experimental = false`; test/WIP status never opts the whole mod into Gen1Recomp's Experimental gate.
- No stat formulas, battle math, move categories, Crystal 251 behavior, Modern UI geometry, save behavior, or link-config logic changed from 2.5.1.

## 2.5.1

- Source baseline: assistant-delivered final `special_stat_split_v2.5.0.zip` (SHA-256 `599f73249c8b26922dc94ef78b3d3ce5469acbff51457b5e4a69fd84f04df6a7`).
- Release-metadata hotfix: the whole mod is now correctly marked `experimental=false`.
- The optional Modern UI BattleWIP compatibility path remains explicitly experimental/WIP; this does not classify the whole mod as experimental.
- No battle, stat, category, save, Crystal 251, or UI rendering logic changed from the approved 2.5.0 build.

## 2.5.0

Inter-mod API, diagnostics and link-configuration safety.

- Source baseline is the assistant-delivered final `special_stat_split_v2.4.2.zip` (SHA-256 `c0e6c7fe4972e892b1f656fe31597e5cb3c753f7c98c1b8dc68ed0b894536dab`).
- Adds `exports.specialStatSplit.apiVersion = 1` with versioned aliases for the existing public helpers plus gameplay-config and diagnostics accessors. Legacy root exports remain intact.
- Adds deterministic gameplay revision `special=<vanilla|gen2>;move=<gen1|gen4>`.
- Registers that revision through the public `link_fields` registry so the engine's own link fingerprint differs when peers use different restart-required gameplay settings.
- Does **not** wrap or replace `link.fingerprint`. Presentation-only options are intentionally excluded.
- Adds automated coverage for all four gameplay revisions, defensive-copy/API behavior and diagnostic state. When a frozen Gen1Recomp source tree is supplied, the suite now also executes its exact `src/link/Fingerprint.lua` against differing revisions.
- No change to split-stat formulas, the 251-species base table, 251-move category table, save lifecycle or existing Modern UI render geometry.
- Promoted from `2.5.0-test1` after user-confirmed in-game functional/UI smoke.
- Dedicated two-peer link smoke was intentionally waived as a release blocker; link-config fingerprinting is retained as a best-effort safeguard and is not advertised as live-certified.
- The 2.5.0 package accidentally retained `experimental = true` at whole-mod level. This release-metadata mistake is corrected in 2.5.1; only the optional ModernUI BattleWIP compatibility path remains experimental/WIP.

## 2.4.2

Final release promoted from the accepted `2.4.2-test7` build.

- No gameplay or Modern UI rendering logic changed from `2.4.2-test7`; final promotion changes release metadata, test expectations and documentation only.
- Keeps the Party-only **ModernUI Party Stats Layout** toggle: `2 ROWS` default or compact `1 ROW`.
- Keeps Summary on one stat per row at every viewport size, with `SP. ATTACK` and `SP. DEFENSE` never paired on the same row.
- `ModernUI Override` remains ON by default for ordinary Party/Summary integration; `ModernUI BattleWIP Override` remains OFF by default and provisional.
- Promotion source archive SHA-256: `c8e9402c222aef37539f683078b729cfd2e97a9895a5029d3d24c110c332fef7`.

## 2.4.2-test7

- Modern UI Summary now always uses one stat per row on both desktop and mobile.
- `SP. ATTACK` and `SP. DEFENSE` are never paired on the same Summary row.
- Summary values remain immediately after their labels, with ID/OT shifted below using Modern UI's native fallback data.
- The `ModernUI Party Stats Layout` 1-row/2-row option still affects Party detail only.

## 2.4.2-test6

- Added **ModernUI Party Stats Layout** choice. Default is **2 ROWS**.
- Optional **1 ROW** mode keeps compact `ATK / DEF / SPD / SPATK / SPDEF` labels.
- Both Party layouts remain width-adaptive and use one shared font scale for all five stats.
- Modern UI Summary behavior is unchanged from test5, including the mobile one-stat-per-row presentation.


## 2.4.2-test5

Mobile/narrow Modern UI Summary polish.

- Based strictly on assistant-delivered `2.4.2-test4` (SHA-256 `c5ed6fb5d61f6bfcd7a8edf565b415e7c1293f62cb771b42cf56f8509b79b40e`).
- Stacked Summary labels are now `SP. ATTACK` and `SP. DEFENSE`.
- Stacked Summary values now sit immediately after their labels, matching Modern UI's native row layout instead of being right-aligned.
- Shifted ID/OT rows preserve Modern UI's exact ownership-data fallback chain.
- No gameplay/stat/category/save behavior changed.

## 2.4.2-test4

- Adds a narrow/mobile Summary override that stacks both split Special stats on separate rows and shifts ID/OT below them.

## 2.4.2-test3

- Party two-row stat block now uses one shared adaptive font size measured from the live panel width; both rows shrink together and never intentionally ellipsize independently.
- Restores Modern UI's normal move/PP font after adaptive stat rendering.

## 2.4.2-test2

- Party labels refined to `ATTACK / DEFENSE / SPEED` then `SPEC. ATTACK / SPEC. DEFENSE`.
- Replaces Modern UI release-number allowlisting with capability-based detection so compatible future releases can keep working automatically.

## 2.4.2-test1

Modern UI Party stat-layout refinement.

- Based strictly on the assistant-delivered final `2.4.1` release (SHA-256 `befbc6c997fc6f464ddf076589a6272e76f6084910246538b3116e0cc904fb54`).
- Replaces the cramped one-row Modern UI Party override with a two-row full-name stat block while preserving the upstream Party card, icons, sprite, HP bar, moves, borders, theme, spacing and interaction.
- Row 1: `ATTACK / DEFENSE / SPEED`.
- Row 2: `SPECIAL ATTACK / SPECIAL DEF`.
- The override no longer shrinks the stat font merely to force five abbreviated cells onto one line.
- The original Modern UI move list is repainted directly below the new stat block with Modern UI's own font, colors, PP formatting and fitted-text helper.
- Summary compatibility remains unchanged (`SP.ATK / SP.DEF` on the existing Summary Special row).
- Surgical renderer support remains explicitly limited to audited Modern UI `0.8.3` and `0.8.4`; unknown future releases fail closed.
- No Special-stat math, move-category mechanics, Move Category readout, Crystal 251 behavior, updater metadata or save schema changed.

## 2.4.1

Final release promoted from the live-tested `2.4.1-test1` build.

- No executable gameplay or Modern UI compatibility logic changed from `2.4.1-test1`; final promotion only updates release metadata, test expectations, and documentation.
- Added audited surgical Party/Summary compatibility for **Gen1 Modern UI 0.8.4** while retaining 0.8.3 support.
- Verified the 0.8.4 Party detail, Summary stat page, and display-stat helpers used by the override are unchanged from 0.8.3.
- Kept the override fail-closed for unknown future Modern UI releases.
- No Special-stat math, move-category mechanics, Move Category readout, save behavior, or Crystal 251 data changed.
- ModernUI BattleWIP Override remains separate, optional, and OFF by default.

## 2.4.0

Final release promoted from the live-tested `2.4.0-test3` build.

- No executable gameplay or presentation logic changed from `2.4.0-test3`; the final promotion only updates release metadata, test expectations and documentation.
- Integrates the former standalone Move Category readout behind **MOVE CATEGORY READOUT**, default ON. The standalone v1.0.1 mod remains safe to co-install but is functionally redundant.
- **ModernUI Override** defaults ON and preserves Gen1 Modern UI 0.8.3's authored Party/Summary layout, repainting only the legacy Special-stat text.
- **ModernUI BattleWIP Override** remains separate and defaults OFF; experimental battle UI compatibility is intentionally provisional until Modern UI publishes a stable battle presenter or cleaner augmentation seam.
- Keeps `github = ZyranCZ/Special-Stat-Split` so the native Gen1Recomp/Gen1Compile GitHub Release update flow remains the update source for the combined mod.
- Final frozen/runtime/real-third-party regression suite passes before packaging. Dedicated live two-peer link smoke remains separately uncertified.

## 2.4.0-test3

Modern UI exact-layout compatibility rework.

- Replaces the ordinary generic Party/Summary adapter approach from test2 with a **surgical Gen1 Modern UI 0.8.3 stat-row shim**.
- Modern UI now remains the renderer for its own Party and Summary screens: sprites, party icons, HP bars, moves, frames, spacing, themes, responsive layout and pointer behavior remain upstream-owned.
- Party changes only the legacy `ATK / DEF / SPD / SPC` text row to five split cells (`ATK / DEF / SPD / SPATK / SPDEF`).
- Summary changes only the existing `SPECIAL` line to `SP.ATK` + `SP.DEF`; ID/OT and panel geometry are not moved.
- The shim reuses Modern UI's own active theme/font/text helpers and repaints only the stat-row background area after the original renderer has completed.
- The ordinary override is intentionally pinned to Modern UI **0.8.3** and fails closed on unknown releases instead of replacing a changed UI with a generic fallback.
- The generic external Party/Summary adapter is no longer registered, so Special Stat Split no longer takes ownership of those complete screens.
- `ModernUI Override` remains default ON and live-toggleable; OFF leaves Modern UI untouched.
- `ModernUI BattleWIP Override` remains default OFF. Its battle Party path now benefits from the same narrow row treatment when enabled; experimental Level Up handling remains provisional.

## 2.4.0-test2

Modern UI override ownership cleanup.

- Adds **ModernUI Override** (`OFF / ON`), default **ON**, for ordinary Party and Summary compatibility through Modern UI's public adapter API.
- Adds **ModernUI BattleWIP Override** (`OFF / ON`), default **OFF**, for all provisional compatibility tied to Modern UI's experimental Battle UI: battle Party presentation and level-up correction.
- Turning either toggle OFF makes Special Stat Split stop claiming the corresponding Modern UI presentation path; no Modern UI file is modified.
- Keeps the two switches independent: ordinary Modern UI compatibility can remain ON while all experimental BattleWIP behavior stays OFF.
- Future Modern UI release numbers are not hard-coded. Adapter registration continues to negotiate public compatibility API v1; incompatible API versions fail closed.
- The experimental battle bridge remains provisional and should be revisited when Modern UI publishes its planned cleaner extension mechanism or a stable Battle UI.
- Source baseline verified before editing: exact assistant-delivered `v2.4.0-test1`.

## 2.4.0-test1

Move Category integration.

- Integrates the former standalone **Move Category Readout v1.0.1** directly into Special Stat Split.
- Adds **MOVE CATEGORY READOUT** toggle, default **ON**, live-toggleable without restart.
- Damaging moves replace the vanilla `TYPE/` label with `PHYS/` or `SPEC/`; status/power-0 moves keep `TYPE/`.
- Readout follows the merged live move definition (`move.category` first, type-based fallback second), so it agrees with both GEN I (BY TYPE) and GEN IV+ (BY MOVE) modes.
- Adds `move_category` as an optional dependency only for deterministic coexistence ordering; the standalone mod is never required.
- If standalone Move Category is also enabled, both wrappers compose safely: only the original `TYPE/` token is transformed, so no duplicate label or manifest conflict is produced.
- Preserves native Gen1Compile/Gen1Recomp GitHub update metadata: `github = ZyranCZ/Special-Stat-Split`.
- Adds regression coverage for readout ON/OFF, GEN I/GEN IV+ category agreement, standalone coexistence, and updater metadata.
- Existing split-stat, Crystal 251 and Modern UI behavior is otherwise inherited from 2.3.0-test5.

## 2.3.0-test5

Modern UI interoperability consent/future-version hardening.

- Adds **Modern UI Level Up Override** to Special Stat Split settings.
- The toggle defaults **OFF**, so Special Stat Split never replaces Gen1 Modern UI's experimental Level Up presentation unless the player explicitly opts in.
- The setting affects only the experimental Modern Battle UI Level Up correction; Party/Summary/battle-Party compatibility continues through Modern UI's official data-only adapter API.
- Level Up correction is now gated by Modern UI public compatibility API **v1** rather than a hard-coded Modern UI release number.
- Future Modern UI release numbers can continue to work when compatibility API v1 and the required public decoration behavior remain available.
- Unsupported future compatibility API versions fail closed: no adapter registration and no Level Up correction hooks are installed.
- No Modern UI file is modified or bundled.

## 2.3.0-test4

Modern Battle UI level-up correctness follow-up.

- Fixes Gen1 Modern UI's dedicated battle **LEVEL UP** card showing the legacy single `SPECIAL` value while Special Stat Split is enabled.
- Does **not** modify or monkey-patch Gen1 Modern UI. The compatibility path lives entirely in Special Stat Split.
- Fixes the failed test3 detection assumption: Modern UI's experimental battle presenter suppresses the level-up child by replacing its `draw` method through the public Gen1Recomp `ui.state.decorate` hook, not through `screen.render_visible`.
- A priority-200 `ui.state.decorate` observer records only a downstream replacement of Special Stat Split's exact source-owned five-stat `BattleState.StatBox.draw`.
- The source-owned native split draw marks each frame in which it actually executes. A priority-200 `render.hud` wrapper calls downstream first, then paints one opaque correction card with **ATTACK / DEFENSE / SPEED / SP. ATK / SP. DEF** only when the foreign decorator is still installed and the native split draw did not run.
- This makes the compatibility path specifically inert for Modern UI's default **BATTLE UI (WIP) = OFF** state, for `HIDE ORIGINAL UI = OFF`, for Modern UI absence, and for VANILLA Special mode.
- No Modern UI option is read through private save data and no foreign function is called directly; the bridge derives its decision from public decoration behavior plus its own draw execution marker.
- The source-owned `BattleState.StatBox` remains the sole owner of input, dismissal, level-up lifecycle and callbacks.
- Adds headless regression coverage against the real Modern UI 0.8.3 `ui.state.decorate` wrapper, including WIP ON/OFF, hide-original ON/OFF, VANILLA/no-Modern-UI guards, and absence of a legacy `SPECIAL` label in the correction model.
- No damage, stat calculation, move-category, Crystal 251, save or battle-switch behavior changed from 2.3.0-test2.

## 2.3.0-test3

Superseded experimental Modern Battle UI level-up attempt.

- Attempted to detect Modern UI level-up suppression through `screen.render_visible` and overlay a five-stat correction card.
- Real-game smoke showed the detection path did not fire: Modern UI still displayed its own four-row card with legacy `SPECIAL`.
- No final release was made from test3. test4 replaces the incorrect suppression assumption with observation of the actual public `ui.state.decorate` draw replacement.

## 2.3.0-test2

Battle Modern UI compatibility follow-up.

- Extends the Special Stat Split data-only Modern UI adapter to **PartyMenu while a battle is active**.
- Fixes the Modern UI battle-party detail path continuing to show legacy `SPC` while ordinary Party/Summary already showed split stats.
- Battle selection, switching, validation, callbacks and queue ownership remain entirely in Gen1Recomp `PartyMenu`; the adapter delegates A/B back through `mod.input`.
- Voluntary battle switching, forced replacement/SHIFT pickers and the battle `SWITCH / STATS / CANCEL` submenu are modeled from their live public state.
- TM/HM, medicine, field rearrangement and other non-battle special Party modes remain delegated to Modern UI's native presenters.
- No damage, stat, move-category, Crystal 251 or save behavior changed from 2.3.0-test1.

## 2.2.2

Launcher update support.

- Added native Gen1Recomp GitHub update metadata for `ZyranCZ/Special-Stat-Split`.
- The launcher can now discover newer GitHub Releases and expose Update / Other versions for this mod.
- No gameplay, stat, move-category, or Crystal 251 compatibility behavior changed from 2.2.1.

## 2.2.1

Crystal split-stat source hardening.

- Expanded the mod-owned Generation II–V Sp. Atk / Sp. Def table from 151 to **251 species**.
- Canonical mod-owned values now have priority over Crystal 251 exports for National Dex #001–251.
- Fixes Johto species silently falling back to identical Sp. Atk / Sp. Def when the optional Crystal export is unavailable at runtime.
- Added explicit regression coverage for Togetic **80/105**, Espeon **130/95**, Umbreon **60/130**, Blissey **75/135**, and other Johto sentinels.
- Crystal move-category/runtime compatibility from 2.2.0 is unchanged.

## 2.2.0

Crystal 251 interoperability release.

- Added `CRYSTAL_251` as an optional dependency; standalone behavior remains on the existing 151-species / 165-move path when Crystal is absent.
- When Crystal is present, consumes its exported ROM-derived `specialAttack` / `specialDefense` values for all 251 species instead of duplicating one legacy Special base.
- Expanded the modern move-category table from 165 to **251** slots, covering all **86 Generation II moves**.
- Added Crystal move identity guarding for slots 166..251 using Crystal's own exported move table.
- Synchronizes modern categories into Crystal's private `crystalMoves` runtime data so AI/reactive consumers agree with the merged registry.
- Added a targeted compatibility bridge for Crystal's type-based damage dispatcher, allowing GEN IV+ per-move categories to drive Attack/Defense vs Sp. Atk/Sp. Def without changing elemental type, STAB, weather or type effectiveness.
- GEN I (BY TYPE) keeps the historical standalone 1..165 delete behavior and leaves Crystal's Gen II move records on Crystal's native type-based path.
- Added a dedicated Crystal 251 runtime contract with split-stat sentinels (Espeon/Umbreon) and category-inversion sentinels including Flame Wheel, Snore, Aeroblast, Spark, Crunch and Shadow Ball.
- Category table validation now checks 251/251 entries: **106 Physical / 52 Special / 93 Status**.

## 2.1.0

Deep category/history/collision audit of the 2.0.0 physical/special split.

- Verified all 165 original moves across Generations IV–IX: **no Physical/Special/Status category changes exist among this move pool after the split was introduced**.
- Renamed the visible modern selector to **`GEN IV+ (BY MOVE)`**. The stored value remains `gen4` for 2.0.0 option compatibility.
- Did **not** add placebo GEN V/VI/VII/VIII/IX selectors because they would produce byte-for-byte equivalent category decisions for the original 165 moves.
- Fixed GEN I mode authority: canonical move categories are now actively cleared with official `mod.DELETE`, so an earlier/lower-priority explicit category cannot leak into `GEN I (BY TYPE)`.
- Added canonical identity protection in addition to numeric move index, preventing a custom move that merely reuses index 1..165 from receiving the wrong historical category.
- Canonical identity table now comes from exact Gen1Recomp/pokered move IDs, including `HI_JUMP_KICK` and other legacy spellings.
- Added `data/gen1_move_registry_ids.csv`.
- Added `data/move_category_generation_audit.csv` covering all 165 moves from Gen I baseline through Gen IX category parity.
- Added `data/move_data_changelog_gen4plus.csv`: 83 recorded post-Gen-III field changes affecting 51 original moves, documenting why a player may remember a move's power/accuracy/PP/effect differently even though category is unchanged.
- Documented the four Gen I -> Gen II elemental type migrations: Karate Chop, Gust, Sand-Attack and Bite.
- Documented why a truthful full Gen II/III preset would require broader elemental-type/type-chart support, especially Dark-type Bite, and is intentionally not faked here.
- Added generation-audit and collision regression tests, including preexisting-category removal, fake reused index protection and exact `HI_JUMP_KICK` ID recognition.
- Existing split-stat math and Gen IV+ category table are otherwise unchanged from the working 2.0.0 behavior.

## 2.0.0

- Added the Generation IV per-move Physical/Special/Status split for all 165 original moves.
- Added independent restart-required `MOVE CATEGORIES` option.
- Uses official content registry and existing Gen1Recomp damage engine.
- Retained the Generation II Sp. Atk / Sp. Def split and its save/UI integrations.

## 1.0.1

- Added optional Pokédex Plus base-stat screen compatibility.

## 1.0.0

- First public Generation II Special Attack / Special Defense stat-split release.
