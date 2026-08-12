# Build report — v2.6.4

## Release baseline

- Source baseline: the accepted 2.6.2 alignment/antialias test build.
- Baseline SHA-256: `dbf6e41a617b2a8da47eb04c66e5bb59b7830e811029e22b6a2a9a08b939bcd7`.
- Release change: Gold / Generation II Gen 3 UI category semibold shoulder increased from 55% to 70% alpha.
- Gen 1 Gen 3 UI category rendering remains at the accepted 55% alpha shoulder.
- Internal version promoted to `2.6.4`.
- No gameplay mechanics or declared-game changes.

## 2.6.4 delta

- Source baseline: final `special_stat_split_v2.6.3.zip`.
- Presentation-only fix: suppress the native Gen 1 / Gold move-category readout whenever the Gen 3 UI TYPE/PP footer is active or has been runtime-observed.
- Keeps the accepted 2.6.3 Gen 3 UI alignment, antialiasing, Gen 1 55% semibold shoulder and Gold 70% semibold shoulder unchanged.
- Adds regression coverage for both immediate declared-Gen3 suppression and runtime-observed suppression.
