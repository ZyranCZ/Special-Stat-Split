-- Integration contract against the exact frozen Gen1Recomp Fingerprint.lua.
-- Usage: texlua tests/frozen_link_fingerprint_contract.lua /path/to/gen1recomp-root
local root = assert(arg[1], "pass frozen Gen1Recomp root")
package.path = "./?.lua;./?/init.lua;" .. package.path

package.preload["src.mods.Runtime"] = function()
  return {
    call = function(_, fallback, ...)
      return fallback(...)
    end,
  }
end

local chunk, err = loadfile(root .. "/src/link/Fingerprint.lua")
assert(chunk, err)
local Fingerprint = chunk()
assert(type(Fingerprint) == "table" and type(Fingerprint.compute) == "function",
  "frozen Fingerprint API unavailable")

local mods = {{ id = "special_stat_split", version = "2.6.3", affectsLink = true }}
local function data(rev)
  return { link_fields = { special_stat_split_rules = { rev = rev } } }
end

local a = Fingerprint.compute(data("special=gen2;move=gen4"), mods)
local b = Fingerprint.compute(data("special=vanilla;move=gen4"), mods)
local c = Fingerprint.compute(data("special=gen2;move=gen1"), mods)
local d = Fingerprint.compute(data("special=gen2;move=gen4"), mods)

assert(a ~= b, "Special-stat gameplay mismatch must change upstream fingerprint")
assert(a ~= c, "Move-category gameplay mismatch must change upstream fingerprint")
assert(a == d, "Identical gameplay revision must produce identical upstream fingerprint")
print("FROZEN UPSTREAM LINK CONFIG FINGERPRINT CONTRACT: PASS")
