#!/usr/bin/env python3
"""Static source-contract checks for the packaged mod.

Not a substitute for an in-engine run; this prevents accidental removal of the
specific delegation/restoration/UI invariants the design relies on.
"""
from pathlib import Path
import json, re

ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / 'main.lua').read_text(encoding='utf-8')
MANIFEST = json.loads((ROOT / 'manifest.json').read_text(encoding='utf-8'))

assert MANIFEST['id'] == 'special_stat_split'
assert MANIFEST['version'] == '2.6.2'
assert 'ModernUI Override' in MAIN
assert 'modern_ui_override' in MAIN
assert 'ModernUI BattleWIP Override' in MAIN
assert 'modern_ui_battle_wip_override' in MAIN
assert MANIFEST['api'] == 2
assert MANIFEST.get('games') == ['gen1', 'gold']
assert 'game_version' not in MANIFEST
assert 'pokedex_plus' in MANIFEST.get('optional_dependencies', [])
assert 'CRYSTAL_251' in MANIFEST.get('optional_dependencies', [])
assert 'gen1_modern_ui' in MANIFEST.get('optional_dependencies', [])
assert 'move_category' in MANIFEST.get('optional_dependencies', [])
assert 'gen3_battle_ui' in MANIFEST.get('optional_dependencies', [])
assert MANIFEST.get('github') == 'ZyranCZ/Special-Stat-Split'
assert MANIFEST.get('experimental') is False
assert MANIFEST.get('affects_link') is True
assert 'engine_internals' in MANIFEST.get('permissions', [])

required = [
    'category ~= "special"',
    'MOVE CATEGORIES (RESTART)',
    'GEN IV+ (BY MOVE)',
    'GEN I (BY TYPE)',
    'mod.exports.moveCategorySplitActive',
    'mod.exports.getMoveCategory',
    'MOVE CATEGORY READOUT',
    'gen3UiRuntimeDetected',
    'automatic-render-capability',
    'end, math.huge)',
    'callWithGen3Inline',
    'categoryOnlyLabel',
    'hooks:wrap("battle.overlay"',
    'move_category_readout',
    'MOVE_READOUT_PATCH_KEY',
    'PHYS/',
    'SPEC/',
    'battle.started',
    'battle.ended',
    'mod.exports.moveCategoryReadoutEnabled',
    'mod.content.link_fields:register("special_stat_split_rules",',
    'local gameplayConfigRevision = ("special=%s;move=%s")',
    'mod.exports.getGameplayConfig',
    'mod.exports.getLinkConfigRevision',
    'mod.exports.getDiagnostics',
    'mod.exports.specialStatSplit = {',
    'apiVersion = 1',
    'return state.originalDamage(ruleset, attacker, defender, move, opts)',
    'local function ensureCurrentSplit(b)',
    'if b.curStats.specialAttack == nil or b.curStats.specialDefense == nil then',
    'ensureCurrentSplit(attacker)',
    'ensureCurrentSplit(defender)',
    'acs.special = acs.specialAttack or acs.special',
    'dcs.special = dcs.specialDefense or dcs.special',
    'ast.special = ast.specialAttack or 0',
    'dst.special = dst.specialDefense or 0',
    'local result = pack(pcall(state.originalDamage',
    'acs.special = save.acsSpecial',
    'dcs.special = save.dcsSpecial',
    'ast.special = save.astSpecial',
    'dst.special = save.dstSpecial',
    'SummaryMenu.draw = function(self)',
    'state.splitStatBoxDraw = function(self)',
    'BattleState.StatBox.draw = state.splitStatBoxDraw',
    '{ "SPATK", st.specialAttack or st.special }',
    '{ "SPDEF", st.specialDefense or st.special }',
    '{ "SP.ATK", st.specialAttack or st.special }',
    '{ "SP.DEF", st.specialDefense or st.special }',
    'aliasStageRun("SPECIAL_UP1_EFFECT", "user", "specialAttack")',
    'aliasStageRun("SPECIAL_UP2_EFFECT", "user", "specialDefense")',
    'aliasStageRun("SPECIAL_DOWN_SIDE_EFFECT", "target", "specialDefense")',
    'stages.specialAttack = stages.special or 0',
    'ctx.user.curStats.specialAttack',
    'ctx.user.curStats.specialDefense',
    'defeatedDef.baseStats.special = row.spa',
    'SaveData.save = function(data, mods)',
    'modernUiOverrideEnabled()',
    'modernUiBattleWipOverrideEnabled()',
    'mod.exports.modernUiOverrideEnabled',
    'mod.exports.modernUiBattleWipOverrideEnabled',
    'mod.find("gen1_modern_ui")',
    '__specialStatSplitModernUiSurgicalV1',
    'closureUpvalue(getter, "runtime")',
    'closureUpvalueMatching(getter',
    'looksLikeModernRuntime',
    'type(getter) ~= "function"',
    'type(runtime.maxMovePP) == "function"',
    'type(runtime.summaryPokemon) == "function"',
    'runtime.drawParty = bridge.wrappedParty',
    'runtime.drawMonDetail = bridge.wrappedMonDetail',
    'runtime.drawSummary = bridge.wrappedSummary',
    '("ATTACK %s"):format',
    '("DEFENSE %s"):format',
    '("SPEED %s"):format',
    '("SPEC. ATTACK %s"):format',
    '("SPEC. DEFENSE %s"):format',
    'local function rowFits(textFont)',
    'while statPixels > 10 and not rowFits(statFont) do',
    'local statDrawScale = 1',
    'statDrawScale = math.min(statDrawScale, width / measured)',
    '("ATK %s"):format',
    '("DEF %s"):format',
    '("SPD %s"):format',
    '("SPATK %s"):format',
    '("SPDEF %s"):format',
    'detailDrawText(value, tx, ty, 0, statDrawScale, statDrawScale)',
    'drawSingle("SP. ATTACK", spa, rowY)',
    'drawSingle("SP. DEFENSE", spd, rowY + statGap)',
    'mod.exports.modernUiSurgicalInstalled',
    'hooks:wrap("ui.state.decorate"',
    'hooks:wrap("render.hud"',
    'nativeLevelUpDrawSeen = setmetatable({}, { __mode = "k" })',
    'state.nativeLevelUpDrawSeen[self] = true',
    'decoratedLevelUpBoxes[decorated] = { draw = afterDraw }',
    'top.draw == decorated.draw',
    'and not nativeWasDrawn',
    'drawCorrectLevelUp(game, viewport, top)',
    '{ { "SPEED", stats.speed }, { "SP. ATK", stats.specialAttack } }',
    '{ { "SP. DEF", stats.specialDefense }, nil }',
    'mod.exports.getSpecialBaseStats = function(species)',
    'state.derivedStats[value]',
    '{ \"specialAttack\", \"specialDefense\" }',
    'local result = pack(pcall(state.originalSave, data, mods))',
]
for text in required:
    assert text in MAIN, f'missing source contract: {text}'

assert 'MODERN_UI_SURGICAL_RELEASES' not in MAIN, 'release-number allowlist must not return'
assert 'hooks:wrap("link.fingerprint"' not in MAIN, 'must not override the engine link fingerprint hook'


# Pixel-geometry release guard for the frozen 8px tile font. These assertions
# keep every glyph inside the white interior rather than over the box border.
# Summary: box (0,8,10,10) -> interior x 8..71, y 72..135.
summary_label_x, summary_value_x = 8, 48
summary_first_y, summary_step = 72, 14
assert summary_label_x + 5 * 8 - 1 <= 47
assert summary_value_x + 3 * 8 - 1 <= 71
assert summary_first_y >= 72
assert summary_first_y + 4 * summary_step + 7 <= 135
assert 'local y = 72 + (i - 1) * 14' in MAIN
assert 'Font.draw(("%3d"):format(r[2] or 0), 48, y)' in MAIN
# Level-up: box (9,2,11,10) -> interior x 80..151, y 24..87.
stat_label_x, stat_value_x = 80, 128
stat_first_y, stat_step = 24, 14
assert stat_label_x + 6 * 8 - 1 <= 127
assert stat_value_x + 3 * 8 - 1 <= 151
assert stat_first_y >= 24
assert stat_first_y + 4 * stat_step + 7 <= 87
assert 'local y = 24 + (i - 1) * 14' in MAIN
assert 'Font.draw(("%3d"):format(r[2] or 0), 128, y)' in MAIN

# The mod must not redefine the upstream shared DV/StatExp ordering.
assert 'Stats.ORDER =' not in MAIN
assert 'dvs.specialAttack' not in MAIN and 'dvs.specialDefense' not in MAIN
assert 'statExp.specialAttack' not in MAIN and 'statExp.specialDefense' not in MAIN

# All three legacy Special move effects must be patched once each.
for effect in ('SPECIAL_UP1_EFFECT','SPECIAL_UP2_EFFECT','SPECIAL_DOWN_SIDE_EFFECT'):
    assert MAIN.count(f'aliasStageRun("{effect}"') == 1

# Both gameplay dimensions are load-time options.
assert 'default = "gen2"' in MAIN
assert 'default = "gen4"' in MAIN
assert 'default = "two_rows"' in MAIN
assert '{ "2 ROWS", "two_rows" }' in MAIN
assert '{ "1 ROW", "one_row" }' in MAIN
assert 'local active = tostring(mod.options:get("mode") or "gen2") == "gen2"' in MAIN
assert 'local moveSplitActive = tostring(mod.options:get("move_split") or "gen4") == "gen4"' in MAIN
assert 'mod.content.moves:each()' in MAIN
assert 'mod.content.moves:patch(id, { category = category })' in MAIN
assert 'mod.content.moves:patch(id, { category = mod.DELETE })' in MAIN
assert 'isCanonicalGen1Move(id, move, index)' in MAIN
assert 'GEN1_MOVE_KEY_BY_INDEX[index]' in MAIN
assert 'GEN4_MOVE_CATEGORY_BY_INDEX[index]' in MAIN
assert MAIN.count('state.active') >= 8

# Integrated Move Category Readout is presentation-only, default ON, and
# composable with the old standalone move_category mod.
assert 'key = "move_category_readout"' in MAIN
assert 'label = "MOVE CATEGORY READOUT"' in MAIN
readout_block = MAIN[MAIN.index('key = "move_category_readout"'):MAIN.index('key = "modern_ui_override"')]
assert 'default = true' in readout_block
assert 'rawget(Font, MOVE_READOUT_PATCH_KEY)' in MAIN
assert 'rawset(Font, MOVE_READOUT_PATCH_KEY, readout)' in MAIN
assert 'text == readout.typeLabel' in MAIN
assert 'def.category or (def.type and TypeChart.category(def.type))' in MAIN
assert '(def.power or 0) == 0 or def.category == "status"' in MAIN
assert 'mod.find("move_category")' in MAIN
assert MANIFEST.get('conflicts', []) == []

# Generation IV+ category data must be complete and explicit for the full Gen I+II move pool.
entries = re.findall(r'^  \[(\d+)\] = "(physical|special|status)", -- ([^\n]+)$', MAIN, re.M)
assert len(entries) == 251, f'expected 251 embedded move categories, got {len(entries)}'
assert [int(i) for i, _, _ in entries] == list(range(1, 252))
counts = {k: sum(1 for _, c, _ in entries if c == k) for k in ('physical','special','status')}
assert counts == {'physical': 106, 'special': 52, 'status': 93}


# Optional Crystal 251 bridge may inspect exported split stats, but the mod-owned
# canonical 251-species table must have priority. Crystal's 251-move runtime table
# is still bridged for per-move categories.
for text in (
    'mod.find("CRYSTAL_251")',
    'crystalExports.crystalBaseStats',
    'crystalExports.crystalMoves',
    'SplitStats.setCrystalBaseStats',
    'mods.CRYSTAL_251.battle.crystal_damage',
    '__special_stat_split_crystal_damage_bridge_v1',
    'bridge.physicalTypes[move.type] = category == "physical"',
):
    assert text in MAIN, f'missing Crystal compatibility contract: {text}'


# Packaged mod runtime must be self-contained. Gen1Recomp loads the manifest
# entry but does not prepend a mod's own directory to the require path.
assert not re.search(r'(?m)^[^\n-]*require\([\"\'](?:lib|data)\.', MAIN)
assert 'local GEN2_SPECIAL_BY_ID = {' in MAIN
assert len(re.findall(r'^  [A-Z0-9_]+ = \{ dex = \d+, spa = \d+, spd = \d+ \},$', MAIN, re.M)) == 251
assert 'local row = speciesDef.id and GEN2_SPECIAL_BY_ID[speciesDef.id] or nil' in MAIN
assert MAIN.index('local row = speciesDef.id and GEN2_SPECIAL_BY_ID[speciesDef.id] or nil') < MAIN.index('row = speciesDef.id and CRYSTAL_SPECIAL_BY_ID')

print('PACKAGED MOD LOADER CONTRACT: PASS')
print('MANIFEST CONTRACT: PASS')
print('DAMAGE DELEGATION/RESTORE CONTRACT: PASS')
print('SHARED SPECIAL DV/STAT EXP CONTRACT: PASS')
print('GEN IV+ MOVE CATEGORY + COLLISION CONTRACT: PASS')
print('MOVE EFFECT ROUTING CONTRACT: PASS')
print('SUMMARY + LEVEL-UP UI CONTRACT: PASS')
print('SAVE SCHEMA STRIP/RESTORE CONTRACT: PASS')
print('VANILLA DELEGATION GUARDS: PASS')

assert 'PokedexPlusStats' in MAIN
assert 'SP.ATK' in MAIN and 'SP.DEF' in MAIN

# Presentation compatibility toggles are intentionally independent.
assert 'key = "modern_ui_override"' in MAIN
assert 'label = "ModernUI Override"' in MAIN
assert re.search(r'key = "modern_ui_override"[\s\S]{0,220}default = true', MAIN)
assert 'key = "modern_ui_battle_wip_override"' in MAIN
assert 'label = "ModernUI BattleWIP Override"' in MAIN
assert re.search(r'key = "modern_ui_battle_wip_override"[\s\S]{0,260}default = false', MAIN)
