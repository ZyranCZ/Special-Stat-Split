# Build report — v2.6.5

## Release lineage

- Official source baseline: `special_stat_split_v2.6.4.zip`
  - SHA-256: `2ea23d07d0db9adfc29600a81408b4bf312fec53a8633c12ea819880b8ac98ab`
- Gen 1 fixed-footer implementation: user-live-approved **TEST F**.
  - Test artifact SHA-256: `dc111335a33c45aaa4046cc74aa0722f73ad258c6c9cd15d129d19174556cee9`
- Gold fixed-footer implementation: user-live-approved fixed-footer test.
  - Test artifact SHA-256: `ba3a7e7c64d9512119711b60858bc7f32039f5043ca17ba31aec93bb330146c6`

Intermediate test labels are not release lineage. The official release sequence is **2.6.4 → 2.6.5**.

## Functional delta from 2.6.4

- Gen 3 Inspired UI category labels on **Red / Blue / Yellow** now start at a fixed footer-local column derived from the stable literal `TYPE` label. Their X position no longer depends on the displayed type value or PP field.
- The same fixed footer-local column policy is applied independently on **Pokémon Gold**.
- The first letter of `PHYSICAL`, `SPECIAL`, and `STATUS` therefore starts at one stable position within each generation's Gen 3 UI footer.
- Existing native-readout suppression, baseline/style capture, Gen 1 55% semibold shoulder and Gold 70% semibold shoulder remain unchanged.
- No battle math, move-category routing, native Special-stat behavior, save/link semantics, manifest game scope, or engine-version policy changed.

## Verification

- Gen 1 runtime section matches the live-approved TEST F implementation after normalizing only the release number.
- Gold pre-Gen1 runtime section matches the live-approved Gold fixed-footer implementation after normalizing only the release number.
- `bash tools/run_all.sh`: PASS before packaging.
- Final package is re-extracted and the same suite is run again before delivery.
