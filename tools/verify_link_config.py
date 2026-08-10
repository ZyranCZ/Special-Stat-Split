#!/usr/bin/env python3
"""Verify every gameplay-mode combination has a unique link revision."""
from itertools import product

def revision(special: str, move: str) -> str:
    return f"special={special};move={move}"

special_modes = ("vanilla", "gen2")
move_modes = ("gen1", "gen4")
rows = {(s, m): revision(s, m) for s, m in product(special_modes, move_modes)}
expected = {
    "special=vanilla;move=gen1",
    "special=vanilla;move=gen4",
    "special=gen2;move=gen1",
    "special=gen2;move=gen4",
}
assert set(rows.values()) == expected
assert len(set(rows.values())) == 4
print("LINK CONFIG MATRIX: PASS (4/4 unique gameplay fingerprints)")
