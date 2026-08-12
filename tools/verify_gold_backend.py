#!/usr/bin/env python3
from pathlib import Path
import re
s=Path('main.lua').read_text()
# Gen1 identity contract stays exactly 165.
m=re.search(r'local GEN1_MOVE_KEY_BY_INDEX = \{(.*?)\n\}', s, re.S)
assert m, 'GEN1 identity table missing'
assert len(re.findall(r'\[\d+\]\s*=\s*"', m.group(1))) == 165, 'Gen1 identity table changed size'
# Gold extension owns exactly 86 Johto move identities, yielding 251 total.
g=re.search(r'local GOLD_GEN2_MOVE_KEYS = \{(.*?)\n\}', s, re.S)
assert g, 'Gold Gen2 identity extension missing'
entries={int(i):name for i,name in re.findall(r'\[(\d+)\]\s*=\s*"([A-Z0-9_]+)"',g.group(1))}
assert len(entries)==86 and min(entries)==166 and max(entries)==251, f'Gold identity extension shape {len(entries)}'
assert entries[166]=='SKETCH' and entries[188]=='SLUDGE_BOMB' and entries[243]=='MIRROR_COAT' and entries[251]=='BEAT_UP'
# Generation boundary is before every historical Gen1-only require.
branch=s.index('if activeGeneration() == 2 then')
for module in ['src.pokemon.Stats','src.battle.Damage','src.battle.Experience','src.inventory.ItemEffects','src.battle.MoveEffects','src.ui.SummaryMenu','src.battle.BattleState','src.core.SaveData']:
    pos=s.index(f'require("{module}")')
    assert branch < pos, f'Gold generation branch occurs after Gen1 require {module}'
# Gold backend must not import/patch Gen1 implementations.
gold=s[s.index('local function runGoldBackend'):s.index('return function(mod)')]
for module in ['src.pokemon.Stats','src.battle.Experience','src.inventory.ItemEffects','src.battle.MoveEffects','src.ui.SummaryMenu','src.core.SaveData']:
    assert module not in gold, f'Gold backend references Gen1 module {module}'
assert 'src.battle.gen2.Damage' in gold and 'src.battle.gen2.Battle' in gold and 'src.battle.gen2.Ai' in gold
assert 'special=native_gen2' in gold
print('GOLD BACKEND STATIC CONTRACT: PASS (165 Gen1 + 86 Gold identities; early generation boundary)')
