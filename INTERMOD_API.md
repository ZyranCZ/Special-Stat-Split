# Inter-mod API

Find the mod with `mod.find("special_stat_split")`, then use its `exports`.
Legacy top-level functions and the `specialStatSplit` v1 table remain present.
New integrations should prefer `specialStatSplitV2`.

## `specialStatSplitV2`

- `api`: `2`
- `version`: current mod version
- `generation`: detected backend (`1` or `2`)
- `getMoveCategory(move)`: effective `physical`, `special`, or `status`
- `getSpecialBaseStats(species)`: `{ specialAttack, specialDefense }`
- `attachSplitStats(mon, speciesDef?)`: ensures derived Gen 1 split stats
- `getGameplayConfig()`: requested Special and move-category modes
- `getLinkConfigRevision()`: deterministic gameplay revision string
- `getDiagnostics()`: backend, registry, integration, and ownership details

Presentation settings are deliberately excluded from the link revision. The
two gameplay settings require a restart and are included.

