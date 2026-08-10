-- Integration contract against exact frozen Gen1Recomp core source files.
-- Usage: texlua tests/frozen_upstream_contract.lua /path/to/gen1recomp-root
local root = assert(arg[1], "pass frozen Gen1Recomp root")
local MODE = arg[2] or "gen2"
package.path = "./?.lua;./?/init.lua;" .. package.path

local function expect(cond, msg)
  if not cond then error("ASSERT: " .. tostring(msg), 2) end
end
local function deepcopy(v, seen)
  if type(v) ~= "table" then return v end
  seen = seen or {}
  if seen[v] then return seen[v] end
  local out = {}; seen[v] = out
  for k, x in pairs(v) do out[deepcopy(k, seen)] = deepcopy(x, seen) end
  return out
end
local function loadFrozen(rel)
  local chunk, err = loadfile(root .. "/" .. rel)
  assert(chunk, err)
  return chunk()
end

-- Minimal environment needed by exact upstream Stats/Damage/Experience.
love = {
  math = { random = function(a, b) return b or a end },
  graphics = {
    setColor=function() end, rectangle=function() end,
  },
}
local Runtime = {
  wantsHook=function() return false end,
  wants=function() return false end,
  call=function(_, fallback, ctx) return fallback(ctx) end,
  emit=function() end,
}
local Logger = { warn=function() end }
local Status = { recordFor=function() return nil end }
local TypeChart = {
  category=function(t) return (t == "PSYCHIC_TYPE" or t == "FIRE_TYPE" or t == "WATER_TYPE" or t == "ELECTRIC_TYPE" or t == "GRASS_TYPE" or t == "ICE_TYPE" or t == "DRAGON_TYPE") and "special" or "physical" end,
  effectiveness=function() return 10 end,
  rows=function() return {} end,
}
local Growth = {
  levelForExp=function(_, _, cap) return math.min(50, cap or 100) end,
  expForLevel=function(_, level) return level * 1000 end,
}
package.preload["src.mods.Runtime"] = function() return Runtime end
package.preload["src.core.Logger"] = function() return Logger end
package.preload["src.battle.Status"] = function() return Status end
package.preload["src.battle.TypeChart"] = function() return TypeChart end
package.preload["src.pokemon.Growth"] = function() return Growth end
local function fmt(s, ...)
  if select("#", ...) == 0 then return s end
  local ok, out = pcall(string.format, s, ...)
  return ok and out or s
end
local Strings = setmetatable({source=function(s) return s end}, {__call=function(_, s, ...) return fmt(s, ...) end})
local romText = function(_, _, fallback, ...) return fmt(fallback, ...) end
package.preload["src.core.Strings"] = function() return Strings end
package.preload["src.core.RomText"] = function() return romText end
package.preload["src.battle.StatusRegistry"] = function() return {inflict=function() return {} end} end
package.preload["src.battle.TurnOrder"] = function() return {effectiveSpeed=function(b) return b.curStats and b.curStats.speed or 1 end} end
package.preload["src.script.Flags"] = function() return {get=function() return false end} end
package.preload["src.world.PikachuFollower"] = function() return {modifyHappiness=function() end} end

local Stats = loadFrozen("src/pokemon/Stats.lua")
package.preload["src.pokemon.Stats"] = function() return Stats end
local Damage = loadFrozen("src/battle/Damage.lua")
package.preload["src.battle.Damage"] = function() return Damage end
local Experience = loadFrozen("src/battle/Experience.lua")
package.preload["src.battle.Experience"] = function() return Experience end

-- Load exact frozen MoveEffects and ItemEffects too; only rendering/save are stubbed.
local MoveEffects = loadFrozen("src/battle/MoveEffects.lua")
package.preload["src.battle.MoveEffects"] = function() return MoveEffects end
local ItemEffects = loadFrozen("src/inventory/ItemEffects.lua")
package.preload["src.inventory.ItemEffects"] = function() return ItemEffects end
local SummaryMenu = { draw=function() end }
local BattleState = { StatBox={draw=function() end} }
local Font = { drawBox=function() end, draw=function() end }
local SaveData = { save=function() return true end }
package.preload["src.ui.SummaryMenu"] = function() return SummaryMenu end
package.preload["src.battle.BattleState"] = function() return BattleState end
package.preload["src.render.Font"] = function() return Font end
package.preload["src.core.SaveData"] = function() return SaveData end

-- Capture exact upstream functions before the mod wraps them.
local upstreamCalc = Stats.calc
local upstreamEnsure = Stats.ensure
local upstreamDamage = Damage.compute
local upstreamExperience = Experience.apply

local patchedEffects = {}
local mod = {
  options={define=function() end, get=function(_, k) if k=="mode" then return MODE == "vanilla" and "vanilla" or "gen2" end end},
  content={move_effects={patch=function(_, id, rec) patchedEffects[id]=rec end}},
  exports={},
}
assert(loadfile("main.lua"))()(mod)

local alakazam = {id="ALAKAZAM", dex=65, name="ALAKAZAM", baseExp=186,
  baseStats={hp=55,attack=50,defense=45,speed=120,special=135}, growthRate="MEDIUM_SLOW", learnset={}}
local chansey = {id="CHANSEY", dex=113, name="CHANSEY", baseExp=255,
  baseStats={hp=250,attack=5,defense=5,speed=50,special=105}, growthRate="FAST", learnset={}}
local dvs={attack=7,defense=7,speed=7,special=10}
local statExp={hp=1000,attack=1000,defense=1000,speed=1000,special=10000}
local aStats=Stats.calc(alakazam,50,dvs,statExp)
local dStats=Stats.calc(chansey,50,dvs,statExp)

if MODE == "vanilla" then
  local cleanA=upstreamCalc(alakazam,50,dvs,statExp)
  local cleanD=upstreamCalc(chansey,50,dvs,statExp)
  for _,k in ipairs({"hp","attack","defense","speed","special"}) do
    expect(aStats[k]==cleanA[k] and dStats[k]==cleanD[k], "VANILLA Stats.calc parity "..k)
  end
  expect(aStats.specialAttack==nil and aStats.specialDefense==nil, "VANILLA adds no split fields")

  local rules={critUsesBaseSpeed=true,focusEnergyBug=true,oneIn256Miss=true,critIgnoresStages=true,randMin=217,randMax=255}
  local rng=function(_,hi) return hi end
  local a={mon={level=50,status=nil},def=alakazam,curStats=deepcopy(aStats),curTypes={"PSYCHIC_TYPE"},stages={special=2},badges={}}
  local d={mon={level=50,status=nil},def=chansey,curStats=deepcopy(dStats),curTypes={"NORMAL_TYPE"},stages={special=-1},badges={},lightScreen=true}
  for _,move in ipairs({
    {id="PSYCHIC",type="PSYCHIC_TYPE",category="special",power=90,accuracy=100},
    {id="BODY_SLAM",type="NORMAL_TYPE",category="physical",power=85,accuracy=100},
  }) do
    local aa,dd=deepcopy(a),deepcopy(d)
    local got,gm=Damage.compute(rules,a,d,move,{forceCrit=false,rng=rng})
    local want,wm=upstreamDamage(rules,aa,dd,move,{forceCrit=false,rng=rng})
    expect(got==want and gm.crit==wm.crit and gm.typeMult==wm.typeMult, "VANILLA exact Damage parity "..move.id)
  end

  local mon={species="ALAKAZAM",level=50,exp=100000,hp=aStats.hp,dvs=dvs,
    statExp={hp=0,attack=0,defense=0,speed=0,special=0},stats=deepcopy(aStats)}
  local data={pokemon={ALAKAZAM=alakazam},constants={levelCap=100},growth_rates={}}
  upstreamExperience(data,deepcopy(mon),chansey,50,false,1,false)
  Experience.apply(data,mon,chansey,50,false,1,false)
  expect(mon.statExp.special==105, "VANILLA Experience retains defeated legacy Special base")

  local xdata={items={X_SPECIAL={name="X SPECIAL"}},pokemon={ALAKAZAM=alakazam},moves={}}
  local xsave={player={name="RED",id=1},party={}}
  local battle={player={name="ALAKAZAM",mon=mon,stages={special=4}}}
  local result=ItemEffects.use(xdata,xsave,"X_SPECIAL",nil,battle)
  expect(result=="consumed" and battle.player.stages.special==5 and battle.player.stages.specialAttack==nil,
    "VANILLA X Special retains legacy Special stage")

  local user={name="USER",isPlayer=true,mon={stats={hp=100},status=nil},stages={special=1}}
  local target={name="TARGET",isPlayer=false,mon={status=nil},stages={special=-1}}
  local ctx={battle={rng=function() return 0 end,data={}},user=user,target=target,move={id="PSYCHIC"}}
  patchedEffects.SPECIAL_UP1_EFFECT.run(ctx)
  expect(user.stages.special==2 and user.stages.specialAttack==nil, "VANILLA Growth legacy path")
  patchedEffects.SPECIAL_DOWN_SIDE_EFFECT.run(ctx)
  expect(target.stages.special==-2 and target.stages.specialDefense==nil, "VANILLA Psychic legacy path")

  print("FROZEN UPSTREAM VANILLA PARITY CONTRACT: PASS")
  os.exit(0)
end

expect(aStats.specialAttack and aStats.specialDefense, "exact Stats.calc wrapper attaches split stats")
expect(dStats.specialAttack and dStats.specialDefense, "defender split stats attached")

-- Exact frozen Stats.applyStage table remains untouched.
local stageExpected={[-6]=25,[-5]=28,[-4]=33,[-3]=40,[-2]=50,[-1]=66,[0]=100,[1]=150,[2]=200,[3]=250,[4]=300,[5]=350,[6]=400}
for s=-6,6 do expect(Stats.applyStage(100,s)==stageExpected[s], "upstream stage "..s) end

local rulesFaithful={critUsesBaseSpeed=true,focusEnergyBug=true,oneIn256Miss=true,critIgnoresStages=true,randMin=217,randMax=255}
local rulesModern={critUsesBaseSpeed=true,focusEnergyBug=false,oneIn256Miss=false,critIgnoresStages=false,randMin=217,randMax=255}
local rngMax=function(_, hi) return hi end
local moveSpecial={id="PSYCHIC",type="PSYCHIC_TYPE",category="special",power=90,accuracy=100}
local movePhysical={id="BODY_SLAM",type="NORMAL_TYPE",category="physical",power=85,accuracy=100}

local function battlers(aStage,dStage)
  local a={mon={level=50,status=nil,dvs=dvs,statExp=statExp},def=alakazam,curStats=deepcopy(aStats),curTypes={"PSYCHIC_TYPE"},stages={special=4,specialAttack=aStage or 0},badges={}}
  local d={mon={level=50,status=nil,dvs=dvs,statExp=statExp},def=chansey,curStats=deepcopy(dStats),curTypes={"NORMAL_TYPE"},stages={special=-4,specialDefense=dStage or 0},badges={}}
  return a,d
end
local function manualSplitBaseline(rules,a,d,move,opts)
  local aa,dd=deepcopy(a),deepcopy(d)
  aa.curStats.special=aa.curStats.specialAttack
  dd.curStats.special=dd.curStats.specialDefense
  aa.stages.special=aa.stages.specialAttack or 0
  dd.stages.special=dd.stages.specialDefense or 0
  return upstreamDamage(rules,aa,dd,move,opts)
end

-- Multiple exact upstream pathways: stages, screen, badges, crit rulesets.
local cases={
  {name="neutral",rules=rulesFaithful,as=0,ds=0,opts={forceCrit=false,rng=rngMax}},
  {name="stages",rules=rulesFaithful,as=2,ds=-1,opts={forceCrit=false,rng=rngMax}},
  {name="light_screen",rules=rulesFaithful,as=0,ds=0,screen=true,opts={forceCrit=false,rng=rngMax}},
  {name="volcano_both",rules=rulesFaithful,as=1,ds=1,badges=true,opts={forceCrit=false,rng=rngMax}},
  {name="faithful_crit",rules=rulesFaithful,as=6,ds=-6,screen=true,badges=true,opts={forceCrit=true,rng=rngMax}},
  {name="modern_crit",rules=rulesModern,as=2,ds=-1,screen=true,badges=true,opts={forceCrit=true,rng=rngMax}},
}
for _,c in ipairs(cases) do
  local a,d=battlers(c.as,c.ds)
  if c.screen then d.lightScreen=true end
  if c.badges then a.badges.VOLCANOBADGE=true; d.badges.VOLCANOBADGE=true end
  local beforeAS, beforeDS=a.curStats.special,d.curStats.special
  local beforeAStage,beforeDStage=a.stages.special,d.stages.special
  local got,gm=Damage.compute(c.rules,a,d,moveSpecial,c.opts)
  local want,wm=manualSplitBaseline(c.rules,a,d,moveSpecial,c.opts)
  expect(got==want, c.name.." damage matches exact frozen Damage.compute with manual SpA/SpD substitution: "..got.." vs "..want)
  expect(gm.crit==wm.crit and gm.typeMult==wm.typeMult, c.name.." metadata preserved")
  expect(a.curStats.special==beforeAS and d.curStats.special==beforeDS, c.name.." stat restore")
  expect(a.stages.special==beforeAStage and d.stages.special==beforeDStage, c.name.." stage restore")
end

-- Physical wrapper must be exactly transparent compared with pre-patch frozen function.
do
  local a,d=battlers(3,-2)
  local aa,dd=deepcopy(a),deepcopy(d)
  local got,gm=Damage.compute(rulesFaithful,a,d,movePhysical,{forceCrit=false,rng=rngMax})
  local want,wm=upstreamDamage(rulesFaithful,aa,dd,movePhysical,{forceCrit=false,rng=rngMax})
  expect(got==want and gm.crit==wm.crit and gm.typeMult==wm.typeMult, "physical path exact frozen parity")
end

-- Existing save mon with legacy stats only: exact upstream ensure would leave it as-is;
-- mod wrapper must derive split fields without replacing vanilla fields.
do
  local legacy=upstreamCalc(alakazam,50,dvs,statExp)
  local mon={species="ALAKAZAM",level=50,dvs=dvs,statExp=statExp,stats=legacy,hp=legacy.hp}
  local same=Stats.ensure(alakazam,mon)
  expect(same==mon and mon.stats==legacy, "old-save stats table identity preserved")
  expect(mon.stats.specialAttack and mon.stats.specialDefense, "old-save gets derived fields on ensure")
end

-- Box-style mon with no stats: upstream ensure computes once, wrapper adds split fields.
do
  local mon={species="CHANSEY",level=50,dvs=dvs,statExp=statExp,hp=999}
  Stats.ensure(chansey,mon)
  expect(mon.stats and mon.stats.specialAttack and mon.stats.specialDefense, "box mon ensure split fields")
  expect(mon.hp<=mon.stats.hp, "upstream HP clamp preserved")
end

-- Exact frozen Experience.apply should see base SpA in its existing Stats.ORDER "special" slot.
do
  local monStats=Stats.calc(alakazam,50,dvs,{hp=0,attack=0,defense=0,speed=0,special=0})
  local mon={species="ALAKAZAM",level=50,exp=100000,hp=monStats.hp,dvs=dvs,
    statExp={hp=0,attack=0,defense=0,speed=0,special=0},stats=monStats}
  local data={pokemon={ALAKAZAM=alakazam},constants={levelCap=100},growth_rates={}}
  local oldBase=chansey.baseStats.special
  Experience.apply(data,mon,chansey,50,false,1,false)
  expect(mon.statExp.special==35, "exact frozen Experience.apply awards defeated Gen II base SpA")
  expect(chansey.baseStats.special==oldBase, "species legacy base special restored after Experience.apply")
end


-- Exact frozen MoveEffects routing, cap behavior, Mist quirk and Haze reset.
do
  local battle={rng=function() return 0 end,data={},speciesSprite=function() return nil end}
  local user={name="USER",isPlayer=true,mon={stats={hp=100},species="ALAKAZAM",status=nil},
    curStats={attack=50,defense=50,speed=100,special=120,specialAttack=140,specialDefense=80},
    curTypes={"PSYCHIC_TYPE"},curMoves={},stages={special=5,specialAttack=5,specialDefense=5}}
  local target={name="TARGET",isPlayer=false,mon={species="CHANSEY",status=nil},
    curStats={attack=5,defense=5,speed=50,special=105,specialAttack=35,specialDefense=105},
    curTypes={"NORMAL_TYPE"},curMoves={},stages={special=-5,specialDefense=-5},mist=true}
  local ctx={battle=battle,user=user,target=target,move={id="PSYCHIC",type="PSYCHIC_TYPE"}}
  patchedEffects.SPECIAL_UP1_EFFECT.run(ctx)
  expect(user.stages.specialAttack==6 and user.stages.special==5, "exact Growth -> SpA and caps at +6")
  patchedEffects.SPECIAL_UP1_EFFECT.run(ctx)
  expect(user.stages.specialAttack==6, "exact Growth remains capped +6")
  patchedEffects.SPECIAL_UP2_EFFECT.run(ctx)
  expect(user.stages.specialDefense==6 and user.stages.special==5, "exact Amnesia -> SpD and caps +6")
  patchedEffects.SPECIAL_DOWN_SIDE_EFFECT.run(ctx)
  expect(target.stages.specialDefense==-6 and target.stages.special==-5, "exact Psychic drop -> SpD and pierces Mist")
  patchedEffects.SPECIAL_DOWN_SIDE_EFFECT.run(ctx)
  expect(target.stages.specialDefense==-6, "exact Psychic drop remains capped -6")

  -- Haze itself needs no patch: exact upstream replaces the whole stage tables.
  user.stages.specialAttack=3; user.stages.specialDefense=-2
  target.stages.specialAttack=-1; target.stages.specialDefense=4
  MoveEffects.RECORDS.HAZE_EFFECT.run(ctx)
  expect(next(user.stages)==nil and next(target.stages)==nil, "exact Haze clears both split stages naturally")

  -- Transform: exact upstream copies stage table; mod adds both current split stats.
  target.stages={specialAttack=2,specialDefense=-2}
  target.curMoves={{id="PSYCHIC",pp=10}}
  user.stages={}; user.curMoves={}
  patchedEffects.TRANSFORM_EFFECT.run(ctx)
  expect(user.curStats.specialAttack==35 and user.curStats.specialDefense==105, "exact Transform copies split stats")
  expect(user.stages.specialAttack==2 and user.stages.specialDefense==-2, "exact Transform copies split stages")

  -- Critical regression: Damage.compute must preserve Transform's copied
  -- SpA/SpD rather than recomputing them from the user's original species.
  -- Give the transformed user an original Alakazam identity so an accidental
  -- reattach would change copied SpA=35 into Alakazam SpA and fail loudly.
  user.mon.level=50; user.mon.dvs=dvs; user.mon.statExp=statExp
  user.def=alakazam; user.curTypes={"PSYCHIC_TYPE"}; user.badges={}
  target.mon.level=50; target.mon.dvs=dvs; target.mon.statExp=statExp
  target.def=chansey; target.badges={}; target.lightScreen=nil
  local copiedAtk=user.curStats.specialAttack
  local copiedDef=target.curStats.specialDefense
  local aa,dd=deepcopy(user),deepcopy(target)
  aa.curStats.special=aa.curStats.specialAttack
  dd.curStats.special=dd.curStats.specialDefense
  aa.stages.special=aa.stages.specialAttack or 0
  dd.stages.special=dd.stages.specialDefense or 0
  local want=upstreamDamage(rulesFaithful,aa,dd,moveSpecial,{forceCrit=false,rng=rngMax})
  local got=Damage.compute(rulesFaithful,user,target,moveSpecial,{forceCrit=false,rng=rngMax})
  expect(got==want, "Transform attacker subsequent special damage uses copied SpA")
  expect(user.curStats.specialAttack==copiedAtk, "Transform attacker copied SpA survives Damage.compute")
  expect(target.curStats.specialDefense==copiedDef, "Transform target copied SpD survives Damage.compute")

  -- Defender-side variant: a transformed defender's copied SpD must likewise
  -- survive the pre-damage ensure path even when defender.def is another species.
  local transDef=deepcopy(target)
  transDef.def=alakazam
  transDef.curStats.specialDefense=160
  transDef.curStats.specialAttack=70
  transDef.stages={specialDefense=1}
  local att=select(1,battlers(0,0))
  local maa,mdd=deepcopy(att),deepcopy(transDef)
  maa.curStats.special=maa.curStats.specialAttack
  mdd.curStats.special=mdd.curStats.specialDefense
  maa.stages.special=maa.stages.specialAttack or 0
  mdd.stages.special=mdd.stages.specialDefense or 0
  local wantDef=upstreamDamage(rulesFaithful,maa,mdd,moveSpecial,{forceCrit=false,rng=rngMax})
  local gotDef=Damage.compute(rulesFaithful,att,transDef,moveSpecial,{forceCrit=false,rng=rngMax})
  expect(gotDef==wantDef, "Transform defender subsequent special damage uses copied SpD")
  expect(transDef.curStats.specialDefense==160, "Transform defender copied SpD survives Damage.compute")
end

-- Exact frozen ItemEffects: X Special, Calcium and Rare Candy lifecycle.
do
  local data={
    items={X_SPECIAL={name="X SPECIAL"},CALCIUM={name="CALCIUM"},RARE_CANDY={name="RARE CANDY"}},
    pokemon={ALAKAZAM=alakazam}, moves={}
  }
  local save={player={name="RED",id=1},party={}}
  local bmon={species="ALAKAZAM",level=50,dvs=dvs,statExp=deepcopy(statExp),stats=Stats.calc(alakazam,50,dvs,statExp),hp=100,exp=100000,moves={}}
  local battle={player={name="ALAKAZAM",mon=bmon,stages={special=4,specialAttack=5}}}
  local result,msgs=ItemEffects.use(data,save,"X_SPECIAL",nil,battle)
  expect(result=="consumed" and battle.player.stages.specialAttack==6 and battle.player.stages.special==4, "exact X Special -> SpA")
  expect(msgs[1]:find("SP%. ATK")~=nil, "exact X Special message relabel")
  result=ItemEffects.use(data,save,"X_SPECIAL",nil,battle)
  expect(result=="consumed" and battle.player.stages.specialAttack==6, "exact X Special cap +6")

  local before=bmon.statExp.special
  result=ItemEffects.use(data,save,"CALCIUM",bmon,nil)
  expect(result=="consumed" and bmon.statExp.special==before+2560, "exact Calcium keeps shared Special Stat Exp")
  expect(bmon.stats.specialAttack and bmon.stats.specialDefense, "Calcium recalc restores both split derived stats")

  local oldLevel=bmon.level
  result=ItemEffects.use(data,save,"RARE_CANDY",bmon,nil)
  expect(result=="consumed" and bmon.level==oldLevel+1, "exact Rare Candy level-up")
  expect(bmon.stats.specialAttack and bmon.stats.specialDefense, "Rare Candy recalc restores both split stats")
end

print("FROZEN UPSTREAM STATS/DAMAGE/EXPERIENCE/MOVEEFFECTS/ITEMEFFECTS CONTRACT: PASS")
