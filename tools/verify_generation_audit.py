#!/usr/bin/env python3
from pathlib import Path
import csv
from collections import Counter
ROOT=Path(__file__).resolve().parents[1]
rows=list(csv.DictReader((ROOT/'data/move_category_generation_audit.csv').open(encoding='utf8')))
assert len(rows)==165
assert [int(r['index']) for r in rows]==list(range(1,166))
for r in rows:
    modern={r[f'gen{g}_category'] for g in range(4,10)}
    assert len(modern)==1, f"Gen IV-IX category drift: {r['index']} {r['identifier']} {modern}"
diffs=[r for r in rows if r['modern_differs_from_gen1']=='yes']
assert len(diffs)==18, len(diffs)
expected={7,8,9,13,16,22,49,51,63,75,101,123,124,127,128,129,152,161}
assert {int(r['index']) for r in diffs}==expected
# Exactly four original moves have documented elemental type migration from Gen I.
type_notes=[r for r in rows if 'elemental type changed after Gen I' in r['note']]
assert {int(r['index']) for r in type_notes}=={2,16,28,44}
print('GENERATION CATEGORY AUDIT: PASS (165/165; Gen IV-IX identical)')
print('GEN I -> GEN IV+ damaging category flips: 18 PASS')
print('GEN I -> GEN II elemental type migrations: 4 PASS')
