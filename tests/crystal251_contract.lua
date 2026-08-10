-- Headless runtime contracts for SPECIAL STAT SPLIT.
-- Runs under texlua with minimal Gen1Recomp stubs. No LÖVE window required.

package.path = './?.lua;./?/init.lua;' .. package.path

local MODE = 'gen2'
local MOVE_MODE = arg[1] or 'gen4'
local function expect(cond, msg)
  if not cond then error('ASSERTION FAILED: ' .. tostring(msg), 2) end
end
local function deepcopy(t)
  if type(t) ~= 'table' then return t end
  local out = {}
  for k,v in pairs(t) do out[k] = deepcopy(v) end
  return out
end

_G.love = { graphics = {
  setColor = function() end,
  rectangle = function() end,
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
local BattleState = { StatBox = { draw = function() end } }
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
  return typeId == 'PSYCHIC' and 'special' or 'physical'
end }

local crystalBaseStats = {
  -- Deliberately wrong upstream split values prove that #001-251 are sourced
  -- from this mod's canonical table rather than trusted from Crystal exports.
  TOGETIC = { hp=55, attack=40, defense=85, speed=40, specialAttack=99, specialDefense=99 },
  ESPEON = { hp=65, attack=65, defense=60, speed=110, specialAttack=99, specialDefense=99 },
  UMBREON = { hp=95, attack=65, defense=110, speed=65, specialAttack=60, specialDefense=130 },
  BLISSEY = { hp=255, attack=10, defense=10, speed=55, specialAttack=75, specialDefense=135 },
}

-- Deliberately seed these with Crystal/Gen-II type-based categories.  The
-- compatibility layer must replace them with modern per-move categories.
local crystalMoves = {
  FLAME_WHEEL  = { id='FLAME_WHEEL',  index=172, type='FIRE',     power=60, category='special' },
  SNORE        = { id='SNORE',        index=173, type='NORMAL',   power=40, category='physical' },
  AEROBLAST    = { id='AEROBLAST',    index=177, type='FLYING',   power=100, category='physical' },
  SLUDGE_BOMB  = { id='SLUDGE_BOMB',  index=188, type='POISON',   power=90, category='physical' },
  SPARK        = { id='SPARK',        index=209, type='ELECTRIC', power=65, category='special' },
  SACRED_FIRE  = { id='SACRED_FIRE',  index=221, type='FIRE',     power=100, category='special' },
  DRAGONBREATH = { id='DRAGONBREATH', index=225, type='DRAGON',   power=60, category='special' },
  CRUNCH       = { id='CRUNCH',       index=242, type='DARK',     power=80, category='special' },
  SHADOW_BALL  = { id='SHADOW_BALL',  index=247, type='GHOST',    power=80, category='physical' },
}

local PHYSICAL_TYPES = {
  NORMAL=true, FIGHTING=true, FLYING=true, POISON=true, GROUND=true,
  ROCK=true, BUG=true, GHOST=true, STEEL=true,
}
local CrystalDamage = {}
function CrystalDamage.moveFor(moveOrId, moves)
  moves = moves or crystalMoves
  local id = type(moveOrId) == 'table' and moveOrId.id or moveOrId
  return id and moves[id] or nil
end
function CrystalDamage.isRouted(moveOrId, moves)
  local move = CrystalDamage.moveFor(moveOrId, moves)
    or (type(moveOrId) == 'table' and moveOrId or nil)
  return move ~= nil and (move.power or 0) > 0 and move.category ~= 'status'
end
function CrystalDamage.prepareMove(move, moves)
  local crystal = CrystalDamage.moveFor(move, moves)
  if not crystal or not CrystalDamage.isRouted(crystal, moves) then return nil end
  local token = {power=move.power, type=move.type, category=move.category}
  move.power = crystal.power
  move.type = crystal.type
  move.category = PHYSICAL_TYPES[crystal.type] and 'physical' or 'special'
  return token
end
function CrystalDamage.compute(ctx, config)
  if ctx and ctx.forceError then error('forced crystal damage failure') end
  local category = PHYSICAL_TYPES[ctx.move.type] and 'physical' or 'special'
  return category, ctx.move.type
end
package.preload['mods.CRYSTAL_251.battle.crystal_damage'] = function() return CrystalDamage end

local stubs = {
  ['src.pokemon.Stats'] = Stats,
  ['src.battle.Damage'] = Damage,
  ['src.battle.Experience'] = Experience,
  ['src.inventory.ItemEffects'] = ItemEffects,
  ['src.battle.MoveEffects'] = MoveEffects,
  ['src.ui.SummaryMenu'] = SummaryMenu,
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
  FLAME_WHEEL  = crystalMoves.FLAME_WHEEL,
  SNORE        = crystalMoves.SNORE,
  AEROBLAST    = crystalMoves.AEROBLAST,
  SLUDGE_BOMB  = crystalMoves.SLUDGE_BOMB,
  SPARK        = crystalMoves.SPARK,
  SACRED_FIRE  = crystalMoves.SACRED_FIRE,
  DRAGONBREATH = crystalMoves.DRAGONBREATH,
  CRUNCH       = crystalMoves.CRUNCH,
  SHADOW_BALL  = crystalMoves.SHADOW_BALL,
}
local DELETE = {}
local patchedMoves = {}
local movesRegistry = {}
function movesRegistry:each()
  local ids = {'FIRE_PUNCH','SWORDS_DANCE','FLAMETHROWER','HYPER_BEAM','WATERFALL','HI_JUMP_KICK','FAKE_MOVE','FLAME_WHEEL','SNORE','AEROBLAST','SLUDGE_BOMB','SPARK','SACRED_FIRE','DRAGONBREATH','CRUNCH','SHADOW_BALL'}
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
local mod = {
  options = {
    define = function() end,
    get = function(_, key)
      if key == 'mode' then return optionMode end
      if key == 'move_split' then return optionMoveMode end
    end,
  },
  content = {
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
    if id == 'CRYSTAL_251' then
      return { id=id, version='0.9.19', exports={crystalBaseStats=crystalBaseStats, crystalMoves=crystalMoves} }
    end
  end,
  log = { info=function() end, warn=function() end, error=function() end },
  DELETE = DELETE,
  exports = {},
}

local init = assert(loadfile('main.lua'))()
init(mod)

-- Crystal 251 interoperability contracts.
local togeticBase = mod.exports.getSpecialBaseStats('TOGETIC')
local espeonBase = mod.exports.getSpecialBaseStats('ESPEON')
local umbreonBase = mod.exports.getSpecialBaseStats('UMBREON')
expect(togeticBase and togeticBase.specialAttack == 80 and togeticBase.specialDefense == 105,
       'Canonical Togetic 80/105 overrides wrong/equal Crystal export')
expect(espeonBase and espeonBase.specialAttack == 130 and espeonBase.specialDefense == 95,
       'Canonical Espeon 130/95 overrides wrong/equal Crystal export')
expect(umbreonBase and umbreonBase.specialAttack == 60 and umbreonBase.specialDefense == 130,
       'Canonical Umbreon uses exact Gen II-V split SpA/SpD')
local togetic = {id='TOGETIC', dex=176, baseStats={attack=40,defense=85,speed=40,special=105}}
local tstats = Stats.calc(togetic, 50, {special=10}, {special=10000})
expect(tstats.specialAttack < tstats.specialDefense,
       'Stats.calc produces distinct canonical Crystal Togetic SpA/SpD')
local espeon = {id='ESPEON', dex=196, baseStats={attack=65,defense=60,speed=110,special=130}}
local estats = Stats.calc(espeon, 50, {special=10}, {special=10000})
expect(estats.specialAttack > estats.specialDefense,
       'Stats.calc produces distinct canonical Crystal Espeon SpA/SpD')

if optionMoveMode == 'gen4' then
  expect(crystalMoves.FLAME_WHEEL.category == 'physical', 'Crystal Flame Wheel becomes physical')
  expect(crystalMoves.SNORE.category == 'special', 'Crystal Snore becomes special')
  expect(crystalMoves.AEROBLAST.category == 'special', 'Crystal Aeroblast becomes special')
  expect(crystalMoves.SLUDGE_BOMB.category == 'special', 'Crystal Sludge Bomb becomes special')
  expect(crystalMoves.SPARK.category == 'physical', 'Crystal Spark becomes physical')
  expect(crystalMoves.SACRED_FIRE.category == 'physical', 'Crystal Sacred Fire becomes physical')
  expect(crystalMoves.CRUNCH.category == 'physical', 'Crystal Crunch becomes physical')
  expect(crystalMoves.SHADOW_BALL.category == 'special', 'Crystal Shadow Ball becomes special')

  -- The Crystal router must obey the modern category while preserving elemental type.
  local fwRuntime = {id='FLAME_WHEEL', index=172, type='NORMAL', power=1, category='physical'}
  local token = CrystalDamage.prepareMove(fwRuntime, crystalMoves)
  expect(token ~= nil and fwRuntime.type == 'FIRE' and fwRuntime.category == 'physical',
         'Crystal prepareMove preserves FIRE type but restores modern Physical category')
  local routedCat, routedType = CrystalDamage.compute({move=fwRuntime}, {moves=crystalMoves})
  expect(routedCat == 'physical' and routedType == 'FIRE',
         'Crystal damage router uses Physical for Flame Wheel without changing type')
  -- Temporary router override must be restored: an unrelated FIRE move remains special by type.
  local fallbackCat = CrystalDamage.compute({move={id='OTHER_FIRE',type='FIRE',power=50}}, {})
  expect(fallbackCat == 'special', 'Crystal physical-type table restored after routed calculation')
  local sbRuntime = {id='SHADOW_BALL', index=247, type='GHOST', power=80, category='special'}
  local sbCat = CrystalDamage.compute({move=sbRuntime}, {moves=crystalMoves})
  expect(sbCat == 'special', 'Crystal damage router uses Special for Shadow Ball despite GHOST type')
  local errOk = pcall(CrystalDamage.compute, {move=fwRuntime, forceError=true}, {moves=crystalMoves})
  expect(not errOk, 'Crystal damage error propagates through bridge')
  local postErrorCat = CrystalDamage.compute({move={id='OTHER_FIRE_2',type='FIRE',power=50}}, {})
  expect(postErrorCat == 'special', 'Crystal router state restored after damage error')

else
  expect(crystalMoves.FLAME_WHEEL.category == 'special', 'GEN I mode leaves Crystal Flame Wheel type-based')
  expect(crystalMoves.SNORE.category == 'physical', 'GEN I mode leaves Crystal Snore type-based')
  expect(crystalMoves.AEROBLAST.category == 'physical', 'GEN I mode leaves Crystal Aeroblast type-based')
  expect(crystalMoves.SPARK.category == 'special', 'GEN I mode leaves Crystal Spark type-based')
  expect(crystalMoves.CRUNCH.category == 'special', 'GEN I mode leaves Crystal Crunch type-based')
  expect(crystalMoves.SHADOW_BALL.category == 'physical', 'GEN I mode leaves Crystal Shadow Ball type-based')
  local fwRuntime = {id='FLAME_WHEEL', index=172, type='NORMAL', power=1}
  local token = CrystalDamage.prepareMove(fwRuntime, crystalMoves)
  expect(token ~= nil and fwRuntime.type == 'FIRE' and fwRuntime.category == 'special',
         'GEN I mode keeps Crystal prepareMove category-by-type')
  local routedCat, routedType = CrystalDamage.compute({move=fwRuntime}, {moves=crystalMoves})
  expect(routedCat == 'special' and routedType == 'FIRE',
         'GEN I mode leaves Crystal damage router unbridged')
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

-- 8) Save strip/restore: tracked stats removed on disk, unrelated fields untouched.
local mon = {species='ALAKAZAM',level=50,dvs=dvs,statExp=statExp,stats=astats}
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

-- 9) UI wrappers render both labels while preserving original screens.
fontCalls = {}
local game = {data={pokemon={ALAKAZAM=alakazam}}}
SummaryMenu.draw({page=1,mon=mon,game=game})
local joined = table.concat(fontCalls, '|')
expect(joined:find('SPATK') and joined:find('SPDEF'), 'Summary renders both compact split labels')
fontCalls = {}
BattleState.StatBox.draw({mon=mon,game=game})
joined = table.concat(fontCalls, '|')
expect(joined:find('SP%.ATK') and joined:find('SP%.DEF'), 'Level-up StatBox renders both split labels')

-- 10) Optional Pokédex Plus Base Stats screen shows split bases and Gen II BST.
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

print('special_stat_split Crystal 251 interoperability contract (' .. string.upper(optionMoveMode) .. '): PASS')
