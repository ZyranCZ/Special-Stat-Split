#!/usr/bin/env python3
"""Independent battle-math certification vectors for the Special split.

This intentionally does not import or execute production Lua. It models only
frozen upstream Gen1Recomp 60cf07f's documented stage/badge/screen ordering and
its integer damage formula, then checks hard-coded expected vectors.
"""
import math

STAGE = {
    -6:(25,100), -5:(28,100), -4:(33,100), -3:(40,100),
    -2:(50,100), -1:(66,100), 0:(100,100), 1:(150,100),
    2:(200,100), 3:(250,100), 4:(300,100), 5:(350,100), 6:(400,100),
}

def apply_stage(value, stage):
    stage = max(-6, min(6, stage))
    n, d = STAGE[stage]
    return max(1, min(999, math.floor(value * n / d)))

def damage(level, power, attack, defense, *, stab=False, random_roll=255,
           crit=False, crit_ignores_stages=True, attack_stage=0,
           defense_stage=0, attack_badge=False, defense_badge=False,
           light_screen=False):
    # Frozen Damage.compute: faithful crit skips stages, badge boosts and screens.
    if crit and crit_ignores_stages:
        atk, dfn = attack, defense
    else:
        atk = apply_stage(attack, attack_stage)
        dfn = apply_stage(defense, defense_stage)
        if attack_badge:
            atk = math.floor(atk * 9 / 8)
        if defense_badge:
            dfn = math.floor(dfn * 9 / 8)
        if not crit and light_screen:
            dfn *= 2

    # GetDamageVars .scaleStats: quarter both if either exceeds one byte.
    if atk > 255 or dfn > 255:
        atk = max(1, math.floor(atk / 4))
        dfn = max(1, math.floor(dfn / 4))

    if crit:
        level *= 2
    out = math.floor(2 * level / 5) + 2
    out = math.floor((out * power * atk / max(1, dfn)) / 50)
    out = min(out, 997) + 2
    if stab:
        out = math.floor(out * 3 / 2)
    if out > 1:
        out = math.floor(out * random_roll / 255)
    return max(out, 1)

def main():
    # Frozen Stats.applyStage table, all thirteen stages.
    expected = {
        -6:25, -5:28, -4:33, -3:40, -2:50, -1:66, 0:100,
        1:150, 2:200, 3:250, 4:300, 5:350, 6:400,
    }
    for stage, want in expected.items():
        got = apply_stage(100, stage)
        assert got == want, (stage, got, want)
    assert apply_stage(100, -99) == 25
    assert apply_stage(100, 99) == 400

    # Split operands: fixed Level 50 / Power 90 / STAB / max random roll.
    # 135 SpA vs 85 SpD is Alakazam's Gen II base split and gives a strong
    # asymmetric sentinel for accidentally reading the legacy shared Special.
    vectors = [
        ({}, 96),
        ({"attack_stage": 2}, 192),
        ({"defense_stage": 2}, 49),
        ({"attack_stage": -2}, 49),
        ({"defense_stage": -2}, 193),
        ({"attack_stage": 6, "defense_stage": -6}, 1498),
        ({"attack_stage": -6, "defense_stage": 6}, 7),
        ({"light_screen": True}, 49),
        # Same x9/8 Volcano boost on both sides cancels at this vector.
        ({"attack_badge": True, "defense_badge": True}, 96),
        ({"attack_badge": True}, 108),
        ({"defense_badge": True}, 87),
    ]
    for opts, want in vectors:
        got = damage(50, 90, 135, 85, stab=True, **opts)
        assert got == want, (opts, got, want)

    # gen1_faithful: critIgnoresStages=true, so even extreme stages/screens/
    # badge boosts do not enter the stat operands.
    faithful_crit = damage(
        50, 90, 135, 85, stab=True, crit=True, crit_ignores_stages=True,
        attack_stage=6, defense_stage=-6, attack_badge=True,
        defense_badge=True, light_screen=True,
    )
    assert faithful_crit == 183, faithful_crit

    # modern_clean: stages and badge boosts still apply on crits, but screens
    # are bypassed because Damage.compute only doubles screens when not crit.
    modern_crit = damage(
        50, 90, 135, 85, stab=True, crit=True, crit_ignores_stages=False,
        attack_stage=2, defense_stage=-1, attack_badge=True,
        defense_badge=True, light_screen=True,
    )
    assert modern_crit == 570, modern_crit

    # Physical control sentinel. This oracle is category-agnostic: the mod's
    # guarantee is that physical moves never enter the alias wrapper at all.
    physical_control = damage(50, 80, 120, 100, stab=True)
    assert physical_control == 66, physical_control

    print("STAGE MATRIX -6..+6: PASS")
    print("SP. ATK / SP. DEF DAMAGE VECTORS: PASS")
    print("LIGHT SCREEN: PASS")
    print("VOLCANO BADGE OPERAND ORDER: PASS")
    print("GEN1_FAITHFUL CRIT BYPASS: PASS")
    print("MODERN_CLEAN CRIT STAGE PATH: PASS")
    print("PHYSICAL CONTROL ORACLE: PASS")

if __name__ == "__main__":
    main()
