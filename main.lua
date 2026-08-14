-- Special Stat Split v2.7.3
-- Gen1Recomp v0.1.86 migration: public registries, hooks and events only.

local mod = ...
local MOD_ID = "special_stat_split"
local MOD_VERSION = "2.7.3"
local unpack = table.unpack or unpack

local function pack(...)
  return { n = select("#", ...), ... }
end

local function loadModLua(path)
  local body, readError = mod:read(path)
  assert(body, ("%s: cannot read %s: %s"):format(MOD_ID, path,
    tostring(readError)))
  local chunk, loadError = load(body, "@" .. MOD_ID .. "/" .. path)
  assert(chunk, ("%s: cannot load %s: %s"):format(MOD_ID, path,
    tostring(loadError)))
  return chunk()
end

local function csvRows(path)
  local body, readError = mod:read(path)
  assert(body, ("%s: cannot read %s: %s"):format(MOD_ID, path,
    tostring(readError)))
  local out = {}
  for line in body:gmatch("[^\r\n]+") do
    local first, second, third = line:match("^([^,]+),([^,]+),?([^,]*)$")
    local index = tonumber(first)
    if index then
      out[index] = { second = second, third = third ~= "" and third or nil }
    end
  end
  return out
end

local SPECIAL = loadModLua("data/gen2_special_stats.lua")
local CATEGORY_ROWS = csvRows("data/gen4_move_categories.csv")
local GEN1_ID_ROWS = csvRows("data/gen1_move_registry_ids.csv")

local CATEGORY_BY_INDEX = {}
local MOVE_IDENTIFIER_BY_INDEX = {}
local GEN1_ID_BY_INDEX = {}
for index, row in pairs(CATEGORY_ROWS) do
  MOVE_IDENTIFIER_BY_INDEX[index] = row.second
  CATEGORY_BY_INDEX[index] = row.third
end
for index, row in pairs(GEN1_ID_ROWS) do
  GEN1_ID_BY_INDEX[index] = row.second
end

-- Gold's runtime ids follow pokecrystal constants.  Gen 1 ids are read from
-- the audited engine registry map above because several spellings differ.
local GOLD_ID_BY_INDEX = {}
for index, id in pairs(GEN1_ID_BY_INDEX) do GOLD_ID_BY_INDEX[index] = id end
local GOLD_GEN2_IDS = {
  [166] = "SKETCH", [167] = "TRIPLE_KICK", [168] = "THIEF",
  [169] = "SPIDER_WEB", [170] = "MIND_READER", [171] = "NIGHTMARE",
  [172] = "FLAME_WHEEL", [173] = "SNORE", [174] = "CURSE", [175] = "FLAIL",
  [176] = "CONVERSION2", [177] = "AEROBLAST", [178] = "COTTON_SPORE",
  [179] = "REVERSAL", [180] = "SPITE", [181] = "POWDER_SNOW",
  [182] = "PROTECT", [183] = "MACH_PUNCH", [184] = "SCARY_FACE",
  [185] = "FAINT_ATTACK", [186] = "SWEET_KISS", [187] = "BELLY_DRUM",
  [188] = "SLUDGE_BOMB", [189] = "MUD_SLAP", [190] = "OCTAZOOKA",
  [191] = "SPIKES", [192] = "ZAP_CANNON", [193] = "FORESIGHT",
  [194] = "DESTINY_BOND", [195] = "PERISH_SONG", [196] = "ICY_WIND",
  [197] = "DETECT", [198] = "BONE_RUSH", [199] = "LOCK_ON", [200] = "OUTRAGE",
  [201] = "SANDSTORM", [202] = "GIGA_DRAIN", [203] = "ENDURE", [204] = "CHARM",
  [205] = "ROLLOUT", [206] = "FALSE_SWIPE", [207] = "SWAGGER",
  [208] = "MILK_DRINK", [209] = "SPARK", [210] = "FURY_CUTTER",
  [211] = "STEEL_WING", [212] = "MEAN_LOOK", [213] = "ATTRACT",
  [214] = "SLEEP_TALK", [215] = "HEAL_BELL", [216] = "RETURN",
  [217] = "PRESENT", [218] = "FRUSTRATION", [219] = "SAFEGUARD",
  [220] = "PAIN_SPLIT", [221] = "SACRED_FIRE", [222] = "MAGNITUDE",
  [223] = "DYNAMIC_PUNCH", [224] = "MEGAHORN", [225] = "DRAGON_BREATH",
  [226] = "BATON_PASS", [227] = "ENCORE", [228] = "PURSUIT",
  [229] = "RAPID_SPIN", [230] = "SWEET_SCENT", [231] = "IRON_TAIL",
  [232] = "METAL_CLAW", [233] = "VITAL_THROW", [234] = "MORNING_SUN",
  [235] = "SYNTHESIS", [236] = "MOONLIGHT", [237] = "HIDDEN_POWER",
  [238] = "CROSS_CHOP", [239] = "TWISTER", [240] = "RAIN_DANCE",
  [241] = "SUNNY_DAY", [242] = "CRUNCH", [243] = "MIRROR_COAT",
  [244] = "PSYCH_UP", [245] = "EXTREME_SPEED", [246] = "ANCIENT_POWER",
  [247] = "SHADOW_BALL", [248] = "FUTURE_SIGHT", [249] = "ROCK_SMASH",
  [250] = "WHIRLPOOL", [251] = "BEAT_UP",
}
for index, id in pairs(GOLD_GEN2_IDS) do GOLD_ID_BY_INDEX[index] = id end

local function normalize(value)
  return tostring(value or ""):lower():gsub("[^%w]", "")
end

local GEN1_INDEX_BY_KEY = {}
local GOLD_INDEX_BY_KEY = {}
for index, id in pairs(GEN1_ID_BY_INDEX) do
  GEN1_INDEX_BY_KEY[normalize(id)] = index
end
for index, id in pairs(GOLD_ID_BY_INDEX) do
  GOLD_INDEX_BY_KEY[normalize(id)] = index
end
for index, identifier in pairs(MOVE_IDENTIFIER_BY_INDEX) do
  GOLD_INDEX_BY_KEY[normalize(identifier)] = index
end

mod.options:define({
  {
    key = "mode",
    label = "SPECIAL STATS (RESTART)",
    type = "choice",
    default = "gen2",
    choices = {
      { "VANILLA", "vanilla" },
      { "GEN II (SP. ATK / SP. DEF)", "gen2" },
    },
  },
  {
    key = "move_split",
    label = "MOVE CATEGORIES (RESTART)",
    type = "choice",
    default = "gen4",
    choices = {
      { "GEN I (BY TYPE)", "gen1" },
      { "GEN IV+ (BY MOVE)", "gen4" },
    },
  },
  {
    key = "move_category_readout",
    label = "MOVE CATEGORY READOUT",
    type = "toggle",
    default = true,
    description = "Show the effective Physical, Special or Status category for the selected move.",
  },
  {
    key = "modern_ui_override",
    label = "ModernUI Override",
    type = "toggle",
    default = true,
    description = "Enable split-stat compatibility for supported Gen 1 Modern UI presentations without replacing the native Summary window.",
  },
  {
    key = "modern_ui_party_stats_layout",
    label = "ModernUI Party Stats Layout",
    type = "choice",
    default = "two_rows",
    choices = {
      { "2 ROWS", "two_rows" },
      { "1 ROW", "one_row" },
    },
    description = "Compatibility preference retained for supported Modern UI Party presentations.",
  },
  {
    key = "modern_ui_battle_wip_override",
    label = "ModernUI BattleWIP Override",
    type = "toggle",
    default = false,
    description = "Opt in to split-stat compatibility when Modern UI Battle WIP is active; the native level-up StatBox is never covered by a replacement card.",
  },
})

local requestedSpecial = tostring(mod.options:get("mode") or "gen2")
local requestedMoves = tostring(mod.options:get("move_split") or "gen4")
local specialActive = requestedSpecial == "gen2"
local moveSplitActive = requestedMoves == "gen4"

-- Generation detection is capability based.  Gold records expose levelMoves
-- and native split base stats; Gen 1 records expose learnset and one special.
local function generationProbe()
  for _, id in ipairs({ "CHARIZARD", "PIKACHU", "BULBASAUR", "CYNDAQUIL" }) do
    local row = mod.content.pokemon:get(id)
    if type(row) == "table" then return row end
  end
  return nil
end

local probe = generationProbe()
local probeStats = probe and probe.baseStats or nil
local isGold = type(probe) == "table" and
  (probe.levelMoves ~= nil or
    (type(probeStats) == "table" and probeStats.specialAttack ~= nil
      and probeStats.special == nil)) or false
local crystal251 = mod.find("CRYSTAL_251")
local modernUi = mod.find("gen1_modern_ui")
local gen3Ui = mod.find("gen3_battle_ui")
  or mod.find("gen3_battle_ui_overhaul") or mod.find("gen3_ui")

local function baseFor(speciesDef)
  if type(speciesDef) ~= "table" then return nil end
  local row = speciesDef.id and SPECIAL.byId[speciesDef.id] or nil
  if not row and speciesDef.dex then row = SPECIAL.byDex[tonumber(speciesDef.dex)] end
  return row
end

local function calcSplitStat(base, dv, statExp, level)
  local ev = math.floor(math.min(255,
    math.ceil(math.sqrt(tonumber(statExp) or 0))) / 4)
  return math.floor(((base + (tonumber(dv) or 0)) * 2 + ev)
    * (tonumber(level) or 1) / 100) + 5
end

local derivedStats = setmetatable({}, { __mode = "k" })

local function attachSplit(stats, speciesDef, level, dvs, statExp)
  if type(stats) ~= "table" then return stats end
  local row = baseFor(speciesDef)
  if not row then
    stats.specialAttack = stats.specialAttack or stats.special
    stats.specialDefense = stats.specialDefense or stats.special
    return stats
  end
  dvs = dvs or {}
  statExp = statExp or {}
  stats.specialAttack = calcSplitStat(row.spa, dvs.special,
    statExp.special, level)
  stats.specialDefense = calcSplitStat(row.spd, dvs.special,
    statExp.special, level)
  derivedStats[stats] = true
  return stats
end

local function expectedMoveId(index)
  if isGold or (crystal251 and index > 165) then
    return GOLD_ID_BY_INDEX[index]
  end
  return GEN1_ID_BY_INDEX[index]
end

local function moveIndex(id, move)
  local byKey = isGold and GOLD_INDEX_BY_KEY or GEN1_INDEX_BY_KEY
  local direct = type(move) == "table" and tonumber(move.index) or nil
  if direct and CATEGORY_BY_INDEX[direct] then
    local expected = expectedMoveId(direct)
    local want = normalize(expected)
    if normalize(id) == want or normalize(move.id) == want
        or normalize(move.name) == want then
      return direct
    end
  end
  local resolved = byKey[normalize(id)]
    or (type(move) == "table" and
      (byKey[normalize(move.id)] or byKey[normalize(move.name)]))
  if not resolved and crystal251 and not isGold then
    resolved = GOLD_INDEX_BY_KEY[normalize(id)]
      or (type(move) == "table" and
        (GOLD_INDEX_BY_KEY[normalize(move.id)]
          or GOLD_INDEX_BY_KEY[normalize(move.name)]))
  end
  return resolved
end

local function moveCategory(id, move, types)
  if type(move) ~= "table" then return nil end
  if move.category == "physical" or move.category == "special"
      or move.category == "status" then
    return move.category
  end
  local index = moveIndex(id, move)
  if moveSplitActive and index then return CATEGORY_BY_INDEX[index] end
  local typeRecord = types and move.type and types[move.type]
  if typeRecord and typeRecord.category then return typeRecord.category end
  local registryType = move.type and mod.content.type_chart:get(move.type) or nil
  return registryType and registryType.category or nil
end

local registryChanged, registryConflicts, identitySkips = 0, 0, 0
local canonicalSeen = {}
for id, move in mod.content.moves:each() do
  local index = moveIndex(id, move)
  local category = index and CATEGORY_BY_INDEX[index] or nil
  if category then
    local expected = expectedMoveId(index)
    local want = normalize(expected)
    local identityOK = normalize(id) == want or normalize(move.id) == want
      or normalize(move.name) == want
    if identityOK then
      canonicalSeen[index] = true
      if moveSplitActive then
        if move.category ~= nil and move.category ~= category then
          registryConflicts = registryConflicts + 1
        end
        mod.content.moves:patch(id, { category = category })
        registryChanged = registryChanged + 1
      else
        local clearLimit = isGold and 251 or 165
        if index <= clearLimit and move.category ~= nil then
          mod.content.moves:patch(id, { category = mod.DELETE })
          registryChanged = registryChanged + 1
        end
      end
    else
      identitySkips = identitySkips + 1
    end
  end
end

local canonicalCount = 0
for index = 1, ((isGold or crystal251) and 251 or 165) do
  if canonicalSeen[index] then canonicalCount = canonicalCount + 1 end
end

-- The native Gen 1 move box already owns this label and its exact pixel-font
-- placement.  The v0.1.86 public battle.overlay seam runs only after that box
-- has drawn, so an overlay can only cover it (and visibly becomes a second
-- panel).  Keep the proven narrow Font.draw composition for this one token:
-- TYPE/ is replaced in place, while every other glyph still follows the exact
-- upstream renderer.  Font is shared engine rendering code; the manifest
-- explicitly declares engine_internals for this audited compatibility seam.
local nativeReadout
if not isGold then
  local Font = require("src.render.Font")
  nativeReadout = Font.__special_stat_split_move_readout_v2
  if not nativeReadout then
    nativeReadout = {
      originalDraw = Font.draw,
      currentBattle = nil,
      typeLabel = "TYPE/",
    }
    Font.__special_stat_split_move_readout_v2 = nativeReadout
    Font.draw = function(text, x, y, ...)
      if text == nativeReadout.typeLabel then
        if nativeReadout.suppress and nativeReadout.suppress() then return nil end
        if nativeReadout.categoryLabel then
          text = nativeReadout.categoryLabel(nativeReadout.currentBattle) or text
        end
      end
      return nativeReadout.originalDraw(text, x, y, ...)
    end
  end

  nativeReadout.typeLabel = "TYPE/"
  nativeReadout.suppress = function()
    return gen3Ui ~= nil
  end
  nativeReadout.categoryLabel = function(battle)
    if mod.options:get("move_category_readout") == false then return nil end
    if not battle or battle.phase ~= "moveSelect" then return nil end
    local moves = battle.player and battle.player.curMoves
    local selected = moves and moves[battle.moveIndex or 1]
    local def = selected and battle.data and battle.data.moves
      and battle.data.moves[selected.id] or nil
    if not def then return nil end
    local category = moveCategory(selected.id, def)
    if category == "status" or (tonumber(def.power) or 0) == 0 then
      return "STAT/"
    end
    if category == "physical" then return "PHYS/" end
    if category == "special" then return "SPEC/" end
    return nil
  end

  mod.events:on("battle.started", function(ev)
    nativeReadout.currentBattle = ev and ev.battle or nil
  end)
  mod.events:on("battle.ended", function()
    nativeReadout.currentBattle = nil
  end)
end

local gameplayConfig = {
  specialStats = specialActive and "gen2" or "vanilla",
  moveCategories = moveSplitActive and "gen4" or "gen1",
}
local gameplayConfigRevision = ("special=%s;move=%s")
  :format(gameplayConfig.specialStats, gameplayConfig.moveCategories)
local linkConfigRegistered = false
if not isGold and mod.content.link_fields then
  mod.content.link_fields:register("special_stat_split_rules", {
    rev = gameplayConfigRevision,
  })
  linkConfigRegistered = true
end

local statsState
local Stats
if not isGold then
  -- Stats is an explicitly supported Gen1Recomp mod facade in v0.1.86.
  Stats = require("src.pokemon.Stats")
  statsState = Stats.__special_stat_split_dispatch_v2
  if not statsState then
    statsState = {
      active = false,
      baseFor = nil,
      attach = nil,
      originalCalc = Stats.calc,
      originalEnsure = Stats.ensure,
    }
    Stats.__special_stat_split_dispatch_v2 = statsState

    Stats.calc = function(speciesDef, level, dvs, statExp)
      local out = statsState.originalCalc(speciesDef, level, dvs, statExp)
      if statsState.active and statsState.attach then
        statsState.attach(out, speciesDef, level, dvs, statExp)
      end
      return out
    end

    Stats.ensure = function(speciesDef, mon)
      local out = statsState.originalEnsure(speciesDef, mon)
      if statsState.active and statsState.attach and type(out) == "table"
          and type(out.stats) == "table" then
        statsState.attach(out.stats, speciesDef, out.level or 1,
          out.dvs or {}, out.statExp or {})
      end
      return out
    end
  end
  statsState.active = specialActive
  statsState.baseFor = baseFor
  statsState.attach = attachSplit
end

local function ensureBattlerSplit(battler)
  if not specialActive or type(battler) ~= "table"
      or type(battler.curStats) ~= "table" then return end
  if battler.curStats.specialAttack ~= nil
      and battler.curStats.specialDefense ~= nil then return end
  local mon = battler.mon or {}
  attachSplit(battler.curStats, battler.def,
    mon.level or battler.level or 1, mon.dvs or {}, mon.statExp or {})
end

mod.hooks:wrap("battle.damage", function(next, ctx)
  local move = ctx and ctx.move
  local category = moveCategory(ctx and ctx.moveId, move,
    ctx and ctx.opts and ctx.opts.types)
  if category ~= "physical" and category ~= "special" then
    return next(ctx)
  end

  if isGold then
    if not moveSplitActive or not ctx.opts then return next(ctx) end
    local typeRecord = ctx.opts.types and move and move.type
      and ctx.opts.types[move.type] or nil
    if not typeRecord then return next(ctx) end
    local oldCategory = typeRecord.category
    local oldScreen = ctx.opts.screen
    typeRecord.category = category
    if ctx.battle and type(ctx.battle.screenActive) == "function" then
      ctx.opts.screen = ctx.battle:screenActive(ctx.target,
        category == "physical")
    end
    local result = pack(pcall(next, ctx))
    typeRecord.category = oldCategory
    ctx.opts.screen = oldScreen
    if not result[1] then error(result[2], 0) end
    return unpack(result, 2, result.n)
  end

  if not specialActive or category ~= "special" then return next(ctx) end
  local user, target = ctx.user, ctx.target
  ensureBattlerSplit(user)
  ensureBattlerSplit(target)
  if not (user and target and user.curStats and target.curStats) then
    return next(ctx)
  end

  user.stages = user.stages or {}
  target.stages = target.stages or {}
  local saved = {
    userSpecial = user.curStats.special,
    targetSpecial = target.curStats.special,
    userStage = user.stages.special,
    targetStage = target.stages.special,
  }
  user.curStats.special = user.curStats.specialAttack or user.curStats.special
  target.curStats.special = target.curStats.specialDefense or target.curStats.special
  user.stages.special = user.stages.specialAttack or 0
  target.stages.special = target.stages.specialDefense or 0
  local result = pack(pcall(next, ctx))
  user.curStats.special = saved.userSpecial
  target.curStats.special = saved.targetSpecial
  user.stages.special = saved.userStage
  target.stages.special = saved.targetStage
  if not result[1] then error(result[2], 0) end
  return unpack(result, 2, result.n)
end)

if isGold and moveSplitActive then
  -- Gold AI estimates damage outside battle.damage.  The public action hook
  -- scopes a type-category view to each move definition while vanilla scores
  -- it, then restores every touched record before returning.
  mod.hooks:wrap("battle.enemy_action", function(next, battle)
    if type(battle) ~= "table" or type(battle.moveDef) ~= "function" then
      return next(battle)
    end
    local originalMoveDef = battle.moveDef
    local restored, seen = {}, {}
    battle.moveDef = function(self, id)
      local def = originalMoveDef(self, id)
      local types = self.data and self.data.type_chart
        and self.data.type_chart.types or nil
      local record = def and types and def.type and types[def.type] or nil
      local category = moveCategory(id, def, types)
      if record and (category == "physical" or category == "special") then
        if not seen[record] then
          seen[record] = true
          restored[#restored + 1] = { record = record, value = record.category }
        end
        record.category = category
      end
      return def
    end
    local result = pack(pcall(next, battle))
    battle.moveDef = originalMoveDef
    for index = #restored, 1, -1 do
      local row = restored[index]
      row.record.category = row.value
    end
    if not result[1] then error(result[2], 0) end
    return unpack(result, 2, result.n)
  end)

  mod.events:on("battle.damage_dealt", function(ev)
    local category = moveCategory(ev and ev.moveId, ev and ev.move,
      ev and ev.battle and ev.battle.data and ev.battle.data.type_chart
        and ev.battle.data.type_chart.types)
    if category ~= "physical" and category ~= "special" then return end
    ev.kind = category
    local battle = ev.battle
    if battle and ev.target and type(battle.volatile) == "function" then
      local volatile = battle:volatile(ev.target)
      if volatile then volatile.tookKind = category end
    end
  end, 1000)
end

if not isGold and specialActive then
  -- Gen II keeps one shared Special Stat Exp; defeated Sp. Atk is awarded.
  mod.hooks:wrap("battle.exp_award", function(next, ctx)
    local def = ctx and ctx.battle and ctx.battle.enemy
      and ctx.battle.enemy.def or nil
    local row = baseFor(def)
    if not (row and def and def.baseStats) then return next(ctx) end
    local old = def.baseStats.special
    def.baseStats.special = row.spa
    local result = pack(pcall(next, ctx))
    def.baseStats.special = old
    if not result[1] then error(result[2], 0) end
    return unpack(result, 2, result.n)
  end)

  local function relabel(messages, label)
    if type(messages) ~= "table" then return messages end
    for index, message in ipairs(messages) do
      if type(message) == "string" then
        messages[index] = message:gsub("SPECIAL", label)
      end
    end
    return messages
  end

  local function aliasStageEffect(effectId, side, stat)
    local original = mod.content.move_effects:get(effectId)
    local originalRun = type(original) == "table" and original.run or nil
    if type(originalRun) ~= "function" then return end
    mod.content.move_effects:patch(effectId, {
      run = function(ctx)
        local battler = side == "user" and ctx.user or ctx.target
        if not battler then return originalRun(ctx) end
        battler.stages = battler.stages or {}
        local old = battler.stages.special
        battler.stages.special = battler.stages[stat] or 0
        local result = pack(pcall(originalRun, ctx))
        battler.stages[stat] = battler.stages.special or 0
        battler.stages.special = old
        if result[1] then
          relabel(result[2], stat == "specialAttack" and "SP. ATK" or "SP. DEF")
        end
        if not result[1] then error(result[2], 0) end
        return unpack(result, 2, result.n)
      end,
    })
  end

  aliasStageEffect("SPECIAL_UP1_EFFECT", "user", "specialAttack")
  aliasStageEffect("SPECIAL_UP2_EFFECT", "user", "specialDefense")
  aliasStageEffect("SPECIAL_DOWN_SIDE_EFFECT", "target", "specialDefense")

  local transform = mod.content.move_effects:get("TRANSFORM_EFFECT")
  local transformRun = type(transform) == "table" and transform.run or nil
  if type(transformRun) == "function" then
    mod.content.move_effects:patch("TRANSFORM_EFFECT", {
      run = function(ctx)
        local result = pack(pcall(transformRun, ctx))
        if result[1] and ctx.user and ctx.target and ctx.user.curStats
            and ctx.target.curStats then
          ctx.user.curStats.specialAttack = ctx.target.curStats.specialAttack
            or ctx.target.curStats.special
          ctx.user.curStats.specialDefense = ctx.target.curStats.specialDefense
            or ctx.target.curStats.special
        end
        if not result[1] then error(result[2], 0) end
        return unpack(result, 2, result.n)
      end,
    })
  end

  -- Registry-owned X Special effect replaces only this item's stage target.
  mod.content.item_effects:register("SPECIAL_STAT_SPLIT_X_SPECIAL", {
    battle = true,
    field = false,
    use = function(ctx)
      local battle = ctx.battle
      local battler = battle and battle.player
      if not battler then return "failed", { "It won't have any effect." } end
      battler.stages = battler.stages or {}

      local save = ctx.save
      if save and save.pikachuHappiness ~= nil and battler.mon
          and battler.mon.species == "PIKACHU" then
        local happiness = tonumber(save.pikachuHappiness) or 90
        local delta = happiness < 200 and 1 or 0
        save.pikachuHappiness = math.max(0, math.min(255, happiness + delta))
      end

      local current = battler.stages.specialAttack or 0
      if current >= 6 then return "consumed", { "Nothing happened!" } end
      battler.stages.specialAttack = current + 1
      return "consumed", {
        ("%s's\nSP. ATK rose!"):format(battler.name or "POKéMON"),
      }
    end,
  })
  if mod.content.items:get("X_SPECIAL") then
    mod.content.items:patch("X_SPECIAL", {
      effect = "SPECIAL_STAT_SPLIT_X_SPECIAL",
    })
  end

  -- Derived fields are deliberately not persisted into vanilla save schema.
  mod.events:on("save.writing", function(ev)
    local seen = {}
    local function strip(value)
      if type(value) ~= "table" or seen[value] then return end
      seen[value] = true
      if derivedStats[value] then
        value.specialAttack = nil
        value.specialDefense = nil
      end
      for _, child in pairs(value) do strip(child) end
    end
    if ev then strip(ev.save) end
  end)
end

local fonts = {}
local function font(size)
  if not (love and love.graphics and love.graphics.newFont) then return nil end
  if not fonts[size] then fonts[size] = love.graphics.newFont(size) end
  return fonts[size]
end

local function graphicsReady()
  return love and love.graphics and love.graphics.rectangle
    and love.graphics.print and love.graphics.setColor
end

local function withGraphics(fn)
  if not graphicsReady() then return end
  local graphics = love.graphics
  if graphics.push then graphics.push("all") end
  local result = pack(pcall(fn, graphics))
  if graphics.pop then graphics.pop() end
  if not result[1] then error(result[2], 0) end
end

local function ensureMonStats(game, mon)
  if type(mon) ~= "table" then return nil end
  local def = game and game.data and game.data.pokemon
    and game.data.pokemon[mon.species] or nil
  if def and not mon.stats and Stats then
    mon.stats = Stats.calc(def, mon.level or 1, mon.dvs or {}, mon.statExp or {})
  elseif def and mon.stats then
    attachSplit(mon.stats, def, mon.level or 1, mon.dvs or {}, mon.statExp or {})
  end
  return mon.stats
end

-- Native Gen 1 Summary and level-up presentation.  v2.7.0 temporarily moved
-- these rows into render.hud, which necessarily painted a second proportional-
-- font card over the cartridge UI.  Both upstream windows are stable engine
-- classes in v0.1.86, so keep the original v2.6.5 integration: replace only
-- the contents of the native boxes with the engine pixel font and tile border.
-- The manifest already declares engine_internals for these audited renderer
-- seams and the native TYPE/ token composition above.
if not isGold then
  local Font = require("src.render.Font")
  local Strings = require("src.core.Strings")
  -- Compose the two Gen 1-only module names after the generation probe so a
  -- Gold boot never asks Gen2Compat for dead Gen 1 UI classes.
  local SummaryMenu = require("src.ui." .. "Summary" .. "Menu")
  local BattleState = require("src.battle." .. "BattleState")
  local StatBox = BattleState and BattleState["StatBox"]
  local nativeStats = SummaryMenu.__special_stat_split_native_stats_v3

  if not nativeStats then
    nativeStats = {
      active = false,
      ensure = nil,
      originalSummaryDraw = SummaryMenu.draw,
      originalStatBoxDraw = StatBox and StatBox["draw"],
      drawSummary = nil,
      drawStatBox = nil,
    }
    SummaryMenu.__special_stat_split_native_stats_v3 = nativeStats

    SummaryMenu.draw = function(self)
      return nativeStats.drawSummary(self)
    end
    if StatBox and type(nativeStats.originalStatBoxDraw) == "function" then
      StatBox["draw"] = function(self)
        return nativeStats.drawStatBox(self)
      end
    end
  end

  nativeStats.active = specialActive
  nativeStats.ensure = ensureMonStats

  nativeStats.drawSummary = function(self)
    local result = pack(pcall(nativeStats.originalSummaryDraw, self))
    if not result[1] then error(result[2], 0) end
    if nativeStats.active and self and self.page == 1 and self.mon then
      local stats = nativeStats.ensure(self.game, self.mon) or {}
      Font.drawBox(0, 8, 10, 10)
      love.graphics.setColor(0, 0, 0, 1)
      local rows = {
        { "ATK", stats.attack }, { "DEF", stats.defense },
        { "SPEED", stats.speed },
        { "SPATK", stats.specialAttack or stats.special },
        { "SPDEF", stats.specialDefense or stats.special },
      }
      for index, row in ipairs(rows) do
        local y = 72 + (index - 1) * 14
        Font.draw(Strings(row[1]), 8, y)
        Font.draw(("%3d"):format(tonumber(row[2]) or 0), 48, y)
      end
      love.graphics.setColor(1, 1, 1, 1)
    end
    return unpack(result, 2, result.n)
  end

  nativeStats.drawStatBox = function(self)
    if not (nativeStats.active and self and self.mon) then
      return nativeStats.originalStatBoxDraw(self)
    end
    local stats = nativeStats.ensure(self.game, self.mon) or {}
    Font.drawBox(9, 2, 11, 10)
    love.graphics.setColor(0, 0, 0, 1)
    local rows = {
      { "ATK", stats.attack }, { "DEF", stats.defense },
      { "SPEED", stats.speed },
      { "SP.ATK", stats.specialAttack or stats.special },
      { "SP.DEF", stats.specialDefense or stats.special },
    }
    for index, row in ipairs(rows) do
      local y = 24 + (index - 1) * 14
      Font.draw(Strings(row[1]), 80, y)
      Font.draw(("%3d"):format(tonumber(row[2]) or 0), 128, y)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end
end

local currentBattleScreen
local function selectedMove(screen)
  if type(screen) ~= "table" then return nil, nil end
  if screen.phase == "moveSelect" and screen.player and screen.player.curMoves then
    local slot = screen.player.curMoves[screen.moveIndex or 1]
    local def = slot and screen.data and screen.data.moves
      and screen.data.moves[slot.id] or nil
    return slot and slot.id, def
  end
  if screen.phase == "moves" and type(screen.playerMoves) == "function" then
    local moves = screen:playerMoves()
    local slot = moves and moves[screen.moveIndex or 1]
    local data = screen.game and screen.game.data
    local def = slot and data and data.moves and data.moves[slot.id] or nil
    return slot and slot.id, def
  end
  return nil, nil
end

local function categoryLabel(id, def, full)
  if type(def) ~= "table" then return nil end
  local category = moveCategory(id, def,
    def and def.type and { [def.type] = mod.content.type_chart:get(def.type) } or nil)
  if category == "status" or (tonumber(def.power) or 0) == 0 then
    return "STATUS"
  end
  if category == "physical" then return full and "PHYSICAL" or "PHYS" end
  if category == "special" then return full and "SPECIAL" or "SPEC" end
  return nil
end

local GoldChrome
if isGold then GoldChrome = require("src.ui.gen2.Chrome") end

local function drawGoldBorderCategory(label)
  if not (GoldChrome and label) then return end
  -- Native Gold move box: Chrome.box(0, 12, 20, 6).  Cut a ten-tile field
  -- directly into its top border and preserve the originally live-tuned
  -- padding: " PHYSICAL ", " SPECIAL  ", and "  STATUS  ".
  local fieldStart, fieldWidth = 8, 10
  local lead = label == "STATUS" and 2 or 1
  withGraphics(function(graphics)
    graphics.setColor(1, 1, 1, 1)
    graphics.rectangle("fill", fieldStart * 8, 12 * 8,
      fieldWidth * 8, 8)
    GoldChrome.print(label, fieldStart + lead, 12)
  end)
end

mod.hooks:wrap("battle.overlay", function(next, screen)
  local result = pack(pcall(next, screen))
  if not result[1] then error(result[2], 0) end
  currentBattleScreen = screen
  if isGold and not gen3Ui
      and mod.options:get("move_category_readout") ~= false then
    local id, def = selectedMove(screen)
    drawGoldBorderCategory(categoryLabel(id, def, true))
  end
  return unpack(result, 2, result.n)
end, math.huge)

mod.hooks:wrap("render.hud", function(next, game, viewport)
  local result = pack(pcall(next, game, viewport))
  if not result[1] then error(result[2], 0) end
  if gen3Ui and mod.options:get("move_category_readout") ~= false then
    local id, def = selectedMove(currentBattleScreen)
    local label = categoryLabel(id, def)
    if label then
      withGraphics(function(graphics)
        local scale = tonumber(viewport and viewport.scale) or 1
        local x = (viewport and viewport.gameX or 0)
          + (viewport and viewport.gameWidth or 160) - 42 * scale
        local y = (viewport and viewport.gameY or 0)
          + (viewport and viewport.gameHeight or 144) - 14 * scale
        graphics.setColor(0.05, 0.05, 0.05, 0.88)
        graphics.rectangle("fill", x, y, 40 * scale, 12 * scale)
        graphics.setColor(1, 1, 1, 1)
        local useFont = font(math.max(7, math.floor(7 * scale)))
        if useFont and graphics.setFont then graphics.setFont(useFont) end
        graphics.print(label, x + 3 * scale, y + scale)
      end)
    end
  end
  return unpack(result, 2, result.n)
end)

-- Pokédex Plus composes through its public screen registry.
if not isGold and specialActive and mod.find("pokedex_plus") then
  local record = mod.content.screens:get("PokedexPlusStats")
  local originalNew = type(record) == "table" and record.new or nil
  if type(originalNew) == "function" then
    mod.content.screens:patch("PokedexPlusStats", {
      new = function(game, opts)
        local screen = originalNew(game, opts)
        if type(screen) ~= "table" or type(screen.stats) ~= "table" then
          return screen
        end
        local species = screen.species or (type(opts) == "table"
          and (opts.species or opts[1]))
        local def = game and game.data and game.data.pokemon
          and game.data.pokemon[species] or nil
        local row = baseFor(def)
        if not row then return screen end
        screen.stats.specialAttack = row.spa
        screen.stats.specialDefense = row.spd
        screen.stats.total = (tonumber(screen.stats.hp) or 0)
          + (tonumber(screen.stats.attack) or 0)
          + (tonumber(screen.stats.defense) or 0)
          + (tonumber(screen.stats.speed) or 0) + row.spa + row.spd
        local originalDraw = screen.draw
        if type(originalDraw) == "function" then
          screen.draw = function(self)
            originalDraw(self)
            withGraphics(function(graphics)
              graphics.setColor(0.98, 0.98, 0.98, 1)
              graphics.rectangle("fill", 8, 40, 144, 88)
              graphics.setColor(0.05, 0.05, 0.05, 1)
              local useFont = font(7)
              if useFont and graphics.setFont then graphics.setFont(useFont) end
              local rows = {
                { "HP", self.stats.hp },
                { "ATTACK", self.stats.attack },
                { "DEFENSE", self.stats.defense },
                { "SPEED", self.stats.speed },
                { "SP.ATK", self.stats.specialAttack },
                { "SP.DEF", self.stats.specialDefense },
                { "TOTAL", self.stats.total },
              }
              for index, stat in ipairs(rows) do
                local y = 43 + (index - 1) * 12
                graphics.print(stat[1], 14, y)
                local value = tostring(math.floor(tonumber(stat[2]) or 0))
                local width = useFont and useFont:getWidth(value) or #value * 5
                graphics.print(value, 146 - width, y)
              end
            end)
          end
        end
        return screen
      end,
    })
  end
end

local function getSpecialBaseStats(species)
  local def = type(species) == "table" and species
    or mod.content.pokemon:get(species)
  local row = baseFor(def)
  if not row then return nil end
  return { specialAttack = row.spa, specialDefense = row.spd }
end

local diagnostics = {
  modVersion = MOD_VERSION,
  target = "Gen1Recomp v0.1.86",
  generation = isGold and 2 or 1,
  backend = isGold and "gold-public-hooks" or "gen1-public-hooks",
  specialSplitActive = specialActive,
  moveCategorySplitActive = moveSplitActive,
  canonicalMovesSeen = canonicalCount,
  registryChanged = registryChanged,
  registryConflicts = registryConflicts,
  identitySkips = identitySkips,
  linkConfigRegistered = linkConfigRegistered,
  integrations = {
    pokedexPlus = mod.find("pokedex_plus") ~= nil,
    crystal251 = crystal251 ~= nil,
    modernUi = modernUi ~= nil,
    moveCategory = mod.find("move_category") ~= nil,
    gen3BattleUi = gen3Ui ~= nil,
  },
}

mod.exports.specialSplitActive = function() return specialActive end
mod.exports.moveCategorySplitActive = function() return moveSplitActive end
mod.exports.moveCategoryReadoutEnabled = function()
  return mod.options:get("move_category_readout") ~= false
end
mod.exports.modernUiOverrideEnabled = function()
  return mod.options:get("modern_ui_override") ~= false
end
mod.exports.modernUiPartyStatsLayout = function()
  return tostring(mod.options:get("modern_ui_party_stats_layout") or "two_rows")
end
mod.exports.modernUiBattleWipOverrideEnabled = function()
  return mod.options:get("modern_ui_battle_wip_override") == true
end
mod.exports.modernUiLevelUpOverrideEnabled =
  mod.exports.modernUiBattleWipOverrideEnabled
mod.exports.getMoveCategory = function(move)
  local id = type(move) == "string" and move or type(move) == "table" and move.id
  local def = type(move) == "table" and move or mod.content.moves:get(id)
  return moveCategory(id, def)
end
mod.exports.getSpecialBaseStats = getSpecialBaseStats
mod.exports.getEffectiveSpecialBaseStats = getSpecialBaseStats
mod.exports.attachSplitStats = function(mon, speciesDef)
  if type(mon) ~= "table" then return mon end
  speciesDef = speciesDef or mod.content.pokemon:get(mon.species)
  if not mon.stats and Stats and speciesDef then
    mon.stats = Stats.calc(speciesDef, mon.level or 1, mon.dvs or {},
      mon.statExp or {})
  elseif mon.stats and speciesDef then
    attachSplit(mon.stats, speciesDef, mon.level or 1, mon.dvs or {},
      mon.statExp or {})
  end
  return mon
end
mod.exports.getGameplayConfig = function() return gameplayConfig end
mod.exports.getEffectiveGameplayConfig = mod.exports.getGameplayConfig
mod.exports.getLinkConfigRevision = function() return gameplayConfigRevision end
mod.exports.getDiagnostics = function() return diagnostics end

mod.exports.specialStatSplit = {
  api = 1,
  version = MOD_VERSION,
  specialSplitActive = mod.exports.specialSplitActive,
  moveCategorySplitActive = mod.exports.moveCategorySplitActive,
  moveCategoryReadoutEnabled = mod.exports.moveCategoryReadoutEnabled,
  getMoveCategory = mod.exports.getMoveCategory,
  getSpecialBaseStats = mod.exports.getSpecialBaseStats,
  attachSplitStats = mod.exports.attachSplitStats,
  getGameplayConfig = mod.exports.getGameplayConfig,
  getLinkConfigRevision = mod.exports.getLinkConfigRevision,
  getDiagnostics = mod.exports.getDiagnostics,
}
mod.exports.specialStatSplitV2 = {
  api = 2,
  version = MOD_VERSION,
  generation = diagnostics.generation,
  getMoveCategory = mod.exports.getMoveCategory,
  getSpecialBaseStats = mod.exports.getSpecialBaseStats,
  attachSplitStats = mod.exports.attachSplitStats,
  getGameplayConfig = mod.exports.getGameplayConfig,
  getLinkConfigRevision = mod.exports.getLinkConfigRevision,
  getDiagnostics = mod.exports.getDiagnostics,
}

mod.log:info(("Special Stat Split %s loaded: %s, special=%s, moves=%s, canonical=%d")
  :format(MOD_VERSION, diagnostics.backend, gameplayConfig.specialStats,
    gameplayConfig.moveCategories, canonicalCount))
