-- Exact frozen Pokemon.new + Evolution.apply lifecycle contract.
-- Usage: texlua tests/frozen_lifecycle_contract.lua /path/to/gen1recomp-root
local root=assert(arg[1],"pass frozen root")
package.path="./?.lua;./?/init.lua;"..package.path
local function expect(c,m) if not c then error("ASSERT: "..m,2) end end
local function loadFrozen(rel) local f,e=loadfile(root.."/"..rel); assert(f,e); return f() end
love={math={random=function(a,b) return b or a end},graphics={setColor=function() end,rectangle=function() end},image={}}
local Runtime={wantsHook=function() return false end,call=function(_,fallback,...) return fallback(...) end,emit=function() end}
local Growth={expForLevel=function(_,lv) return lv*1000 end}
local Strings=setmetatable({source=function(s) return s end},{__call=function(_,s,...) local ok,o=pcall(string.format,s,...); return ok and o or s end})
package.preload["src.mods.Runtime"]=function() return Runtime end
package.preload["src.pokemon.Growth"]=function() return Growth end
package.preload["src.core.Music"]=function() return {play=function() end,restoreMap=function() end,special=function() return nil end} end
package.preload["src.ui.Screens"]=function() return {push=function() end} end
package.preload["src.render.TextBox"]=function() return {new=function() return {} end} end
package.preload["src.core.Strings"]=function() return Strings end
package.preload["src.core.RomText"]=function() return function(_,_,fallback,...) local ok,o=pcall(string.format,fallback,...); return ok and o or fallback end end

local Stats=loadFrozen("src/pokemon/Stats.lua")
package.preload["src.pokemon.Stats"]=function() return Stats end
-- Main's unrelated integration surfaces.
package.preload["src.battle.Damage"]=function() return {compute=function() return 1,{crit=false,typeMult=10} end} end
package.preload["src.battle.Experience"]=function() return {apply=function() return {},0 end} end
package.preload["src.inventory.ItemEffects"]=function() return {use=function() return "kept",{} end} end
package.preload["src.battle.MoveEffects"]=function() return {RECORDS={}} end
package.preload["src.ui.SummaryMenu"]=function() return {draw=function() end} end
package.preload["src.battle.BattleState"]=function() return {StatBox={draw=function() end}} end
package.preload["src.render.Font"]=function() return {drawBox=function() end,draw=function() end} end
package.preload["src.core.SaveData"]=function() return {save=function() return true end} end
package.preload["src.battle.TypeChart"]=function() return {category=function() return "physical" end} end
local mod={options={define=function() end,get=function() return "gen2" end},content={move_effects={patch=function() end}},exports={}}
assert(loadfile("main.lua"))()(mod)

local Pokemon=loadFrozen("src/pokemon/Pokemon.lua")
package.preload["src.pokemon.Pokemon"]=function() return Pokemon end
local Evolution=loadFrozen("src/pokemon/Evolution.lua")

local kadabra={id="KADABRA",dex=64,name="KADABRA",growthRate="MEDIUM_SLOW",catchRate=100,
 baseStats={hp=40,attack=35,defense=30,speed=105,special=120},level1Moves={},learnset={},evolutions={}}
local alakazam={id="ALAKAZAM",dex=65,name="ALAKAZAM",growthRate="MEDIUM_SLOW",catchRate=50,
 baseStats={hp=55,attack=50,defense=45,speed=120,special=135},level1Moves={},learnset={},evolutions={}}
local data={pokemon={KADABRA=kadabra,ALAKAZAM=alakazam},moves={}}
local rng=function() return 10 end
local mon=Pokemon.new(data,"KADABRA",30,rng)
expect(mon.stats.specialAttack and mon.stats.specialDefense,"exact Pokemon.new gets split stats")
local oldSpa,oldSpd=mon.stats.specialAttack,mon.stats.specialDefense
local game={data=data,save={pokedex={seen={},owned={}}}}
Evolution.apply(game,mon,"ALAKAZAM","TRADE")
expect(mon.species=="ALAKAZAM","exact evolution species change")
expect(mon.stats.specialAttack and mon.stats.specialDefense,"exact Evolution.apply recalculates split stats")
expect(mon.stats.specialAttack~=oldSpa or mon.stats.specialDefense~=oldSpd,"evolution updates split base stats")
expect(game.save.pokedex.seen.ALAKAZAM and game.save.pokedex.owned.ALAKAZAM,"upstream evolution dex side effects preserved")
print("FROZEN UPSTREAM POKEMON/EVOLUTION LIFECYCLE CONTRACT: PASS")
