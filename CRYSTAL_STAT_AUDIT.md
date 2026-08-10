# Crystal 251 Special-stat audit — v2.2.2

## Finding

Crystal 251's ROM parser maps the Generation II base-stat record correctly:

- byte +5: Special Attack
- byte +6: Special Defense

The `pret/pokecrystal` Togetic base-stat record is `55, 40, 85, 40, 80, 105` in the documented order `hp, atk, def, spd, sat, sdf`, therefore Togetic's canonical Generation II values are **Sp. Atk 80 / Sp. Def 105**.

The in-game equal-stat symptom was traced to Special Stat Split v2.2.0's fallback behavior, not to the canonical Crystal record layout. v2.2.0 only owned #001-151 split-base rows. If Crystal's optional cross-mod `crystalBaseStats` export was unavailable, a Johto species had no split row and fell back to `vanillaSpecial, vanillaSpecial`.

## v2.2.2 resolution

- The mod now owns an authoritative Generation II-V Sp. Atk / Sp. Def table for National Dex **#001-251**.
- Crystal 251 exports cannot override these canonical values.
- Crystal split exports are retained only as last-resort data outside the canonical table / compatibility diagnostics.
- The complete 251-row CSV is `data/gen2_special_stats.csv`.
- The test suite cross-checks all **251 species / 502 SpA+SpD values** against a frozen Generation II-V reference snapshot.
- Regression tests deliberately feed wrong Crystal values (Togetic 99/99 and Espeon 99/99) and require the mod to return Togetic 80/105 and Espeon 130/95.

## Johto sentinels

| Pokémon | Sp. Atk | Sp. Def |
|---|---:|---:|
| Togepi | 40 | 65 |
| Togetic | 80 | 105 |
| Espeon | 130 | 95 |
| Umbreon | 60 | 130 |
| Shuckle | 10 | 230 |
| Mantine | 80 | 140 |
| Blissey | 75 | 135 |
| Lugia | 90 | 154 |
| Ho-Oh | 110 | 154 |
| Celebi | 100 | 100 |

## Sources used for the audit

- `pret/pokecrystal`: `data/pokemon/base_stats/*.asm` (canonical disassembly data for Pokémon Crystal)
- Bulbapedia: `List of Pokémon by base stats in Generations II-V` (full-table cross-check)
- Crystal 251 v0.9.19 source: `lib/extractor.lua` and `main.lua`
