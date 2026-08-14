# Special Stat Split 2.7.3

Target: **Gen1Recomp v0.1.86** (`3de45b671cada26835639c9bb3623201fefedfc3`).

This mod gives Red/Blue/Yellow the Generation II Special Attack and Special
Defense model and can apply Generation IV+ per-move Physical/Special/Status
categories. The same package also supports Gold, where split special stats are
native and the optional per-move category split is added through shared public
battle hooks.

## Installation

Install the ZIP with Gen1Recomp's mod manager, or extract it as a single
`special_stat_split` directory inside the game's `mods` directory. Keep
`manifest.json`, `main.lua`, and `data/` together. Restart after changing either
gameplay option.

## Options

- **Special Stats:** vanilla Gen I Special or Gen II Sp. Atk / Sp. Def on Gen 1.
  Gold already has native split special stats; this option does not collapse
  Gold back to one Special stat.
- **Move Categories:** Gen I/II category by type or Gen IV+ category by move.
- **Move Category Readout:** Gen 1 replaces native `TYPE/` with `PHYS/`,
  `SPEC/`, or `STAT/`; Gold embeds `PHYSICAL`, `SPECIAL`, or `STATUS` directly
  into the native move-list border.
- **ModernUI Override:** compatibility preference for supported external Gen 1
  UI presentations. It never paints a replacement card over native Summary.
- **ModernUI BattleWIP Override:** compatibility preference for that external
  UI; the native level-up StatBox is never covered by a replacement card.

## Behavior retained

- Canonical Gen II-V Sp. Atk / Sp. Def data for National Dex #001-251.
- Canonical Gen IV+ categories for move indices #001-251.
- Shared Gen I Special DV and Special Stat Exp, including defeated Sp. Atk
  yield, Growth/Amnesia/Psychic stage routing, Transform, and X Special.
- Exact upstream damage formulas, RNG, critical-hit handling, type modifiers,
  Reflect/Light Screen, Counter/Mirror Coat routing, and Gold AI scoring.
- Vanilla save schema: derived Gen 1 split-stat fields are removed at
  `save.writing` and recreated on demand.
- Link configuration revision for Gen 1 link play.
- Native manifest update metadata (`github`) remains enabled.

## Compatibility

- **Gen 1 and Gold:** one capability-routed source and no version allow-list.
  Audited native renderer seams update the existing Summary, level-up, and
  move-list windows; they do not place proportional-font cards or bordered
  labels over them.
- **Crystal 251:** all 251 category slots are recognized when that optional
  content owner is active on Gen 1.
- **Pokédex Plus:** its public `PokedexPlusStats` screen record receives the
  six-stat base-stat view.
- **Gen 1 Modern UI / Gen 3 Battle UI:** no `debug` upvalues are used. Native
  Summary/level-up screens are preserved; the separate Gen 3 battle UI keeps
  its screen-space category compatibility path.
- **Move Category:** registry composition is retained; this mod's priority 150
  makes its selected gameplay mode authoritative.

See `COMPATIBILITY.md` and `VERIFICATION.md` for the migration audit and test
scope. The versioned exports are documented in `INTERMOD_API.md`.
