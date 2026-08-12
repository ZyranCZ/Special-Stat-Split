-- Headless runtime contracts for SPECIAL STAT SPLIT.
-- Runs under texlua with minimal Gen1Recomp stubs. No LÖVE window required.

package.path = './?.lua;./?/init.lua;' .. package.path

local MODE = arg[1] or 'gen2'
local MOVE_MODE = arg[2] or 'gen4'
local BATTLE_WIP_OVERRIDE = arg[3] or 'off'
local MODERN_OVERRIDE = os.getenv('MODERN_UI_OVERRIDE') or 'on'
local MODERN_PARTY_LAYOUT = os.getenv('MODERN_UI_PARTY_LAYOUT') or 'two_rows'
local READOUT_MODE = arg[4] or 'on'
local REAL_MOVE_CATEGORY_MAIN = os.getenv('REAL_MOVE_CATEGORY_MAIN')
local function expect(cond, msg)
  if not cond then error('ASSERTION FAILED: ' .. tostring(msg), 2) end
end
local function deepcopy(t)
  if type(t) ~= 'table' then return t end
  local out = {}
  for k,v in pairs(t) do out[k] = deepcopy(v) end
  return out
end

local hudPrintCalls = {}
local hudPrintRecords = {}
local currentHudFont
local function fakeFont(size)
  local f = { _size = tonumber(size) or 15 }
  function f:getHeight() return self._size end
  function f:getWidth(text) return #tostring(text or '') * math.max(6, math.floor(self._size * 0.55)) end
  function f:setFilter() end
  function f:hasGlyphs() return true end
  return f
end
_G.love = { graphics = {
  setColor = function() end,
  rectangle = function() end,
  setLineWidth = function() end,
  push = function() end,
  pop = function() end,
  origin = function() end,
  getWidth = function() return 1024 end,
  getHeight = function() return 768 end,
  newFont = function(a, b)
    local size = type(a) == 'number' and a or b
    return fakeFont(size or 15)
  end,
  setFont = function(font) currentHudFont = font end,
  getFont = function() return currentHudFont or fakeFont(15) end,
  print = function(text, x, y, r, sx, sy)
    local value = tostring(text)
    hudPrintCalls[#hudPrintCalls+1] = value
    hudPrintRecords[#hudPrintRecords+1] = {
      text = value,
      fontSize = currentHudFont and currentHudFont._size or nil,
      sx = type(sx) == 'number' and sx or 1,
      sy = type(sy) == 'number' and sy or 1,
      x = x,
      y = y,
    }
  end,
} }

local fontCalls = {}
local Font = {
  draw = function(text, x, y) fontCalls[#fontCalls+1] = tostring(text) end,
  drawBox = function() end,
  width = function(text) return #tostring(text) * 8 end,
}
local Strings = setmetatable({ source = function(s) return s end }, {
  __call = function(_, fmt, ...)
    if select('#', ...) == 0 then return tostring(fmt) end
    return string.format(tostring(fmt), ...)
  end,
})

local Stats = {}
function Stats.calc(def, level, dvs, statExp)
  local b = def.baseStats or {}
  local dv = dvs or {}
  local ex = statExp or {}
  local function calc(base, key)
    local ev = math.floor(math.min(255, math.ceil(math.sqrt(ex[key] or 0))) / 4)
    return math.floor(((base + (dv[key] or 0)) * 2 + ev) * level / 100) + 5
  end
  return {
    hp = 100,
    attack = calc(b.attack or 50, 'attack'),
    defense = calc(b.defense or 50, 'defense'),
    speed = calc(b.speed or 50, 'speed'),
    special = calc(b.special or 50, 'special'),
  }
end
function Stats.ensure(def, mon)
  mon.stats = mon.stats or Stats.calc(def, mon.level or 1, mon.dvs or {}, mon.statExp or {})
  return mon
end

local damageSeen = {}
local Damage = {}
function Damage.compute(ruleset, attacker, defender, move, opts)
  local category = move.category or ((move.type == 'FIRE' or move.type == 'WATER' or move.type == 'PSYCHIC') and 'special' or 'physical')
  local special = category == 'special'
  local atkKey, defKey = special and 'special' or 'attack', special and 'special' or 'defense'
  damageSeen[#damageSeen+1] = {
    a = attacker.curStats[atkKey],
    d = defender.curStats[defKey],
    as = attacker.stages and attacker.stages[atkKey],
    ds = defender.stages and defender.stages[defKey],
    category = category,
    physical = category == 'physical',
  }
  if opts and opts.throw then error('forced damage failure') end
  return attacker.curStats[atkKey] - defender.curStats[defKey] + 1000,
         attacker.stages[atkKey] or 0,
         defender.stages[defKey] or 0
end
Damage.BADGE_BOOSTS = { VOLCANO = 'special' }

local Experience = {}
local expSeen
function Experience.apply(data, mon, defeatedDef, ...)
  expSeen = defeatedDef.baseStats.special
  return true, {'EXP OK'}
end

local ItemEffects = {}
function ItemEffects.use(data, saveData, itemId, target, battle)
  if itemId == 'X_SPECIAL' then
    local s = battle.player.stages
    s.special = math.min(6, (s.special or 0) + 1)
    return true, {"PLAYER's\nSPECIAL rose!"}
  end
  return true, {'ITEM OK'}
end

local function statEffect(delta, side, chance)
  return function(ctx)
    local who = side == 'target' and ctx.target or ctx.user
    if chance and ctx.battle.rng(0,255) >= chance then return {} end
    who.stages.special = math.max(-6, math.min(6, (who.stages.special or 0) + delta))
    return {"MON's\nSPECIAL " .. (delta > 0 and 'rose!' or 'fell!')}
  end
end
local MoveEffects = { RECORDS = {} }
MoveEffects.RECORDS.SPECIAL_UP1_EFFECT = { run = statEffect(1, 'user') }
MoveEffects.RECORDS.SPECIAL_UP2_EFFECT = { run = statEffect(2, 'user') }
MoveEffects.RECORDS.SPECIAL_DOWN_SIDE_EFFECT = { run = statEffect(-1, 'target', 85) }
MoveEffects.RECORDS.TRANSFORM_EFFECT = { run = function(ctx)
  ctx.user.curStats = {
    hp = ctx.user.mon.stats.hp,
    attack = ctx.target.curStats.attack,
    defense = ctx.target.curStats.defense,
    speed = ctx.target.curStats.speed,
    special = ctx.target.curStats.special,
  }
  ctx.user.stages = deepcopy(ctx.target.stages)
  return {'TRANSFORMED'}
end }

local SummaryMenu = { draw = function() end }
SummaryMenu.__index = SummaryMenu
local PartyMenu = {}
PartyMenu.__index = PartyMenu
local BattleState = { StatBox = { draw = function() end } }
BattleState.StatBox.__index = BattleState.StatBox
local SaveData = {}
local saveSeen
function SaveData.save(data, mods)
  saveSeen = {
    trackedSpa = data.party[1].stats.specialAttack,
    trackedSpd = data.party[1].stats.specialDefense,
    unrelatedSpa = data.unrelated.specialAttack,
    unrelatedSpd = data.unrelated.specialDefense,
  }
  if data.forceSaveError then error('forced save failure') end
  return true, 'saved'
end

local TypeChart = { category = function(typeId)
  local physical = { NORMAL=true, FIGHTING=true, FLYING=true, POISON=true, GROUND=true, ROCK=true, BUG=true, GHOST=true }
  local special = { FIRE=true, WATER=true, GRASS=true, ELECTRIC=true, PSYCHIC=true, ICE=true, DRAGON=true }
  if physical[typeId] then return 'physical' end
  if special[typeId] then return 'special' end
  return 'physical'
end }

local stubs = {
  ['src.pokemon.Stats'] = Stats,
  ['src.battle.Damage'] = Damage,
  ['src.battle.Experience'] = Experience,
  ['src.inventory.ItemEffects'] = ItemEffects,
  ['src.battle.MoveEffects'] = MoveEffects,
  ['src.ui.SummaryMenu'] = SummaryMenu,
  ['src.ui.PartyMenu'] = PartyMenu,
  ['src.battle.BattleState'] = BattleState,
  ['src.render.Font'] = Font,
  ['src.core.Strings'] = Strings,
  ['src.core.SaveData'] = SaveData,
  ['src.battle.TypeChart'] = TypeChart,
}
for name, value in pairs(stubs) do
  package.preload[name] = function() return value end
end

local patchedEffects = {}
local patchedScreens = {}
local originalPokedexStats = {
  new = function(game, opts)
    local species = (opts and (opts.species or opts[1])) or 'ALAKAZAM'
    return {
      game = game, species = species, name = species,
      stats = { hp=55, attack=50, defense=45, speed=120, special=135, total=405 },
      draw = function(self)
        Font.draw('BASE STATS', 8, 16)
        Font.draw('SPECIAL', 16, 100)
      end,
    }
  end,
}
local moveRecords = {
  FIRE_PUNCH   = { id='FIRE_PUNCH',   index=7,   type='FIRE',   power=75, category='special' },
  SWORDS_DANCE = { id='SWORDS_DANCE', index=14,  type='NORMAL', power=0 },
  FLAMETHROWER = { id='FLAMETHROWER', index=53,  type='FIRE',   power=95 },
  HYPER_BEAM   = { id='HYPER_BEAM',   index=63,  type='NORMAL', power=150 },
  WATERFALL    = { id='WATERFALL',    index=127, type='WATER',  power=80 },
  HI_JUMP_KICK = { id='HI_JUMP_KICK', index=136, type='FIGHTING', power=85 },
  FAKE_MOVE    = { id='FAKE_MOVE',    index=7,   type='FIRE',   power=75, category='special' },
}
local DELETE = {}
local patchedMoves = {}
local movesRegistry = {}
function movesRegistry:each()
  local ids = {'FIRE_PUNCH','SWORDS_DANCE','FLAMETHROWER','HYPER_BEAM','WATERFALL','HI_JUMP_KICK','FAKE_MOVE'}
  local i = 0
  return function()
    i = i + 1
    local id = ids[i]
    if not id then return nil end
    return id, moveRecords[id]
  end
end
function movesRegistry:patch(id, partial)
  patchedMoves[id] = deepcopy(partial)
  for k,v in pairs(partial) do
    if v == DELETE then moveRecords[id][k] = nil else moveRecords[id][k] = v end
  end
end

local optionMode = MODE == 'vanilla' and 'vanilla' or 'gen2'
local optionMoveMode = MOVE_MODE == 'gen1' and 'gen1' or 'gen4'
local optionBattleWipOverride = BATTLE_WIP_OVERRIDE == 'on'
local optionModernOverride = MODERN_OVERRIDE ~= 'off'
local optionModernPartyLayout = MODERN_PARTY_LAYOUT == 'one_row' and 'one_row' or 'two_rows'
local optionReadout = READOUT_MODE ~= 'off'
local registeredModernUiAdapter
local specialExports = {}
local specialHandle = {
  id = 'special_stat_split', version = '2.6.3', exports = specialExports,
}
local realModernUiMod
local modernUiStub
local realModernPath = os.getenv('MODERN_UI_MAIN')
local noModernUi = os.getenv('NO_MODERN_UI') == '1'
local testModernVersion = os.getenv('MODERN_UI_VERSION') or '0.8.4'
local testModernApi = tonumber(os.getenv('MODERN_UI_API') or '1') or 1
local unsupportedModernApi = (not noModernUi) and not realModernPath and testModernApi ~= 1
if noModernUi then
  modernUiStub = nil
elseif realModernPath and realModernPath ~= '' then
  local modernOptionValues = { battleUiWip = true, hideOriginalUi = true }
  local modernOptions = { _testValues = modernOptionValues }
  function modernOptions:define(schema) self.schema = schema end
  function modernOptions:get(key)
    if modernOptionValues[key] ~= nil then return modernOptionValues[key] end
    for _, row in ipairs(self.schema or {}) do
      if row.key == key then return row.default end
    end
  end
  local modernHookWrappers = {}
  local modernHooks = {}
  function modernHooks:wrap(name, fn, priority)
    modernHookWrappers[name] = { fn=fn, priority=priority }
    return function() modernHookWrappers[name] = nil end
  end
  local modernEvents = {}
  function modernEvents:on(_, fn) return fn end
  realModernUiMod = {
    id = 'gen1_modern_ui', version = testModernVersion, options = modernOptions,
    hooks = modernHooks, events = modernEvents,
    input = { tap = function() return true end },
    assets = { image = function(_, path) return { path = path } end },
    exports = {},
    _testHookWrappers = modernHookWrappers,
  }
  realModernUiMod.find = function(id)
    if id == 'special_stat_split' then return specialHandle end
  end
  local modernInstaller = assert(loadfile(realModernPath))()
  modernInstaller(realModernUiMod)
  modernUiStub = {
    id = 'gen1_modern_ui', version = testModernVersion, exports = realModernUiMod.exports,
  }
else
  modernUiStub = {
    id = 'gen1_modern_ui', version = testModernVersion,
    exports = {
      version = testModernApi, compatibilityApiVersion = testModernApi,
      registerAdapter = function(spec)
        registeredModernUiAdapter = spec
        return true
      end,
    },
  }
end
local tappedButtons = {}
local specialOptionSchema
local specialEventListeners = {}
local registeredLinkFields = {}
local linkFieldsRegistry = {}
function linkFieldsRegistry:register(id, record)
  registeredLinkFields[id] = deepcopy(record)
end
local specialHookWrappers = {}
local specialHookWrapperLists = {}
local specialHooks = {}
function specialHooks:wrap(name, fn, priority)
  local row = { fn = fn, priority = priority }
  specialHookWrappers[name] = row
  specialHookWrapperLists[name] = specialHookWrapperLists[name] or {}
  table.insert(specialHookWrapperLists[name], row)
  return function()
    if specialHookWrappers[name] == row then specialHookWrappers[name] = nil end
    local list = specialHookWrapperLists[name] or {}
    for i = #list, 1, -1 do
      if list[i] == row then table.remove(list, i) break end
    end
  end
end
local mod = {
  id = 'special_stat_split',
  version = '2.6.3',
  hooks = specialHooks,
  options = {
    define = function(_, schema) specialOptionSchema = schema end,
    get = function(_, key)
      if key == 'mode' then return optionMode end
      if key == 'move_split' then return optionMoveMode end
      if key == 'modern_ui_override' then return optionModernOverride end
      if key == 'modern_ui_party_stats_layout' then return optionModernPartyLayout end
      if key == 'modern_ui_battle_wip_override' then return optionBattleWipOverride end
      if key == 'move_category_readout' then return optionReadout end
    end,
  },
  events = {
    on = function(_, name, fn)
      specialEventListeners[name] = specialEventListeners[name] or {}
      table.insert(specialEventListeners[name], fn)
      return fn
    end,
  },
  content = {
    link_fields = linkFieldsRegistry,
    moves = movesRegistry,
    move_effects = {
      patch = function(_, id, record) patchedEffects[id] = record end,
    },
    screens = {
      get = function(_, id)
        if id == 'PokedexPlusStats' then return originalPokedexStats end
      end,
      patch = function(_, id, record) patchedScreens[id] = record end,
    },
  },
  find = function(id)
    if id == 'pokedex_plus' then return { id=id, version='1.3.0', exports={} } end
    if id == 'gen1_modern_ui' then return modernUiStub end
    if id == 'move_category' and (os.getenv('STANDALONE_MOVE_CATEGORY') == '1'
        or (REAL_MOVE_CATEGORY_MAIN and REAL_MOVE_CATEGORY_MAIN ~= '')) then
      return { id=id, version='1.0.1', exports=standaloneExports }
    end
  end,
  log = { info=function() end, warn=function() end, error=function() end },
  DELETE = DELETE,
  input = { tap = function(_, game, button) tappedButtons[#tappedButtons+1] = button; return true end },
  exports = specialExports,
}

local standaloneMoveCategory = os.getenv('STANDALONE_MOVE_CATEGORY') == '1'
  or (REAL_MOVE_CATEGORY_MAIN and REAL_MOVE_CATEGORY_MAIN ~= '')
local standaloneCurrentBattle
local standaloneEventListeners = {}
local standaloneExports = {}
if REAL_MOVE_CATEGORY_MAIN and REAL_MOVE_CATEGORY_MAIN ~= '' then
  local standaloneEnabled = os.getenv('STANDALONE_MOVE_CATEGORY_ENABLED') ~= '0'
  local standaloneMod = {
    id = 'move_category', version = '1.0.1', ui = { Font = Font }, exports = standaloneExports,
    options = {
      define = function() end,
      get = function(_, key) if key == 'enabled' then return standaloneEnabled end end,
    },
    events = {
      on = function(_, name, fn)
        standaloneEventListeners[name] = standaloneEventListeners[name] or {}
        table.insert(standaloneEventListeners[name], fn)
        return fn
      end,
    },
    log = { info=function() end, warn=function() end, error=function() end },
  }
  local standaloneInit = assert(loadfile(REAL_MOVE_CATEGORY_MAIN))()
  standaloneInit(standaloneMod)
elseif standaloneMoveCategory then
  -- Lightweight fallback composition stub when the exact standalone source is
  -- not supplied by the caller.
  local downstream = Font.draw
  Font.draw = function(text, x, y, ...)
    if text == 'TYPE/' and standaloneCurrentBattle
        and standaloneCurrentBattle.phase == 'moveSelect' then
      local moves = standaloneCurrentBattle.player and standaloneCurrentBattle.player.curMoves
      local selected = moves and moves[standaloneCurrentBattle.moveIndex]
      local def = selected and standaloneCurrentBattle.data
        and standaloneCurrentBattle.data.moves and standaloneCurrentBattle.data.moves[selected.id]
      if def and (def.power or 0) > 0 and def.category ~= 'status' then
        local category = def.category or TypeChart.category(def.type)
        text = category == 'special' and 'SPEC/' or 'PHYS/'
      end
    end
    return downstream(text, x, y, ...)
  end
end

local init = assert(loadfile('main.lua'))()
init(mod)

local function emitSpecial(name, payload)
  if standaloneMoveCategory then
    if name == 'battle.started' then standaloneCurrentBattle = payload and payload.battle or nil end
    if name == 'battle.ended' then standaloneCurrentBattle = nil end
    for _, fn in ipairs(standaloneEventListeners[name] or {}) do fn(payload) end
  end
  for _, fn in ipairs(specialEventListeners[name] or {}) do fn(payload) end
end

local modernOverrideRow, modernPartyLayoutRow, battleWipOverrideRow
for _, row in ipairs(specialOptionSchema or {}) do
  if row.key == 'modern_ui_override' then modernOverrideRow = row end
  if row.key == 'modern_ui_party_stats_layout' then modernPartyLayoutRow = row end
  if row.key == 'modern_ui_battle_wip_override' then battleWipOverrideRow = row end
end
expect(modernOverrideRow ~= nil, 'ModernUI Override option is defined')
expect(modernOverrideRow.label == 'ModernUI Override', 'ModernUI Override label is exact')
expect(modernOverrideRow.type == 'toggle' and modernOverrideRow.default == true,
  'ModernUI Override defaults ON')
expect(modernPartyLayoutRow ~= nil, 'ModernUI Party Stats Layout option is defined')
expect(modernPartyLayoutRow.label == 'ModernUI Party Stats Layout',
  'ModernUI Party Stats Layout label is exact')
expect(modernPartyLayoutRow.type == 'choice' and modernPartyLayoutRow.default == 'two_rows',
  'ModernUI Party Stats Layout defaults to 2 ROWS')
expect(battleWipOverrideRow ~= nil, 'ModernUI BattleWIP Override option is defined')
expect(battleWipOverrideRow.label == 'ModernUI BattleWIP Override',
  'ModernUI BattleWIP Override label is exact')
expect(battleWipOverrideRow.type == 'toggle' and battleWipOverrideRow.default == false,
  'ModernUI BattleWIP Override defaults OFF')
expect(mod.exports.modernUiOverrideEnabled() == optionModernOverride,
  'ModernUI Override export reflects option state')
expect(mod.exports.modernUiPartyStatsLayout() == optionModernPartyLayout,
  'ModernUI Party Stats Layout export reflects option state')
expect(mod.exports.modernUiBattleWipOverrideEnabled() == optionBattleWipOverride,
  'ModernUI BattleWIP Override export reflects option state')
expect(mod.exports.modernUiLevelUpOverrideEnabled() == optionBattleWipOverride,
  'legacy Level Up Override export aliases BattleWIP state')

local readoutRow
for _, row in ipairs(specialOptionSchema or {}) do
  if row.key == 'move_category_readout' then readoutRow = row break end
end
expect(readoutRow ~= nil, 'integrated Move Category Readout option is defined')
expect(readoutRow.label == 'MOVE CATEGORY READOUT', 'Move Category Readout label is exact')
expect(readoutRow.type == 'toggle' and readoutRow.default == true,
  'Move Category Readout defaults ON')
expect(type(mod.exports.moveCategoryReadoutEnabled) == 'function'
  and mod.exports.moveCategoryReadoutEnabled() == optionReadout,
  'Move Category Readout export reflects option state')

local expectedLinkRevision = ('special=%s;move=%s'):format(optionMode, optionMoveMode)
expect(type(registeredLinkFields.special_stat_split_rules) == 'table',
  'gameplay configuration registers a public link_fields record')
expect(registeredLinkFields.special_stat_split_rules.rev == expectedLinkRevision,
  'link_fields revision encodes only the two gameplay modes')
expect(type(mod.exports.getLinkConfigRevision) == 'function'
  and mod.exports.getLinkConfigRevision() == expectedLinkRevision,
  'root link-config export reflects registered gameplay revision')
expect(type(mod.exports.getGameplayConfig) == 'function',
  'root gameplay-config export exists')
local gameplayConfig = mod.exports.getGameplayConfig()
expect(gameplayConfig.specialStats == optionMode and gameplayConfig.moveCategories == optionMoveMode,
  'gameplay-config export reports the active gameplay modes')
gameplayConfig.specialStats = 'mutated'
expect(mod.exports.getGameplayConfig().specialStats == optionMode,
  'gameplay-config export returns a defensive copy')
expect(type(mod.exports.specialStatSplit) == 'table',
  'versioned inter-mod API table exists')
expect(mod.exports.specialStatSplit.apiVersion == 1,
  'versioned inter-mod API reports apiVersion 1')
expect(mod.exports.specialStatSplit.modVersion == '2.6.3',
  'versioned inter-mod API reports release version')
expect(mod.exports.specialStatSplit.specialSplitActive == mod.exports.specialSplitActive
  and mod.exports.specialStatSplit.moveCategorySplitActive == mod.exports.moveCategorySplitActive
  and mod.exports.specialStatSplit.getMoveCategory == mod.exports.getMoveCategory
  and mod.exports.specialStatSplit.getSpecialBaseStats == mod.exports.getSpecialBaseStats
  and mod.exports.specialStatSplit.attachSplitStats == mod.exports.attachSplitStats,
  'versioned API aliases the legacy implementation functions')
expect(type(mod.exports.getDiagnostics) == 'function',
  'diagnostics export exists')
local diagnostics = mod.exports.getDiagnostics()
expect(diagnostics.apiVersion == 1 and diagnostics.modVersion == '2.6.3',
  'diagnostics identify API/build version')
expect(diagnostics.link.configRegistered == true
  and diagnostics.link.configRevision == expectedLinkRevision,
  'diagnostics expose registered link-config revision')
expect(diagnostics.integrations.modernUi.detected == (not noModernUi),
  'diagnostics report Modern UI presence')
expect(diagnostics.integrations.standaloneMoveCategory.detected == (standaloneMoveCategory == true),
  'diagnostics report standalone Move Category presence')

local function lastFontText()
  return fontCalls[#fontCalls]
end
local function resetFontCalls() fontCalls = {} end
local readoutBattle = {
  phase='moveSelect', moveIndex=1,
  player={curMoves={{id='FIRE_PUNCH'}}},
  data={moves=moveRecords},
}
emitSpecial('battle.started', {battle=readoutBattle})
resetFontCalls(); Font.draw('TYPE/', 8, 72)
local expectedFireLabel
if optionReadout or standaloneMoveCategory then
  expectedFireLabel = optionMoveMode == 'gen4' and 'PHYS/' or 'SPEC/'
else
  expectedFireLabel = 'TYPE/'
end
expect(lastFontText() == expectedFireLabel,
  'integrated readout follows the active move-category mechanic and composes with standalone mod')
expect(#fontCalls == 1, 'integrated/standalone composition draws the label exactly once')
readoutBattle.player.curMoves[1] = {id='SWORDS_DANCE'}
resetFontCalls(); Font.draw('TYPE/', 8, 72)
expect(lastFontText() == 'TYPE/',
  'integrated and standalone readouts leave status/power-0 moves at TYPE/')
emitSpecial('battle.ended', {})
resetFontCalls(); Font.draw('TYPE/', 8, 72)
expect(lastFontText() == 'TYPE/',
  'integrated and standalone readouts are inactive outside battle')

-- GEN 1 Gen 3 UI compatibility: observe the wide TYPE ... PP footer from
-- render.hud and add the full PHYSICAL/SPECIAL/STATUS label using the same
-- outer-hook strategy as the live-confirmed Gold path. The native Font.draw
-- readout above remains a separate path and must keep working unchanged.
local gen1Gen3Hud
for _, row in ipairs(specialHookWrapperLists['render.hud'] or {}) do
  if row.priority == math.huge then gen1Gen3Hud = row break end
end
expect(type(mod.exports.gen3UiMoveCategoryGen1Installed) == 'function'
  and mod.exports.gen3UiMoveCategoryGen1Installed() == true,
  'GEN 1 Gen 3 UI move-panel observer install export is active')
expect(gen1Gen3Hud and type(gen1Gen3Hud.fn) == 'function',
  'GEN 1 Gen 3 UI move-panel observer is registered at render.hud')

local gen3Battle = {
  phase='moveSelect', moveIndex=1,
  player={curMoves={{id='FIRE_PUNCH'}}},
  data={moves=moveRecords},
}
emitSpecial('battle.started', {battle=gen3Battle})
hudPrintCalls = {}
hudPrintRecords = {}
gen1Gen3Hud.fn(function()
  love.graphics.print('FIRE PUNCH', 410, 650)
  love.graphics.print('TYPE', 450, 700)
  love.graphics.print('FIRE', 510, 700)
  love.graphics.print('PP 15 / 15', 900, 700)
end, {data={moves=moveRecords}}, {})
local expectedFull = optionMoveMode == 'gen4' and 'PHYSICAL' or 'SPECIAL'
local fullCount = 0
for _, value in ipairs(hudPrintCalls) do if value == expectedFull then fullCount = fullCount + 1 end end
if optionReadout then
  expect(fullCount == 2,
    'GEN 1 Gen 3 UI footer draws the full category with softened semibold overdraw')
else
  expect(fullCount == 0,
    'GEN 1 Gen 3 UI footer respects MOVE CATEGORY READOUT OFF')
end

-- Status label through the live Gen 1 battle model.
gen3Battle.player.curMoves[1] = {id='SWORDS_DANCE'}
hudPrintCalls = {}
gen1Gen3Hud.fn(function()
  love.graphics.print('SWORDS DANCE', 410, 650)
  love.graphics.print('TYPE', 450, 700)
  love.graphics.print('NORMAL', 510, 700)
  love.graphics.print('PP 20 / 20', 900, 700)
end, {data={moves=moveRecords}}, {})
local statusCount = 0
for _, value in ipairs(hudPrintCalls) do if value == 'STATUS' then statusCount = statusCount + 1 end end
expect((optionReadout and statusCount == 2) or ((not optionReadout) and statusCount == 0),
  'GEN 1 Gen 3 UI footer resolves STATUS and respects the readout toggle')

-- If a replacement screen hides the Gen 1 move cursor, infer the selected move
-- from the visible leftmost move name rendered by Gen 3 UI.
emitSpecial('battle.ended', {})
hudPrintCalls = {}
gen1Gen3Hud.fn(function()
  love.graphics.print('FIRE PUNCH', 410, 650)
  love.graphics.print('TYPE', 450, 700)
  love.graphics.print('FIRE', 510, 700)
  love.graphics.print('PP 15 / 15', 900, 700)
end, {data={moves=moveRecords}}, {})
local fallbackCount = 0
for _, value in ipairs(hudPrintCalls) do if value == expectedFull then fallbackCount = fallbackCount + 1 end end
expect((optionReadout and fallbackCount == 2) or ((not optionReadout) and fallbackCount == 0),
  'GEN 1 Gen 3 UI visible move-name fallback resolves the category')

expect(type(mod.exports.modernUiSurgicalInstalled) == 'function',
  'Modern UI surgical-install status export exists')
if noModernUi then
  expect(mod.exports.modernUiSurgicalInstalled() == false,
    'Modern UI absence leaves surgical override inactive')
  expect(registeredModernUiAdapter == nil,
    'ordinary Modern UI compatibility does not register a generic replacement adapter')
elseif unsupportedModernApi then
  expect(mod.exports.modernUiSurgicalInstalled() == false,
    'unsupported Modern UI API leaves surgical override inactive')
  expect(registeredModernUiAdapter == nil,
    'unsupported Modern UI API registers no generic replacement adapter')
  local unsupportedHud = specialHookWrappers['render.hud']
  expect(specialHookWrappers['ui.state.decorate'] == nil
    and (unsupportedHud == nil or unsupportedHud.priority ~= 200),
    'unsupported future Modern UI API installs no BattleWIP level-up override hooks')
elseif realModernUiMod then
  expect(mod.exports.modernUiSurgicalInstalled() == true,
    'real Modern UI renderer with compatible capabilities receives the surgical stat-row override regardless of release number')
  local registered = realModernUiMod._gen1ModernCompatibility
    and realModernUiMod._gen1ModernCompatibility.adapters
    and realModernUiMod._gen1ModernCompatibility.adapters.special_stat_split
  expect(registered == nil,
    'ordinary Party/Summary compatibility does not replace Modern UI with a generic external presenter')
else
  expect(mod.exports.modernUiSurgicalInstalled() == false,
    'Modern UI stub without the required renderer capability leaves the surgical override inactive')
  expect(registeredModernUiAdapter == nil,
    'renderer-less Modern UI stub does not receive a generic replacement adapter')
end

-- Generation IV move categories are explicit per move, independent of type.
if optionMoveMode == 'gen4' then
  expect(patchedMoves.FIRE_PUNCH and patchedMoves.FIRE_PUNCH.category == 'physical',
         'Fire Punch becomes physical despite FIRE type')
  expect(patchedMoves.FLAMETHROWER and patchedMoves.FLAMETHROWER.category == 'special',
         'Flamethrower remains special')
  expect(patchedMoves.HYPER_BEAM and patchedMoves.HYPER_BEAM.category == 'special',
         'Hyper Beam becomes special despite NORMAL type')
  expect(patchedMoves.WATERFALL and patchedMoves.WATERFALL.category == 'physical',
         'Waterfall becomes physical despite WATER type')
  expect(patchedMoves.SWORDS_DANCE and patchedMoves.SWORDS_DANCE.category == 'status',
         'status category is explicit')
  expect(patchedMoves.HI_JUMP_KICK and patchedMoves.HI_JUMP_KICK.category == 'physical',
         'exact Gen1Recomp HI_JUMP_KICK registry id is recognized')
  expect(mod.exports.moveCategorySplitActive() == true, 'move split export active')
  expect(mod.exports.getMoveCategory(7) == 'physical' and mod.exports.getMoveCategory(53) == 'special',
         'move category export uses Gen IV table')
  expect(patchedMoves.FAKE_MOVE == nil and moveRecords.FAKE_MOVE.category == 'special',
         'GEN IV+ index collision guard leaves noncanonical custom move untouched')
else
  expect(patchedMoves.FIRE_PUNCH ~= nil, 'GEN I mode must actively clear explicit categories')
  expect(moveRecords.FIRE_PUNCH.category == nil, 'GEN I mode forces Fire Punch back to type fallback')
  expect(moveRecords.FLAMETHROWER.category == nil and moveRecords.HYPER_BEAM.category == nil,
         'GEN I mode clears category on canonical moves')
  expect(moveRecords.HI_JUMP_KICK.category == nil,
         'GEN I mode recognizes exact legacy HI_JUMP_KICK id')
  expect(patchedMoves.FAKE_MOVE == nil and moveRecords.FAKE_MOVE.category == 'special',
         'index collision guard leaves noncanonical custom move untouched')
  expect(mod.exports.moveCategorySplitActive() == false, 'move split export inactive')
  expect(mod.exports.getMoveCategory(7) == nil, 'GEN I move category export falls back')
end

local alakazam = {
  id = 'ALAKAZAM', dex = 65,
  baseStats = { attack=50, defense=45, speed=120, special=135 },
}
local chansey = {
  id = 'CHANSEY', dex = 113,
  baseStats = { attack=5, defense=5, speed=50, special=105 },
}
local dvs = { attack=7, defense=7, speed=7, special=10 }
local statExp = { attack=1000, defense=1000, speed=1000, special=10000 }

if optionMode == 'vanilla' then
  expect(mod.exports.getSpecialBaseStats('ALAKAZAM') == nil,
         'VANILLA inter-mod base-stat export must be inactive')
  local stats = Stats.calc(alakazam, 50, dvs, statExp)
  expect(stats.specialAttack == nil and stats.specialDefense == nil,
         'VANILLA Stats.calc must not add split fields')
  local a = { curStats={special=111}, stages={special=2} }
  local d = { curStats={special=77}, stages={special=-1} }
  Damage.compute({}, a, d, {category='special'})
  local last = damageSeen[#damageSeen]
  expect(last.a == 111 and last.d == 77 and last.as == 2 and last.ds == -1,
         'VANILLA damage must delegate untouched')
  local save = { party={{stats={special=99}}}, unrelated={specialAttack=12,specialDefense=13} }
  SaveData.save(save, {})
  expect(saveSeen.unrelatedSpa == 12 and saveSeen.unrelatedSpd == 13,
         'VANILLA save delegate')
  expect(patchedScreens.PokedexPlusStats ~= nil,
         'Pokédex Plus screen wrapper should be registered when dependency is present')
  local vanillaDex = patchedScreens.PokedexPlusStats.new(
    {data={pokemon={ALAKAZAM=alakazam}}}, {species='ALAKAZAM'})
  expect(vanillaDex.stats.specialAttack == nil and vanillaDex.stats.specialDefense == nil,
         'VANILLA Pokédex Plus screen remains untouched')
  print('special_stat_split runtime stub (VANILLA / ' .. string.upper(optionMoveMode) .. '): PASS')
  os.exit(0)
end

-- 1) Real Lua stat attachment with shared Special DV/Stat Exp.
local exported = mod.exports.getSpecialBaseStats('ALAKAZAM')
expect(exported and exported.specialAttack == 135 and exported.specialDefense == 85,
       'GEN II inter-mod base-stat export')
local astats = Stats.calc(alakazam, 50, dvs, statExp)
local cstats = Stats.calc(chansey, 50, dvs, statExp)
expect(astats.specialAttack ~= nil and astats.specialDefense ~= nil, 'split fields attached')
expect(astats.specialAttack > astats.specialDefense, 'Alakazam SpA > SpD')
expect(cstats.specialDefense > cstats.specialAttack, 'Chansey SpD > SpA')

-- 2) Special damage gets SpA/SpD + separate stages; legacy fields restore.
local attacker = {
  mon={level=50,dvs=dvs,statExp=statExp}, def=alakazam,
  curStats=astats, stages={special=4,specialAttack=2,attack=1},
}
local defender = {
  mon={level=50,dvs=dvs,statExp=statExp}, def=chansey,
  curStats=cstats, stages={special=-4,specialDefense=-1,defense=-2},
}
local oldASpecial, oldDSpecial = astats.special, cstats.special
local out, as, ds = Damage.compute({}, attacker, defender, {category='special'})
local last = damageSeen[#damageSeen]
expect(last.a == astats.specialAttack and last.d == cstats.specialDefense,
       'special damage uses attacker SpA / defender SpD')
expect(last.as == 2 and last.ds == -1, 'special damage uses separate stages')
expect(astats.special == oldASpecial and cstats.special == oldDSpecial,
       'legacy calculated special restored')
expect(attacker.stages.special == 4 and defender.stages.special == -4,
       'legacy special stages restored')

-- Error path must restore too.
local ok = pcall(Damage.compute, {}, attacker, defender, {category='special'}, {throw=true})
expect(not ok, 'forced damage error propagated')
expect(astats.special == oldASpecial and cstats.special == oldDSpecial,
       'damage error path restores calculated special')
expect(attacker.stages.special == 4 and defender.stages.special == -4,
       'damage error path restores special stages')

-- 3) Physical path does not substitute split stats.
Damage.compute({}, attacker, defender, {category='physical'})
last = damageSeen[#damageSeen]
expect(last.a == astats.attack and last.d == cstats.defense and last.physical,
       'physical damage delegates through Attack / Defense')

-- 4) GEN IV category data controls the actual stat operands, not just UI text.
if optionMoveMode == 'gen4' then
  Damage.compute({}, attacker, defender, moveRecords.FIRE_PUNCH)
  last = damageSeen[#damageSeen]
  expect(last.category == 'physical' and last.a == astats.attack and last.d == cstats.defense,
         'Fire Punch uses Attack / Defense under GEN IV split')
  Damage.compute({}, attacker, defender, moveRecords.HYPER_BEAM)
  last = damageSeen[#damageSeen]
  expect(last.category == 'special' and last.a == astats.specialAttack and last.d == cstats.specialDefense,
         'Hyper Beam uses Sp. Atk / Sp. Def under GEN IV split')
end

-- 5) Experience shared Special bucket is awarded from defeated base SpA.
Experience.apply({}, {}, chansey, 50, false, 1, false)
expect(expSeen == 35, 'Gen II shared Special Stat Exp gain uses defeated base SpA')
expect(chansey.baseStats.special == 105, 'Experience wrapper restores species legacy special')

-- 5) X Special -> Sp. Atk only; legacy stage preserved; message relabelled.
local battle = { player={stages={special=3,specialAttack=1}} }
local okItem, msgs = ItemEffects.use({}, {}, 'X_SPECIAL', nil, battle)
expect(okItem == true, 'X Special original result preserved')
expect(battle.player.stages.specialAttack == 2, 'X Special increments SpA stage')
expect(battle.player.stages.special == 3, 'X Special legacy stage restored')
expect(msgs[1]:find('SP%. ATK') ~= nil, 'X Special message says SP. ATK')

-- 6) Move-effect routing.
local user = { stages={special=5,specialAttack=0,specialDefense=0} }
local target = { stages={special=-5,specialDefense=0} }
local ctx = { user=user, target=target, battle={rng=function() return 0 end} }
local growthMsg = patchedEffects.SPECIAL_UP1_EFFECT.run(ctx)
expect(user.stages.specialAttack == 1 and user.stages.special == 5,
       'Growth routes to SpA')
expect(growthMsg[1]:find('SP%. ATK') ~= nil, 'Growth message relabelled')
local amnesiaMsg = patchedEffects.SPECIAL_UP2_EFFECT.run(ctx)
expect(user.stages.specialDefense == 2 and user.stages.special == 5,
       'Amnesia routes to SpD')
expect(amnesiaMsg[1]:find('SP%. DEF') ~= nil, 'Amnesia message relabelled')
local psychicMsg = patchedEffects.SPECIAL_DOWN_SIDE_EFFECT.run(ctx)
expect(target.stages.specialDefense == -1 and target.stages.special == -5,
       'Psychic side drop routes to SpD')
expect(psychicMsg[1]:find('SP%. DEF') ~= nil, 'Psychic drop message relabelled')

-- 7) Transform copies both current split stats and split stages via existing stage copy.
local tUser = { mon={stats={hp=123}}, curStats={special=1}, stages={} }
local tTarget = {
  curStats={attack=1,defense=2,speed=3,special=4,specialAttack=155,specialDefense=88},
  stages={specialAttack=2,specialDefense=-2}, curTypes={'PSYCHIC'}, curMoves={},
  mon={species='ALAKAZAM'}, name='TARGET',
}
local tctx = {user=tUser,target=tTarget,battle={speciesSprite=function() return nil end}}
patchedEffects.TRANSFORM_EFFECT.run(tctx)
expect(tUser.curStats.specialAttack == 155 and tUser.curStats.specialDefense == 88,
       'Transform copies split current stats')
expect(tUser.stages.specialAttack == 2 and tUser.stages.specialDefense == -2,
       'Transform keeps copied split stages')

-- Transform -> damage regression.  A transformed curStats table already owns
-- copied SpA/SpD and must not be overwritten from the user's original species.
tUser.mon.level = 50; tUser.mon.dvs = dvs; tUser.mon.statExp = statExp
tUser.def = {id='ALAKAZAM',dex=65,baseStats={hp=55,attack=50,defense=45,speed=120,special=135}}
tUser.curTypes = {'PSYCHIC'}; tUser.badges = {}
tTarget.mon.level = 50; tTarget.mon.dvs = dvs; tTarget.mon.statExp = statExp
tTarget.def = {id='CHANSEY',dex=113,baseStats={hp=250,attack=5,defense=5,speed=50,special=105}}
tTarget.badges = {}
local copiedSpa = tUser.curStats.specialAttack
Damage.compute({}, tUser, tTarget, {id='PSYCHIC',type='PSYCHIC',category='special',power=90}, {})
expect(tUser.curStats.specialAttack == copiedSpa, 'Transform copied SpA survives subsequent Damage.compute')

-- 8) Gen1 Modern UI exact-layout compatibility.
-- Ordinary Party/Summary must remain Modern UI-owned; the capability-checked
-- override changes only its legacy stat text block after the upstream renderer.
local mon = {species='ALAKAZAM',nickname='SPOON',level=50,hp=100,dvs=dvs,statExp=statExp,stats=astats,ot='RED',otId=12345,
  moves={{id='PSYCHIC',pp=10}}}
local uiGame = {
  data = {
    pokemon = { ALAKAZAM = { id='ALAKAZAM', dex=65, name='ALAKAZAM', types={'PSYCHIC'}, baseStats=alakazam.baseStats } },
    moves = { PSYCHIC = { id='PSYCHIC', name='PSYCHIC', pp=10 } },
  },
  save = { party = { mon }, player = { name='RED', id=12345 } },
}
if realModernUiMod then
  local function getUpvalue(fn, wanted)
    for i=1,64 do
      local name, value = debug.getupvalue(fn, i)
      if not name then break end
      if name == wanted then return value end
    end
  end
  local runtime = getUpvalue(realModernUiMod.exports.getScaleTokens, 'runtime')
  expect(type(runtime) == 'table', 'real Modern UI runtime can be resolved through the capability-checked shim')
  local bridge = rawget(runtime, '__specialStatSplitModernUiSurgicalV1')
  expect(type(bridge) == 'table' and runtime.drawMonDetail == bridge.wrappedMonDetail
      and runtime.drawSummary == bridge.wrappedSummary,
    'surgical shim wraps only Modern UI built-in detail/Summary render functions')

  local theme = realModernUiMod.exports.themes.default
  expect(type(theme) == 'table', 'real Modern UI default theme is available for renderer contract test')

  -- Directly exercise the selected-Pokémon detail renderer under Party context.
  -- The original renderer still executes; the shim then replaces only its lower
  -- stats/moves text block with two full-name stat rows and the same move list.
  hudPrintCalls = {}
  hudPrintRecords = {}
  bridge.inParty = true
  bridge.partyIsBattle = false
  runtime.drawMonDetail(uiGame, mon, 100, 100, 400, 300, theme, 'party')
  bridge.inParty = false
  local joinedParty = table.concat(hudPrintCalls, '|')
  local function statRecords(records)
    local out = {}
    for _, record in ipairs(records) do
      if record.text:match('^ATTACK ') or record.text:match('^DEFENSE ')
          or record.text:match('^SPEED ') or record.text:match('^SPEC%. ATTACK ')
          or record.text:match('^SPEC%. DEFENSE ') then
        out[#out+1] = record
      end
    end
    return out
  end
  local function effectiveSize(record)
    return (record.fontSize or 0) * (record.sx or 1)
  end
  if optionModernOverride and optionMode == 'gen2' then
    local expectedLabels
    if optionModernPartyLayout == 'one_row' then
      expectedLabels = {'ATK ', 'DEF ', 'SPD ', 'SPATK ', 'SPDEF '}
      for _, label in ipairs(expectedLabels) do
        expect(joinedParty:find(label, 1, true),
          'one-row Party layout renders compact ' .. label .. ' label')
      end
      expect(not joinedParty:find('SPEC. ATTACK', 1, true)
          and not joinedParty:find('SPEC. DEFENSE', 1, true),
        'one-row Party layout does not render full two-row labels')
    else
      expectedLabels = {'ATTACK ', 'DEFENSE ', 'SPEED ', 'SPEC. ATTACK ', 'SPEC. DEFENSE '}
      for _, label in ipairs(expectedLabels) do
        expect(joinedParty:find(label, 1, true),
          'two-row Party layout renders full ' .. label .. ' label')
      end
    end

    local function layoutStatRecords(records)
      -- Modern UI's original one-row ATK/DEF/SPD text is still present in the
      -- captured call stream even though our opaque lower-block repaint covers
      -- it on screen. Select the last matching draw for each expected label,
      -- which is the surgical override's final visible output.
      local found = {}
      for i=#records,1,-1 do
        local record = records[i]
        for labelIndex, label in ipairs(expectedLabels) do
          if not found[labelIndex] and record.text:sub(1, #label) == label then
            found[labelIndex] = record
          end
        end
      end
      local out = {}
      for i=1,#expectedLabels do if found[i] then out[#out+1] = found[i] end end
      return out
    end
    local wideStats = layoutStatRecords(hudPrintRecords)
    expect(#wideStats == 5, 'wide Party override prints exactly five split stat labels')
    local wideSize = effectiveSize(wideStats[1])
    for _, record in ipairs(wideStats) do
      expect(not record.text:find('%.%.%.'), 'wide Party stat labels are never ellipsized')
      expect(math.abs(effectiveSize(record) - wideSize) < 0.001,
        'all Party stat labels use one shared effective font size')
    end
    if optionModernPartyLayout == 'one_row' then
      local y0 = wideStats[1].y
      for _, record in ipairs(wideStats) do
        expect(math.abs((record.y or 0) - (y0 or 0)) < 0.001,
          'one-row Party layout keeps all five stats on one row')
      end
    else
      expect((wideStats[4].y or 0) > (wideStats[1].y or 0),
        'two-row Party layout places special stats on the second row')
    end

    -- Force a compact/narrow detail panel. The exact same five labels must stay
    -- complete, and all stats must shrink by the same measured proportion.
    hudPrintCalls = {}
    hudPrintRecords = {}
    bridge.inParty = true
    runtime.drawMonDetail(uiGame, mon, 100, 100, 220, 300, theme, 'party')
    bridge.inParty = false
    local narrowStats = layoutStatRecords(hudPrintRecords)
    expect(#narrowStats == 5, 'narrow Party override still prints all five stat labels')
    local narrowSize = effectiveSize(narrowStats[1])
    for _, record in ipairs(narrowStats) do
      expect(not record.text:find('%.%.%.'), 'narrow Party stat labels are never ellipsized')
      expect(math.abs(effectiveSize(record) - narrowSize) < 0.001,
        'narrow Party stats share the same adaptive font scale')
    end
    expect(narrowSize <= wideSize,
      'Party stat font never grows when the live detail panel is narrower')
  else
    expect(not joinedParty:find('SPEC%. ATTACK ') and not joinedParty:find('SPEC%. DEFENSE '),
      'ModernUI Override OFF or VANILLA mode leaves the upstream Party block untouched')
  end

  -- Summary remains the built-in presenter too, but unlike Party its split
  -- stat layout is intentionally NOT user-selectable: every viewport stacks
  -- SP. ATTACK and SP. DEFENSE on separate rows, followed by ID and OT.
  local summaryState = setmetatable({ game=uiGame, page=1, mon=mon }, SummaryMenu)
  local function verifyStackedSummary(viewport, description)
    hudPrintCalls = {}
    hudPrintRecords = {}
    local okSummary = pcall(runtime.drawSummary, uiGame, summaryState, viewport, theme)
    expect(okSummary, description .. ' Modern UI Summary renderer remains callable')
    local summaryJoined = table.concat(hudPrintCalls, '|')
    expect(summaryJoined:find('SP%. ATTACK', 1, false)
        and summaryJoined:find('SP%. DEFENSE', 1, false),
      description .. ' Summary uses full SP. ATTACK and SP. DEFENSE labels')
    expect(not summaryJoined:find('SP%.ATK', 1, false)
        and not summaryJoined:find('SP%.DEF', 1, false),
      description .. ' Summary no longer uses paired compact split-special labels')

    local function lastRecord(text)
      for i=#hudPrintRecords,1,-1 do
        if hudPrintRecords[i].text == text then return hudPrintRecords[i] end
      end
    end
    local spaLabel = lastRecord('SP. ATTACK')
    local spdLabel = lastRecord('SP. DEFENSE')
    local spaValue = lastRecord(tostring(astats.specialAttack))
    local spdValue = lastRecord(tostring(astats.specialDefense))
    expect(spaLabel and spdLabel and spaValue and spdValue,
      description .. ' Summary emits both split labels and values')
    expect((spdLabel.y or 0) > (spaLabel.y or 0),
      description .. ' Summary puts each split special on its own row')
    expect(spaValue.x > spaLabel.x and spdValue.x > spdLabel.x,
      description .. ' Summary values follow their labels rather than right-aligning')
    expect(math.abs((spaValue.y or 0) - (spaLabel.y or 0)) < 0.001
        and math.abs((spdValue.y or 0) - (spdLabel.y or 0)) < 0.001,
      description .. ' Summary label/value pairs share their row')
    expect(lastRecord('12345') and lastRecord('RED'),
      description .. ' Summary preserves Modern UI ID/OT values below split stats')
  end

  if optionModernOverride and optionMode == 'gen2' then
    verifyStackedSummary(
      { width=1024, height=768, safe={x=0,y=0,width=1024,height=768} },
      'desktop')
    verifyStackedSummary(
      { width=480, height=900, safe={x=0,y=0,width=480,height=900} },
      'mobile')
  end
end

-- 9) Save strip/restore: tracked stats removed on disk, unrelated fields untouched.
local save = {party={mon}, unrelated={specialAttack=12,specialDefense=13}}
local s1, s2 = SaveData.save(save, {})
expect(s1 == true and s2 == 'saved', 'SaveData return values preserved')
expect(saveSeen.trackedSpa == nil and saveSeen.trackedSpd == nil,
       'derived split fields absent during serialization')
expect(saveSeen.unrelatedSpa == 12 and saveSeen.unrelatedSpd == 13,
       'unrelated same-named fields preserved')
expect(astats.specialAttack ~= nil and astats.specialDefense ~= nil,
       'derived fields restored after save')

save.forceSaveError = true
local saveOk = pcall(SaveData.save, save, {})
expect(not saveOk, 'forced save error propagated')
expect(astats.specialAttack ~= nil and astats.specialDefense ~= nil,
       'save error path restores derived fields')

-- 10) UI wrappers render both labels while preserving original screens.
fontCalls = {}
local game = {data={pokemon={ALAKAZAM=alakazam}}}
SummaryMenu.draw({page=1,mon=mon,game=game})
local joined = table.concat(fontCalls, '|')
expect(joined:find('SPATK') and joined:find('SPDEF'), 'Summary renders both compact split labels')
fontCalls = {}
BattleState.StatBox.draw({mon=mon,game=game})
joined = table.concat(fontCalls, '|')
expect(joined:find('SP%.ATK') and joined:find('SP%.DEF'), 'Level-up StatBox renders both split labels')

-- 11) Modern Battle UI level-up correction uses only public hook seams.
-- Modern UI 0.8.x experimental BATTLE UI (WIP) suppresses the source StatBox
-- by decorating its draw method through ui.state.decorate rather than through
-- screen.render_visible. We therefore observe that exact public decoration and
-- use our own native split draw as the per-frame truth signal.
if noModernUi or unsupportedModernApi then
  local noModernHud = specialHookWrappers['render.hud']
  expect(specialHookWrappers['ui.state.decorate'] == nil
    and (noModernHud == nil or noModernHud.priority ~= 200),
    'no Modern UI means no level-up correction hooks')
else
  local decorateHook = specialHookWrappers['ui.state.decorate']
  local hudHook = specialHookWrappers['render.hud']
  expect(decorateHook and decorateHook.priority == 200,
    'level-up decoration observer is registered above Modern UI priority')
  expect(hudHook and hudHook.priority == 200,
    'level-up correction HUD is registered above Modern UI priority')

  local levelBox = setmetatable({ mon=mon, game=uiGame }, BattleState.StatBox)
  local battleBase = { isOpaque=true, phase='menu', queue={}, kind='wild', enemy={}, player={}, draw=function() end, game=uiGame }
  uiGame.stack = {
    states = { battleBase, levelBox },
    top = function(self) return self.states[#self.states] end,
    visibleBase = function() return 1 end,
  }
  local viewport = { width=1024, height=768, safe={x=0,y=0,width=1024,height=768} }

  if realModernUiMod then
    local modernDecorate = realModernUiMod._testHookWrappers
      and realModernUiMod._testHookWrappers['ui.state.decorate']
    expect(modernDecorate and modernDecorate.priority == 100,
      'real Modern UI registers ui.state.decorate at priority 100')

    -- WIP Battle UI ON + HIDE ORIGINAL UI ON: Modern UI replaces our exact
    -- split StatBox draw with a suppressing wrapper. Our outer decorator must
    -- record the replacement without modifying the foreign wrapper.
    realModernUiMod.options._testValues.battleUiWip = true
    realModernUiMod.options._testValues.hideOriginalUi = true
    local sourceDraw = levelBox.draw
    local decoratedResult = decorateHook.fn(function(g, st, model)
      return modernDecorate.fn(function(g2, st2, model2) return st2 end,
        g, st, model)
    end, uiGame, levelBox, nil)
    expect(decoratedResult == levelBox, 'decorator chain preserves the level-up state')
    expect(levelBox.draw ~= sourceDraw,
      'real Modern UI WIP battle decorator replaces source split StatBox draw')

    -- The decorated child draw is now suppressed: it must NOT execute our
    -- native split draw, which is the signal that a correction is required.
    fontCalls = {}
    levelBox:draw()
    local nativeText = table.concat(fontCalls, '|')
    expect(nativeText:find('SP.ATK', 1, true) == nil
      and nativeText:find('SP.DEF', 1, true) == nil,
      'real Modern UI suppressing wrapper prevents native split StatBox draw')

    hudPrintCalls = {}
    local downstreamRan = false
    hudHook.fn(function() downstreamRan = true end, uiGame, viewport)
    expect(downstreamRan == true, 'correction HUD calls downstream before overlay')
    local correctedText = table.concat(hudPrintCalls, '|')
    if optionMode == 'gen2' and optionBattleWipOverride then
      expect(correctedText:find('LEVEL UP!', 1, true) ~= nil,
        'decorated suppressed StatBox produces correction level-up card')
      expect(correctedText:find('SP. ATK', 1, true) ~= nil
        and correctedText:find('SP. DEF', 1, true) ~= nil,
        'correction card exposes both split stats')
      expect(correctedText:find('SPECIAL', 1, true) == nil,
        'correction card never prints legacy SPECIAL')
    else
      expect(#hudPrintCalls == 0,
        optionBattleWipOverride and 'VANILLA Special mode never draws split correction card'
          or 'Level Up Override OFF never draws a correction card')
    end

    -- HIDE ORIGINAL UI OFF: the same Modern UI wrapper now delegates to our
    -- native split draw. The per-frame native-draw marker must prevent a second
    -- overlay even though the decorator function is still installed.
    realModernUiMod.options._testValues.hideOriginalUi = false
    fontCalls = {}
    levelBox:draw()
    nativeText = table.concat(fontCalls, '|')
    if optionMode == 'gen2' then
      expect(nativeText:find('SP.ATK', 1, true) ~= nil
        and nativeText:find('SP.DEF', 1, true) ~= nil,
        'visible native StatBox still renders both split stats')
    end
    hudPrintCalls = {}
    hudHook.fn(function() end, uiGame, viewport)
    expect(#hudPrintCalls == 0,
      'executed native split draw suppresses duplicate correction overlay')

    -- BATTLE UI (WIP) OFF (the Modern UI default): a fresh decorate pass
    -- restores the source-owned draw. Our observer must retire the candidate,
    -- leaving only the normal native Special Stat Split StatBox.
    realModernUiMod.options._testValues.battleUiWip = false
    local restoredResult = decorateHook.fn(function(g, st, model)
      return modernDecorate.fn(function(g2, st2, model2) return st2 end,
        g, st, model)
    end, uiGame, levelBox, nil)
    expect(restoredResult == levelBox, 'Battle UI off decorate pass preserves state')
    fontCalls = {}
    levelBox:draw()
    nativeText = table.concat(fontCalls, '|')
    if optionMode == 'gen2' then
      expect(nativeText:find('SP.ATK', 1, true) ~= nil
        and nativeText:find('SP.DEF', 1, true) ~= nil,
        'Battle UI off restores the normal split native level-up StatBox')
    end
    hudPrintCalls = {}
    hudHook.fn(function() end, uiGame, viewport)
    expect(#hudPrintCalls == 0,
      'Battle UI off produces no Modern UI correction overlay')

    -- Restore harness defaults for any later Modern UI checks.
    realModernUiMod.options._testValues.battleUiWip = true
    realModernUiMod.options._testValues.hideOriginalUi = true
  else
    -- Stub API case: no foreign decorator exists, so our public hooks must stay
    -- inert and never invent a correction merely because Modern UI is present.
    hudPrintCalls = {}
    decorateHook.fn(function(g, st, model) return st end, uiGame, levelBox, nil)
    levelBox:draw()
    hudHook.fn(function() end, uiGame, viewport)
    expect(#hudPrintCalls == 0,
      'Modern UI presence without a foreign StatBox decorator does not trigger correction')
  end
end

-- 12) Optional Pokédex Plus Base Stats screen shows split bases and Gen II BST.
expect(patchedScreens.PokedexPlusStats ~= nil, 'Pokédex Plus screen compatibility patched')
local dexGame = { data={ pokemon={ ALAKAZAM=alakazam } } }
local dexScreen = patchedScreens.PokedexPlusStats.new(dexGame, {species='ALAKAZAM'})
expect(dexScreen.stats.specialAttack == 135 and dexScreen.stats.specialDefense == 85,
       'Pokédex Plus screen receives Gen II SpA/SpD bases')
expect(dexScreen.stats.total == 490, 'Pokédex Plus TOTAL uses six Gen II battle stats')
fontCalls = {}
dexScreen:draw()
joined = table.concat(fontCalls, '|')
expect(joined:find('SP%.ATK') and joined:find('SP%.DEF'),
       'Pokédex Plus draw renders SP.ATK and SP.DEF')

print('special_stat_split runtime stub (GEN II / ' .. string.upper(optionMoveMode) .. '): PASS')
