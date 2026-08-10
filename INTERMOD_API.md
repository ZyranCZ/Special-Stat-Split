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

Consumers should check `apiVersion` rather than the Special Stat Split release number. Do not mutate returned diagnostic/config tables and do not depend on undocumented fields. The legacy root exports are retained in 2.5.1 so existing consumers continue to work.

## Link-safety contract

The gameplay revision contains only restart-required battle-math choices:

- `special=vanilla|gen2`
- `move=gen1|gen4`

Presentation-only options intentionally do not enter this revision. Special Stat Split registers the revision through Gen1Recomp's public `link_fields` registry; it does not wrap or replace the engine's `link.fingerprint` hook.
