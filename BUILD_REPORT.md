# Build report — v2.5.1

## 2.5.1 build baseline

The sole source is the final assistant-delivered `special_stat_split_v2.5.0.zip`, SHA-256 `599f73249c8b26922dc94ef78b3d3ce5469acbff51457b5e4a69fd84f04df6a7`. Before editing, the package was freshly extracted and verified as `2.5.0` in both `manifest.json` and the `main.lua` header. No older package was used.

This 2.5.1 release is a metadata-only hotfix over the approved 2.5.0 build: it changes the package identity to 2.5.1 and sets `experimental=false` for the whole mod. The versioned API v1, diagnostics, deterministic link gameplay revision, split-stat formulas, move-category datasets, save contract, Crystal 251 behavior and Modern UI renderer geometry are otherwise unchanged. The optional Modern UI BattleWIP bridge remains explicitly WIP/experimental as a feature, without classifying the whole mod as experimental.

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
