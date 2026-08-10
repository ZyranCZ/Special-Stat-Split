# Generation audit — original 165 moves

This audit answers a narrow question precisely: **does the Physical / Special / Status category of any original Generation I move differ between later generations after the per-move split was introduced?**

## Result

**No.** The complete original 165-move pool is category-identical across **Generation IV, V, VI, VII, VIII and IX**. Therefore Special Stat Split uses one truthful selector, `GEN IV+ (BY MOVE)`, rather than six visually different selectors that would perform the same operation.

This conclusion is scoped to moves #1..165. It must not be generalized to later moves. For example, later-generation moves can have generation-specific category overrides, so an expanded move pool would need a new audit.

The exhaustive machine-readable table is `data/move_category_generation_audit.csv`.

## Gen I -> GEN IV+ category flips

There are exactly **18 damaging moves** whose ordinary damage side differs from the Generation I type-based rule:

| # | Move | Gen I model | GEN IV+ | Note |
|---:|---|---|---|---|
| 7 | fire-punch | Special | Physical |  |
| 8 | ice-punch | Special | Physical |  |
| 9 | thunder-punch | Special | Physical |  |
| 13 | razor-wind | Physical | Special |  |
| 16 | gust | Physical | Special | elemental type changed after Gen I: normal -> flying |
| 22 | vine-whip | Special | Physical |  |
| 49 | sonic-boom | Physical | Special | fixed/special damage bypasses ordinary Attack/Defense operands in Gen1Recomp |
| 51 | acid | Physical | Special |  |
| 63 | hyper-beam | Physical | Special |  |
| 75 | razor-leaf | Special | Physical |  |
| 101 | night-shade | Physical | Special | fixed/special damage bypasses ordinary Attack/Defense operands in Gen1Recomp |
| 123 | smog | Physical | Special |  |
| 124 | sludge | Physical | Special |  |
| 127 | waterfall | Special | Physical |  |
| 128 | clamp | Special | Physical |  |
| 129 | swift | Physical | Special |  |
| 152 | crabhammer | Special | Physical |  |
| 161 | tri-attack | Physical | Special |  |

SonicBoom and Night Shade appear in the table because their metadata category changes, but their fixed-damage behavior continues through dedicated mechanics rather than ordinary Attack/Defense or Sp. Atk/Sp. Def damage.

## Elemental type is a separate history axis

Four original moves changed elemental type after Generation I:

| # | Move | Gen I type | Gen II+ type | Category consequence |
|---:|---|---|---|---|
| 2 | karate-chop | Normal | Fighting | Category unchanged in GEN IV+ audit |
| 16 | gust | Normal | Flying | Category unchanged in GEN IV+ audit |
| 28 | sand-attack | Normal | Ground | Category unchanged in GEN IV+ audit |
| 44 | bite | Normal | Dark | Important for any truthful Gen II/III preset: Dark was a Special type pre-Gen-IV |

These are not GEN IV+ category changes. They matter when someone asks for a **full historical generation preset**, because STAB, effectiveness and pre-Gen-IV type-based Physical/Special rules depend on elemental type. Bite is the clearest blocker to pretending that GEN II/III is only a category toggle: Dark does not exist in vanilla Red/Blue's type set.

## Why players can correctly remember the same move differently

The category can remain identical while another field changes. PokeAPI's version-group changelog reconstruction packaged here records **83 field changes affecting 51 original moves from Generation IV onward**:

- Gen 4: 13 field changes across 12 moves (accuracy=4, power=5, pp=4).
- Gen 5: 22 field changes across 15 moves (accuracy=10, effect_id=1, power=6, pp=5).
- Gen 6: 30 field changes across 27 moves (accuracy=6, power=15, pp=8, target_id=1).
- Gen 7: 12 field changes across 9 moves (accuracy=1, effect_id=1, power=6, pp=3, priority=1).
- Gen 8: 6 field changes across 4 moves (power=4, pp=2).

Examples include Tackle's power/accuracy changes, Jump Kick and High Jump Kick power/PP changes, Thrash/Petal Dance power changes, the Generation VI reductions to Flamethrower/Hydro Pump/Surf/Ice Beam/Blizzard/Thunderbolt/Thunder/Fire Blast, Generation VII Leech Life's major power increase, and transient Let's Go values for Absorb/Mega Drain/Solar Beam/Sky Attack.

A particularly important lesson is that **generation alone may not fully identify move data**. Hypnosis changed accuracy in Diamond/Pearl and changed again in Platinum, both within Generation IV. If a future mod mode promises complete move parameters rather than only damage category, it should be based on an explicit game/version group rather than a broad generation label.

## Sources used for the audit

The category table is cross-checked against PokeAPI move damage classes and Pokémon Showdown's current + generation override data. Exact original move identity/order is tied to Gen1Recomp's frozen ROM manifest and pret/pokered move constants. Historical parameter differences are retained in `data/move_data_changelog_gen4plus.csv` so the result can be independently inspected without trusting a prose summary.
