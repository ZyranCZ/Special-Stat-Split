# Optional link QA — Special Stat Split v2.5.1

The final **2.5.1** release does **not** claim dedicated live multiplayer certification. Link support is best-effort: the mod registers its restart-required gameplay configuration through Gen1Recomp v0.1.75's public `link_fields.rev` surface, which the engine includes in its link fingerprint.

This matrix is retained for anyone who later wants to certify the path. It is **not a release blocker**.

## Two-peer matrix

Use **Gen1Recomp v0.1.75** on both peers and Special Stat Split `2.5.1` on both.

| Case | Peer A | Peer B | Expected |
|---|---|---|---|
| 1 | GEN II + GEN IV+ | GEN II + GEN IV+ | Link battle accepted |
| 2 | GEN II + GEN IV+ | VANILLA + GEN IV+ | Rejected before battle simulation / fingerprint mismatch |
| 3 | GEN II + GEN IV+ | GEN II + GEN I | Rejected before battle simulation / fingerprint mismatch |
| 4 | VANILLA + GEN I | VANILLA + GEN I | Link battle accepted |
| 5 | Same gameplay modes; different Move Category Readout / Modern UI presentation options | Same gameplay modes | Remains link-compatible |

For accepted cases, play several turns with at least one physical and one special damaging move and confirm no desync. For rejected cases, the battle should not begin.

## Current certification status

- Automated gameplay-config revision tests: **PASS**.
- Contract for registering the revision on the public `link_fields` surface: **PASS**.
- Direct test against the frozen upstream `Fingerprint.lua`: runs when the pinned Gen1Recomp source tree is supplied to the suite.
- Real two-peer live smoke: **NOT PERFORMED / NOT CLAIMED**.
