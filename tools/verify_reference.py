#!/usr/bin/env python3
"""Independent verification oracle. Does not import production Lua code."""
import csv, math, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]

def calc_stat(base, dv, stat_exp, level):
    ev = math.floor(min(255, math.ceil(math.sqrt(stat_exp))) / 4)
    return math.floor(((base + dv) * 2 + ev) * level / 100) + 5

def gen1_damage(level, power, attack, defense, stab=False, type_rows=(), random_roll=255, crit=False):
    if attack > 255 or defense > 255:
        attack = max(1, attack // 4)
        defense = max(1, defense // 4)
    if crit:
        level *= 2
    d = math.floor(2 * level / 5) + 2
    d = math.floor((d * power * attack / max(1, defense)) / 50)
    d = min(d, 997) + 2
    if stab:
        d = math.floor(d * 3 / 2)
    for mult in type_rows:
        d = math.floor(d * mult / 10)
    if d == 0:
        return 0
    if d > 1:
        d = math.floor(d * random_roll / 255)
    return max(d, 1)

def load_rows():
    with (ROOT / "data" / "gen2_special_stats.csv").open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))

def main():
    rows = load_rows()
    assert len(rows) == 251
    assert [int(r["dex"]) for r in rows] == list(range(1, 252))
    ids = [r["id"] for r in rows]
    assert len(ids) == len(set(ids))

    by = {r["id"]: r for r in rows}
    # Canonical sentinels specifically chosen to catch modern-stat contamination.
    assert (int(by["BUTTERFREE"]["sp_atk"]), int(by["BUTTERFREE"]["sp_def"])) == (80, 80)
    assert (int(by["ALAKAZAM"]["sp_atk"]), int(by["ALAKAZAM"]["sp_def"])) == (135, 85)
    assert (int(by["CHANSEY"]["sp_atk"]), int(by["CHANSEY"]["sp_def"])) == (35, 105)
    assert (int(by["MEWTWO"]["sp_atk"]), int(by["MEWTWO"]["sp_def"])) == (154, 90)
    # Johto sentinels catch the exact regression that previously collapsed
    # unknown Crystal species back to one legacy SPECIAL value.
    assert (int(by["TOGETIC"]["sp_atk"]), int(by["TOGETIC"]["sp_def"])) == (80, 105)
    assert (int(by["ESPEON"]["sp_atk"]), int(by["ESPEON"]["sp_def"])) == (130, 95)
    assert (int(by["UMBREON"]["sp_atk"]), int(by["UMBREON"]["sp_def"])) == (60, 130)
    assert (int(by["BLISSEY"]["sp_atk"]), int(by["BLISSEY"]["sp_def"])) == (75, 135)

    # Shared DV / Stat Exp: same inputs, different base stat produces independent output.
    spa = calc_stat(135, 10, 10000, 50)
    spd = calc_stat(85, 10, 10000, 50)
    assert spa != spd

    # Damage oracle vectors: only the selected operands differ.
    # Fixed 255 roll removes random variation.
    same = gen1_damage(50, 90, 100, 100, stab=True, random_roll=255)
    assert same == 61, same
    high_atk = gen1_damage(50, 90, 150, 100, stab=True, random_roll=255)
    low_def = gen1_damage(50, 90, 100, 50, stab=True, random_roll=255)
    assert high_atk == 91, high_atk
    assert low_def == 121, low_def

    # Floor-sensitive vectors: exact values matter, not only ordering.
    assert gen1_damage(37, 95, 123, 117, stab=False, random_roll=217) == 28
    assert gen1_damage(63, 120, 256, 255, stab=True, random_roll=232) == 90

    print("REFERENCE DATA: 251/251 PASS")
    print("GEN II SENTINELS: PASS")
    print("SHARED SPECIAL DV/STAT EXP ORACLE: PASS")
    print("DAMAGE ORACLE VECTORS: PASS")

if __name__ == "__main__":
    main()
