# Compatibility and collision audit — v2.6.4

Last fully frozen audit baseline: Gen1Recomp v0.1.75 / `60cf07fb0a1ffce0ec6d5d0d2f78a921a6d0b7da`. This is not a runtime version gate.

## Generation boundary: Red / Blue / Yellow vs Gold

The Gold port is additive. The entry chunk resolves the active generation before loading any historical Gen 1 battle/stat/save/UI internals. Generation 1 continues into the established v2.5.2-compatible backend; Generation 2 enters a separate Gold backend.

### Red / Blue / Yellow

All existing v2.5.2 compatibility behavior remains authoritative: mod-owned split-stat emulation, Crystal 251 interoperability, Gen1 Modern UI shims, Gen 1 save stripping/restoration and the existing link revision contract.

### Gold

Gold's native split-stat model is authoritative. The mod does **not** install its Gen 1 `Stats`, EXP, X SPECIAL, move-effect, Transform, save-stripper, Summary, level-up, Crystal-private-damage or Gen1 Modern UI stat patches. The only battle-math extension is optional per-move category selection.

For GEN IV+ mode, the narrow Gold bridge scopes a category around the engine's own damage calculation; it does not copy the Gold damage formula and does not rewrite move type. Current-source auditing found category consumers in ordinary damage/screen routing, stored damage kind, expected-damage AI and smart-AI move history; these are covered by the shared resolver described in `GOLD_CATEGORY_CONSUMERS.md`.

The Gold readout uses the public `battle.overlay` hook and does not replace `BattleState:drawPanel`. It paints a selected-move category title into the move box top border while leaving native move rows, PP, cursor and SELECT reordering intact.

Version **2.6.4** continues the **Gold-only** Gen 2 declaration in addition to Gen 1 (`games: ["gen1", "gold"]`). Gold boot/battle entry, native Summary split-stat presentation and the final category readout have live verification, and the Gen 3 UI move footer is live-verified on both Gold and Gen 1; Silver/Crystal remain outside the declared support set.

## Gen1Recomp engine-version policy

There is **no `game_version` pin** in the manifest. Special Stat Split intentionally attempts to load on future Gen1Recomp releases instead of refusing them because the release number changed. Compatibility is evaluated by the actual API/capabilities used by each integration. If a future engine release genuinely changes one of those surfaces, that concrete regression can then be fixed; release-number churn alone is not a blocker.

The manifest keeps `api = 2`. This is the Mod API major required by the code and is intentionally different from pinning a Gen1Recomp engine release. The whole mod is always `experimental = false`.


## Standalone Move Category Readout v1.0.1

The standalone `move_category` mod is **not a conflict**. Since 2.4.2, Special Stat Split integrates the same readout but keeps `move_category` as an optional dependency so an active standalone copy is ordered before Special Stat Split. Gen1Recomp optional dependencies affect ordering without making the dependency mandatory.

Both implementations only replace the exact original `TYPE/` token. If both are enabled, whichever wrapper sees `TYPE/` first converts it to `PHYS/` or `SPEC/`; the other then receives a different token and does nothing. The label is therefore drawn exactly once and no conflict warning is declared. If either readout toggle is ON, the category remains visible; if both are OFF, vanilla `TYPE/` remains.

The integrated readout resolves category from the merged live move record, so it automatically follows Special Stat Split's selected GEN I/GEN IV+ category mode and any compatible later registry owner.

## Category registry semantics

Special Stat Split uses the official `moves` content registry and has manifest priority **150**. Gen1Recomp applies registry patches in mod load order. Therefore category ownership is deterministic but not exclusive:

- A lower-priority mod that set an explicit category first is overridden by the selected Special Stat Split mode.
- In `GEN I (BY TYPE)` mode, Special Stat Split actively removes an earlier explicit category from each canonical Gen I move using `mod.DELETE`; this fixes a 2.0.0 leak where an earlier modern category could survive.
- A higher-priority mod loaded later can override Special Stat Split. This is expected registry behavior, not something this mod can honestly prevent while remaining a normal content mod.
- A full `override()` by another mod can likewise replace fields established earlier.

If two gameplay mods both intentionally own historical move categories, choose their priorities/order deliberately and test the resulting merged move records.

## Numeric-index collision protection

2.0.0 trusted only `move.index`. 2.1.0 requires the index **and** a canonical Gen1Recomp identity from the exact ROM `moveOrder` table. A custom move reusing an index 1..165 is skipped unless it also presents the canonical identity for that slot.

This guard intentionally uses Gen1Recomp IDs rather than modern display identifiers. Important examples include `HI_JUMP_KICK`, `THUNDERPUNCH`, `SONICBOOM`, `PSYCHIC_M`, `SELFDESTRUCT` and `SOFTBOILED`.

## CRYSTAL 251

**Supported as an optional dependency.** Crystal has priority 110 and Special Stat Split priority 150; the optional dependency additionally expresses the intended load relationship.

Without Crystal, no Crystal modules are required. With Crystal:

- The mod-owned #001–251 Generation II–V table is the authoritative split-base source. `crystalBaseStats` is never allowed to override those canonical values.
- Gen II move slots 166..251 are categorized only when they match Crystal's exported canonical move records.
- The private `crystalMoves` table is updated in GEN IV+ mode because Crystal's AI and several reactive/effect paths consult that runtime data.
- Crystal's ordinary damage router derives category from type internally, so v2.2.0 bridges that one decision during a synchronous damage call. The elemental `move.type` itself is never substituted, preserving STAB/effectiveness/weather behavior.
- The temporary category-dispatch override is restored on both success and error paths.

This is a compatibility layer, not a fork of Crystal: no Crystal species/move data are bundled into Special Stat Split.

## STEEL/FAIRY AND TYPING CHARTS

The supplied `steel_typing` mod has priority 100 and changes type records/species typing rather than move categories. No direct category-write collision was found. Because Special Stat Split's GEN IV+ category is explicit, changing a type chart does not automatically flip a move from Physical to Special or vice versa. STAB/effectiveness remain governed by the active elemental type/type chart.

A future attempt to emulate full Gen II/III move data is a different problem: Bite becomes Dark in Gen II, while base Gen1Recomp does not supply Dark as a vanilla type. Special Stat Split therefore does not pretend that a simple GEN II/III category toggle would recreate historical behavior.

## Move-overhaul mods

These are the most important conceptual conflicts.

A rebalance mod may change a canonical move's purpose, power or even make a formerly status move damaging. If it keeps the same canonical ID/index, `GEN IV+` at priority 150 will still enforce that move's historical Generation IV+ damage category. This is correct for a historical-category preset but may be wrong for the rebalance author's redesigned move.

Likewise, a mod that modernizes base power/accuracy/PP/effects is independent from this mod. Special Stat Split does not overwrite those fields, but the combined result may be a hybrid of Gen1 effect code + another mod's parameters + this mod's category. That can be desirable, but it should be intentional.

## Engine-side category use

The exact frozen target source was searched globally. `move.category` is consumed in `src/battle/Damage.lua`; no second category-based trainer-AI or move-effect branch was found in the frozen Lua source. This limits hidden side effects of adding an explicit category.

Fixed/direct/reactive moves retain dedicated behavior paths. Their modern category may affect display/data consistency but does not by itself rewrite Counter, Bide, OHKO, fixed-damage or Super Fang mechanics.

## Gen1 Modern UI overrides

Two independent presentation toggles exist so Special Stat Split never has to take ownership of more Modern UI than the player wants.

- **ModernUI Override** — default **ON**. For supported Gen1 Modern UI **0.8.3 and 0.8.4**, keeps the built-in Party/Summary presenter and surgically repaints only its legacy Special-stat text. OFF leaves those screens completely untouched.
- **ModernUI BattleWIP Override** — default **OFF**. Controls only provisional compatibility for Modern UI's experimental Battle UI (WIP): battle Party presentation and the level-up correction bridge.

When BattleWIP Override is ON on the supported Modern UI renderer, battle Party keeps Modern UI's own list/detail card and receives only the same five-value stat-row repaint. Special Stat Split does not replace PartyMenu rows, cursor behavior or callbacks. Gen1Recomp PartyMenu remains the sole owner of switch legality, fainted-mon rejection, voluntary SWITCH/STATS/CANCEL behavior, forced replacement, callbacks and stack transitions. When BattleWIP Override is OFF, that experimental battle presentation is not altered.

## Move-info UI mods

A UI that reads the merged `move.category` should agree with battle damage. A UI that ignores the field and independently derives Physical/Special solely from elemental type can show stale GEN I information while battle uses GEN IV+.

This mismatch is presentation-only but confusing; such a UI needs its own compatibility fix.

## EXP Share Modes / Pokédex Plus

The preexisting split-stat compatibility notes still apply. EXP Share Modes can own a private legacy `SPECIAL` level-up display even though shared stat calculation is correct. Pokédex Plus compatibility is handled through the registered screen integration when that dependency is available.

## Save and restart

The category mode is configuration, not per-Pokémon save state. Changing it requires a full restart so registries are rebuilt consistently. The split SpA/SpD values remain derived fields and are stripped/restored around the vanilla serializer as before.

## Link battles

The manifest keeps `affects_link=true`. Since 2.5.0 the mod additionally registers a deterministic record through Gen1Recomp's public `link_fields` registry:

- `special=vanilla;move=gen1`
- `special=vanilla;move=gen4`
- `special=gen2;move=gen1`
- `special=gen2;move=gen4`

`link_fields.rev` is part of Gen1Recomp's own link fingerprint, so different restart-required gameplay settings are expected to produce a pre-battle fingerprint mismatch even when both peers run the same Special Stat Split version. The mod does not hook or replace the engine fingerprint implementation.

Move Category Readout, ModernUI Override, Party layout and BattleWIP presentation choices are excluded because they do not alter battle math. Static/runtime contracts prove the four gameplay revisions are unique. Dedicated two-peer live certification was not performed and is not claimed; the retained best-effort matrix is documented in `OPTIONAL_LINK_QA_2.5.2.md`.

## Gen1 Modern UI level-up card

Gen1 Modern UI 0.8.x has a dedicated battle level-up renderer that reads `mon.stats.special` directly and bypasses generic screen adapters. v2.4.2 can correct this **without modifying Modern UI**, but only when the user explicitly enables **ModernUI BattleWIP Override**. The override is **OFF by default**.

The bridge is intentionally scoped to Modern UI's **experimental BATTLE UI (WIP)** path, which is disabled by default. The ordinary/default battle UI already uses the normal Special Stat Split five-row StatBox and needs no Modern UI correction.

When **ModernUI BattleWIP Override = ON**, the level-up bridge uses two public Gen1Recomp hook seams at priority 200, above Modern UI's priority-100 wrappers:

- `ui.state.decorate`: records only when a downstream decorator replaces Special Stat Split's exact source-owned five-stat `BattleState.StatBox.draw`; if a later decorate pass restores that exact draw, the candidate is retired.
- `render.hud`: calls downstream first and overlays the corrected five-stat card only while that recorded decorator is still installed **and** our native five-stat draw did not execute in the current frame.

This distinction matters for the experimental presenter's own `HIDE ORIGINAL UI` option: if the native child is allowed to draw, its execution marker prevents a duplicate overlay even though Modern UI's wrapper remains installed. With BATTLE UI (WIP) OFF, the source draw is restored and no overlay is possible. VANILLA mode and absence of Modern UI likewise install/produce no split correction. The bridge does not alter the state stack, input, callbacks, Pokémon data or Modern UI functions and does not inspect another mod's private option storage.


## Future Gen1 Modern UI versions

The ordinary **ModernUI Override is capability-gated, not release-number-gated**. It requires compatibility API v1 and verifies the runtime renderer/helper capabilities it needs. A future release number alone does not disable the override; compatible future versions are attempted automatically. An incompatible API, missing helper, or genuinely changed renderer structure causes a **fail-closed no-op**: Modern UI is left untouched rather than being replaced by Special Stat Split's generic UI or patched using guessed coordinates.

This is stricter than the earlier adapter-based experiment by design. The override reaches only the currently audited renderer and exists as a temporary bridge until upstream exposes a supported way for another mod to augment the existing Pokémon detail/stat presentation. Once such a public seam exists, this private-runtime shim should be removed and replaced with the official integration.

**ModernUI BattleWIP Override** remains separately opt-in and experimental. Its stable release compatibility will be revisited when Modern UI's battle presenter is no longer WIP.

