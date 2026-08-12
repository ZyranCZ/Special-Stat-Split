# Special Stat Split inter-mod API — v1

Introduced in **2.5.0**. Existing root exports remain available for backward compatibility; new integrations should prefer the versioned API table and feature-detect `apiVersion`.

```lua
local handle = mod.find("special_stat_split")
local api = handle and handle.exports and handle.exports.specialStatSplit
if api and api.apiVersion == 1 then
  -- Safe to consume API v1.
end
```

## API v1

`handle.exports.specialStatSplit` contains:

- `apiVersion` — currently `1`.
- `modVersion` — installed Special Stat Split version.
- `specialSplitActive()` — whether Generation II Sp. Atk / Sp. Def mode is active.
- `moveCategorySplitActive()` — whether GEN IV+ per-move categories are active.
- `moveCategoryReadoutEnabled()` — current presentation-only readout toggle.
- `getMoveCategory(moveOrIndex)` — modern category for a canonical move when GEN IV+ mode is active; otherwise `nil`.
- `getSpecialBaseStats(speciesOrId)` — `{ specialAttack, specialDefense }` when split stats are active; otherwise `nil`.
- `attachSplitStats(mon, speciesDef)` — attaches calculated split stats to a Pokémon table and returns that table.
- `getGameplayConfig()` — returns a defensive copy containing `specialStats = "vanilla"|"gen2"` and `moveCategories = "gen1"|"gen4"`.
- `getLinkConfigRevision()` — deterministic gameplay revision string used by the link-safety registration.
- `getDiagnostics()` — read-only snapshot of gameplay mode, link registration and detected integrations.

## Compatibility rules

Consumers should check `apiVersion` rather than the Special Stat Split release number. Do not mutate returned diagnostic/config tables and do not depend on undocumented fields. The legacy root exports are retained in 2.6.0 so existing consumers continue to work.

## Link-safety contract

The gameplay revision contains only restart-required battle-math choices:

- `special=vanilla|gen2`
- `move=gen1|gen4`

Presentation-only options intentionally do not enter this revision. Special Stat Split registers the revision through Gen1Recomp's public `link_fields` registry; it does not wrap or replace the engine's `link.fingerprint` hook.
## API v2 for generation-aware consumers

Version 2.6.0 adds `handle.exports.specialStatSplitV2` without changing the meaning/version number of the legacy v1 table. Consumers should feature-detect it rather than infer support from the mod release number.

`specialStatSplitV2` currently exposes:

- `apiVersion = 2`
- `generation()` — currently returns `"gold"` on the Gold backend.
- `getRequestedGameplayConfig()` — the saved/shared option request.
- `getEffectiveGameplayConfig()` — the mechanics actually active for the current game. On Gold, Special stats are always `native_gen2`; move categories are `type_based_gen2` or `gen4`.
- `getEffectiveSpecialBaseStats(species)` — reads native Gold `specialAttack` / `specialDefense` base data when available.
- `getMoveCategory(move)` — the effective modern category helper when GEN IV+ mode is active.
- `attachSplitStats(mon)` — retained as a generation-safe no-op on Gold; it never recalculates or overwrites native Gold stats.
- `getDiagnostics()` — includes requested/effective configuration, Gold category-bridge/readout coverage and applicability of optional Gen 1 integrations.

### Legacy v1 behavior on Gold

API v1 remains `apiVersion = 1`. `getSpecialBaseStats()` returns `nil` on Gold instead of silently redefining the historical v1 function around Gold-native data, and `attachSplitStats(mon)` returns the mon unchanged. New consumers that need native Gold values should use API v2.

### Gold link revision

When the engine exposes `link_fields`, Gold fingerprints **effective gameplay**, not the no-op requested Special setting. Both requested `VANILLA` and `GEN II` therefore use `special=native_gen2`; only `move=type_gen2` versus `move=gen4` is a Gold gameplay distinction. This avoids a false mismatch between two mechanically identical Gold Special-stat settings.
### 2.6.2 presentation diagnostics

On Gold, `getDiagnostics().integrations.gen3Ui` reports whether `gen3_battle_ui` is detected, its exposed handle version when available, and whether the active presentation target is `inline-type-row` or the native Gold tab. This is diagnostic/presentation metadata only and does not change API v1/v2 gameplay semantics.


