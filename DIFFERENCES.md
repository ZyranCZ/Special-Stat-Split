# Differences from vanilla Gen1Recomp — v2.5.1


## Link/configuration behavior added in 2.5.0

Special Stat Split publishes its restart-required gameplay configuration to Gen1Recomp's link fingerprint through `link_fields.rev`. This does not change single-player battle math; it prevents peers with different Special-stat or move-category modes from being treated as an identical lockstep ruleset. Presentation-only settings are omitted.

This file lists intentional gameplay divergences introduced by Special Stat Split. It does not claim to modernize the complete battle engine.

## Move Category Readout (default ON)

- During battle move selection, damaging moves may display `PHYS/` or `SPEC/` where vanilla displays `TYPE/`.
- This is presentation-only; the elemental type, category data and damage calculation are not changed by the readout itself.
- Status/power-0 moves keep `TYPE/`.
- The feature can be disabled independently.

## When SPECIAL STATS = GEN II

- One calculated `SPECIAL` combat stat is supplemented by separate calculated Sp. Atk and Sp. Def using Generation II–V Kanto base values.
- Ordinary special-category attacks use attacker Sp. Atk and defender Sp. Def.
- Growth and X Special modify Sp. Atk; Amnesia and Psychic's Special drop modify Sp. Def.
- The single Generation I Special DV and Special Stat Exp bucket remain shared.
- Summary/level-up presentation exposes the split stats.

## When MOVE CATEGORIES = GEN IV+

- The 165 original moves receive explicit Generation IV+ Physical/Special/Status categories independent of elemental type.
- Exactly 18 damaging moves differ in normal damage side from Generation I's category-by-type rule.
- STAB, type effectiveness, base power, accuracy, PP, priority, secondary effects and special move-effect logic remain those supplied by Gen1Recomp/other active mods.

## When MOVE CATEGORIES = GEN I

- Special Stat Split actively removes explicit categories on canonical original moves at its registry priority so the engine's type-based fallback is authoritative against earlier/lower-priority patches.

## Explicit non-goals

- No full Gen II/III/IV/V/VI/VII/VIII/IX move-data emulation.
- No elemental move-type modernization such as Bite -> Dark.
- No modern abilities, natures, held items, EV/IV system or complete later-generation damage engine.

See `GENERATION_AUDIT.md` for why the later category selector is correctly labelled GEN IV+ rather than offering six identical generation choices.

## With Crystal 251

The mod uses its own audited #001–251 Sp. Atk / Sp. Def table for Johto species and extends modern category ownership to the 86 Gen II moves supplied by Crystal 251. Crystal exports are non-authoritative compatibility/fallback data; no Crystal source is bundled.
