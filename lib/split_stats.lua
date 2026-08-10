-- Pure helpers for Gen II-style Special Attack / Special Defense.
-- This module deliberately keeps the original Gen I Special DV and Special Stat Exp shared.
local Gen2 = require("data.gen2_special_stats")

local M = {}

local function calcOne(base, dv, statExp, level)
  local ev = math.floor(math.min(255, math.ceil(math.sqrt(statExp or 0))) / 4)
  return math.floor(((base + (dv or 0)) * 2 + ev) * level / 100) + 5
end

M.calcOne = calcOne

function M.baseFor(speciesDef)
  if type(speciesDef) ~= "table" then return nil end
  local row = speciesDef.id and Gen2.byId[speciesDef.id]
  if not row and speciesDef.dex then row = Gen2.byDex[speciesDef.dex] end
  return row
end

function M.calculate(speciesDef, level, dvs, statExp, vanillaSpecial)
  local row = M.baseFor(speciesDef)
  if not row then
    return vanillaSpecial, vanillaSpecial
  end
  dvs = dvs or {}
  statExp = statExp or {}
  local dv = dvs.special or 0
  local exp = statExp.special or 0
  return calcOne(row.spa, dv, exp, level),
         calcOne(row.spd, dv, exp, level)
end

function M.attach(stats, speciesDef, level, dvs, statExp)
  if type(stats) ~= "table" then return stats end
  local spa, spd = M.calculate(speciesDef, level, dvs, statExp, stats.special)
  stats.specialAttack = spa
  stats.specialDefense = spd
  return stats
end

return M
