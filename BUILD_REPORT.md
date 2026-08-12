# Build report — v2.6.0


## 2.6.0 Gold feature release

- Adds the generation-isolated Pokémon Gold backend while preserving the existing Gen 1 backend.
- Final manifest targets `gen1` and `gold` only.
- Gold keeps native Sp. Atk/Sp. Def mechanics and gains optional GEN IV+ per-move category routing.
- Gold selected-move readout uses the public `battle.overlay` seam with normalized top-border title spacing.
- User live verification on Gold v0.1.78 covers boot/battle entry, native split-stat Summary presentation and the final readout.
- Complete bundled regression suite passes before and after packaging.

## 2.5.2 build baseline

The sole source is the final assistant-delivered `special_stat_split_v2.5.0.zip`, SHA-256 `599f73249c8b26922dc94ef78b3d3ce5469acbff51457b5e4a69fd84f04df6a7`. Before editing, the package was freshly extracted and verified as `2.5.0` in both `manifest.json` and the `main.lua` header. No older package was used.

This 2.5.2 release changes compatibility policy rather than gameplay: the manifest no longer declares a `game_version` release range, so future Gen1Recomp version-number changes do not disable the mod before it can run. Mod API `2` and capability checks remain the structural safety contracts. `experimental=false` remains mandatory. Gameplay, datasets, save behavior, Crystal 251 behavior, Modern UI geometry and link-config logic are unchanged from 2.5.1.

## Inherited 2.4.2 release contents

The v2.4.2 release keeps the completed test7 presentation behavior:

- **ModernUI Party Stats Layout = 2 ROWS** (default): `ATTACK / DEFENSE / SPEED`, then `SPEC. ATTACK / SPEC. DEFENSE`.
- **ModernUI Party Stats Layout = 1 ROW**: compact `ATK / DEF / SPD / SPATK / SPDEF`.
- Party choices use one shared adaptive font scale calculated from the live panel width.
- Summary is intentionally independent of the Party toggle and always places `SP. ATTACK` and `SP. DEFENSE` on separate rows on desktop and mobile, with ID/OT moved below using Modern UI's native fallback data.

## Forward compatibility

Modern UI ordinary Party/Summary compatibility is capability-gated rather than version-number-gated. 0.8.3 and 0.8.4 are verified implementations; a compatible future version number (tested synthetically as 0.9.9) continues to install the shim. Missing/incompatible API or renderer capabilities fail closed.

## Automated verification

PASS against:

- 251/251 split-stat reference rows and 502/502 SpA/SpD values;
- 251/251 modern move categories;
- all Special/category configurations;
- standalone Move Category coexistence contracts;
- Crystal 251 contracts;
- Party/Summary layout and Modern UI capability guards;
- ModernUI Override ON/OFF, BattleWIP guards and VANILLA guards.

The test7 suite was run before promotion and the final suite was rerun after metadata/documentation conversion. The distributable ZIP keeps `manifest.json` and `main.lua` at archive root.
