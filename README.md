# Special Stat Split

**Special Stat Split 2.6.0** combines the stat split, per-move category mechanics, and the former standalone Move Category readout in one Gen1Recomp mod:

1. **Generation II Special-stat split** — the original calculated `SPECIAL` becomes separate **Sp. Atk** and **Sp. Def**.
2. **Modern per-move damage categories** — original moves can use the Generation IV+ **Physical / Special / Status** category of the individual move instead of Generation I's category-by-elemental-type rule.
3. **Move Category Readout** — the battle move box can replace the redundant `TYPE/` label with `PHYS/` or `SPEC/`, matching the category the battle engine is actually using.

A FIRE move is therefore not automatically special in modern mode: **Fire Punch is Physical**, while **Flamethrower is Special**.

> **Save options and fully restart Gen1Recomp after changing either gameplay mode.**

## Pokémon Gold / Gen 2 support

Version **2.6.0** adds a **generation-isolated Gold backend** and declares `games: ["gen1", "gold"]`. Red/Blue/Yellow keep the established Gen 1 backend while Pokémon Gold uses its native Generation II stat systems plus this mod's optional per-move category layer.

On **Red / Blue / Yellow**, behavior remains the established v2.5.2 contract. On **Pokémon Gold**:

- Gold's native **Sp. Atk / Sp. Def**, shared Special DV, shared Special Stat Exp, native X SPECIAL, Growth/Amnesia/Psychic effects, Transform, save model, Summary and level-up presentation are left untouched.
- `SPECIAL STATS (RESTART)` remains a shared saved option, but both of its requested values are mechanically **native Gen II** on Gold. The option still matters when the same mod is loaded under Gen 1.
- `GEN I (BY TYPE)` means **Gold's native type-based category model**, including Gold's own Dark/Steel types and move types. It does not emulate Red's type table.
- `GEN IV+ (BY MOVE)` changes only which offensive/defensive stat pair a damaging move uses. Move type remains untouched, so Gold still owns STAB, effectiveness, weather, held-item modifiers, critical hits and damage variation.
- The Gold move-select screen has no spare `TYPE/` field. The first live build tried a one-letter gutter marker, but the real v0.1.78 layout showed that it lands on the box edge and is not useful in play. The readout now uses the public `battle.overlay` seam to cut a clear title into the move box's top border for the **currently selected move**: **PHYSICAL**, **SPECIAL**, or **STATUS**. Non-formula damage is labeled **FIXED**, **OHKO**, or **REACTIVE** instead of pretending it uses Attack/Defense or Sp. Atk/Sp. Def. Move names, PP, cursor and SELECT reordering remain native Gold.
- Gen1 Modern UI and CRYSTAL 251 compatibility shims are treated as **Gen 1-only** on Gold; native Gold systems are not patched through those paths.

Gold boot, battle entry, native split-stat Summary presentation and the final selected-move category readout were live-tested on Gen1Recomp/Gold v0.1.78. The bundled automated suite additionally covers category routing, AI, Counter/Mirror Coat basis, type-based fallback, API/link semantics and Gen 1 regressions. Remaining edge-case/live matrices are documented in `GOLD_PORT_STATUS.md`; Silver/Crystal are not claimed by this release.

## 2.6.0 compatibility policy

Special Stat Split no longer pins a specific Gen1Recomp release in `manifest.json`. New Gen1Recomp releases are allowed to load the mod automatically; a version-number change by itself is **not** treated as incompatibility. The policy is now **try to run first, update only if a real breakage is observed**.

The manifest still declares Mod API `2`, because that is the structural API contract the mod actually uses. `experimental` is permanently `false`; WIP status of an optional integration never makes the whole mod Experimental.

## New in 2.5.0

- Adds a **versioned inter-mod API v1** while preserving all existing root exports. See `INTERMOD_API.md`.
- Registers the two restart-required gameplay choices through Gen1Recomp's public `link_fields.rev` surface so same-version peers with different battle-math settings produce different link fingerprints.
- Adds read-only diagnostics for active gameplay modes, link registration, Modern UI, Crystal 251 and standalone Move Category detection.
- Presentation-only settings are deliberately excluded from the gameplay revision.
- Core stat math, move-category data, save behavior and the existing Modern UI renderers are inherited unchanged from 2.4.2.

This is the **2.6.0 release**. The in-game single-player/UI paths were user-smoke-tested successfully. Dedicated two-peer link certification is not a release blocker; gameplay-option fingerprinting remains a best-effort safeguard through Gen1Recomp's public `link_fields.rev` fingerprint surface.

## Target

Last fully frozen integration baseline: **Gen1Recomp v0.1.75**, commit `60cf07fb0a1ffce0ec6d5d0d2f78a921a6d0b7da`. This is an audit baseline, **not** a manifest compatibility pin.

The manifest deliberately contains **no `game_version` field**. New engine releases are allowed to attempt loading; the frozen baseline only records the last exact upstream integration snapshot used by the bundled historical contracts.

## Install / test

Import the ZIP through Gen1Recomp's mod manager, or unpack it as one mod directory under `mods/`. Choose the options, save, and fully restart the game after changing either gameplay mode. The distributable ZIP keeps `manifest.json` and `main.lua` at the archive root as required by the official publishing guide.

## Options

### SPECIAL STATS (RESTART)

- **VANILLA** — original Generation I single `SPECIAL` stat.
- **GEN II (SP. ATK / SP. DEF)** — separate calculated Sp. Atk / Sp. Def using this mod's own audited **251-species Generation II–V base-stat table**. Crystal 251 cannot override these values.

Default: **GEN II**.

### MOVE CATEGORIES (RESTART)

- **GEN I (BY TYPE)** — Red/Blue behavior. Any explicit category on the 165 canonical moves is actively removed so Gen1Recomp is forced back to its type-based category rule.
- **GEN IV+ (BY MOVE)** — standalone: all 165 original moves receive their audited per-move Physical / Special / Status category. With **CRYSTAL 251**: the table extends through all 251 Gen I+II move slots, including all 86 moves introduced in Gen II.

Default: **GEN IV+**.

The stored option value remains `gen4` for backward compatibility with 2.0.0 settings.

### MOVE CATEGORY READOUT

- **ON (default)** — while choosing a damaging move in battle, replace the vanilla `TYPE/` label with `PHYS/` or `SPEC/`. The elemental type remains on the line below, so the box reads for example `PHYS/FIRE` or `SPEC/PSYCHIC`.
- **OFF** — keep the original `TYPE/` label.

The readout is presentation-only and changes immediately; no restart is required. It follows the **merged live move record**: an explicit per-move category wins, otherwise the active Gen I type-based category is used. Status/power-0 moves keep `TYPE/` rather than displaying a misleading damage category.

This feature incorporates the behavior of the former standalone **Move Category Readout v1.0.1**. If that standalone mod is also enabled, the two are deliberately compatible: there is no manifest conflict and no duplicate visible label. Each wrapper only reacts to the exact original `TYPE/` token, so once one has changed it to `PHYS/` or `SPEC/`, the other simply passes it through.

Once this combined version is installed, the standalone Move Category mod is **functionally redundant** and may be disabled or removed. Keeping it installed is still supported for users who want to preserve their existing setup.

### ModernUI Override

The surgical Modern UI shim is **capability-gated, not release-number-gated**. It is verified against Gen1 Modern UI 0.8.3 and 0.8.4, but later releases are allowed to keep working automatically when they still expose compatibility API v1 and the renderer/helper capabilities the shim requires. If those capabilities actually change, the shim fails closed and leaves Modern UI untouched.


- **ON (default)** — on the currently supported Gen1 Modern UI renderer, keep Modern UI's own Party and Summary screens **1:1** and surgically replace only its legacy single-SPECIAL stat text with the split values.
- **OFF** — leave Modern UI completely untouched.

The shim does **not** replace the Party/Summary presenter with Special Stat Split's own generic layout: Modern UI still draws its sprites, icons, HP bar, frame, spacing, responsive sizing and interaction. In Party, **ModernUI Party Stats Layout** chooses between the default two-row full-label block (`ATTACK / DEFENSE / SPEED`, then `SPEC. ATTACK / SPEC. DEFENSE`) and a compact one-row block (`ATK / DEF / SPD / SPATK / SPDEF`). Both choices measure the live panel width and use one shared adaptive stat font scale, then repaint the same Modern UI-styled move/PP list immediately below. In Summary, Summary always stacks `SP. ATTACK` and `SP. DEFENSE` on separate rows on every viewport size, with ID/OT shifted below while preserving Modern UI's own label/value spacing and ownership-data fallbacks.

This is a temporary presentation-only runtime override. It modifies no Modern UI file. New Modern UI version numbers are allowed to keep using the shim automatically when the required API/renderer capabilities are still present; only an actually incompatible structure fails closed and leaves Modern UI untouched. If Modern UI exposes an official built-in-stat augmentation API in a future release, that supported seam should replace this shim.

### ModernUI BattleWIP Override

- **OFF (default)** — leave Gen1 Modern UI's experimental Battle UI (WIP) presentation completely untouched.
- **ON** — opt in to the provisional battle compatibility layer: the in-battle Party picker can expose Sp. Atk / Sp. Def, and the experimental Level Up card can be corrected to five stats when Modern UI suppresses the native split StatBox.

This setting is deliberately separate because Modern UI's Battle UI is experimental and disabled by default. Special Stat Split does not treat this provisional bridge as a permanent integration contract.

## Why there is one GEN IV+ choice, not GEN IV / V / VI / VII / VIII / IX

This was exhaustively checked for every original move. **All 165 original Generation I moves have the same damage category in Generations IV, V, VI, VII, VIII and IX.** Splitting the menu into six generation choices would therefore create six labels that produce the same category table.

That statement applies only to the original 165 moves. Later moves can change category between generations; if this mod ever expands the move pool, generation-specific tables may become necessary.

See `GENERATION_AUDIT.md` and `data/move_category_generation_audit.csv` for the complete **165-row original Gen I** cross-generation audit. The separate Crystal 251 compatibility tables extend runtime category ownership through move slot 251.

## Important: category is not the same thing as move type or full move mechanics

`GEN IV+ (BY MOVE)` changes **only the Physical / Special / Status damage class**. It deliberately does **not** modernize elemental type, base power, accuracy, PP, priority, target, secondary effects, trapping rules, recharge rules, critical-hit rules or any other move behavior.

This distinction matters historically:

- Four original moves changed **elemental type** after Generation I: Karate Chop, Gust, Sand-Attack and Bite.
- Many original moves later changed power, accuracy, PP or behavior. The packaged audit currently records **83 field changes affecting 51 of the original moves from Generation IV onward**.
- Some values changed even inside one generation/version family, so a future "full modern move data" preset would need a precise game/version-group definition, not merely a generation number.

Therefore this mod does not advertise GEN II/III or GEN IV/V/VI/etc. as full battle-engine presets. Its move selector is specifically a **damage-category era selector**.

## What changes compared with Red/Blue

Exactly **18 damaging moves** switch the normal Attack/Special side when moving from Generation I's type-based model to Generation IV+ per-move categories:

Fire Punch, Ice Punch, ThunderPunch, Razor Wind, Gust, Vine Whip, SonicBoom, Acid, Hyper Beam, Razor Leaf, Night Shade, Smog, Sludge, Waterfall, Clamp, Swift, Crabhammer and Tri Attack.

Fixed/direct-damage moves such as SonicBoom and Night Shade still use their special engine effects; assigning their modern category is primarily data/UI consistency and does not convert fixed damage into a normal stat formula.

## Crystal 251 compatibility

Crystal 251 is an **optional** dependency. If it is absent, normal Gen I gameplay is unchanged from the previous standalone implementation. The packaged split-stat reference now contains National Dex #001–251, but entries #152–251 are simply unused unless another content mod (such as Crystal 251) supplies those species.

If Crystal 251 is present:

- **Sp. Atk / Sp. Def do not depend on Crystal exports anymore.** This mod owns the canonical Gen II–V values for all 251 species. Crystal's export may be detected as diagnostic/fallback data, but it cannot replace #001–251 values.
- The GEN IV+ category table extends from move slots 1..165 to 1..251. All 86 Gen II moves receive explicit per-move Physical / Special / Status categories.
- Crystal's private `crystalMoves` runtime table is synchronized too, so its AI/reactive paths see the same category as the merged move registry.
- Crystal's damage router normally derives Physical/Special from elemental type. In GEN IV+ mode, this mod bridges that internal category decision for the current calculation while leaving the move's actual type unchanged, so STAB, weather and effectiveness still use the real elemental type.
- GEN I (BY TYPE) does not force modern categories onto Crystal's Gen II moves; Crystal's native type-based behavior remains in control.

Examples that exercise the bridge include Flame Wheel (Fire / Physical), Snore (Normal / Special), Aeroblast (Flying / Special), Spark (Electric / Physical), Crunch (Dark / Physical) and Shadow Ball (Ghost / Special).

## Collision hardening added in 2.1.0

The 2.0.0 implementation categorized any merged move whose numeric index was 1..165. The audited build is stricter:

- A move is patched only when **both** its numeric Gen I slot and canonical Gen1Recomp registry identity match.
- The identity table uses the engine's exact ROM-manifest IDs, including legacy spellings such as `HI_JUMP_KICK`, `THUNDERPUNCH`, `SONICBOOM`, `PSYCHIC_M`, `SELFDESTRUCT` and `SOFTBOILED`.
- A custom move that merely reuses a vanilla numeric index is skipped instead of receiving a wrong historical category.
- In **GEN I (BY TYPE)** mode the mod uses the official `mod.DELETE` sentinel to remove an earlier explicit `category`, preventing a lower-priority category mod from silently leaking modern behavior into a setting labelled GEN I.

Registry priority still matters: Special Stat Split has priority **150**. Earlier/lower-priority move-category patches are intentionally superseded by the selected Special Stat Split mode. A later/higher-priority mod can supersede Special Stat Split again; that is normal Gen1Recomp last-writer behavior and is documented in `COMPATIBILITY.md`.

## Gen1 Modern UI compatibility

**ModernUI Override** now deliberately preserves Modern UI's built-in visual design instead of supplying a replacement generic screen. When the required renderer capabilities are present, Modern UI draws the complete Party/Summary interface and Special Stat Split repaints only the legacy stat text area using Modern UI's own active theme, font helpers and coordinates. No Modern UI file is bundled or edited.
- **ModernUI Party Stats Layout** — default **2 ROWS**; switch to **1 ROW** for compact `ATK / DEF / SPD / SPATK / SPDEF` presentation. This affects Party detail only; Summary keeps its dedicated responsive split-stat layout.

The in-battle Party row and battle Level Up compatibility remain separated under **ModernUI BattleWIP Override**, default OFF, because Modern UI's **BATTLE UI (WIP)** is experimental. When enabled on the supported renderer, the battle Party uses the same narrow stat-row treatment; the separate Level Up bridge remains provisional. The normal/default battle UI already uses Special Stat Split's native five-stat level-up display and needs no override.

Unlike the previous generic adapter experiment, this temporary exact-layout shim is **capability-gated rather than release-gated**. A newer Modern UI version is allowed to keep working automatically when compatibility API v1 and the required renderer/helper capabilities are still present. If those capabilities actually change, the shim fails closed and leaves the author's UI untouched. If the Modern UI developer publishes a clean data-extension seam for the existing Party/Summary detail card, this shim should be retired in favor of that supported API.

## Battle behavior

With both defaults enabled:

- Physical move -> Attack vs Defense.
- Special move -> Sp. Atk vs Sp. Def.
- Category comes from the move record, not elemental type.
- STAB still uses elemental type.
- Type effectiveness still uses the active Gen1Recomp type chart.
- Fixed/direct-damage and reactive moves keep their existing effect paths.
- Existing Gen1Recomp damage floor ordering, RNG, critical-hit rulesets and move effects are preserved.

The exact target engine was searched for `move.category`; the category is consumed by the damage module rather than by a second hidden AI/category subsystem.

## Special-stat behavior retained

The existing split-stat implementation remains unchanged in intent: one shared Special DV and one shared Special Stat Exp bucket feed separate calculated Sp. Atk and Sp. Def; Growth and X Special affect Sp. Atk; Amnesia and Psychic's Special drop affect Sp. Def; Transform, Haze, Light Screen, Calcium, Rare Candy, level-up, evolution, Summary UI and save strip/restore remain covered by the frozen integration suite.

## Packaged audit data

- `data/gen4_move_categories.csv` — authoritative 1..251 Gen I+II category table used by the mod; slots 166..251 activate only when Crystal 251 supplies those moves.
- `data/gen1_move_registry_ids.csv` — exact 1..165 Gen1Recomp/pokered move IDs used by the collision guard.
- `data/move_category_generation_audit.csv` — category comparison for every original move across GEN IV–IX plus Gen I baseline/type notes.
- `data/move_data_changelog_gen4plus.csv` — non-category move-data changes from Generation IV onward, retained so players can see why a remembered move may differ even though its category did not.

## Gen1Compile / launcher update support

The manifest keeps the GitHub update source **`ZyranCZ/Special-Stat-Split`**. Gen1Recomp/Gen1Compile's native mod updater can therefore compare the installed manifest version against GitHub Releases and offer newer releases/other versions without any custom network code inside this mod.

The old standalone Move Category repository is **not** used as the update source for the integrated feature; once using this combined mod, updates for the combined functionality come from the Special Stat Split repository. If the standalone `move_category` mod remains installed, its own manifest may still be checked independently by the launcher.

## Verification status

The current build passes the complete bundled reference, category, generation-audit, source-contract and runtime-stub suites, including a regression test where Crystal deliberately exports wrong equal values for Togetic and Espeon. The canonical table still wins. The bundled exact v0.1.75 frozen-upstream suite remains the last complete frozen integration baseline. The release is not restricted to that engine version.

A dedicated real two-peer link battle and broad live compatibility pass with every third-party move overhaul remain manual tests. Crystal 251 compatibility is covered by source audit plus a dedicated headless runtime contract, but an imported-ROM in-game smoke is still recommended.

See `VERIFICATION.md`, `TESTING.md`, `COMPATIBILITY.md` and `GENERATION_AUDIT.md`.
