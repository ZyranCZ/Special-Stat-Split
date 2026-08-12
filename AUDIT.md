# Deep audit — v2.5.2


## 2.5.2 architecture delta

The executable delta from final 2.4.2 is intentionally narrow: a public API v1 façade, diagnostics, and one `link_fields.rev` registration derived only from `mode` and `move_split`. Existing stat math, move routing, save handling and UI rendering paths are not reimplemented. Legacy exports remain available. The engine's link fingerprint hook is not replaced.

Automated status: ✅ API/config/runtime contracts. Live status: ✅ user-confirmed in-game functional/UI smoke. Dedicated two-peer handshake: 🟡 not performed and not claimed as certified; it is not a release blocker.
## 2.4.2 Party layout option

Baseline is assistant-delivered `2.4.2-test5` (SHA-256 `9814c8919631f58f69dc46e9d08f5a201aeaebfc3e87601ee60d29a4ac251426`). The new option is presentation-only and live. It changes only the Modern UI Party detail stat-row arrangement; Summary presentation and gameplay math are unchanged. Both one-row and two-row modes share the existing live-width adaptive sizing path.


Status: ✅ automated/frozen contract, ✅ user-confirmed core live UI smoke, 🟡 optional/third-party or dedicated multiplayer paths, 🔒 intentionally preserved.

| Area | Intended behavior | Audit result |
|---|---|---|
| Gen II base SpA/SpD | 251 species, shared Special DV/Stat Exp; mod-owned values authoritative | ✅ |
| Ordinary physical damage | Attack vs Defense | ✅ |
| Ordinary special damage | SpA vs SpD in split mode | ✅ |
| GEN I category mode | no explicit canonical category; fallback by elemental type | ✅ now authoritative via `mod.DELETE` |
| GEN IV+ category mode | explicit per-move category | ✅ 165/165 standalone; 251/251 with Crystal extension |
| GEN IV -> IX category drift | none for original 165 | ✅ exhaustive audit |
| Custom reused move index | must not inherit canonical category | ✅ identity guard |
| Legacy move ID spelling | exact Gen1Recomp IDs | ✅ including `HI_JUMP_KICK` |
| Earlier/lower-priority category mod | selected SSS mode wins | ✅ registry semantics |
| Later/higher-priority category mod | later patch may win | 🔒 normal registry semantics |
| STAB/effectiveness | active elemental type/chart | 🔒 |
| Move power/accuracy/PP/effect | not modernized by category mode | 🔒 documented |
| Fixed/direct/reactive mechanics | retain dedicated paths | 🔒 / ✅ source audit |
| Critical hit rulesets | preserve upstream ruleset semantics | ✅ |
| Screens / stat stages | route through selected operands | ✅ |
| Save schema | derived split stats stripped/restored | ✅ |
| Summary / native level-up UI | split display in Gen II stat mode | ✅ code + user live smoke |
| Modern UI ordinary Party/Summary | Modern UI keeps full renderer; only legacy stat text area is repainted when ModernUI Override = ON (default) | ✅ real 0.8.3 + 0.8.4 renderer contracts / 🟡 future upstream dependent |
| Modern UI experimental battle Party / LEVEL UP | provisional ownership/correction only when ModernUI BattleWIP Override = ON (default OFF) | ✅ real-hook contract / 🟡 experimental upstream |
| Integrated Move Category readout | PHYS/SPEC follows merged live category; status/power-0 keep TYPE/ | ✅ ON/OFF + GEN I/IV + coexistence contract |
| Standalone `move_category` coexistence | no conflict, no duplicate visible label | ✅ optional ordering + composable token wrapper |
| Launcher update metadata | Special Stat Split GitHub Releases remain update source | ✅ manifest/source contract |
| Move-info UIs | should consume merged `move.category` | 🟡 third-party dependent |
| Gen1 Modern UI battle Party | optional WIP-only surgical SPATK/SPDEF row repaint; source PartyMenu and Modern UI retain interaction/layout ownership | ✅ contract / 🟡 experimental upstream |
| Link | same gameplay fingerprint/options required | ✅ deterministic audit / 🟡 dedicated two-peer live not certified |

## Category scope

The modern selector is deliberately called **GEN IV+**, not "GEN IX" or "modern data". Only damage class is modernized. A later-generation memory discrepancy may instead be a power, PP, accuracy, effect, priority, target or elemental-type change; `GENERATION_AUDIT.md` and the two packaged CSV audits separate those dimensions.

## Full historical preset warning

A truthful Gen II/III mode cannot be implemented merely by renaming the category selector. Category is still type-based in those generations, while some moves changed elemental type after Red/Blue. Bite becomes Dark, which requires Dark type/chart support to reproduce correctly. Keeping Bite Normal while only forcing it Special would be a hybrid, not Gen II/III fidelity.

## Fixed/special-effect finding

Explicit category metadata is safe only because Gen1Recomp's dedicated move-effect paths remain in control for fixed/direct/reactive mechanics. Category assignment is not interpreted as permission to replace Seismic Toss/Night Shade/Dragon Rage/SonicBoom/Counter/Bide/OHKO/Super Fang logic with the ordinary damage formula.

## Registry ownership finding

2.0.0 had a real ambiguity: selecting GEN I wrote no category, so an explicit category established by an earlier mod could survive and defeat the label. 2.1.0 closes that hole with official delete semantics on canonical original moves. It cannot and should not prevent a later higher-priority mod from intentionally changing the same field.

## Crystal 251 extension audit

v2.2.2 keeps Crystal's split-base export only as non-authoritative compatibility data; the complete mod-owned #001–251 table is the source of truth. The Crystal 251 move runtime table and private type-based damage dispatcher remain audited. The compatibility layer is conditional: none of these modules are required when Crystal is absent.


ModernUI Override defaults ON for ordinary Party/Summary integration. ModernUI BattleWIP Override defaults OFF for all experimental battle presentation. Ordinary exact-layout compatibility is capability-gated through public compatibility API v1 plus the expected renderer/helper structure; it is verified on 0.8.3/0.8.4 but no longer disabled merely because a future release number changes. Incompatible structures still fail closed. The shim should be removed once upstream publishes a cleaner supported way to augment the existing built-in stat rows. The provisional BattleWIP bridge remains separate and default OFF.

## 2.4.2 Modern UI Party/Summary layout refinement

The surgical shim uses two adaptive Party stat rows (`ATTACK / DEFENSE / SPEED` then `SPEC. ATTACK / SPEC. DEFENSE`) and repaints the upstream move/PP text immediately below with the same Modern UI helpers. Summary stacks `SP. ATTACK` and `SP. DEFENSE` on separate rows on every viewport, with values immediately following labels and ID/OT shifted below. No gameplay/data path changed.
