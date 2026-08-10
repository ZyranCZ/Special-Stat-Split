#!/usr/bin/env python3
from pathlib import Path
import hashlib, sys
if len(sys.argv) != 2:
    raise SystemExit('usage: verify_frozen_sources.py /path/to/gen1recomp-root')
root=Path(sys.argv[1])
expected={
 'src/pokemon/Stats.lua':'1e918f2c18554606b39c7eed1b4bd302c42c935873facbc095437a9a2dce228d',
 'src/battle/Damage.lua':'8aaa4b5cc0bdb2cb58fa786c526aecbc395380d922fba355bf396508c98d9e99',
 'src/battle/Experience.lua':'1fc915b680e60da112cfac757032f3344321a0458239dd41c7ed2d22efb665de',
 'src/battle/MoveEffects.lua':'566b0ae3ccedc4e896f57307424045ad1385a45478b40796d3a31961d26c2ae2',
 'src/inventory/ItemEffects.lua':'c6b302ff6ffbc30590f2f25b208fa87abc97d1c7c5ed97e1ec5298fefef918c7',
 'src/core/SaveData.lua':'ae9da11257196dafc6f5c2170f689ddbd8eea79afa728752e94619d8122d604b',
 'src/pokemon/Pokemon.lua':'f4e7ff1734dbd83ca154e57d37fd7b0767f87cabca15d6fe5875538d60af37dd',
 'src/pokemon/Evolution.lua':'b2d3212d60c2e2460b638171c3760ea0a4260d974f4610fcc6db4e0e7eb597d1',
 'src/ui/SummaryMenu.lua':'153c533fbfc3d4c5b903611af4913f93e1e9edfbcbb732450758ccff30e26816',
}
for rel,want in expected.items():
    p=root/rel
    if not p.exists(): raise AssertionError(f'missing frozen source: {rel}')
    got=hashlib.sha256(p.read_bytes()).hexdigest()
    assert got==want, f'{rel}: expected {want}, got {got}'
print('FROZEN UPSTREAM SOURCE HASHES: PASS')
