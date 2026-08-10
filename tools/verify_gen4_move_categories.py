#!/usr/bin/env python3
"""Verify Gen IV+ categories for Gen I+II and exact Gen1Recomp identities for Gen I."""
from pathlib import Path
import csv, re
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / 'main.lua').read_text(encoding='utf-8')
CAT_CSV = ROOT / 'data' / 'gen4_move_categories.csv'
ID_CSV = ROOT / 'data' / 'gen1_move_registry_ids.csv'

with CAT_CSV.open(newline='', encoding='utf-8') as f:
    rows = [(int(r['index']), r['identifier'], r['category']) for r in csv.DictReader(f)]
with ID_CSV.open(newline='', encoding='utf-8') as f:
    id_rows = [(int(r['index']), r['gen1recomp_registry_id']) for r in csv.DictReader(f)]

assert len(rows) == 251 and [i for i,_,_ in rows] == list(range(1,252))
assert len(id_rows) == 165 and [i for i,_ in id_rows] == list(range(1,166))
assert Counter(c for _,_,c in rows) == Counter({'physical':106, 'status':93, 'special':52})

embedded = {
    int(i): cat for i, cat in re.findall(r'^  \[(\d+)\] = "(physical|special|status)", -- ', MAIN, re.M)
}
identities = {
    int(i): ident for i, ident in re.findall(r'^  \[(\d+)\] = "([A-Z0-9_]+)",$', MAIN, re.M)
}
assert len(embedded) == 251, f'embedded category table has {len(embedded)} entries'
assert len(identities) == 165, f'embedded Gen I registry identity table has {len(identities)} entries'
for i, _ident, category in rows:
    assert embedded.get(i) == category, f'category mismatch at {i}'
for i, registry_id in id_rows:
    assert identities.get(i) == registry_id, f'registry ID mismatch at {i}: {identities.get(i)} vs {registry_id}'

# Exact Gen1Recomp/pokered naming sentinels that differ from modern identifiers.
assert identities[94] == 'PSYCHIC_M'
assert identities[136] == 'HI_JUMP_KICK'
assert identities[9] == 'THUNDERPUNCH'
assert identities[49] == 'SONICBOOM'

# Cross-era category sentinels, including type/category inversions among Gen II moves.
expected = {
    7:'physical', 13:'special', 16:'special', 22:'physical', 51:'special', 63:'special',
    75:'physical', 127:'physical', 128:'physical', 129:'special', 152:'physical', 161:'special',
    172:'physical', 173:'special', 177:'special', 188:'special', 189:'special', 209:'physical',
    221:'physical', 225:'special', 242:'physical', 247:'special', 251:'physical',
}
for i, category in expected.items():
    assert embedded[i] == category

print('GEN IV+ MOVE CATEGORY TABLE: PASS (251/251)')
print('GEN1RECOMP REGISTRY IDENTITY TABLE: PASS (165/165)')
print('CATEGORY COUNTS: physical=106 special=52 status=93')
print('GEN I+II TYPE-INDEPENDENT + LEGACY-ID SENTINELS: PASS')
