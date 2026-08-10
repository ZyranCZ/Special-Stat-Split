-- Contract tests intended to run inside a Gen1Recomp/Lua test environment.
local Gen2 = require("data.gen2_special_stats")
local Split = require("lib.split_stats")

assert(Gen2.byId.BUTTERFREE.spa == 80)
assert(Gen2.byId.ALAKAZAM.spa == 135 and Gen2.byId.ALAKAZAM.spd == 85)
assert(Gen2.byId.CHANSEY.spa == 35 and Gen2.byId.CHANSEY.spd == 105)
assert(Gen2.byId.MEWTWO.spa == 154 and Gen2.byId.MEWTWO.spd == 90)
assert(Gen2.byId.TOGETIC.spa == 80 and Gen2.byId.TOGETIC.spd == 105)
assert(Gen2.byId.ESPEON.spa == 130 and Gen2.byId.ESPEON.spd == 95)
assert(Gen2.byId.UMBREON.spa == 60 and Gen2.byId.UMBREON.spd == 130)
assert(Gen2.byId.BLISSEY.spa == 75 and Gen2.byId.BLISSEY.spd == 135)

local def = { id = "ALAKAZAM", dex = 65 }
local dvs = { special = 10 }
local exp = { special = 10000 }
local spa, spd = Split.calculate(def, 50, dvs, exp, 0)
assert(spa > spd)

-- One shared Special DV and one shared Special Stat Exp feed both calculations.
assert(spa == Split.calcOne(135, 10, 10000, 50))
assert(spd == Split.calcOne(85, 10, 10000, 50))

local togetic = { id = "TOGETIC", dex = 176 }
local tSpa, tSpd = Split.calculate(togetic, 50, dvs, exp, 0)
assert(tSpa == Split.calcOne(80, 10, 10000, 50))
assert(tSpd == Split.calcOne(105, 10, 10000, 50))
assert(tSpa ~= tSpd)

print("special_stat_split reference contracts: PASS")
