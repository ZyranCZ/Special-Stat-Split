# Compatibility audit

| Area | v2.7.3 implementation | Result |
|---|---|---|
| Sandbox | `mod:read`, sandboxed `load`, audited native renderer composition | No blocked `io`, `os`, `debug`, `package`, `dofile`, or `loadfile` use |
| Permissions | Supported Stats facade plus audited `Font`, Gen 1 Summary/StatBox, and Gold Chrome seams | `engine_internals`; generation-gated and regression tested |
| Gen 1 damage | `battle.damage` aliases legacy Special to Sp. Atk/Sp. Def for the exact upstream call | Preserves upstream formula and RNG |
| Gold damage | `battle.damage` scopes type-category and screen choice to the selected move | Per-move category without changing STAB/type |
| Gold AI | `battle.enemy_action` scopes the category while vanilla scores each move | Restored immediately after the call |
| Counter/Mirror Coat | `battle.damage_dealt` corrects `kind` and `tookKind` | Uses actual move category |
| Stat growth | Supported Stats facade, `battle.exp_award`, move-effect registry, item-effect registry | Gen II shared DV/Stat Exp rules retained |
| Saves | `save.writing` removes only mod-derived stat fields | Vanilla disk schema retained |
| Native Gen 1 readout | Narrow `Font.draw` composition changes only the exact `TYPE/` token to `PHYS/`, `SPEC/`, or `STAT/` | Uses upstream pixel font and placement; no overlay panel |
| Native Gen 1 Summary | Reuses `Font.drawBox(0,8,10,10)` and native pixel rows | No screen-space replacement card |
| Native Gen 1 level-up | Reuses `BattleState.StatBox` at `(9,2,11,10)` | Five split rows inside the original window |
| Native Gold readout | Ten-tile cut-out in `Chrome.box(0,12,20,6)` top border | Full label with original per-label spacing; no outlined panel |
| Other UI | `render.hud` only for the separate Gen 3 battle UI path; screens registry for Pokédex Plus | No `debug` upvalue surgery |
| Link play | `link_fields` only on Gen 1, where the registry is live | Gameplay options fingerprinted |
| Updates | Manifest `github` field | Native updater path retained |

## Optional mods

| Mod | Integration | Verification |
|---|---|---|
| CRYSTAL_251 | Detects the active content owner and maps categories #166-251 | Real loader combination, 251 category assertions |
| pokedex_plus | Patches the public `PokedexPlusStats` screen factory | Loader/static path verified; live visual layout not exercised |
| gen1_modern_ui | Compatibility options retained; no fallback card is painted over native Summary/level-up | Loader/static path verified; external live layout not exercised |
| gen3_battle_ui | Screen-space selected-move category pill | Loader/static path verified; live visual layout not exercised |
| move_category | Composes through the shared moves registry | Registry ownership and priority audited |

The package declares exact game tokens `gen1` and `gold`. It does not use a
hard engine version allow-list; v0.1.86 is the verified target, while future
compatibility remains capability-driven. The strict Gen 2 static scan reports
the dynamically named Gen 1 Summary/StatBox modules as intentionally
unresolved, then returns `will load`; the production Gold loader path is also
exercised directly by the regression harness.
