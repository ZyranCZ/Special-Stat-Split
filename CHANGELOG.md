# Changelog

## 2.7.3 — Native stat windows and Gold border readout

### Fixed

- Removed the proportional-font replacement card that covered the native Gen 1
  Summary stat box.
- Restored five split-stat rows inside the original `10x10` Summary box using
  the engine pixel font and border tiles.
- Removed the replacement level-up card and restored the five-row split layout
  inside the native `StatBox` window.
- Removed Gold's separate outlined `SPEC` panel.
- Restored the original ten-tile cut-out in the top border of Gold's move list:
  ` PHYSICAL `, ` SPECIAL  `, and `  STATUS  `.

### Tested

- Direct native-coordinate assertions for Summary and level-up Sp. Atk/Sp. Def.
- `render.hud` replacement stat-card rectangle/text counts both remain zero.
- Gold border-field geometry, full labels, padding, and zero outlined panels.
- Migration functional/regression harness: **472/472 PASS**.

## 2.7.2 — Native status-category label

### Fixed

- Status moves now replace the native Gen 1 `TYPE/` token with `STAT/` in the
  same pixel-font position as `PHYS/` and `SPEC/`.
- The fix covers the reported `SUPERSONIC` case and does not reintroduce an
  overlay panel.

### Tested

- Added direct `STAT/` assertions for both `SWORDS_DANCE` and `SUPERSONIC`.
- Migration functional/regression harness: **459/459 PASS**.

## 2.7.1 — Native Gen 1 category-label correction

### Fixed

- Removed the visibly separate category overlay panel from the native Gen 1
  move-selection box.
- Restored the original in-place `TYPE/` → `PHYS/` / `SPEC/` substitution,
  using the game's own pixel font, coordinates, and draw call.
- Status and zero-power moves continue to show the original `TYPE/` label.

### Tested

- Added direct assertions for `SPEC/`, `PHYS/`, retained status `TYPE/`, and
  zero Gen 1 overlay-panel rectangles.
- Migration functional/regression harness: **458/458 PASS**.

## 2.7.0 — Gen1Recomp v0.1.86 migration

### Fixed

- Restored a real Gold loader path instead of relying on Gen 1 private module
  facades.
- Kept Gold Reflect/Light Screen, Counter/Mirror Coat, damage event kind, and
  enemy AI decisions aligned with each move's effective category.
- Restored Crystal 251 category ownership for indices 166-251 on Gen 1.
- Kept Gen 1 derived stats out of the persisted save schema.

### Migrated

- Removed `engine_internals`, `debug.getupvalue`, private runtime-chain
  inspection, and direct Gen 1/Gold battle/UI module patches.
- Moved damage, AI, EXP, save, screen, item, move-effect, and presentation work
  to v0.1.86 public hooks, events, registries, and the supported Stats facade.
- Replaced embedded data copies with sandboxed `mod:read` + `load`/CSV parsing.
- Replaced surgical third-party renderer patches with public-HUD fallbacks.
- Changed the manifest category from the legacy alias `GAMEPLAY` to `MECHANIC`.

### Tested

- Production loader state `loaded` on Gen 1 and Gold.
- Production loader state `loaded` with a Crystal 251 optional dependency.
- All 165 Gen 1 and all 251 Gold/Crystal move categories.
- Split-stat math, special damage operands/stages, X Special, save stripping,
  Gold screens, damage event routing, and Gold AI category restoration.
- v0.1.86 `modkit lint`, fixture validation, and strict `gen2check`.
