-- Exact frozen SaveData.save integration: verify derived split stats never enter serialized progress data.
-- Usage: texlua tests/frozen_save_contract.lua /path/to/gen1recomp-root
local root=assert(arg[1],"pass frozen root")
package.path="./?.lua;./?/init.lua;"..package.path
local function expect(c,m) if not c then error("ASSERT: "..m,2) end end
local function deepcopy(v,s)
  if type(v)~="table" then return v end; s=s or {}; if s[v] then return s[v] end
  local o={}; s[v]=o; for k,x in pairs(v) do o[deepcopy(k,s)]=deepcopy(x,s) end; return o
end
local function loadFrozen(rel) local f,e=loadfile(root.."/"..rel); assert(f,e); return f() end

local files={}
love={
  math={random=function(a,b) return b or a end},
  filesystem={
    getInfo=function(n) return files[n] and {type="file"} or nil end,
    read=function(n) return files[n] end,
    write=function(n,b) files[n]=b; return true end,
    remove=function(n) files[n]=nil; return true end,
    createDirectory=function() return true end,
    getSource=function() return nil end,
    getSourceBaseDirectory=function() return nil end,
  },
  system={getOS=function() return "Linux" end},
  graphics={setColor=function() end,rectangle=function() end},
}
local Logger={warn=function() end,error=function() end,info=function() end}
local Runtime={wantsHook=function() return false end,wants=function() return false end,emit=function() end}
local captured
local Serializer={
  encode=function(t) captured=deepcopy(t); return "ENCODED" end,
  decode=function() return nil,"empty" end,
}
local GameVersion={get=function() return "red" end,saveSuffix=function() return "" end,info=function(v) return v=="red" and {} or nil end}
package.preload["src.core.Logger"]=function() return Logger end
package.preload["src.core.Version"]=function() return {saveFormat=4,engine="0.1.75"} end
package.preload["src.core.SaveSerializer"]=function() return Serializer end
package.preload["src.mods.Runtime"]=function() return Runtime end
package.preload["src.mods.Semver"]=function() return {compare=function() return 0 end} end
package.preload["src.pokemon.Boxes"]=function() return {ensure=function() end,deposit=function() return 1 end} end
package.preload["src.inventory.Bag"]=function() return {add=function() return true end} end
package.preload["src.inventory.Badges"]=function() return {count=function() return 0 end} end
package.preload["src.core.GameVersion"]=function() return GameVersion end

local Stats=loadFrozen("src/pokemon/Stats.lua")
local upstreamCalc=Stats.calc
package.preload["src.pokemon.Stats"]=function() return Stats end
local SaveData=loadFrozen("src/core/SaveData.lua")
package.preload["src.core.SaveData"]=function() return SaveData end

-- Other main.lua modules are irrelevant to this save contract.
local Damage={compute=function() return 1,{crit=false,typeMult=10} end}
local Experience={apply=function() return {},0 end}
local ItemEffects={use=function() return "kept",{} end}
local MoveEffects={RECORDS={}}
local SummaryMenu={draw=function() end}; local BattleState={StatBox={draw=function() end}}
local Strings=setmetatable({}, {__call=function(_,s) return s end})
package.preload["src.battle.Damage"]=function() return Damage end
package.preload["src.battle.Experience"]=function() return Experience end
package.preload["src.inventory.ItemEffects"]=function() return ItemEffects end
package.preload["src.battle.MoveEffects"]=function() return MoveEffects end
package.preload["src.ui.SummaryMenu"]=function() return SummaryMenu end
package.preload["src.battle.BattleState"]=function() return BattleState end
package.preload["src.render.Font"]=function() return {drawBox=function() end,draw=function() end} end
package.preload["src.core.Strings"]=function() return Strings end
package.preload["src.battle.TypeChart"]=function() return {category=function() return "physical" end} end

local mod={options={define=function() end,get=function() return "gen2" end},content={move_effects={patch=function() end}},exports={}}
assert(loadfile("main.lua"))()(mod)

local alakazam={id="ALAKAZAM",dex=65,baseStats={hp=55,attack=50,defense=45,speed=120,special=135}}
local dvs={attack=7,defense=7,speed=7,special=10}
local se={hp=1000,attack=1000,defense=1000,speed=1000,special=10000}
local stats=Stats.calc(alakazam,50,dvs,se)
expect(stats.specialAttack and stats.specialDefense,"tracked split stats exist before save")
local save={
  version="red", meta={format=4,engine="0.1.75",mods={}},
  party={{species="ALAKAZAM",level=50,dvs=dvs,statExp=se,stats=stats}},
  unrelated={specialAttack=777,specialDefense=888},
}
-- Exact SaveData.validate old-save/box path: existing legacy stat table is preserved,
-- a box mon with no stats is derived, and both receive split fields through wrapped Stats.ensure.
local legacyStats=upstreamCalc(alakazam,50,dvs,se)
local oldParty={species="ALAKAZAM",level=50,dvs=dvs,statExp=se,stats=legacyStats,hp=legacyStats.hp,moves={}}
local boxMon={species="ALAKAZAM",level=50,dvs=dvs,statExp=se,hp=999,moves={}}
local validateSave={party={oldParty},boxes={{boxMon}},inventory={},pcItems={}}
local validateData={pokemon={ALAKAZAM=alakazam},moves={},items={},maps={},constants={}}
SaveData.validate(validateSave,validateData)
expect(oldParty.stats==legacyStats,"exact validate preserves existing old-save stats table identity")
expect(oldParty.stats.specialAttack and oldParty.stats.specialDefense,"exact validate derives split fields on old party save")
expect(boxMon.stats and boxMon.stats.specialAttack and boxMon.stats.specialDefense,"exact validate derives box-mon split fields")
expect(boxMon.hp<=boxMon.stats.hp,"exact validate preserves upstream HP clamp for box mon")

local ok=SaveData.save(save,nil)
expect(ok==true,"exact SaveData.save succeeds")
expect(captured and captured.party and captured.party[1],"serializer capture exists")
local diskStats=captured.party[1].stats
expect(diskStats.specialAttack==nil and diskStats.specialDefense==nil,"derived fields stripped before exact serializer")
expect(diskStats.special==stats.special,"legacy calculated Special remains serialized")
expect(captured.party[1].dvs.special==10 and captured.party[1].statExp.special==10000,"shared Special DV/StatExp schema unchanged")
expect(captured.unrelated.specialAttack==777 and captured.unrelated.specialDefense==888,"unrelated same-named fields not stripped")
expect(stats.specialAttack and stats.specialDefense,"derived fields restored in memory after exact save")
print("FROZEN UPSTREAM SAVEDATA SERIALIZATION CONTRACT: PASS")
