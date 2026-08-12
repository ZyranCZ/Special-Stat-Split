# Manual smoke test — v2.6.2

Frozen integration fixture: **Gen1Recomp v0.1.75**, commit `60cf07fb0a1ffce0ec6d5d0d2f78a921a6d0b7da`. Runtime compatibility is intentionally not pinned to this release.

Automated tests cover the full stat/category tables, Gen IV–IX parity, collision guards, gameplay-config link revisions, public API/diagnostics contracts, source guards and operand routing. Manual testing should focus on real-game integration, third-party combinations and the real two-peer handshake.

The 2.6.2 release has user-confirmed Gold boot/battle, Summary/category-readout smoke and live Gen 3 UI move-footer smoke on both Gold and Gen 1. Dedicated multiplayer certification is optional rather than a release gate; see `OPTIONAL_LINK_QA_2.5.2.md` if it is ever tested later.


## Gen 1 + Gen 3 Inspired UI move-category check

1. Boot Red, Blue, or Yellow with Gen 3 Inspired UI enabled and **MOVE CATEGORY READOUT = ON**.
2. Open FIGHT and highlight a damaging Physical move: the wide footer must show **PHYSICAL** between the displayed TYPE value and PP.
3. Highlight a damaging Special move: the same field must show **SPECIAL**.
4. Highlight a status move: the same field must show **STATUS**.
5. The text must inherit the footer style, remain pixel-sharp, and use the same confirmed bold weight as the live Gold path.
6. Set **MOVE CATEGORY READOUT = OFF**: the Gen 3 UI footer must return to its untouched original form.
7. Disable Gen 3 UI and repeat FIGHT: the original Gen 1 readout must still use the established `PHYS/` / `SPEC/` replacement and must not show the wide full-word overlay.

## Gold + Gen 3 Inspired UI Overhaul v1.4.0

1. Enable `gen3_battle_ui` v1.4.0 and Special Stat Split 2.6.2 on Gold.
2. Keep **MOVE CATEGORY READOUT = ON** and enter FIGHT.
3. Highlight a modern **Physical** move (Bite or Fire Punch are suitable): the bottom information row should retain `TYPE <element>` on the left and `PP` on the right, with **PHYSICAL** in the gap on the **same row**.
4. Highlight a modern **Special** move such as Water Gun/Flamethrower/Shadow Ball as appropriate to the current moveset: the same location should read **SPECIAL**.
5. Highlight a Status move: the same location should read **STATUS**.
6. Confirm the native Gold top-border category tab is not also visible over the Gen 3 move panel.
7. Move the cursor through all four slots and verify category text updates immediately without shifting `TYPE`, the elemental type, or `PP`.
8. Set **MOVE CATEGORY READOUT = OFF**: Gen 3 UI's row must return to its untouched original form.
9. If possible, repeat after resizing/window scaling; the category should remain between type and PP because placement is measured from the live renderer rather than fixed coordinates.

## Gold / Gen 2

Automated Gold contracts are now part of `bash tools/run_all.sh`. They are **not** a substitute for the real Gold runtime matrix. Gold is enabled in the final `manifest.json`; the following matrix remains useful for extended regression testing on current Gold-capable Gen1Recomp builds:

1. Boot with requested SPECIAL STATS = VANILLA and = GEN II; both must retain native Gold Sp. Atk / Sp. Def with no duplicate Summary/level-up UI.
2. In type-based mode, verify native Gold categories (e.g. Fire Punch follows FIRE/Special; Shadow Ball follows GHOST/Physical).
3. In GEN IV+ mode, verify both category-flip directions with deliberately asymmetric Attack/Sp. Atk and Defense/Sp. Def fixtures (Fire Punch -> Physical, Shadow Ball -> Special are suitable sentinels).
4. Verify Reflect / Light Screen, Counter / Mirror Coat, AI choice, crit, STAB, effectiveness, weather and held type boosters remain Gold-native except for the selected stat pair.
5. Verify Growth, Amnesia, Psychic's Sp. Def drop, X SPECIAL, Transform, Haze and Light Screen occur exactly once with native Gold behavior.
6. Save, restart and reload; DVs, Stat Exp, Sp. Atk, Sp. Def, moves and mod options must round-trip with no Gen 1 save stripping.
7. In native Gold FIGHT, the top-border title should follow the selected move (`PHYSICAL`, `SPECIAL`, `STATUS`, or the documented non-formula label) without moving the native rows; SELECT move-reordering must retain its native marker. With Gen 3 UI active, use the dedicated inline-row matrix above instead.
8. Confirm native Gold Party/Summary/level-up screens are otherwise visually unchanged.

Current verified and still-unverified Gold edges are recorded in `GOLD_PORT_STATUS.md`.

## Integrated Move Category Readout

1. Leave **MOVE CATEGORY READOUT = ON** (default).
2. In battle, open FIGHT and highlight a damaging move. The label above the elemental type should read `PHYS/` or `SPEC/`.
3. In **GEN IV+ (BY MOVE)** mode, Fire Punch must read `PHYS/` while Flamethrower reads `SPEC/`.
4. In **GEN I (BY TYPE)** mode, Fire Punch must fall back to the Fire-type special category and therefore read `SPEC/`.
5. Highlight a status/power-0 move such as Growl; it must keep `TYPE/`.
6. Set **MOVE CATEGORY READOUT = OFF**; the label must return to `TYPE/` immediately without restart.
7. Optional coexistence smoke: enable the old standalone `move_category` mod too. There must be one label only, no Mod Manager conflict/error, and disabling only one readout must leave the other able to provide the label.

## Launcher updater metadata

The packaged manifest must retain `github = ZyranCZ/Special-Stat-Split`. The launcher/Gen1Compile update check should therefore continue to use Special Stat Split GitHub Releases for this combined mod.

## Crystal 251 smoke

With Crystal 251 imported and enabled:

1. Enable `GEN II (SP. ATK / SP. DEF)` and `GEN IV+ (BY MOVE)`, save and fully restart.
2. Inspect a Johto species with unequal Special bases (for example Espeon or Umbreon) and verify Sp. Atk / Sp. Def are not duplicated.
3. Exercise at least one Gen II move whose modern category differs from its Gen II type category, e.g. Flame Wheel (Physical Fire), Snore (Special Normal), Crunch (Physical Dark) or Shadow Ball (Special Ghost).
4. Confirm battle damage follows the modern operand pair while STAB/effectiveness still follows the move's elemental type.
5. Switch only `MOVE CATEGORIES` to `GEN I (BY TYPE)`, save/restart, and verify Crystal's native Gen II type-based category behavior returns.
6. Disable Crystal entirely and repeat an existing Kanto smoke to confirm the standalone path is unchanged.

## A. Default configuration

1. Select `GEN II (SP. ATK / SP. DEF)`.
2. Select `GEN IV+ (BY MOVE)`.
3. Save and fully restart Gen1Recomp.
4. Verify Summary/level-up split-stat UI.
5. Verify Fire Punch is Physical, Flamethrower Special, Hyper Beam Special, Waterfall Physical and Swift/Tri Attack Special.

## B. Real operand routing

Use attackers/defenders whose Attack vs Sp. Atk and Defense vs Sp. Def differ clearly. Confirm that Fire Punch/Waterfall track Attack/Defense while Flamethrower/Hyper Beam track Sp. Atk/Sp. Def. Do not use fixed-damage moves as proof of stat routing.

## C. GEN I authority regression

1. Set a lower-priority move mod (if available) that gives Fire Punch an explicit Physical category.
2. Select `GEN I (BY TYPE)` in Special Stat Split and restart.
3. Fire Punch must behave as FIRE/type-based Special in the vanilla type chart: the earlier explicit category must not leak through.
4. Hyper Beam must return to NORMAL/type-based Physical.

The automated registry stub already exercises this exact earlier-category removal; live smoke confirms the real manager/load order.

## D. Custom-index collision regression

If testing with a custom-move mod that reuses an index 1..165 for a differently named move, verify that Special Stat Split logs/skips it rather than assigning the original move's category. A canonical replacement preserving the original ID/index is intentionally treated as that historical move slot.

## E. Special/fixed/reactive moves

Smoke Counter, Bide, Seismic Toss, Night Shade, Dragon Rage, SonicBoom, Super Fang, an OHKO move, Metronome and Mirror Move if convenient. The goal is not to make them use modern mechanics; it is to confirm the category metadata layer does not disturb their existing Gen1Recomp effect paths.

## F. Stat mechanics

Verify Growth -> Sp. Atk, Amnesia -> Sp. Def, X Special -> Sp. Atk, Psychic secondary -> Sp. Def, Light Screen/Reflect, Haze and Transform.

## G. Save/reload

Save, quit completely, relaunch, load, deposit/withdraw a Pokémon and re-open Summary. Confirm party/PC data is intact.

## H. Compatibility pass

Test the normal mod set, especially typing/chart mods, move-info UIs and any move overhaul/rebalance. A move-info UI should display merged `move.category`; a type-only display may disagree with battle and needs its own patch.

## I. Link

Before dedicated link certification, run a two-peer battle with identical v2.4.2 gameplay settings and at least one category-flipped move (Fire Punch or Hyper Beam). Mismatched category options should not be considered a supported link configuration.


## Release smoke status

- Core single-player split/category smoke: **PASS (user-reported across the release test line)**.
- Modern UI ordinary Party/Summary surgical override: **PASS on 0.8.3 in prior live testing; 0.8.4 requires the same visual smoke after allowlist extension.**
- Modern UI experimental BattleWIP compatibility: provisional only and default OFF; earlier battle Party path received live confirmation, but this is not treated as a stable release target.
- Standalone Move Category coexistence: **automated PASS**; a dedicated live dual-install smoke remains optional.
- Dedicated two-peer live link battle: **NOT SEPARATELY VERIFIED**.

## Modern UI ordinary-screen exact-layout regression

With **Gen1 Modern UI 0.8.3 or 0.8.4** installed and `SPECIAL STATS` on GEN II:

1. Leave **ModernUI Override = ON** (default) and open Party. Compare against Modern UI with the override OFF: the party list, icons, selected Pokémon sprite, name/type, HP bar, frame, dimensions and footer must remain visually identical. The selected detail lower text block should now show two adaptive stat rows — `ATTACK / DEFENSE / SPEED` and `SPEC. ATTACK / SPEC. DEFENSE` — with the move/PP list immediately below in the same Modern UI styling. Both rows must share the same font scale and remain complete on narrow panels.
2. Open Summary page 1. On every viewport size, `SP. ATTACK <value>` and `SP. DEFENSE <value>` must appear on separate rows, with each value immediately after its label; ID and OT move below them but preserve Modern UI's native values and spacing.
3. Set **ModernUI Override = OFF**. Modern UI must immediately return to its own untouched legacy `SPC` / `SPECIAL` presentation.
4. Re-enable the override and confirm the narrow split-stat repaint returns without changing the rest of the layout.
5. If testing a future Modern UI release with the same required renderer capabilities, the shim should keep working regardless of the version number. If those capabilities are missing/incompatible, it must fail closed instead of replacing the screen with a generic presenter.

## Modern UI battle Party regression

This remains provisional. Enable Gen1 Modern UI's experimental Battle UI and set **ModernUI BattleWIP Override = ON**. From a battle, open POKéMON. The battle Party must retain Modern UI's own visual layout and only its selected-Pokémon stat row may receive the five-value split repaint. With **ModernUI BattleWIP Override = OFF**, Special Stat Split must not alter that experimental battle Party presentation.

Test voluntary switching and forced replacement to confirm original PartyMenu callbacks still own all interaction.

## Modern Battle UI level-up regression — v2.4.2

1. Enable Gen1 Modern UI's experimental **BATTLE UI (WIP)**, set `SPECIAL STATS` to `GEN II (SP. ATK / SP. DEF)`, and set **ModernUI BattleWIP Override = ON**. Both the Modern UI Battle UI and this override are opt-in; the normal/default battle UI already uses the native split StatBox.
2. Gain a level during battle.
3. The visible LEVEL UP card must show **ATTACK, DEFENSE, SPEED, SP. ATK and SP. DEF**. It must not show a legacy `SPECIAL` row.
4. Press A/B: the card must close through the normal native `BattleState.StatBox` lifecycle and battle must continue normally.
5. Disable Modern Battle UI and repeat: only the native five-row Special Stat Split StatBox should appear; there must not be a duplicate high-resolution correction card.
6. Set `SPECIAL STATS` to VANILLA, restart and repeat: no split correction card should be drawn.
7. On mobile, repeat once with touch controls visible and verify the correction card remains above the lower controls and no obsolete `SPECIAL` text protrudes around it.


### BattleWIP opt-in guard

Repeat once with **ModernUI BattleWIP Override = OFF**. Special Stat Split must not draw its correction card; Modern UI owns its experimental Level Up presentation unchanged. This is intentional.


## ModernUI Party Stats Layout toggle

With ModernUI Override ON and split stats active, verify both Party-only choices:
- `2 ROWS` (default): `ATTACK / DEFENSE / SPEED` then `SPEC. ATTACK / SPEC. DEFENSE`.
- `1 ROW`: `ATK / DEF / SPD / SPATK / SPDEF` on one line.
Summary must remain unchanged in both cases.

## Gold live readout check

In a Gold battle, open **FIGHT** and move the cursor between moves. The top border of the move box should show the selected move's effective class:

- `PHYSICAL` — uses Attack / Defense for normal formula damage.
- `SPECIAL` — uses Sp. Atk / Sp. Def for normal formula damage.
- `STATUS` — non-damaging status move.
- `FIXED` — fixed/non-formula damage such as Seismic Toss, Night Shade, Dragon Rage, Sonic Boom, Psywave or Super Fang.
- `OHKO` — Guillotine, Horn Drill or Fissure.
- `REACTIVE` — Bide.

The label must update immediately as the cursor moves and must remain visible during SELECT move reordering. Move names and PP must not shift or be overwritten.
