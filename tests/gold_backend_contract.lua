-- Headless Gold backend contract for Special Stat Split.
-- Uses minimal Gen 2 module stubs shaped after upstream ae6cac89 and verifies
-- category routing, AI, screen/damage-kind consistency, identity guards,
-- native-special no-op semantics, effective link config, and hot reload.

package.path = "./?.lua;./?/init.lua;" .. package.path

local GameVersion = { generation = function() return 2 end }
package.preload["src.core.GameVersion"] = function() return GameVersion end

-- Any accidental Gen 1 backend load on Gold is a hard failure.
for _, name in ipairs({
  "src.pokemon.Stats", "src.battle.Damage", "src.battle.Experience",
  "src.inventory.ItemEffects", "src.battle.MoveEffects", "src.ui.SummaryMenu",
  "src.battle.BattleState", "src.core.SaveData",
}) do
  package.preload[name] = function() error("GEN1_REQUIRE_ON_GOLD:" .. name) end
end

local Damage = {}
local nativePhysical = {
  NORMAL=true, FIGHTING=true, FLYING=true, POISON=true, GROUND=true,
  ROCK=true, BUG=true, GHOST=true, STEEL=true,
}
function Damage.isPhysical(moveType, types)
  local row = types and types[moveType]
  if row and row.category then return row.category == "physical" end
  return nativePhysical[moveType] == true
end
function Damage.calc(opts)
  local physical = Damage.isPhysical(opts.moveType, opts.types)
  local atk = physical and opts.attacker.attack or opts.attacker.specialAttack
  local def = physical and opts.defender.defense or opts.defender.specialDefense
  local damage = math.floor((atk or 1) * 10 / math.max(1, def or 1))
  return damage, { effectiveness = 10, physical = physical }
end
package.preload["src.battle.gen2.Damage"] = function() return Damage end

local Battle = {}
function Battle:hitOnce(attacker, defender, def, opts)
  opts = opts or {}
  if def.throwForRestoreTest then error("RESTORE_SENTINEL") end
  local types = self.data.type_chart.types
  local physicalForScreen = Damage.isPhysical(def.type, types)
  local damage, info = Damage.calc({
    level = attacker.level or 50,
    power = def.power or 50,
    moveType = def.type,
    attacker = {
      attack = attacker.stats.attack,
      specialAttack = attacker.stats.specialAttack,
      types = attacker.types,
    },
    defender = {
      defense = defender.stats.defense,
      specialDefense = defender.stats.specialDefense,
      types = defender.types,
    },
    types = types,
    matchups = self.data.type_chart.matchups,
  })
  local kind = Damage.isPhysical(def.type, types) and "physical" or "special"
  return damage, {
    kind = kind,
    screenKind = physicalForScreen and "reflect" or "lightScreen",
    physical = info.physical,
  }
end
function Battle:volatile(mon) return mon._volatile or {} end
function Battle:moveDef(id) return self.data.moves[id] end
function Battle:smartAiState()
  local types = self.data.type_chart.types
  local st = self:volatile(self.player)
  local p, s = 0, 0
  for _, id in ipairs(st.usedMoves or {}) do
    local def = self:moveDef(id)
    if def and (def.power or 0) > 0 then
      if Damage.isPhysical(def.type, types) then p=p+1 else s=s+1 end
    end
  end
  local last = st.lastMove and self:moveDef(st.lastMove) or nil
  return {
    playerPhysicalMoves = p,
    playerSpecialMoves = s,
    playerSpecialType = false,
    playerLastMoveSpecial = last and not Damage.isPhysical(last.type, types) or nil,
  }
end
package.preload["src.battle.gen2.Battle"] = function() return Battle end

local Ai = {}
function Ai.choose(context)
  local bestId, bestDamage = nil, -1
  for _, move in ipairs(context.moves or {}) do
    if (move.pp or 0) > 0 then
      local def = context.moveDef(move.id)
      local damage = 0
      if def and (def.power or 0) > 0 then
        damage = Damage.calc({
          moveType = def.type,
          attacker = {
            attack = context.attacker.stats.attack,
            specialAttack = context.attacker.stats.specialAttack,
          },
          defender = {
            defense = context.defender.stats.defense,
            specialDefense = context.defender.stats.specialDefense,
          },
          types = context.typeChart.types,
          matchups = context.typeChart.matchups,
        })
      end
      if damage > bestDamage then bestId, bestDamage = move.id, damage end
    end
  end
  return bestId, { bestDamage = bestDamage }
end
package.preload["src.battle.gen2.Ai"] = function() return Ai end

local overlayMarks = {}
local overlayRects = {}
local rawTextDraws = {}
local currentDrawColor = { 1, 1, 1, 1 }
local testFont = {
  getWidth = function(_, text) return #tostring(text or "") * 6 end,
}
_G.love = {
  graphics = {
    getColor = function()
      return currentDrawColor[1], currentDrawColor[2], currentDrawColor[3], currentDrawColor[4]
    end,
    getDimensions = function() return 1026, 768 end,
    setColor = function(r, g, b, a)
      currentDrawColor = { r, g, b, a == nil and 1 or a }
    end,
    rectangle = function(mode, x, y, w, h)
      overlayRects[#overlayRects + 1] = { mode=mode, x=x, y=y, w=w, h=h }
    end,
    getFont = function() return testFont end,
    print = function(text, x, y, ...)
      rawTextDraws[#rawTextDraws + 1] = {
        kind="print", text=text, x=x, y=y, extra={...},
        color={currentDrawColor[1], currentDrawColor[2], currentDrawColor[3], currentDrawColor[4]},
      }
    end,
    printf = function(text, x, y, limit, align, ...)
      rawTextDraws[#rawTextDraws + 1] = {
        kind="printf", text=text, x=x, y=y, limit=limit, align=align, extra={...},
        color={currentDrawColor[1], currentDrawColor[2], currentDrawColor[3], currentDrawColor[4]},
      }
    end,
  },
}
package.preload["src.ui.gen2.Chrome"] = function()
  return {
    print = function(text, tx, ty)
      overlayMarks[#overlayMarks + 1] = { text = text, tx = tx, ty = ty }
    end,
  }
end

local DELETE = {}
local function makeRegistry(rows)
  local r = { rows = rows, patches = {} }
  function r:each()
    local keys = {}
    for id in pairs(self.rows) do keys[#keys+1] = id end
    table.sort(keys)
    local i = 0
    return function()
      i=i+1
      local id=keys[i]
      if id then return id, self.rows[id] end
    end
  end
  function r:patch(id, patch)
    self.patches[id] = patch
    local row = self.rows[id]
    if patch.category == DELETE then row.category = nil
    elseif patch.category ~= nil then row.category = patch.category end
  end
  return r
end

local function makeMod(mode, moveMode, rows)
  local values = {
    mode = mode or "gen2",
    move_split = moveMode or "gen4",
    move_category_readout = true,
    modern_ui_override = true,
    modern_ui_party_stats_layout = "two_rows",
    modern_ui_battle_wip_override = false,
  }
  local defined
  local options = {}
  function options:define(spec) defined = spec end
  function options:get(key) return values[key] end
  local links = { rows = {} }
  function links:register(id, row) self.rows[id] = row end
  local registry = makeRegistry(rows)
  local logs = {}
  local wraps = {}
  local hooks = {}
  function hooks:wrap(name, fn, priority)
    wraps[name] = { fn = fn, priority = priority }
  end
  local mod = {
    version = "2.6.2",
    DELETE = DELETE,
    options = options,
    content = { moves = registry, link_fields = links },
    exports = {},
    hooks = hooks,
    find = function(id)
      if id == "gen3_battle_ui" then return values.__gen3Ui end
      return nil
    end,
    log = {
      info = function(_, text) logs[#logs+1] = text end,
      warn = function(_, text) logs[#logs+1] = "WARN:" .. text end,
    },
  }
  return mod, values, registry, links, function() return defined end, logs, wraps
end

local TYPE_CHART = { types = {
  FIRE={category="special"}, GHOST={category="physical"},
  NORMAL={category="physical"}, DARK={category="special"},
  POISON={category="physical"}, FIGHTING={category="physical"},
  GROUND={category="physical"},
}, matchups={} }

local function baseRows()
  return {
    FIRE_PUNCH={id="FIRE_PUNCH", index=7, name="Fire Punch", type="FIRE", power=75},
    SCRATCH={id="SCRATCH", index=10, name="Scratch", type="NORMAL", power=40},
    FLAMETHROWER={id="FLAMETHROWER", index=53, name="Flamethrower", type="FIRE", power=95},
    BITE={id="BITE", index=44, name="Bite", type="DARK", power=60},
    HYPER_BEAM={id="HYPER_BEAM", index=63, name="Hyper Beam", type="NORMAL", power=150},
    SLUDGE_BOMB={id="SLUDGE_BOMB", index=188, name="Sludge Bomb", type="POISON", power=90},
    SHADOW_BALL={id="SHADOW_BALL", index=247, name="Shadow Ball", type="GHOST", power=80},
    SWORDS_DANCE={id="SWORDS_DANCE", index=14, name="Swords Dance", type="NORMAL", power=0},
    SEISMIC_TOSS={id="SEISMIC_TOSS", index=69, name="Seismic Toss", type="FIGHTING", power=0},
    FISSURE={id="FISSURE", index=90, name="Fissure", type="GROUND", power=0},
    BIDE={id="BIDE", index=117, name="Bide", type="NORMAL", power=0},
    CUSTOM_FAKE={id="CUSTOM_FAKE", index=7, name="Custom Fake", type="FIRE", power=75},
  }
end

local entry = assert(loadfile("main.lua"))()
assert(type(entry) == "function", "main.lua did not return mod entry")

-- GEN IV+ Gold backend.
local rows = baseRows()
local mod, values, registry, links, defined, _, wraps = makeMod("gen2", "gen4", rows)
entry(mod)
assert(type(defined()) == "table", "Gold options were not defined")
assert(rows.FIRE_PUNCH.category == "physical", "Fire Punch registry category")
assert(rows.SHADOW_BALL.category == "special", "Shadow Ball registry category")
assert(rows.SLUDGE_BOMB.category == "special", "Sludge Bomb registry category")
assert(rows.HYPER_BEAM.category == "special", "Hyper Beam registry category")
assert(rows.CUSTOM_FAKE.category == nil, "identity collision received canonical category")
assert(registry.patches.CUSTOM_FAKE == nil, "identity collision was patched")
assert(wraps["battle.overlay"] and type(wraps["battle.overlay"].fn) == "function",
  "Gold battle.overlay readout hook was not registered")

-- Gold has no TYPE/ slot.  The public overlay cuts a readable category title
-- into the move box's top border, leaving all four native move-name/PP rows
-- untouched.  Non-formula damage gets an explicit label instead of pretending
-- it uses the selected Attack/Special stat pair.
local overlayScreen = {
  phase = "moves", moveIndex = 1,
  game = { data = { moves = rows, type_chart = TYPE_CHART } },
  battle = { player = { moves = {
    {id="FIRE_PUNCH"},{id="SHADOW_BALL"},{id="SWORDS_DANCE"},
    {id="SEISMIC_TOSS"},{id="FISSURE"},{id="BIDE"},
  } } },
  playerMoves = function(self) return self.battle.player.moves end,
}
local function expectOverlayLabel(index, label, tx)
  overlayScreen.moveIndex = index
  overlayMarks = {}
  overlayRects = {}
  wraps["battle.overlay"].fn(function() end, overlayScreen)
  assert(#overlayMarks == 1 and overlayMarks[1].text == label
    and overlayMarks[1].tx == tx and overlayMarks[1].ty == 12,
    ("Gold readout label mismatch at slot %d: wanted %s"):format(index, label))
  assert(#overlayRects == 1 and overlayRects[1].mode == "fill"
    and overlayRects[1].x == 8 * 8 and overlayRects[1].y == 12 * 8
    and overlayRects[1].w == 10 * 8 and overlayRects[1].h == 8,
    ("Gold readout field width/anchor mismatch at slot %d: wanted 10 tiles"):format(index))
end
expectOverlayLabel(1, "PHYSICAL", 9)
expectOverlayLabel(2, "SPECIAL", 9)
expectOverlayLabel(3, "STATUS", 10)
expectOverlayLabel(4, "FIXED", 10)
expectOverlayLabel(5, "OHKO", 11)
expectOverlayLabel(6, "REACTIVE", 9)
-- The old gutter marker had to disappear during SELECT swapping.  The new
-- top-border title does not collide with Gold's native hollow row marker, so it
-- should remain visible while a slot is held.
overlayScreen.moveIndex = 2
overlayScreen.moveSwapIndex = 2
overlayMarks = {}
wraps["battle.overlay"].fn(function() end, overlayScreen)
assert(#overlayMarks == 1 and overlayMarks[1].text == "SPECIAL",
  "Gold readout disappeared during native SELECT move reordering")
overlayScreen.moveSwapIndex = nil
assert(wraps["battle.overlay"].priority == math.huge,
  "Gold readout wrapper must stay outermost for automatic Gen 3 UI inline capture")

-- Gen 3 Inspired UI v1.4.0 Gold move-panel compatibility.  This bridge does
-- not rely on battle.overlay, a foreign mod id, a hard-coded BattleState class,
-- or fixed screen coordinates.  It wraps the final render.hud chain, observes
-- the actual TYPE / PP text painted by the replacement move panel, and uses the
-- live Gold state (or, if that cursor is hidden, the selected move name the UI
-- itself renders) to add PHYSICAL / SPECIAL / STATUS on the same baseline.
local function resetUiDraws()
  overlayMarks, overlayRects, rawTextDraws = {}, {}, {}
end
local function findRaw(text)
  for _, row in ipairs(rawTextDraws) do
    if row.text == text then return row end
  end
  return nil
end

assert(wraps["render.hud"] and type(wraps["render.hud"].fn) == "function"
  and wraps["render.hud"].priority == math.huge,
  "Gold Gen 3 UI move-panel observer was not installed as outer render.hud wrapper")

local renderGame = {
  data = { moves = rows, type_chart = TYPE_CHART },
  stack = { top = function() return overlayScreen end },
}

-- Direct native/replacement state path: moveIndex + battle.player.moves.
overlayScreen.moveIndex = 1
resetUiDraws()
wraps["render.hud"].fn(function()
  love.graphics.print("FIRE PUNCH", 420, 650)
  love.graphics.print("TYPE", 450, 700)
  love.graphics.print("FIRE", 510, 700)
  love.graphics.print("PP 15 / 15", 900, 700)
end, renderGame, {})
local panelPhysical = assert(findRaw("PHYSICAL"),
  "Gen 3 UI render.hud observer did not draw PHYSICAL from live Gold state")
assert(panelPhysical.y == 700 and panelPhysical.x > 530 and panelPhysical.x < 900,
  "Gen 3 UI PHYSICAL was not placed in the observed TYPE/PP gap")

-- The category text must inherit the TYPE/type-value colour, not PP or any
-- lighter footer colour.  This mirrors Gen 3 UI v1.4.0, where TYPE WATER and
-- PP are visually dark but unrelated draw calls can leave a washed-out colour
-- active by the time our post-render injection runs.
resetUiDraws()
currentDrawColor = { 1, 1, 1, 1 }
wraps["render.hud"].fn(function()
  love.graphics.setColor(0.20, 0.22, 0.24, 1)
  love.graphics.print("FIRE PUNCH", 420, 650)
  love.graphics.print("TYPE", 450, 700)
  love.graphics.setColor(0.18, 0.20, 0.22, 1)
  love.graphics.print("FIRE", 510, 700)
  love.graphics.setColor(0.75, 0.75, 0.75, 1)
  love.graphics.print("PP 15 / 15", 900, 700)
end, renderGame, {})
local colorMatchedPhysical = assert(findRaw("PHYSICAL"),
  "Gen 3 UI colour-match probe did not draw PHYSICAL")
assert(colorMatchedPhysical.color
  and math.abs(colorMatchedPhysical.color[1] - 0.18) < 0.001
  and math.abs(colorMatchedPhysical.color[2] - 0.20) < 0.001
  and math.abs(colorMatchedPhysical.color[3] - 0.22) < 0.001,
  "Gen 3 UI category did not inherit the rendered move-type colour")
local firstGen3Diag = mod.exports.getDiagnostics().integrations.gen3Ui
assert(firstGen3Diag.detected == true and firstGen3Diag.runtimeDetected == true
  and firstGen3Diag.presentation == "gen3-render-hud-type-row"
  and firstGen3Diag.activation == "observed-type-pp-row",
  "Gold diagnostics did not record the successful observed TYPE/PP injection")

-- Text-derived fallback: replacement screen exposes no moveIndex/battle fields.
-- The selected detail is the LEFTMOST visible move name; the four-choice list
-- may render the same name again farther right.
local replacementState = { screenId = "Gen2BattleState" }
renderGame.stack.top = function() return replacementState end
resetUiDraws()
wraps["render.hud"].fn(function()
  love.graphics.print("SCRATCH", 410, 650)
  love.graphics.print("SCRATCH", 760, 650)
  love.graphics.print("LEER", 760, 675)
  love.graphics.print("TYPE", 450, 700)
  love.graphics.print("NORMAL", 510, 700)
  love.graphics.print("PP 32 / 35", 900, 700)
end, renderGame, {})
local scratchPhysical = assert(findRaw("PHYSICAL"),
  "Gen 3 UI visible move-name fallback did not resolve SCRATCH")
assert(scratchPhysical.y == 700 and scratchPhysical.x > 550 and scratchPhysical.x < 900,
  "SCRATCH category was not centered in the observed TYPE/PP gap")

-- SPECIAL category through the same replacement-screen fallback.
resetUiDraws()
wraps["render.hud"].fn(function()
  love.graphics.print("SHADOW BALL", 410, 650)
  love.graphics.print("TYPE", 450, 700)
  love.graphics.print("GHOST", 510, 700)
  love.graphics.print("PP 15 / 15", 900, 700)
end, renderGame, {})
assert(findRaw("SPECIAL"), "Gen 3 UI visible move-name fallback did not draw SPECIAL")

-- STATUS category.
resetUiDraws()
wraps["render.hud"].fn(function()
  love.graphics.print("SWORDS DANCE", 410, 650)
  love.graphics.print("TYPE", 450, 700)
  love.graphics.print("NORMAL", 510, 700)
  love.graphics.print("PP 20 / 20", 900, 700)
end, renderGame, {})
assert(findRaw("STATUS"), "Gen 3 UI visible move-name fallback did not draw STATUS")

-- Whole-row renderer: TYPE/type/PP may be emitted in one call.
resetUiDraws()
wraps["render.hud"].fn(function()
  love.graphics.print("SHADOW BALL", 410, 650)
  love.graphics.print("TYPE  GHOST                              PP 15 / 15", 450, 700)
end, renderGame, {})
assert(findRaw("SPECIAL"), "Gen 3 UI whole-row move footer did not draw SPECIAL")

-- Future native category support must not be duplicated.
resetUiDraws()
wraps["render.hud"].fn(function()
  love.graphics.print("SHADOW BALL", 410, 650)
  love.graphics.print("TYPE  GHOST      SPECIAL                 PP 15 / 15", 450, 700)
end, renderGame, {})
local specialCount = 0
for _, row in ipairs(rawTextDraws) do if row.text == "SPECIAL" then specialCount = specialCount + 1 end end
assert(specialCount == 0, "Gen 3 UI category was duplicated despite native category text")

-- Non-move HUDs have no TYPE+PP row and therefore receive no category text.
resetUiDraws()
wraps["render.hud"].fn(function()
  love.graphics.print("SOME OTHER HUD", 450, 700)
end, renderGame, {})
assert(not findRaw("PHYSICAL") and not findRaw("SPECIAL") and not findRaw("STATUS"),
  "move category leaked outside a TYPE/PP move footer")

-- LOVE interception must restore even when a downstream HUD renderer throws.
local originalPrintAfterTests = love.graphics.print
local originalPrintfAfterTests = love.graphics.printf
local okRestore = pcall(function()
  wraps["render.hud"].fn(function() error("GEN3_RENDER_SENTINEL") end, renderGame, {})
end)
assert(not okRestore, "Gen 3 renderer error sentinel did not propagate")
assert(love.graphics.print == originalPrintAfterTests and love.graphics.printf == originalPrintfAfterTests,
  "Gen 3 UI render.hud text interception leaked after downstream error")

local gen3Diag = mod.exports.getDiagnostics().integrations.gen3Ui
assert(gen3Diag.detected == true and gen3Diag.runtimeDetected == true,
  "Gold diagnostics lost Gen 3 UI move-panel detection")
resetUiDraws()

local attacker = { level=50, stats={attack=500, specialAttack=20}, types={"NORMAL"} }
local defender = { stats={defense=20, specialDefense=500}, types={"NORMAL"} }
local battle = setmetatable({
  data={moves=rows, type_chart=TYPE_CHART},
  player={_volatile={usedMoves={"FIRE_PUNCH","SHADOW_BALL"},lastMove="SHADOW_BALL"}},
}, {__index=Battle})

-- FIRE is special by native Gold type, but Fire Punch is physical by move.
local damage, info = battle:hitOnce(attacker, defender, rows.FIRE_PUNCH, {moveId="FIRE_PUNCH"})
assert(info.kind == "physical", "Fire Punch damage kind did not flip physical")
assert(info.screenKind == "reflect", "Fire Punch screen routing did not flip physical")
assert(info.physical == true and damage > 100, "Fire Punch did not use Attack/Defense")

-- GHOST is physical by native Gold type, but Shadow Ball is special by move.
local shadowDamage, shadowInfo = battle:hitOnce(attacker, defender, rows.SHADOW_BALL, {moveId="SHADOW_BALL"})
assert(shadowInfo.kind == "special", "Shadow Ball damage kind did not flip special")
assert(shadowInfo.screenKind == "lightScreen", "Shadow Ball screen routing did not flip special")
assert(shadowInfo.physical == false and shadowDamage < 10, "Shadow Ball did not use SpA/SpD")

-- Custom index collision falls back to native Gold type classification.
local customDamage, customInfo = battle:hitOnce(attacker, defender, rows.CUSTOM_FAKE, {moveId="CUSTOM_FAKE"})
assert(customInfo.kind == "special" and customInfo.screenKind == "lightScreen",
  "custom index collision inherited canonical Fire Punch category")
assert(customDamage < 10, "custom index collision did not use native Gold special FIRE")

-- Scoped override must restore even when the underlying hit raises.
local throwDef={id="FIRE_PUNCH",index=7,name="Fire Punch",type="FIRE",power=75,throwForRestoreTest=true}
local ok, err = pcall(battle.hitOnce, battle, attacker, defender, throwDef, {moveId="FIRE_PUNCH"})
assert(not ok and tostring(err):find("RESTORE_SENTINEL",1,true), "restore test did not raise sentinel")
assert(Damage.isPhysical("FIRE", TYPE_CHART.types) == false, "category scope leaked after error")

-- Smart AI history must use per-move category, while playerSpecialType remains native.
local smart = battle:smartAiState()
assert(smart.playerPhysicalMoves == 1 and smart.playerSpecialMoves == 1,
  "smart AI used-move category counts are inconsistent")
assert(smart.playerLastMoveSpecial == true, "smart AI last-move category not modern")
assert(smart.playerSpecialType == false, "native type heuristic was rewritten")

-- AI expected damage calls Damage.calc directly: bridge must still rank Fire Punch
-- with Attack/Defense rather than treating both FIRE moves as special.
local chosen = Ai.choose({
  moves={{id="FIRE_PUNCH",pp=15},{id="FLAMETHROWER",pp=15}},
  moveDef=function(id) return rows[id] end,
  attacker=attacker, defender=defender, typeChart=TYPE_CHART,
})
assert(chosen == "FIRE_PUNCH", "AI expected damage did not honor per-move category")
assert(Damage.isPhysical("FIRE", TYPE_CHART.types) == false, "AI category scope leaked")

-- Gold's Special Stats option is requested config only; effective gameplay is native Gen II.
local diag = mod.exports.getDiagnostics()
assert(diag.generation == "gold", "Gold diagnostics generation")
assert(diag.requested.specialStats == "gen2", "requested special config")
assert(diag.effective.specialStats == "native_gen2", "effective Gold special config")
assert(diag.gold.gen1StatBackendInstalled == false, "Gen1 stat backend installed on Gold")
local mon={stats={specialAttack=111,specialDefense=222}}
assert(mod.exports.attachSplitStats(mon) == mon, "legacy attachSplitStats did not no-op on Gold")
assert(mon.stats.specialAttack==111 and mon.stats.specialDefense==222, "Gold native stats were overwritten")
local nativeBase=mod.exports.getEffectiveSpecialBaseStats({specialAttack=105,specialDefense=95})
assert(nativeBase.specialAttack==105 and nativeBase.specialDefense==95, "API v2 native special stats")
assert(mod.exports.specialStatSplit.apiVersion==1, "legacy API v1 changed")
assert(mod.exports.specialStatSplitV2.apiVersion==2, "Gold API v2 missing")
assert(links.rows.special_stat_split_rules.rev == "special=native_gen2;move=gen4", "Gold effective link revision")

-- Same Gold gameplay fingerprint for requested VANILLA/GEN II special mode.
local modVanilla, _, _, linksVanilla = makeMod("vanilla", "gen4", baseRows())
entry(modVanilla)
assert(linksVanilla.rows.special_stat_split_rules.rev == links.rows.special_stat_split_rules.rev,
  "Gold no-op special setting created false link mismatch")
assert(modVanilla.exports.getDiagnostics().effective.specialStats == "native_gen2",
  "Gold VANILLA requested setting changed native special model")

-- Hot reload to type-based mode disables bridge and clears explicit canonical categories.
local typeRows=baseRows()
for _, row in pairs(typeRows) do
  if row.id ~= "CUSTOM_FAKE" then row.category="physical" end
end
local modType, _, typeRegistry, typeLinks, _, _, typeWraps = makeMod("gen2", "gen1", typeRows)
entry(modType)
assert(typeRows.FIRE_PUNCH.category == nil and typeRows.SHADOW_BALL.category == nil,
  "type-based Gold mode did not clear explicit canonical categories")
assert(typeRegistry.patches.CUSTOM_FAKE == nil, "type mode patched identity collision")
local typeBattle=setmetatable({data={moves=typeRows,type_chart=TYPE_CHART},player={_volatile={}}},{__index=Battle})
local _, typeInfo=typeBattle:hitOnce(attacker,defender,typeRows.FIRE_PUNCH,{moveId="FIRE_PUNCH"})
assert(typeInfo.kind=="special" and typeInfo.screenKind=="lightScreen",
  "Gold type-based mode did not delegate to native FIRE category")
local _, ghostTypeInfo=typeBattle:hitOnce(attacker,defender,typeRows.SHADOW_BALL,{moveId="SHADOW_BALL"})
assert(ghostTypeInfo.kind=="physical", "Gold type-based GHOST category was not native")
assert(typeLinks.rows.special_stat_split_rules.rev == "special=native_gen2;move=type_gen2",
  "Gold type-based effective link revision")
local typeOverlayScreen = {
  phase = "moves", moveIndex = 1,
  game = { data = { moves = typeRows, type_chart = TYPE_CHART } },
  battle = { player = { moves = {{id="FIRE_PUNCH"}} } },
  playerMoves = function(self) return self.battle.player.moves end,
}
overlayMarks = {}
overlayRects = {}
typeWraps["battle.overlay"].fn(function() end, typeOverlayScreen)
assert(#overlayMarks == 1 and overlayMarks[1].text == "SPECIAL"
  and overlayMarks[1].tx == 9 and overlayMarks[1].ty == 12,
  "Gold type-based readout did not use native FIRE special category")
assert(#overlayRects == 1 and overlayRects[1].x == 8 * 8
  and overlayRects[1].w == 10 * 8,
  "Gold type-based SPECIAL readout did not keep the normalized 10-tile field")
assert(modType.exports.getDiagnostics().gold.categoryConsumers.readout == "covered-public-overlay+gen3-inline",
  "Gold diagnostics did not report public-overlay readout coverage")

print("special_stat_split Gold backend contract: PASS")
