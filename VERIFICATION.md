# Verification record

Verified against the official Gen1Recomp `v0.1.86` tag at commit
`3de45b671cada26835639c9bb3623201fefedfc3`.

## Automated results

- `modkit lint`: PASS
- `modkit validate --base fixture`: PASS
- `modkit gen2check --strict --notes`: PASS (`will load`; the two dynamically
  named, Gen 1-only native UI modules are generation-gated and intentionally
  not followed by the static scanner)
- Real v0.1.86 loader, Gen 1: state `loaded`, no loader errors
- Real v0.1.86 loader, Gold: state `loaded`, no loader errors
- Real v0.1.86 loader, Gen 1 + Crystal 251: state `loaded`, no loader errors
- Migration functional/regression harness: **472/472 PASS**
- Native Gen 1 readout: `TYPE/` → `PHYS/` / `SPEC/` / `STAT/` PASS,
  including `SUPERSONIC`; additional overlay-panel rectangle count **0** PASS
- Native Summary: `SPATK` / `SPDEF` at the original pixel-box coordinates;
  proportional-font draw count **0** PASS
- Native level-up StatBox: `SP.ATK` / `SP.DEF` at the original window
  coordinates; proportional-font draw count **0** PASS
- Gen 1 `render.hud`: replacement stat-card rectangle and text counts **0** PASS
- Native Gold readout: `PHYSICAL` / `SPECIAL` / `STATUS` at the original
  ten-tile border field with per-label padding; outlined-panel count **0** PASS
- Canonical categories: **165/165 Gen 1** and **251/251 Gold/Crystal PASS**
- Canonical split-stat reference: **251/251 species, 502/502 values PASS**
- Battle math/stage/Light Screen/critical path oracles: PASS

The headless loader harness runs the production Loader, sandbox, option schema,
registry merge, dependency sort, hook/event buses, validation, and status
reporting. It is not a mocked manifest-only check.

## Not exercised here

No imported ROM-generated cache or graphical game executable was available in
this environment. Therefore a live in-game visual smoke test, imported-base
validation, link handshake between two running clients, and optional UI mod
pixel layout remain user-test items.

## Efficient manual smoke test

Start one Gen 1 game with default settings, open Charizard's Summary, then in a
single battle select **Fire Punch** and use **X Special** before attacking. One
pass confirms split stats/readout, a formerly type-special move that is now
physical, the Sp. Atk stage item, and the damage path. Save and reload once to
confirm the vanilla save schema still round-trips.
