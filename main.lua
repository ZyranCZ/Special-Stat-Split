-- SPECIAL STAT SPLIT v2.6.5
-- Release build for Gen1Recomp commit 60cf07fb0a1ffce0ec6d5d0d2f78a921a6d0b7da.
--
-- Scope: Generation II Special stat split + Generation IV+ per-move damage categories + integrated move-category battle readout.
-- Each original Gen I move can be explicitly physical/special/status independent of type.
-- The original Gen1Recomp damage formula, RNG, type handling and rulesets are preserved.
--
-- RELEASE NOTE:
-- v2.0.0 passed automated/frozen contracts and user-reported in-game smoke.
-- v2.1.0 hardened category ownership/collision behavior.
-- v2.2.2 makes the mod-owned canonical #001-251 SpA/SpD table authoritative;
-- CRYSTAL_251 exports are only audited/fallback data. v2.2.0 added optional interoperability:
-- Sp. Atk/Sp. Def for all 251 species plus GEN IV+ per-move categories for all
-- 251 Crystal move slots, including Crystal's private damage-routing path.

local MOD_ID = "special_stat_split"
local PATCH_KEY = "__special_stat_split_dispatch_v1"
local MOVE_READOUT_PATCH_KEY = "__special_stat_split_move_category_readout_v1"
local unpack = table.unpack or unpack
local function pack(...) return { n = select("#", ...), ... } end

local function escapePattern(s)
  return (tostring(s):gsub("([^%w])", "%%%1"))
end

local function relabelMessages(messages, fromLabel, toLabel)
  if type(messages) ~= "table" then return messages end
  local pat = escapePattern(fromLabel)
  for i, msg in ipairs(messages) do
    if type(msg) == "string" then
      messages[i] = msg:gsub(pat, toLabel)
    end
  end
  return messages
end

-- Mod-local helpers/data are embedded in main.lua on purpose.
-- Gen1Recomp loads the manifest entry but does not add each mod directory
-- to Lua/LÖVE require paths, so mod-local library imports are not portable in packaged builds.
local GEN2_SPECIAL_BY_ID = {
  BULBASAUR = { dex = 1, spa = 65, spd = 65 },
  IVYSAUR = { dex = 2, spa = 80, spd = 80 },
  VENUSAUR = { dex = 3, spa = 100, spd = 100 },
  CHARMANDER = { dex = 4, spa = 60, spd = 50 },
  CHARMELEON = { dex = 5, spa = 80, spd = 65 },
  CHARIZARD = { dex = 6, spa = 109, spd = 85 },
  SQUIRTLE = { dex = 7, spa = 50, spd = 64 },
  WARTORTLE = { dex = 8, spa = 65, spd = 80 },
  BLASTOISE = { dex = 9, spa = 85, spd = 105 },
  CATERPIE = { dex = 10, spa = 20, spd = 20 },
  METAPOD = { dex = 11, spa = 25, spd = 25 },
  BUTTERFREE = { dex = 12, spa = 80, spd = 80 },
  WEEDLE = { dex = 13, spa = 20, spd = 20 },
  KAKUNA = { dex = 14, spa = 25, spd = 25 },
  BEEDRILL = { dex = 15, spa = 45, spd = 80 },
  PIDGEY = { dex = 16, spa = 35, spd = 35 },
  PIDGEOTTO = { dex = 17, spa = 50, spd = 50 },
  PIDGEOT = { dex = 18, spa = 70, spd = 70 },
  RATTATA = { dex = 19, spa = 25, spd = 35 },
  RATICATE = { dex = 20, spa = 50, spd = 70 },
  SPEAROW = { dex = 21, spa = 31, spd = 31 },
  FEAROW = { dex = 22, spa = 61, spd = 61 },
  EKANS = { dex = 23, spa = 40, spd = 54 },
  ARBOK = { dex = 24, spa = 65, spd = 79 },
  PIKACHU = { dex = 25, spa = 50, spd = 40 },
  RAICHU = { dex = 26, spa = 90, spd = 80 },
  SANDSHREW = { dex = 27, spa = 20, spd = 30 },
  SANDSLASH = { dex = 28, spa = 45, spd = 55 },
  NIDORAN_F = { dex = 29, spa = 40, spd = 40 },
  NIDORINA = { dex = 30, spa = 55, spd = 55 },
  NIDOQUEEN = { dex = 31, spa = 75, spd = 85 },
  NIDORAN_M = { dex = 32, spa = 40, spd = 40 },
  NIDORINO = { dex = 33, spa = 55, spd = 55 },
  NIDOKING = { dex = 34, spa = 85, spd = 75 },
  CLEFAIRY = { dex = 35, spa = 60, spd = 65 },
  CLEFABLE = { dex = 36, spa = 85, spd = 90 },
  VULPIX = { dex = 37, spa = 50, spd = 65 },
  NINETALES = { dex = 38, spa = 81, spd = 100 },
  JIGGLYPUFF = { dex = 39, spa = 45, spd = 25 },
  WIGGLYTUFF = { dex = 40, spa = 75, spd = 50 },
  ZUBAT = { dex = 41, spa = 30, spd = 40 },
  GOLBAT = { dex = 42, spa = 65, spd = 75 },
  ODDISH = { dex = 43, spa = 75, spd = 65 },
  GLOOM = { dex = 44, spa = 85, spd = 75 },
  VILEPLUME = { dex = 45, spa = 100, spd = 90 },
  PARAS = { dex = 46, spa = 45, spd = 55 },
  PARASECT = { dex = 47, spa = 60, spd = 80 },
  VENONAT = { dex = 48, spa = 40, spd = 55 },
  VENOMOTH = { dex = 49, spa = 90, spd = 75 },
  DIGLETT = { dex = 50, spa = 35, spd = 45 },
  DUGTRIO = { dex = 51, spa = 50, spd = 70 },
  MEOWTH = { dex = 52, spa = 40, spd = 40 },
  PERSIAN = { dex = 53, spa = 65, spd = 65 },
  PSYDUCK = { dex = 54, spa = 65, spd = 50 },
  GOLDUCK = { dex = 55, spa = 95, spd = 80 },
  MANKEY = { dex = 56, spa = 35, spd = 45 },
  PRIMEAPE = { dex = 57, spa = 60, spd = 70 },
  GROWLITHE = { dex = 58, spa = 70, spd = 50 },
  ARCANINE = { dex = 59, spa = 100, spd = 80 },
  POLIWAG = { dex = 60, spa = 40, spd = 40 },
  POLIWHIRL = { dex = 61, spa = 50, spd = 50 },
  POLIWRATH = { dex = 62, spa = 70, spd = 90 },
  ABRA = { dex = 63, spa = 105, spd = 55 },
  KADABRA = { dex = 64, spa = 120, spd = 70 },
  ALAKAZAM = { dex = 65, spa = 135, spd = 85 },
  MACHOP = { dex = 66, spa = 35, spd = 35 },
  MACHOKE = { dex = 67, spa = 50, spd = 60 },
  MACHAMP = { dex = 68, spa = 65, spd = 85 },
  BELLSPROUT = { dex = 69, spa = 70, spd = 30 },
  WEEPINBELL = { dex = 70, spa = 85, spd = 45 },
  VICTREEBEL = { dex = 71, spa = 100, spd = 60 },
  TENTACOOL = { dex = 72, spa = 50, spd = 100 },
  TENTACRUEL = { dex = 73, spa = 80, spd = 120 },
  GEODUDE = { dex = 74, spa = 30, spd = 30 },
  GRAVELER = { dex = 75, spa = 45, spd = 45 },
  GOLEM = { dex = 76, spa = 55, spd = 65 },
  PONYTA = { dex = 77, spa = 65, spd = 65 },
  RAPIDASH = { dex = 78, spa = 80, spd = 80 },
  SLOWPOKE = { dex = 79, spa = 40, spd = 40 },
  SLOWBRO = { dex = 80, spa = 100, spd = 80 },
  MAGNEMITE = { dex = 81, spa = 95, spd = 55 },
  MAGNETON = { dex = 82, spa = 120, spd = 70 },
  FARFETCH_D = { dex = 83, spa = 58, spd = 62 },
  DODUO = { dex = 84, spa = 35, spd = 35 },
  DODRIO = { dex = 85, spa = 60, spd = 60 },
  SEEL = { dex = 86, spa = 45, spd = 70 },
  DEWGONG = { dex = 87, spa = 70, spd = 95 },
  GRIMER = { dex = 88, spa = 40, spd = 50 },
  MUK = { dex = 89, spa = 65, spd = 100 },
  SHELLDER = { dex = 90, spa = 45, spd = 25 },
  CLOYSTER = { dex = 91, spa = 85, spd = 45 },
  GASTLY = { dex = 92, spa = 100, spd = 35 },
  HAUNTER = { dex = 93, spa = 115, spd = 55 },
  GENGAR = { dex = 94, spa = 130, spd = 75 },
  ONIX = { dex = 95, spa = 30, spd = 45 },
  DROWZEE = { dex = 96, spa = 43, spd = 90 },
  HYPNO = { dex = 97, spa = 73, spd = 115 },
  KRABBY = { dex = 98, spa = 25, spd = 25 },
  KINGLER = { dex = 99, spa = 50, spd = 50 },
  VOLTORB = { dex = 100, spa = 55, spd = 55 },
  ELECTRODE = { dex = 101, spa = 80, spd = 80 },
  EXEGGCUTE = { dex = 102, spa = 60, spd = 45 },
  EXEGGUTOR = { dex = 103, spa = 125, spd = 65 },
  CUBONE = { dex = 104, spa = 40, spd = 50 },
  MAROWAK = { dex = 105, spa = 50, spd = 80 },
  HITMONLEE = { dex = 106, spa = 35, spd = 110 },
  HITMONCHAN = { dex = 107, spa = 35, spd = 110 },
  LICKITUNG = { dex = 108, spa = 60, spd = 75 },
  KOFFING = { dex = 109, spa = 60, spd = 45 },
  WEEZING = { dex = 110, spa = 85, spd = 70 },
  RHYHORN = { dex = 111, spa = 30, spd = 30 },
  RHYDON = { dex = 112, spa = 45, spd = 45 },
  CHANSEY = { dex = 113, spa = 35, spd = 105 },
  TANGELA = { dex = 114, spa = 100, spd = 40 },
  KANGASKHAN = { dex = 115, spa = 40, spd = 80 },
  HORSEA = { dex = 116, spa = 70, spd = 25 },
  SEADRA = { dex = 117, spa = 95, spd = 45 },
  GOLDEEN = { dex = 118, spa = 35, spd = 50 },
  SEAKING = { dex = 119, spa = 65, spd = 80 },
  STARYU = { dex = 120, spa = 70, spd = 55 },
  STARMIE = { dex = 121, spa = 100, spd = 85 },
  MR_MIME = { dex = 122, spa = 100, spd = 120 },
  SCYTHER = { dex = 123, spa = 55, spd = 80 },
  JYNX = { dex = 124, spa = 115, spd = 95 },
  ELECTABUZZ = { dex = 125, spa = 95, spd = 85 },
  MAGMAR = { dex = 126, spa = 100, spd = 85 },
  PINSIR = { dex = 127, spa = 55, spd = 70 },
  TAUROS = { dex = 128, spa = 40, spd = 70 },
  MAGIKARP = { dex = 129, spa = 15, spd = 20 },
  GYARADOS = { dex = 130, spa = 60, spd = 100 },
  LAPRAS = { dex = 131, spa = 85, spd = 95 },
  DITTO = { dex = 132, spa = 48, spd = 48 },
  EEVEE = { dex = 133, spa = 45, spd = 65 },
  VAPOREON = { dex = 134, spa = 110, spd = 95 },
  JOLTEON = { dex = 135, spa = 110, spd = 95 },
  FLAREON = { dex = 136, spa = 95, spd = 110 },
  PORYGON = { dex = 137, spa = 85, spd = 75 },
  OMANYTE = { dex = 138, spa = 90, spd = 55 },
  OMASTAR = { dex = 139, spa = 115, spd = 70 },
  KABUTO = { dex = 140, spa = 55, spd = 45 },
  KABUTOPS = { dex = 141, spa = 65, spd = 70 },
  AERODACTYL = { dex = 142, spa = 60, spd = 75 },
  SNORLAX = { dex = 143, spa = 65, spd = 110 },
  ARTICUNO = { dex = 144, spa = 95, spd = 125 },
  ZAPDOS = { dex = 145, spa = 125, spd = 90 },
  MOLTRES = { dex = 146, spa = 125, spd = 85 },
  DRATINI = { dex = 147, spa = 50, spd = 50 },
  DRAGONAIR = { dex = 148, spa = 70, spd = 70 },
  DRAGONITE = { dex = 149, spa = 100, spd = 100 },
  MEWTWO = { dex = 150, spa = 154, spd = 90 },
  MEW = { dex = 151, spa = 100, spd = 100 },
  CHIKORITA = { dex = 152, spa = 49, spd = 65 },
  BAYLEEF = { dex = 153, spa = 63, spd = 80 },
  MEGANIUM = { dex = 154, spa = 83, spd = 100 },
  CYNDAQUIL = { dex = 155, spa = 60, spd = 50 },
  QUILAVA = { dex = 156, spa = 80, spd = 65 },
  TYPHLOSION = { dex = 157, spa = 109, spd = 85 },
  TOTODILE = { dex = 158, spa = 44, spd = 48 },
  CROCONAW = { dex = 159, spa = 59, spd = 63 },
  FERALIGATR = { dex = 160, spa = 79, spd = 83 },
  SENTRET = { dex = 161, spa = 35, spd = 45 },
  FURRET = { dex = 162, spa = 45, spd = 55 },
  HOOTHOOT = { dex = 163, spa = 36, spd = 56 },
  NOCTOWL = { dex = 164, spa = 76, spd = 96 },
  LEDYBA = { dex = 165, spa = 40, spd = 80 },
  LEDIAN = { dex = 166, spa = 55, spd = 110 },
  SPINARAK = { dex = 167, spa = 40, spd = 40 },
  ARIADOS = { dex = 168, spa = 60, spd = 60 },
  CROBAT = { dex = 169, spa = 70, spd = 80 },
  CHINCHOU = { dex = 170, spa = 56, spd = 56 },
  LANTURN = { dex = 171, spa = 76, spd = 76 },
  PICHU = { dex = 172, spa = 35, spd = 35 },
  CLEFFA = { dex = 173, spa = 45, spd = 55 },
  IGGLYBUFF = { dex = 174, spa = 40, spd = 20 },
  TOGEPI = { dex = 175, spa = 40, spd = 65 },
  TOGETIC = { dex = 176, spa = 80, spd = 105 },
  NATU = { dex = 177, spa = 70, spd = 45 },
  XATU = { dex = 178, spa = 95, spd = 70 },
  MAREEP = { dex = 179, spa = 65, spd = 45 },
  FLAAFFY = { dex = 180, spa = 80, spd = 60 },
  AMPHAROS = { dex = 181, spa = 115, spd = 90 },
  BELLOSSOM = { dex = 182, spa = 90, spd = 100 },
  MARILL = { dex = 183, spa = 20, spd = 50 },
  AZUMARILL = { dex = 184, spa = 50, spd = 80 },
  SUDOWOODO = { dex = 185, spa = 30, spd = 65 },
  POLITOED = { dex = 186, spa = 90, spd = 100 },
  HOPPIP = { dex = 187, spa = 35, spd = 55 },
  SKIPLOOM = { dex = 188, spa = 45, spd = 65 },
  JUMPLUFF = { dex = 189, spa = 55, spd = 85 },
  AIPOM = { dex = 190, spa = 40, spd = 55 },
  SUNKERN = { dex = 191, spa = 30, spd = 30 },
  SUNFLORA = { dex = 192, spa = 105, spd = 85 },
  YANMA = { dex = 193, spa = 75, spd = 45 },
  WOOPER = { dex = 194, spa = 25, spd = 25 },
  QUAGSIRE = { dex = 195, spa = 65, spd = 65 },
  ESPEON = { dex = 196, spa = 130, spd = 95 },
  UMBREON = { dex = 197, spa = 60, spd = 130 },
  MURKROW = { dex = 198, spa = 85, spd = 42 },
  SLOWKING = { dex = 199, spa = 100, spd = 110 },
  MISDREAVUS = { dex = 200, spa = 85, spd = 85 },
  UNOWN = { dex = 201, spa = 72, spd = 48 },
  WOBBUFFET = { dex = 202, spa = 33, spd = 58 },
  GIRAFARIG = { dex = 203, spa = 90, spd = 65 },
  PINECO = { dex = 204, spa = 35, spd = 35 },
  FORRETRESS = { dex = 205, spa = 60, spd = 60 },
  DUNSPARCE = { dex = 206, spa = 65, spd = 65 },
  GLIGAR = { dex = 207, spa = 35, spd = 65 },
  STEELIX = { dex = 208, spa = 55, spd = 65 },
  SNUBBULL = { dex = 209, spa = 40, spd = 40 },
  GRANBULL = { dex = 210, spa = 60, spd = 60 },
  QWILFISH = { dex = 211, spa = 55, spd = 55 },
  SCIZOR = { dex = 212, spa = 55, spd = 80 },
  SHUCKLE = { dex = 213, spa = 10, spd = 230 },
  HERACROSS = { dex = 214, spa = 40, spd = 95 },
  SNEASEL = { dex = 215, spa = 35, spd = 75 },
  TEDDIURSA = { dex = 216, spa = 50, spd = 50 },
  URSARING = { dex = 217, spa = 75, spd = 75 },
  SLUGMA = { dex = 218, spa = 70, spd = 40 },
  MAGCARGO = { dex = 219, spa = 80, spd = 80 },
  SWINUB = { dex = 220, spa = 30, spd = 30 },
  PILOSWINE = { dex = 221, spa = 60, spd = 60 },
  CORSOLA = { dex = 222, spa = 65, spd = 85 },
  REMORAID = { dex = 223, spa = 65, spd = 35 },
  OCTILLERY = { dex = 224, spa = 105, spd = 75 },
  DELIBIRD = { dex = 225, spa = 65, spd = 45 },
  MANTINE = { dex = 226, spa = 80, spd = 140 },
  SKARMORY = { dex = 227, spa = 40, spd = 70 },
  HOUNDOUR = { dex = 228, spa = 80, spd = 50 },
  HOUNDOOM = { dex = 229, spa = 110, spd = 80 },
  KINGDRA = { dex = 230, spa = 95, spd = 95 },
  PHANPY = { dex = 231, spa = 40, spd = 40 },
  DONPHAN = { dex = 232, spa = 60, spd = 60 },
  PORYGON2 = { dex = 233, spa = 105, spd = 95 },
  STANTLER = { dex = 234, spa = 85, spd = 65 },
  SMEARGLE = { dex = 235, spa = 20, spd = 45 },
  TYROGUE = { dex = 236, spa = 35, spd = 35 },
  HITMONTOP = { dex = 237, spa = 35, spd = 110 },
  SMOOCHUM = { dex = 238, spa = 85, spd = 65 },
  ELEKID = { dex = 239, spa = 65, spd = 55 },
  MAGBY = { dex = 240, spa = 70, spd = 55 },
  MILTANK = { dex = 241, spa = 40, spd = 70 },
  BLISSEY = { dex = 242, spa = 75, spd = 135 },
  RAIKOU = { dex = 243, spa = 115, spd = 100 },
  ENTEI = { dex = 244, spa = 90, spd = 75 },
  SUICUNE = { dex = 245, spa = 90, spd = 115 },
  LARVITAR = { dex = 246, spa = 45, spd = 50 },
  PUPITAR = { dex = 247, spa = 65, spd = 70 },
  TYRANITAR = { dex = 248, spa = 95, spd = 100 },
  LUGIA = { dex = 249, spa = 90, spd = 154 },
  HO_OH = { dex = 250, spa = 110, spd = 154 },
  CELEBI = { dex = 251, spa = 100, spd = 100 },
}
local GEN2_SPECIAL_BY_DEX = {}
for _, row in pairs(GEN2_SPECIAL_BY_ID) do GEN2_SPECIAL_BY_DEX[row.dex] = row end

local GEN4_MOVE_CATEGORY_BY_INDEX = {
  [1] = "physical", -- pound
  [2] = "physical", -- karate-chop
  [3] = "physical", -- double-slap
  [4] = "physical", -- comet-punch
  [5] = "physical", -- mega-punch
  [6] = "physical", -- pay-day
  [7] = "physical", -- fire-punch
  [8] = "physical", -- ice-punch
  [9] = "physical", -- thunder-punch
  [10] = "physical", -- scratch
  [11] = "physical", -- vice-grip
  [12] = "physical", -- guillotine
  [13] = "special", -- razor-wind
  [14] = "status", -- swords-dance
  [15] = "physical", -- cut
  [16] = "special", -- gust
  [17] = "physical", -- wing-attack
  [18] = "status", -- whirlwind
  [19] = "physical", -- fly
  [20] = "physical", -- bind
  [21] = "physical", -- slam
  [22] = "physical", -- vine-whip
  [23] = "physical", -- stomp
  [24] = "physical", -- double-kick
  [25] = "physical", -- mega-kick
  [26] = "physical", -- jump-kick
  [27] = "physical", -- rolling-kick
  [28] = "status", -- sand-attack
  [29] = "physical", -- headbutt
  [30] = "physical", -- horn-attack
  [31] = "physical", -- fury-attack
  [32] = "physical", -- horn-drill
  [33] = "physical", -- tackle
  [34] = "physical", -- body-slam
  [35] = "physical", -- wrap
  [36] = "physical", -- take-down
  [37] = "physical", -- thrash
  [38] = "physical", -- double-edge
  [39] = "status", -- tail-whip
  [40] = "physical", -- poison-sting
  [41] = "physical", -- twineedle
  [42] = "physical", -- pin-missile
  [43] = "status", -- leer
  [44] = "physical", -- bite
  [45] = "status", -- growl
  [46] = "status", -- roar
  [47] = "status", -- sing
  [48] = "status", -- supersonic
  [49] = "special", -- sonic-boom
  [50] = "status", -- disable
  [51] = "special", -- acid
  [52] = "special", -- ember
  [53] = "special", -- flamethrower
  [54] = "status", -- mist
  [55] = "special", -- water-gun
  [56] = "special", -- hydro-pump
  [57] = "special", -- surf
  [58] = "special", -- ice-beam
  [59] = "special", -- blizzard
  [60] = "special", -- psybeam
  [61] = "special", -- bubble-beam
  [62] = "special", -- aurora-beam
  [63] = "special", -- hyper-beam
  [64] = "physical", -- peck
  [65] = "physical", -- drill-peck
  [66] = "physical", -- submission
  [67] = "physical", -- low-kick
  [68] = "physical", -- counter
  [69] = "physical", -- seismic-toss
  [70] = "physical", -- strength
  [71] = "special", -- absorb
  [72] = "special", -- mega-drain
  [73] = "status", -- leech-seed
  [74] = "status", -- growth
  [75] = "physical", -- razor-leaf
  [76] = "special", -- solar-beam
  [77] = "status", -- poison-powder
  [78] = "status", -- stun-spore
  [79] = "status", -- sleep-powder
  [80] = "special", -- petal-dance
  [81] = "status", -- string-shot
  [82] = "special", -- dragon-rage
  [83] = "special", -- fire-spin
  [84] = "special", -- thunder-shock
  [85] = "special", -- thunderbolt
  [86] = "status", -- thunder-wave
  [87] = "special", -- thunder
  [88] = "physical", -- rock-throw
  [89] = "physical", -- earthquake
  [90] = "physical", -- fissure
  [91] = "physical", -- dig
  [92] = "status", -- toxic
  [93] = "special", -- confusion
  [94] = "special", -- psychic
  [95] = "status", -- hypnosis
  [96] = "status", -- meditate
  [97] = "status", -- agility
  [98] = "physical", -- quick-attack
  [99] = "physical", -- rage
  [100] = "status", -- teleport
  [101] = "special", -- night-shade
  [102] = "status", -- mimic
  [103] = "status", -- screech
  [104] = "status", -- double-team
  [105] = "status", -- recover
  [106] = "status", -- harden
  [107] = "status", -- minimize
  [108] = "status", -- smokescreen
  [109] = "status", -- confuse-ray
  [110] = "status", -- withdraw
  [111] = "status", -- defense-curl
  [112] = "status", -- barrier
  [113] = "status", -- light-screen
  [114] = "status", -- haze
  [115] = "status", -- reflect
  [116] = "status", -- focus-energy
  [117] = "physical", -- bide
  [118] = "status", -- metronome
  [119] = "status", -- mirror-move
  [120] = "physical", -- self-destruct
  [121] = "physical", -- egg-bomb
  [122] = "physical", -- lick
  [123] = "special", -- smog
  [124] = "special", -- sludge
  [125] = "physical", -- bone-club
  [126] = "special", -- fire-blast
  [127] = "physical", -- waterfall
  [128] = "physical", -- clamp
  [129] = "special", -- swift
  [130] = "physical", -- skull-bash
  [131] = "physical", -- spike-cannon
  [132] = "physical", -- constrict
  [133] = "status", -- amnesia
  [134] = "status", -- kinesis
  [135] = "status", -- soft-boiled
  [136] = "physical", -- high-jump-kick
  [137] = "status", -- glare
  [138] = "special", -- dream-eater
  [139] = "status", -- poison-gas
  [140] = "physical", -- barrage
  [141] = "physical", -- leech-life
  [142] = "status", -- lovely-kiss
  [143] = "physical", -- sky-attack
  [144] = "status", -- transform
  [145] = "special", -- bubble
  [146] = "physical", -- dizzy-punch
  [147] = "status", -- spore
  [148] = "status", -- flash
  [149] = "special", -- psywave
  [150] = "status", -- splash
  [151] = "status", -- acid-armor
  [152] = "physical", -- crabhammer
  [153] = "physical", -- explosion
  [154] = "physical", -- fury-swipes
  [155] = "physical", -- bonemerang
  [156] = "status", -- rest
  [157] = "physical", -- rock-slide
  [158] = "physical", -- hyper-fang
  [159] = "status", -- sharpen
  [160] = "status", -- conversion
  [161] = "special", -- tri-attack
  [162] = "physical", -- super-fang
  [163] = "physical", -- slash
  [164] = "status", -- substitute
  [165] = "physical", -- struggle
  [166] = "status", -- sketch
  [167] = "physical", -- triple-kick
  [168] = "physical", -- thief
  [169] = "status", -- spider-web
  [170] = "status", -- mind-reader
  [171] = "status", -- nightmare
  [172] = "physical", -- flame-wheel
  [173] = "special", -- snore
  [174] = "status", -- curse
  [175] = "physical", -- flail
  [176] = "status", -- conversion-2
  [177] = "special", -- aeroblast
  [178] = "status", -- cotton-spore
  [179] = "physical", -- reversal
  [180] = "status", -- spite
  [181] = "special", -- powder-snow
  [182] = "status", -- protect
  [183] = "physical", -- mach-punch
  [184] = "status", -- scary-face
  [185] = "physical", -- feint-attack
  [186] = "status", -- sweet-kiss
  [187] = "status", -- belly-drum
  [188] = "special", -- sludge-bomb
  [189] = "special", -- mud-slap
  [190] = "special", -- octazooka
  [191] = "status", -- spikes
  [192] = "special", -- zap-cannon
  [193] = "status", -- foresight
  [194] = "status", -- destiny-bond
  [195] = "status", -- perish-song
  [196] = "special", -- icy-wind
  [197] = "status", -- detect
  [198] = "physical", -- bone-rush
  [199] = "status", -- lock-on
  [200] = "physical", -- outrage
  [201] = "status", -- sandstorm
  [202] = "special", -- giga-drain
  [203] = "status", -- endure
  [204] = "status", -- charm
  [205] = "physical", -- rollout
  [206] = "physical", -- false-swipe
  [207] = "status", -- swagger
  [208] = "status", -- milk-drink
  [209] = "physical", -- spark
  [210] = "physical", -- fury-cutter
  [211] = "physical", -- steel-wing
  [212] = "status", -- mean-look
  [213] = "status", -- attract
  [214] = "status", -- sleep-talk
  [215] = "status", -- heal-bell
  [216] = "physical", -- return
  [217] = "physical", -- present
  [218] = "physical", -- frustration
  [219] = "status", -- safeguard
  [220] = "status", -- pain-split
  [221] = "physical", -- sacred-fire
  [222] = "physical", -- magnitude
  [223] = "physical", -- dynamic-punch
  [224] = "physical", -- megahorn
  [225] = "special", -- dragon-breath
  [226] = "status", -- baton-pass
  [227] = "status", -- encore
  [228] = "physical", -- pursuit
  [229] = "physical", -- rapid-spin
  [230] = "status", -- sweet-scent
  [231] = "physical", -- iron-tail
  [232] = "physical", -- metal-claw
  [233] = "physical", -- vital-throw
  [234] = "status", -- morning-sun
  [235] = "status", -- synthesis
  [236] = "status", -- moonlight
  [237] = "special", -- hidden-power
  [238] = "physical", -- cross-chop
  [239] = "special", -- twister
  [240] = "status", -- rain-dance
  [241] = "status", -- sunny-day
  [242] = "physical", -- crunch
  [243] = "special", -- mirror-coat
  [244] = "status", -- psych-up
  [245] = "physical", -- extreme-speed
  [246] = "special", -- ancient-power
  [247] = "special", -- shadow-ball
  [248] = "special", -- future-sight
  [249] = "physical", -- rock-smash
  [250] = "special", -- whirlpool
  [251] = "physical", -- beat-up
}

local GEN1_MOVE_KEY_BY_INDEX = {
  [1] = "POUND",
  [2] = "KARATE_CHOP",
  [3] = "DOUBLESLAP",
  [4] = "COMET_PUNCH",
  [5] = "MEGA_PUNCH",
  [6] = "PAY_DAY",
  [7] = "FIRE_PUNCH",
  [8] = "ICE_PUNCH",
  [9] = "THUNDERPUNCH",
  [10] = "SCRATCH",
  [11] = "VICEGRIP",
  [12] = "GUILLOTINE",
  [13] = "RAZOR_WIND",
  [14] = "SWORDS_DANCE",
  [15] = "CUT",
  [16] = "GUST",
  [17] = "WING_ATTACK",
  [18] = "WHIRLWIND",
  [19] = "FLY",
  [20] = "BIND",
  [21] = "SLAM",
  [22] = "VINE_WHIP",
  [23] = "STOMP",
  [24] = "DOUBLE_KICK",
  [25] = "MEGA_KICK",
  [26] = "JUMP_KICK",
  [27] = "ROLLING_KICK",
  [28] = "SAND_ATTACK",
  [29] = "HEADBUTT",
  [30] = "HORN_ATTACK",
  [31] = "FURY_ATTACK",
  [32] = "HORN_DRILL",
  [33] = "TACKLE",
  [34] = "BODY_SLAM",
  [35] = "WRAP",
  [36] = "TAKE_DOWN",
  [37] = "THRASH",
  [38] = "DOUBLE_EDGE",
  [39] = "TAIL_WHIP",
  [40] = "POISON_STING",
  [41] = "TWINEEDLE",
  [42] = "PIN_MISSILE",
  [43] = "LEER",
  [44] = "BITE",
  [45] = "GROWL",
  [46] = "ROAR",
  [47] = "SING",
  [48] = "SUPERSONIC",
  [49] = "SONICBOOM",
  [50] = "DISABLE",
  [51] = "ACID",
  [52] = "EMBER",
  [53] = "FLAMETHROWER",
  [54] = "MIST",
  [55] = "WATER_GUN",
  [56] = "HYDRO_PUMP",
  [57] = "SURF",
  [58] = "ICE_BEAM",
  [59] = "BLIZZARD",
  [60] = "PSYBEAM",
  [61] = "BUBBLEBEAM",
  [62] = "AURORA_BEAM",
  [63] = "HYPER_BEAM",
  [64] = "PECK",
  [65] = "DRILL_PECK",
  [66] = "SUBMISSION",
  [67] = "LOW_KICK",
  [68] = "COUNTER",
  [69] = "SEISMIC_TOSS",
  [70] = "STRENGTH",
  [71] = "ABSORB",
  [72] = "MEGA_DRAIN",
  [73] = "LEECH_SEED",
  [74] = "GROWTH",
  [75] = "RAZOR_LEAF",
  [76] = "SOLARBEAM",
  [77] = "POISONPOWDER",
  [78] = "STUN_SPORE",
  [79] = "SLEEP_POWDER",
  [80] = "PETAL_DANCE",
  [81] = "STRING_SHOT",
  [82] = "DRAGON_RAGE",
  [83] = "FIRE_SPIN",
  [84] = "THUNDERSHOCK",
  [85] = "THUNDERBOLT",
  [86] = "THUNDER_WAVE",
  [87] = "THUNDER",
  [88] = "ROCK_THROW",
  [89] = "EARTHQUAKE",
  [90] = "FISSURE",
  [91] = "DIG",
  [92] = "TOXIC",
  [93] = "CONFUSION",
  [94] = "PSYCHIC_M",
  [95] = "HYPNOSIS",
  [96] = "MEDITATE",
  [97] = "AGILITY",
  [98] = "QUICK_ATTACK",
  [99] = "RAGE",
  [100] = "TELEPORT",
  [101] = "NIGHT_SHADE",
  [102] = "MIMIC",
  [103] = "SCREECH",
  [104] = "DOUBLE_TEAM",
  [105] = "RECOVER",
  [106] = "HARDEN",
  [107] = "MINIMIZE",
  [108] = "SMOKESCREEN",
  [109] = "CONFUSE_RAY",
  [110] = "WITHDRAW",
  [111] = "DEFENSE_CURL",
  [112] = "BARRIER",
  [113] = "LIGHT_SCREEN",
  [114] = "HAZE",
  [115] = "REFLECT",
  [116] = "FOCUS_ENERGY",
  [117] = "BIDE",
  [118] = "METRONOME",
  [119] = "MIRROR_MOVE",
  [120] = "SELFDESTRUCT",
  [121] = "EGG_BOMB",
  [122] = "LICK",
  [123] = "SMOG",
  [124] = "SLUDGE",
  [125] = "BONE_CLUB",
  [126] = "FIRE_BLAST",
  [127] = "WATERFALL",
  [128] = "CLAMP",
  [129] = "SWIFT",
  [130] = "SKULL_BASH",
  [131] = "SPIKE_CANNON",
  [132] = "CONSTRICT",
  [133] = "AMNESIA",
  [134] = "KINESIS",
  [135] = "SOFTBOILED",
  [136] = "HI_JUMP_KICK",
  [137] = "GLARE",
  [138] = "DREAM_EATER",
  [139] = "POISON_GAS",
  [140] = "BARRAGE",
  [141] = "LEECH_LIFE",
  [142] = "LOVELY_KISS",
  [143] = "SKY_ATTACK",
  [144] = "TRANSFORM",
  [145] = "BUBBLE",
  [146] = "DIZZY_PUNCH",
  [147] = "SPORE",
  [148] = "FLASH",
  [149] = "PSYWAVE",
  [150] = "SPLASH",
  [151] = "ACID_ARMOR",
  [152] = "CRABHAMMER",
  [153] = "EXPLOSION",
  [154] = "FURY_SWIPES",
  [155] = "BONEMERANG",
  [156] = "REST",
  [157] = "ROCK_SLIDE",
  [158] = "HYPER_FANG",
  [159] = "SHARPEN",
  [160] = "CONVERSION",
  [161] = "TRI_ATTACK",
  [162] = "SUPER_FANG",
  [163] = "SLASH",
  [164] = "SUBSTITUTE",
  [165] = "STRUGGLE",
}
local function normalizeMoveKey(value)
  return tostring(value or ""):lower():gsub("[^%w]", "")
end

local function isCanonicalGen1Move(id, move, index)
  local expected = GEN1_MOVE_KEY_BY_INDEX[index]
  if not expected or type(move) ~= "table" then return false end
  local want = normalizeMoveKey(expected)
  return normalizeMoveKey(id) == want
      or normalizeMoveKey(move.id) == want
      or normalizeMoveKey(move.name) == want
end

local SplitStats = {}
local CRYSTAL_SPECIAL_BY_ID = nil

function SplitStats.setCrystalBaseStats(baseStats)
  if type(baseStats) ~= "table" then
    CRYSTAL_SPECIAL_BY_ID = nil
    return 0
  end
  local out, count = {}, 0
  for id, row in pairs(baseStats) do
    if type(row) == "table" then
      local spa = tonumber(row.specialAttack)
      local spd = tonumber(row.specialDefense)
      if spa and spd then
        out[id] = { spa = spa, spd = spd }
        count = count + 1
      end
    end
  end
  CRYSTAL_SPECIAL_BY_ID = out
  return count
end

local function calcSplitStat(base, dv, statExp, level)
  local ev = math.floor(math.min(255, math.ceil(math.sqrt(statExp or 0))) / 4)
  return math.floor(((base + (dv or 0)) * 2 + ev) * level / 100) + 5
end
SplitStats.calcOne = calcSplitStat
function SplitStats.baseFor(speciesDef)
  if type(speciesDef) ~= "table" then return nil end
  -- The mod-owned Gen II-V table is authoritative for National Dex #001-251.
  -- This avoids silently collapsing Johto back to one legacy SPECIAL value if
  -- Crystal's optional cross-mod export is unavailable at runtime.
  local row = speciesDef.id and GEN2_SPECIAL_BY_ID[speciesDef.id] or nil
  if not row and speciesDef.dex then row = GEN2_SPECIAL_BY_DEX[speciesDef.dex] end
  -- Crystal remains a last-resort fallback for content outside our canonical
  -- table, never an override for #001-251.
  if not row then
    row = speciesDef.id and CRYSTAL_SPECIAL_BY_ID
      and CRYSTAL_SPECIAL_BY_ID[speciesDef.id] or nil
  end
  return row
end
function SplitStats.calculate(speciesDef, level, dvs, statExp, vanillaSpecial)
  local row = SplitStats.baseFor(speciesDef)
  if not row then return vanillaSpecial, vanillaSpecial end
  dvs = dvs or {}
  statExp = statExp or {}
  local dv = dvs.special or 0
  local exp = statExp.special or 0
  return calcSplitStat(row.spa, dv, exp, level), calcSplitStat(row.spd, dv, exp, level)
end
function SplitStats.attach(stats, speciesDef, level, dvs, statExp)
  if type(stats) ~= "table" then return stats end
  local spa, spd = SplitStats.calculate(speciesDef, level, dvs, statExp, stats.special)
  stats.specialAttack = spa
  stats.specialDefense = spd
  return stats
end

-- Gold / Generation II backend -------------------------------------------------
--
-- Gold already owns the Generation II special-stat model.  This backend is
-- intentionally entered before any Gen 1-only require below, so Gold never
-- installs the Stats/Experience/ItemEffects/SaveData/UI compatibility patches
-- that Red/Blue/Yellow need.  Its gameplay addition is only the optional
-- Generation IV+ per-move category selector.
local GOLD_CATEGORY_PATCH_KEY = "__special_stat_split_gold_category_bridge_v1"

local function activeGeneration()
  local ok, GameVersion = pcall(require, "src.core.GameVersion")
  if not ok or type(GameVersion) ~= "table"
      or type(GameVersion.generation) ~= "function" then
    return 1
  end
  local okGeneration, generation = pcall(GameVersion.generation)
  if okGeneration then return tonumber(generation) or 1 end
  return 1
end

local GOLD_MOVE_KEY_BY_INDEX = {}
for index, id in pairs(GEN1_MOVE_KEY_BY_INDEX) do GOLD_MOVE_KEY_BY_INDEX[index] = id end
local GOLD_GEN2_MOVE_KEYS = {
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
  [214] = "SLEEP_TALK", [215] = "HEAL_BELL", [216] = "RETURN", [217] = "PRESENT",
  [218] = "FRUSTRATION", [219] = "SAFEGUARD", [220] = "PAIN_SPLIT",
  [221] = "SACRED_FIRE", [222] = "MAGNITUDE", [223] = "DYNAMIC_PUNCH",
  [224] = "MEGAHORN", [225] = "DRAGON_BREATH", [226] = "BATON_PASS",
  [227] = "ENCORE", [228] = "PURSUIT", [229] = "RAPID_SPIN",
  [230] = "SWEET_SCENT", [231] = "IRON_TAIL", [232] = "METAL_CLAW",
  [233] = "VITAL_THROW", [234] = "MORNING_SUN", [235] = "SYNTHESIS",
  [236] = "MOONLIGHT", [237] = "HIDDEN_POWER", [238] = "CROSS_CHOP",
  [239] = "TWISTER", [240] = "RAIN_DANCE", [241] = "SUNNY_DAY", [242] = "CRUNCH",
  [243] = "MIRROR_COAT", [244] = "PSYCH_UP", [245] = "EXTREME_SPEED",
  [246] = "ANCIENT_POWER", [247] = "SHADOW_BALL", [248] = "FUTURE_SIGHT",
  [249] = "ROCK_SMASH", [250] = "WHIRLPOOL", [251] = "BEAT_UP",
}
for index, id in pairs(GOLD_GEN2_MOVE_KEYS) do GOLD_MOVE_KEY_BY_INDEX[index] = id end

local GOLD_MOVE_INDEX_BY_KEY = {}
for index, id in pairs(GOLD_MOVE_KEY_BY_INDEX) do
  GOLD_MOVE_INDEX_BY_KEY[normalizeMoveKey(id)] = index
end

local function goldMoveIndex(id, move)
  if type(move) == "table" then
    local direct = tonumber(move.index)
    if direct then return direct end
  end
  local index = GOLD_MOVE_INDEX_BY_KEY[normalizeMoveKey(id)]
  if index then return index end
  if type(move) == "table" then
    return GOLD_MOVE_INDEX_BY_KEY[normalizeMoveKey(move.id)]
      or GOLD_MOVE_INDEX_BY_KEY[normalizeMoveKey(move.name)]
  end
  return nil
end

local function isCanonicalGoldMove(id, move, index)
  if not (index and index >= 1 and index <= 251 and type(move) == "table") then
    return false
  end
  local expected = GOLD_MOVE_KEY_BY_INDEX[index]
  if not expected then return false end
  local want = normalizeMoveKey(expected)
  return normalizeMoveKey(id) == want
      or normalizeMoveKey(move.id) == want
      or normalizeMoveKey(move.name) == want
end

local function defineGoldOptions(mod)
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
      description = "Show the effective Physical/Special category for the selected move. On Gold, type-based mode uses Gold's native type category and GEN IV+ uses the individual move.",
    },
    {
      key = "modern_ui_override",
      label = "ModernUI Override",
      type = "toggle",
      default = true,
      description = "Gen 1 compatibility setting. Gold already has native Sp. Atk / Sp. Def presentation, so this setting does not install a Gold stat override.",
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
      description = "Gen 1 Modern UI compatibility setting. It is not applied to Gold's native party/summary stat presentation.",
    },
    {
      key = "modern_ui_battle_wip_override",
      label = "ModernUI BattleWIP Override",
      type = "toggle",
      default = false,
      description = "Gen 1 Modern UI compatibility setting. It is not applied to Gold's native battle UI.",
    },
  })
end

local function runGoldBackend(mod)
  defineGoldOptions(mod)

  local Damage = require("src.battle.gen2.Damage")
  local Battle = require("src.battle.gen2.Battle")
  local Ai = require("src.battle.gen2.Ai")

  local requestedSpecial = tostring(mod.options:get("mode") or "gen2")
  local requestedMove = tostring(mod.options:get("move_split") or "gen4")
  local moveSplitActive = requestedMove == "gen4"
  local requestedSpecialActive = requestedSpecial == "gen2"

  -- Registry ownership.  Gold's native move TYPE never changes.  GEN IV+ adds
  -- category metadata to canonical rows; type-based mode removes explicit
  -- canonical categories so lower-priority modern-category data cannot leak in.
  local registryChanged, registryConflicts, identitySkips = 0, 0, 0
  local canonicalSeen = {}
  if mod.content and mod.content.moves
      and type(mod.content.moves.each) == "function"
      and type(mod.content.moves.patch) == "function" then
    for id, move in mod.content.moves:each() do
      local index = goldMoveIndex(id, move)
      local category = index and GEN4_MOVE_CATEGORY_BY_INDEX[index] or nil
      if category and isCanonicalGoldMove(id, move, index) then
        canonicalSeen[index] = true
        if moveSplitActive then
          if move.category ~= nil and move.category ~= category then
            registryConflicts = registryConflicts + 1
          end
          mod.content.moves:patch(id, { category = category })
          registryChanged = registryChanged + 1
        elseif move.category ~= nil and mod.DELETE ~= nil then
          registryConflicts = registryConflicts + 1
          mod.content.moves:patch(id, { category = mod.DELETE })
          registryChanged = registryChanged + 1
        elseif move.category ~= nil and mod.DELETE == nil
            and mod.log and type(mod.log.warn) == "function" then
          mod.log:warn("Gold type-based mode could not clear an explicit canonical move.category because mod.DELETE is unavailable")
        end
      elseif index and index >= 1 and index <= 251 and category then
        identitySkips = identitySkips + 1
      end
    end
  end
  local canonicalCount = 0
  for i = 1, 251 do if canonicalSeen[i] then canonicalCount = canonicalCount + 1 end end

  local bridge = rawget(Damage, GOLD_CATEGORY_PATCH_KEY)
  if not bridge then
    bridge = {
      active = false,
      categoryFor = nil,
      stack = {},
      pendingAiCategory = nil,
      originalIsPhysical = Damage.isPhysical,
      originalCalc = Damage.calc,
      originalHitOnce = Battle.hitOnce,
      originalSmartAiState = Battle.smartAiState,
      originalAiChoose = Ai.choose,
    }
    rawset(Damage, GOLD_CATEGORY_PATCH_KEY, bridge)

    local function withCategory(category, fn, ...)
      if category ~= "physical" and category ~= "special" then
        return fn(...)
      end
      local stack = bridge.stack
      stack[#stack + 1] = category
      local result = pack(pcall(fn, ...))
      stack[#stack] = nil
      if not result[1] then error(result[2], 0) end
      return unpack(result, 2, result.n)
    end
    bridge.withCategory = withCategory

    Damage.isPhysical = function(moveType, types)
      local current = bridge.stack[#bridge.stack]
      if bridge.active and (current == "physical" or current == "special") then
        return current == "physical"
      end
      return bridge.originalIsPhysical(moveType, types)
    end

    -- AI expected damage calls Damage.calc directly rather than battle.damage.
    -- Ai.choose arms exactly one category immediately after resolving each move;
    -- this wrapper consumes it for that one expected-damage calculation only.
    Damage.calc = function(opts)
      local category = bridge.active and bridge.pendingAiCategory or nil
      if category == "physical" or category == "special" then
        bridge.pendingAiCategory = nil
        return bridge.withCategory(category, bridge.originalCalc, opts)
      end
      return bridge.originalCalc(opts)
    end

    Battle.hitOnce = function(self, attacker, defender, def, opts)
      local category = bridge.active and bridge.categoryFor
        and bridge.categoryFor(opts and opts.moveId or (def and def.id), def) or nil
      if category == "physical" or category == "special" then
        return bridge.withCategory(category, bridge.originalHitOnce,
          self, attacker, defender, def, opts)
      end
      return bridge.originalHitOnce(self, attacker, defender, def, opts)
    end

    Battle.smartAiState = function(self, ...)
      local out = bridge.originalSmartAiState(self, ...)
      if not (bridge.active and bridge.categoryFor and type(out) == "table") then
        return out
      end
      local playerState = self:volatile(self.player)
      local physical, special = 0, 0
      for _, id in ipairs(playerState.usedMoves or {}) do
        local def = self:moveDef(id)
        if def and (def.power or 0) > 0 then
          local category = bridge.categoryFor(id, def)
          if category == "physical" then physical = physical + 1
          elseif category == "special" then special = special + 1
          else
            local types = self.data.type_chart and self.data.type_chart.types
            if bridge.originalIsPhysical(def.type, types) then
              physical = physical + 1
            else
              special = special + 1
            end
          end
        end
      end
      out.playerPhysicalMoves = physical
      out.playerSpecialMoves = special
      local lastId = playerState.lastMove
      local lastDef = lastId and self:moveDef(lastId) or nil
      if lastDef then
        local category = bridge.categoryFor(lastId, lastDef)
        if category == "physical" then out.playerLastMoveSpecial = false
        elseif category == "special" then out.playerLastMoveSpecial = true end
      end
      -- playerSpecialType deliberately remains Gold's native TYPE heuristic.
      return out
    end

    Ai.choose = function(context)
      if not (bridge.active and bridge.categoryFor and type(context) == "table"
          and type(context.moveDef) == "function") then
        return bridge.originalAiChoose(context)
      end
      local originalMoveDef = context.moveDef
      local oldPending = bridge.pendingAiCategory
      context.moveDef = function(id)
        local def = originalMoveDef(id)
        local category = def and bridge.categoryFor(id, def) or nil
        if def and (def.power or 0) > 0
            and (category == "physical" or category == "special") then
          bridge.pendingAiCategory = category
        else
          bridge.pendingAiCategory = nil
        end
        return def
      end
      local result = pack(pcall(bridge.originalAiChoose, context))
      context.moveDef = originalMoveDef
      bridge.pendingAiCategory = oldPending
      if not result[1] then error(result[2], 0) end
      return unpack(result, 2, result.n)
    end
  end

  bridge.active = moveSplitActive
  bridge.categoryFor = function(id, move)
    if not moveSplitActive or type(move) ~= "table" then return nil end
    -- Explicit category is authoritative for noncanonical/custom moves too.
    -- Canonical rows below are owned by this mod's audited 1..251 table.
    local index = goldMoveIndex(id, move)
    if index and GEN4_MOVE_CATEGORY_BY_INDEX[index]
        and isCanonicalGoldMove(id, move, index) then
      local category = GEN4_MOVE_CATEGORY_BY_INDEX[index]
      if category == "physical" or category == "special" then return category end
      return nil
    end
    if move.category == "physical" or move.category == "special" then
      return move.category
    end
    return nil
  end
  bridge.pendingAiCategory = nil
  while #bridge.stack > 0 do bridge.stack[#bridge.stack] = nil end

  local effectiveMove = moveSplitActive and "gen4" or "type_based_gen2"
  local gameplayConfig = {
    specialStats = requestedSpecialActive and "gen2" or "vanilla",
    moveCategories = moveSplitActive and "gen4" or "gen1",
  }
  local effectiveConfig = {
    specialStats = "native_gen2",
    moveCategories = effectiveMove,
  }
  local gameplayConfigRevision = ("special=native_gen2;move=%s")
    :format(moveSplitActive and "gen4" or "type_gen2")
  local linkConfigRegistered = false
  if mod.content and mod.content.link_fields
      and type(mod.content.link_fields.register) == "function" then
    mod.content.link_fields:register("special_stat_split_rules", {
      rev = gameplayConfigRevision,
    })
    linkConfigRegistered = true
  end

  -- Gold has no spare TYPE/ field in its four-row move list.  Use the public
  -- battle.overlay seam instead of replacing BattleState:drawPanel.  The first
  -- Gold live test showed that a one-letter marker in tile 0 lands on the move
  -- box border and is effectively unreadable at normal play scale.  The
  -- selected move therefore gets a clear category tab cut into the TOP border
  -- of the move box: PHYSICAL / SPECIAL / STATUS.  Non-formula damage classes
  -- are called out explicitly (FIXED / OHKO / REACTIVE) so the readout never
  -- implies that Attack/Defense or Sp.Atk/Sp.Def drives damage when it does not.
  -- Names and PP remain on Gold's four native rows, untouched.
  local readoutHookInstalled = false
  local gen3UiRuntimeDetected = false
  local gen3UiRuntimeInline = false
  -- Gold/Gen 2 only: Gen 3 UI v1.4 renders its replacement battle panel from
  -- render.hud after the normal battle.overlay pass.  Latch the current Gold
  -- battle screen in battle.overlay, then draw the category after render.hud's
  -- downstream chain exactly like the already-live-tested Enemy HP integration.
  local gen3UiRenderHudInstalled = false
  local gen3UiRenderHudDrawn = false
  local gen3UiRenderHudSource = nil
  local goldLastScreen = nil
  local function gen3UiHandleForDiagnostics()
    if type(mod.find) ~= "function" then return nil end
    for _, id in ipairs({ "gen3_battle_ui", "gen3_battle_ui_overhaul", "gen3_ui" }) do
      local ok, handle = pcall(mod.find, id)
      if ok and handle then return handle end
    end
    return nil
  end
  local function runtimeGen3Entry()
    local ok, Runtime = pcall(require, "src.mods.Runtime")
    local hooks = ok and Runtime and Runtime.hooks or nil
    local chain = hooks and hooks.chains and hooks.chains["render.hud"]
    if type(chain) ~= "table" then return nil end
    for _, entry in ipairs(chain) do
      if type(entry) == "table" and type(entry.callback) == "function"
          and tostring(entry.owner or "") == "gen3_battle_ui" then
        return entry
      end
    end
    return nil
  end
  local function gen3UiActive()
    if gen3UiHandleForDiagnostics() ~= nil then return true, "mod.find" end
    if runtimeGen3Entry() ~= nil then return true, "runtime-owner" end
    return false, nil
  end
  local hooks = mod.hooks
  if hooks and type(hooks.wrap) == "function" then
    local Chrome, chromeTried
    local function getChrome()
      if chromeTried then return Chrome end
      chromeTried = true
      local ok, value = pcall(require, "src.ui.gen2.Chrome")
      if ok and type(value) == "table" and type(value.print) == "function" then
        Chrome = value
      end
      return Chrome
    end

    local fixedDamageMoves = {
      sonicboom = true, dragonrage = true, nightshade = true,
      seismictoss = true, psywave = true, superfang = true,
    }
    local ohkoMoves = {
      guillotine = true, horndrill = true, fissure = true,
    }
    local reactiveDamageMoves = { bide = true }

    -- The Gen 3-inspired UI has its own wide move panel on Gold.  Do NOT gate
    -- compatibility on a mod id: v1.4.0 is distributed as an external release
    -- and its loader-visible identity/order may change independently of its
    -- renderer.  Instead, detect the capability live: if downstream rendering
    -- exposes a TYPE <move type> ... PP information row for the selected move,
    -- inject the trinary category there automatically.  Native Gold has no such
    -- row, so it naturally falls back to the proven top-border tab.

    local function categoryOnlyLabel(id, def, data)
      if type(def) ~= "table" then return nil end

      -- STATUS is stable across both settings.  Use the audited canonical table
      -- first so a type-based Gold boot does not mistake a power-0 status move
      -- for a damaging move merely because every Gen 2 type is physical/special.
      local moveIndex = goldMoveIndex(id, def)
      local audited = moveIndex and GEN4_MOVE_CATEGORY_BY_INDEX[moveIndex] or nil
      if isCanonicalGoldMove(id, def, moveIndex) and audited == "status" then
        return "STATUS"
      end
      if def.category == "status" then return "STATUS" end

      local category
      if moveSplitActive then
        category = bridge.categoryFor(id, def)
      end
      if category ~= "physical" and category ~= "special" then
        local types = data and data.type_chart and data.type_chart.types
        category = bridge.originalIsPhysical(def.type, types)
          and "physical" or "special"
      end
      return category == "physical" and "PHYSICAL" or "SPECIAL"
    end

    -- Working Gen 3 UI technique borrowed from Enemy HP v2.1.0 test A/B:
    -- its replacement UI is a screen-space render.hud presenter.  Draw only
    -- after that presenter has finished, never from the earlier Gold overlay.
    local function gen3Scale()
      local G = rawget(_G, "love") and love.graphics or nil
      if not (G and type(G.getDimensions) == "function") then return nil end
      local sw, sh = G.getDimensions()
      local raw = math.min(sw / 430, sh / 245)
      if raw <= 4.5 then return math.max(2.85, math.min(raw, 3.85)) end
      return math.max(3.85, math.min(3.85 + (raw - 4.5) * 0.72, 7.0))
    end

    local gen3Fonts = {}
    local function gen3Font(size)
      local G = rawget(_G, "love") and love.graphics or nil
      if not G then return nil end
      local px = math.max(4, math.floor(math.max(4, (tonumber(size) or 4) * 1.08) + 0.5))
      if gen3Fonts[px] then return gen3Fonts[px] end
      local okFont, EngineFont = pcall(require, "src.render.Font")
      if okFont and EngineFont and EngineFont.PLAINPIXEL
          and type(G.newFont) == "function" then
        local ok, font = pcall(G.newFont, EngineFont.PLAINPIXEL, px, "normal")
        if ok and font then
          if type(font.setFilter) == "function" then
            pcall(font.setFilter, font, "linear", "linear")
          end
          gen3Fonts[px] = font
          return font
        end
      end
      return type(G.getFont) == "function" and G.getFont() or nil
    end

    local function exactGen3Print(textValue, x, y, size, color, align, width)
      local G = rawget(_G, "love") and love.graphics or nil
      if not (G and type(G.setColor) == "function") then return false end
      local font = gen3Font(size)
      local oldFont = type(G.getFont) == "function" and G.getFont() or nil
      local r, g, b, a
      if type(G.getColor) == "function" then r, g, b, a = G.getColor() end
      if font and type(G.setFont) == "function" then G.setFont(font) end
      textValue = tostring(textValue or "")
      color = color or {0.11, 0.12, 0.11, 1}
      local shadow = {0.14, 0.16, 0.13, 0.24}
      if width and type(G.printf) == "function" then
        G.setColor(shadow); G.printf(textValue, x + 1, y + 1, width, align or "left")
        G.setColor(color); G.printf(textValue, x, y, width, align or "left")
        G.printf(textValue, x + 0.45, y, width, align or "left")
      elseif type(G.print) == "function" then
        G.setColor(shadow); G.print(textValue, x + 1, y + 1)
        G.setColor(color); G.print(textValue, x, y)
        G.print(textValue, x + 0.45, y)
      else
        return false
      end
      if oldFont and type(G.setFont) == "function" then G.setFont(oldFont) end
      if r ~= nil then G.setColor(r, g, b, a or 1) else G.setColor(1, 1, 1, 1) end
      return true
    end

    local function selectedMoveForGoldScreen(screen)
      if type(screen) ~= "table" or screen.phase ~= "moves" then return nil, nil, nil end
      local index = tonumber(screen.moveIndex)
      if not index then return nil, nil, nil end
      local moves
      if type(screen.playerMoves) == "function" then
        local ok, value = pcall(screen.playerMoves, screen)
        if ok then moves = value end
      end
      if type(moves) ~= "table" then
        moves = screen.battle and screen.battle.player and screen.battle.player.moves
      end
      local selected = type(moves) == "table" and moves[index] or nil
      if type(selected) ~= "table" then return nil, nil, nil end
      local data = screen.game and screen.game.data
      local def = data and data.moves and data.moves[selected.id]
      return selected, def, data
    end

    local function goldScreenIsTop(game, screen)
      if type(screen) ~= "table" or screen.phase ~= "moves" then return false end
      local stack = game and game.stack
      if not stack then return true end
      local top
      if type(stack.top) == "function" then
        local ok, value = pcall(stack.top, stack)
        if ok then top = value end
      elseif type(stack.states) == "table" then
        top = stack.states[#stack.states]
      end
      return top == nil or top == screen
    end

    local function drawFixedGen3Category(game, screen)
      if mod.options:get("move_category_readout") == false
          or not goldScreenIsTop(game, screen) then return false end
      local selected, def, data = selectedMoveForGoldScreen(screen)
      if not selected or type(def) ~= "table" then return false end
      local label = categoryOnlyLabel(selected.id, def, data)
      if not label then return false end
      local G = rawget(_G, "love") and love.graphics or nil
      if not (G and type(G.getDimensions) == "function") then return false end
      local s = gen3Scale()
      if not s then return false end
      local sw, sh = G.getDimensions()
      -- Tuned to Gen 3 UI v1.4.0's Gold TYPE ... PP footer.  These are
      -- screen-space coordinates derived from the same scale helper used by
      -- the live-working Enemy HP Gen 3 overlay.  The centered field occupies
      -- only the blank area between the move type and PP counter.
      local x = sw - 135 * s
      local y = sh - 20.7 * s
      local width = 58 * s
      return exactGen3Print(label, x, y, 4.4 * s,
        {0.11, 0.12, 0.11, 1}, "center", width)
    end

    local function readoutLabel(id, def, data)
      if type(def) ~= "table" then return nil end
      local key = normalizeMoveKey(id)
      if key == "" then key = normalizeMoveKey(def.id) end
      if key == "" then key = normalizeMoveKey(def.name) end
      if fixedDamageMoves[key] then return "FIXED" end
      if ohkoMoves[key] then return "OHKO" end
      if reactiveDamageMoves[key] then return "REACTIVE" end
      return categoryOnlyLabel(id, def, data)
    end

    local function drawReadoutTab(chrome, label)
      if not (chrome and label) then return false end
      -- Box is Chrome.box(0, 12, 20, 6).  Keep tile 19 (right border cap)
      -- intact and anchor the readout tab to a stable left edge so the top
      -- border looks consistent across all labels.  Live Gold tuning uses the
      -- PHYSICAL readout as the baseline: one blank tile, eight letters, one
      -- blank tile.  STATUS and SPECIAL use explicit per-label padding to keep
      -- the tab visually balanced without drifting back to the far right.
      local fieldStart, lead, fieldWidth = 8, 1, 10
      if label == "STATUS" then
        lead, fieldWidth = 2, 10
      elseif label == "SPECIAL" then
        lead, fieldWidth = 1, 10
      elseif label == "FIXED" then
        lead, fieldWidth = 2, 10
      elseif label == "OHKO" then
        lead, fieldWidth = 3, 10
      elseif label == "REACTIVE" then
        lead, fieldWidth = 1, 10
      elseif label == "PHYSICAL" then
        lead, fieldWidth = 1, 10
      end
      local tx = fieldStart + lead
      local G = rawget(_G, "love") and love.graphics or nil
      local oldColor
      if G and type(G.setColor) == "function" and type(G.rectangle) == "function" then
        if type(G.getColor) == "function" then oldColor = { G.getColor() } end
        G.setColor(1, 1, 1, 1)
        G.rectangle("fill", fieldStart * 8, 12 * 8, fieldWidth * 8, 8)
      end
      chrome.print(label, tx, 12)
      if G and type(G.setColor) == "function" then
        if oldColor and #oldColor >= 3 then
          G.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] or 1)
        else
          G.setColor(1, 1, 1, 1)
        end
      end
      return true
    end

    local function normalizedUiText(value)
      if type(value) ~= "string" then return nil end
      return value:upper():gsub("[%c]", " ")
    end

    local function moveTypeToken(def)
      local token = type(def) == "table" and tostring(def.type or "") or ""
      token = token:upper():gsub("_TYPE$", ""):gsub("[^A-Z0-9]", "")
      return token
    end

    -- Run the downstream overlay chain while temporarily observing LOVE's text
    -- calls.  This is deliberately renderer-agnostic: no Gen 3 UI coordinates,
    -- font size, window size, or release number are hardcoded.  Once the UI has
    -- drawn TYPE + the selected move's type and exposes PP on the same baseline,
    -- put PHYSICAL/SPECIAL/STATUS in the actual gap using the exact current font,
    -- colour, transform, and canvas.  If the foreign renderer changes enough
    -- that these capabilities disappear, restoration is guaranteed and the
    -- native Gold tab is used as a fail-safe instead.
    local function callWithGen3Inline(next, screen, label, def)
      local G = rawget(_G, "love") and love.graphics or nil
      if not (G and type(G.print) == "function") then
        return pack(next(screen)), false
      end
      local originalPrint = G.print
      local originalPrintf = type(G.printf) == "function" and G.printf or nil
      local typeToken = moveTypeToken(def)
      if typeToken == "" then return pack(next(screen)), false end

      local rowY, typeEnd, ppX
      local injected, alreadyPresent = false, false
      local pendingExtra = nil

      local function sameRow(a, b)
        return type(a) == "number" and type(b) == "number"
          and math.abs(a - b) <= 2
      end

      local function fontWidth(text)
        local font = type(G.getFont) == "function" and G.getFont() or nil
        if font and type(font.getWidth) == "function" then
          local ok, width = pcall(font.getWidth, font, tostring(text or ""))
          if ok and type(width) == "number" then return width end
        end
        return #tostring(text or "") * 6
      end

      local function visualStartX(text, x, limit, align)
        if type(x) ~= "number" then return nil end
        if type(limit) ~= "number" then return x end
        local width = fontWidth(text)
        if align == "right" then return x + limit - width end
        if align == "center" then return x + (limit - width) / 2 end
        return x
      end

      local function wordPresent(upper, word)
        return type(upper) == "string" and upper:find(word, 1, true) ~= nil
      end

      local function maybeInject(extra)
        if injected or alreadyPresent or not (rowY and typeEnd and ppX) then return end
        local width = fontWidth(label)
        local left = typeEnd + 4
        local right = ppX - 4
        if right - left < width then return end
        local x = left + (right - left - width) / 2
        -- Preserve per-call rotation/scale arguments when PP was rendered with
        -- love.graphics.print(...).  Most Gen 3 UI builds use a global transform,
        -- but carrying these through makes the bridge safe for either style.
        if type(extra) == "table" and (extra.n or 0) > 0 then
          originalPrint(label, x, rowY, unpack(extra, 1, extra.n))
        else
          originalPrint(label, x, rowY)
        end
        injected = true
      end

      local function observe(text, x, y, limit, align, extra)
        local upper = normalizedUiText(text)
        if not upper or type(x) ~= "number" or type(y) ~= "number" then return end
        local startX = visualStartX(text, x, limit, align)
        if not startX then return end

        if wordPresent(upper, "PHYSICAL") or wordPresent(upper, "SPECIAL")
            or wordPresent(upper, "STATUS") then
          if rowY == nil or sameRow(rowY, y) then alreadyPresent = true end
        end

        local typeWordPos = upper:find("TYPE", 1, true)
        local typePos = upper:find(typeToken, 1, true)
        local ppPos = upper:find("PP", 1, true)

        if typeWordPos then
          rowY = y
          if typePos then
            typeEnd = startX + fontWidth(tostring(text):sub(1, typePos + #typeToken - 1))
          else
            typeEnd = startX + fontWidth(tostring(text))
          end
        elseif rowY and sameRow(rowY, y) and typePos then
          typeEnd = startX + fontWidth(tostring(text):sub(1, typePos + #typeToken - 1))
        end

        if rowY and sameRow(rowY, y) and ppPos then
          ppX = startX + fontWidth(tostring(text):sub(1, ppPos - 1))
          pendingExtra = extra
          maybeInject(pendingExtra)
        end
      end

      G.print = function(text, x, y, ...)
        local extra = pack(...)
        local result = pack(originalPrint(text, x, y, ...))
        observe(text, x, y, nil, nil, extra)
        return unpack(result, 1, result.n)
      end
      if originalPrintf then
        G.printf = function(text, x, y, limit, align, ...)
          local extra = pack(...)
          local result = pack(originalPrintf(text, x, y, limit, align, ...))
          observe(text, x, y, limit, align, extra)
          return unpack(result, 1, result.n)
        end
      end

      local called = pack(pcall(next, screen))
      G.print = originalPrint
      if originalPrintf then G.printf = originalPrintf end
      if not called[1] then error(called[2], 0) end

      local result = { n = called.n - 1 }
      for i = 2, called.n do result[i - 1] = called[i] end
      return result, injected or alreadyPresent
    end

    -- Native Gold still uses the proven top-border tab.  Gen 3 UI may later
    -- cover this whole panel, which is fine: the dedicated render.hud bridge
    -- below observes the replacement move panel itself and draws into its real
    -- TYPE ... PP row.  Keeping the native branch here preserves the exact
    -- non-Gen3 behavior that was already live-tested.
    hooks:wrap("battle.overlay", function(next, screen)
      goldLastScreen = screen
      local result = pack(next(screen))
      local gen3ActiveNow = gen3UiRuntimeDetected
      if not gen3ActiveNow then
        local active = gen3UiActive()
        gen3ActiveNow = active and true or false
      end
      if mod.options:get("move_category_readout") == false
          or gen3ActiveNow
          or type(screen) ~= "table" or screen.phase ~= "moves" then
        return unpack(result, 1, result.n)
      end
      local index = tonumber(screen.moveIndex)
      if not index then return unpack(result, 1, result.n) end
      local moves
      if type(screen.playerMoves) == "function" then
        local ok, value = pcall(screen.playerMoves, screen)
        if ok then moves = value end
      end
      if type(moves) ~= "table" then
        moves = screen.battle and screen.battle.player and screen.battle.player.moves
      end
      local selected = type(moves) == "table" and moves[index] or nil
      if type(selected) ~= "table" then return unpack(result, 1, result.n) end
      local data = screen.game and screen.game.data
      local def = data and data.moves and data.moves[selected.id]
      local chrome = getChrome()
      local fallback = readoutLabel(selected.id, def, data)
      if chrome and fallback then drawReadoutTab(chrome, fallback) end
      return unpack(result, 1, result.n)
    end, math.huge)

    -- ------------------------------------------------------------------
    -- Gen 3 UI / Gold move-panel bridge.
    --
    -- Gen 3 UI v1.4 replaces the presentation of the move-selection panel.
    -- Do not guess its mod id, BattleState class, cursor field or coordinates.
    -- Instead wrap the FINAL screen-space render.hud chain and observe the
    -- actual text it paints.  A compatible move panel identifies itself by
    -- drawing a TYPE row and a PP value.  The selected move is taken from the
    -- live Gen2BattleState when possible; if the replacement UI hides/renames
    -- that cursor state, the selected move name it visibly draws (SCRATCH,
    -- WATER GUN, etc.) is matched back to game.data.moves.  The category is
    -- then painted after downstream rendering, using the exact font, colour,
    -- transform and baseline captured from that TYPE/PP row.
    --
    -- This block exists only in generation == 2.  The Gen 1 backend below the
    -- early generation return is never loaded or modified by this bridge.

    local function topStateOf(game)
      local stack = game and game.stack
      if not stack then return nil end
      if type(stack.top) == "function" then
        local ok, value = pcall(stack.top, stack)
        if ok then return value end
      end
      if type(stack.states) == "table" then
        return stack.states[#stack.states]
      end
      return nil
    end

    local function candidateMovesFromState(state)
      if type(state) ~= "table" then return nil end
      if type(state.playerMoves) == "function" then
        local ok, value = pcall(state.playerMoves, state)
        if ok and type(value) == "table" then return value end
      end
      local battle = state.battle
      if type(battle) == "table" and type(battle.player) == "table"
          and type(battle.player.moves) == "table" then
        return battle.player.moves
      end
      for _, key in ipairs({ "model", "battleState", "battleModel" }) do
        local holder = state[key]
        local b = type(holder) == "table" and (holder.battle or holder) or nil
        if type(b) == "table" and type(b.player) == "table"
            and type(b.player.moves) == "table" then
          return b.player.moves
        end
      end
      return nil
    end

    local function selectedFromState(state, data)
      if type(state) ~= "table" then return nil, nil end
      local moves = candidateMovesFromState(state)
      -- Some replacement screens keep the chosen move itself rather than an
      -- index.  Accept only a table carrying an id that resolves in this Gold
      -- move table; arbitrary menu item tables are ignored.
      for _, key in ipairs({ "selectedMove", "currentMove", "move" }) do
        local row = state[key]
        if type(row) == "table" and row.id and data and data.moves
            and data.moves[row.id] then
          return row, data.moves[row.id]
        elseif type(row) == "string" and data and data.moves and data.moves[row] then
          return { id = row }, data.moves[row]
        end
      end
      if type(moves) ~= "table" then return nil, nil end

      local holders = { state, state.menu, state.moveMenu, state.movesMenu,
                        state.cursorState, state.selection }
      local keys = { "moveIndex", "selectedMoveIndex", "moveCursor",
                     "cursor", "index", "selected" }
      for _, holder in ipairs(holders) do
        if type(holder) == "table" then
          for _, key in ipairs(keys) do
            local raw = tonumber(holder[key])
            if raw then
              -- Native Gold is 1-based.  A replacement UI is allowed to use a
              -- 0-based cursor, so try both without ever leaving the move list.
              for _, idx in ipairs({ raw, raw + 1 }) do
                local row = moves[idx]
                if type(row) == "table" and row.id and data and data.moves
                    and data.moves[row.id] then
                  return row, data.moves[row.id]
                end
              end
            end
          end
        end
      end
      return nil, nil
    end

    local function normalizedMoveText(value)
      local text = tostring(value or ""):upper()
      text = text:gsub("[%c]", " "):gsub("[_%-]+", " ")
      text = text:gsub("[^A-Z0-9 '%.]", " ")
      text = text:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
      return text
    end

    local function moveNameIndex(data)
      local byName = {}
      for id, def in pairs((data and data.moves) or {}) do
        if type(def) == "table" then
          local names = { def.name, id }
          for _, value in ipairs(names) do
            local key = normalizedMoveText(value)
            if key ~= "" and byName[key] == nil then
              byName[key] = { id = id, def = def }
            end
          end
        end
      end
      return byName
    end

    local function cloneTransform(G)
      if type(G.getTransform) ~= "function" then return nil end
      local ok, transform = pcall(G.getTransform)
      if not ok or not transform then return nil end
      if type(transform.clone) == "function" then
        local okClone, clone = pcall(transform.clone, transform)
        if okClone then return clone end
      end
      return transform
    end

    local function callFontWidth(call, text)
      local font = call and call.font
      if font and type(font.getWidth) == "function" then
        local ok, width = pcall(font.getWidth, font, tostring(text or ""))
        if ok and type(width) == "number" then return width end
      end
      return #tostring(text or "") * 6
    end

    local function visualCallStart(call)
      if not call or type(call.x) ~= "number" then return nil end
      if call.kind ~= "printf" or type(call.limit) ~= "number" then return call.x end
      local width = callFontWidth(call, call.text)
      if call.align == "right" then return call.x + call.limit - width end
      if call.align == "center" then return call.x + (call.limit - width) / 2 end
      return call.x
    end

    local function sameBaseline(a, b)
      return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= 3
    end

    local function colorLuma(color)
      if type(color) ~= "table" then return math.huge end
      local r = tonumber(color[1]) or 1
      local g = tonumber(color[2]) or 1
      local b = tonumber(color[3]) or 1
      return ((0.2126 * r) + (0.7152 * g) + (0.0722 * b))
    end

    local function callStyleScore(call)
      if type(call) ~= "table" then return math.huge end
      local a = (type(call.color) == "table" and tonumber(call.color[4])) or 1
      local x = type(call.startX) == "number" and math.abs(call.startX - math.floor(call.startX + 0.5)) or 1
      local y = type(call.y) == "number" and math.abs(call.y - math.floor(call.y + 0.5)) or 1
      -- Lower is better: prefer the darkest fully-opaque observed draw that
      -- already sits on whole-pixel coordinates.  This avoids inheriting a
      -- pale helper/shadow pass from the replacement footer.
      return colorLuma(call.color) + ((1 - math.max(0, math.min(a, 1))) * 4) + (x * 0.5) + (y * 0.5)
    end

    local function captureHudCall(G, kind, text, x, y, limit, align)
      local call = {
        kind = kind, text = tostring(text or ""), x = x, y = y,
        limit = limit, align = align,
        font = type(G.getFont) == "function" and G.getFont() or nil,
        transform = cloneTransform(G),
      }
      if type(G.getColor) == "function" then
        local r, g, b, a = G.getColor()
        call.color = { r, g, b, a }
      end
      call.startX = visualCallStart(call)
      call.width = callFontWidth(call, call.text)
      call.upper = normalizedUiText(call.text) or ""
      return call
    end

    local function findSelectedFromHud(calls, data, typeY)
      local index = moveNameIndex(data)
      local best, bestScore
      for _, call in ipairs(calls) do
        local hit = index[normalizedMoveText(call.text)]
        if hit and type(call.startX) == "number" and type(call.y) == "number" then
          -- The selected-move detail is the leftmost move-name rendering in
          -- the footer; the four-choice list sits to its right.  Prefer that
          -- leftmost occurrence, with closeness to the TYPE row as tie-break.
          local vertical = type(typeY) == "number" and math.abs(typeY - call.y) or 0
          local score = call.startX * 1000 + vertical
          if bestScore == nil or score < bestScore then
            bestScore = score
            best = hit
          end
        end
      end
      if best then return { id = best.id }, best.def end
      return nil, nil
    end

    local function rowGeometry(calls, def)
      local typeCall
      for _, call in ipairs(calls) do
        if call.upper:find("TYPE", 1, true) then
          typeCall = call
          break
        end
      end
      if not typeCall then return nil end
      local rowY = typeCall.y
      local ppCall
      for _, call in ipairs(calls) do
        if sameBaseline(rowY, call.y) and call.upper:find("PP", 1, true) then
          ppCall = call
          break
        end
      end
      if not ppCall then return nil end

      -- Already supported natively by a future Gen 3 UI?  Do not duplicate it.
      for _, call in ipairs(calls) do
        if sameBaseline(rowY, call.y) and
            (call.upper:find("PHYSICAL", 1, true)
             or call.upper:find("SPECIAL", 1, true)
             or call.upper:find("STATUS", 1, true)) then
          return { already = true }
        end
      end

      local typeToken = normalizedMoveText(def and def.type):gsub(" ", "")
      local typeEnd
      -- The category must visually belong to TYPE, not PP.  Keep the exact
      -- font/transform/color of the rendered type value (WATER/NORMAL/etc.)
      -- and fall back to the TYPE label when a replacement UI emits the row in
      -- a shape where the value cannot be isolated.  Gen 3 UI v1.4.0 appears
      -- to render footer text in more than one pass; some captures therefore
      -- see both a washed-out helper pass and the final darker visible pass.
      -- Prefer the darkest matching type-token draw on the baseline so our
      -- inserted PHYSICAL/SPECIAL/STATUS inherits the same visible style the
      -- player actually sees, not an earlier pale pass.
      local typeStyle = typeCall
      local bestStyle, bestEnd, bestScore
      for _, call in ipairs(calls) do
        if sameBaseline(rowY, call.y) then
          local compact = normalizedMoveText(call.text):gsub(" ", "")
          local pos = typeToken ~= "" and compact:find(typeToken, 1, true) or nil
          if pos then
            local rawUpper = tostring(call.text):upper()
            local rawPos = rawUpper:find(typeToken, 1, true)
            local candidateEnd
            if rawPos then
              candidateEnd = call.startX + callFontWidth(call,
                tostring(call.text):sub(1, rawPos + #typeToken - 1))
            else
              candidateEnd = call.startX + call.width
            end
            local score = callStyleScore(call)
            if bestScore == nil or score < bestScore then
              bestScore = score
              bestStyle = call
              bestEnd = candidateEnd
            end
          end
        end
      end
      if bestStyle then
        typeStyle = bestStyle
        typeEnd = bestEnd
      end
      if not typeEnd then
        typeEnd = typeCall.startX + typeCall.width
      end

      local ppX = ppCall.startX
      local ppPos = tostring(ppCall.text):upper():find("PP", 1, true)
      if ppPos and ppPos > 1 then
        ppX = ppCall.startX + callFontWidth(ppCall,
          tostring(ppCall.text):sub(1, ppPos - 1))
      end
      if type(typeEnd) ~= "number" or type(ppX) ~= "number" or ppX <= typeEnd then
        return nil
      end

      -- Fixed footer-local column.  One "cell" is the average advance of the
      -- literal TYPE label itself, so the point scales naturally with the
      -- replacement UI font/transform.  Column 24 is intentionally independent
      -- of both the type VALUE and the PP text/position.
      local typeLabelWidth = callFontWidth(typeCall, "TYPE")
      local cell = type(typeLabelWidth) == "number" and typeLabelWidth / 4 or nil
      local fixedX = type(cell) == "number" and cell > 0
          and (typeCall.startX + cell * 24) or nil
      if type(fixedX) ~= "number" then return nil end

      return { y = (typeStyle and typeStyle.y) or rowY,
        typeEnd = typeEnd, ppX = ppX, fixedX = fixedX, style = typeStyle }
    end

    local function drawObservedCategory(G, originalPrint, geom, label)
      if not (geom and label and geom.style) or geom.already then return false end
      local style = geom.style
      local space = callFontWidth(style, " ")
      local labelWidth = callFontWidth(style, label)
      -- Fixed footer-local column.  The category start is anchored to a stable
      -- point derived from the literal TYPE label, not from PP and not from the
      -- varying move-type value.  This keeps the first letter of PHYSICAL /
      -- SPECIAL / STATUS on the same X across the whole footer row.
      local x = tonumber(geom.fixedX)
      if type(x) ~= "number" then return false end
      local minX = geom.typeEnd + math.max(2, space)
      if x < minX then x = minX end
      if geom.ppX and x + labelWidth >= geom.ppX then return false end
      local y = geom.y

      local pushed = false
      if type(G.push) == "function" then
        local ok = pcall(G.push, "all")
        pushed = ok
      end
      local oldFont = type(G.getFont) == "function" and G.getFont() or nil
      local oldColor
      if type(G.getColor) == "function" then oldColor = { G.getColor() } end
      if style.transform and type(G.replaceTransform) == "function" then
        pcall(G.replaceTransform, style.transform)
      end
      if style.font and type(G.setFont) == "function" then pcall(G.setFont, style.font) end
      if style.color and type(G.setColor) == "function" then
        pcall(G.setColor, style.color[1], style.color[2], style.color[3], style.color[4] or 1)
      end
      -- Keep the TEST K semibold appearance, but soften it to match Gen 3 UI:
      -- one normal pass plus a half-pixel, partially transparent shoulder.  A
      -- full one-pixel triple overdraw made the category visibly harsher than
      -- the antialiased footer text.
      originalPrint(label, x, y)
      if style.color and type(G.setColor) == "function" then
        pcall(G.setColor, style.color[1], style.color[2], style.color[3],
          (style.color[4] or 1) * 0.70)
        originalPrint(label, x + 0.5, y)
        pcall(G.setColor, style.color[1], style.color[2], style.color[3],
          style.color[4] or 1)
      else
        originalPrint(label, x + 0.5, y)
      end
      if pushed and type(G.pop) == "function" then
        pcall(G.pop)
      else
        if oldFont and type(G.setFont) == "function" then pcall(G.setFont, oldFont) end
        if oldColor and type(G.setColor) == "function" then
          pcall(G.setColor, oldColor[1], oldColor[2], oldColor[3], oldColor[4] or 1)
        end
      end
      return true
    end

    local renderHudOk = pcall(function()
      hooks:wrap("render.hud", function(next, game, viewport)
        if mod.options:get("move_category_readout") == false then
          return next(game, viewport)
        end
        local G = rawget(_G, "love") and love.graphics or nil
        if not (G and type(G.print) == "function") then
          return next(game, viewport)
        end

        local originalPrint = G.print
        local originalPrintf = type(G.printf) == "function" and G.printf or nil
        local calls = {}
        G.print = function(text, x, y, ...)
          calls[#calls + 1] = captureHudCall(G, "print", text, x, y)
          return originalPrint(text, x, y, ...)
        end
        if originalPrintf then
          G.printf = function(text, x, y, limit, align, ...)
            calls[#calls + 1] = captureHudCall(G, "printf", text, x, y, limit, align)
            return originalPrintf(text, x, y, limit, align, ...)
          end
        end

        local called = pack(pcall(next, game, viewport))
        G.print = originalPrint
        if originalPrintf then G.printf = originalPrintf end
        if not called[1] then error(called[2], 0) end

        local typeY
        for _, call in ipairs(calls) do
          if call.upper:find("TYPE", 1, true) then typeY = call.y break end
        end
        if typeY ~= nil then
          local data = game and game.data
          local state = topStateOf(game)
          local selected, def = selectedFromState(state, data)
          if not def then selected, def = findSelectedFromHud(calls, data, typeY) end
          local geom = def and rowGeometry(calls, def) or nil
          local label = def and categoryOnlyLabel(selected and selected.id, def, data) or nil
          if geom and geom.already then
            gen3UiRuntimeDetected = true
            gen3UiRuntimeInline = true
            gen3UiRenderHudSource = "observed-native-category-row"
          elseif geom and label and drawObservedCategory(G, originalPrint, geom, label) then
            gen3UiRuntimeDetected = true
            gen3UiRuntimeInline = true
            gen3UiRenderHudDrawn = true
            gen3UiRenderHudSource = "observed-type-pp-row"
          end
        end

        local result = { n = called.n - 1 }
        for i = 2, called.n do result[i - 1] = called[i] end
        return unpack(result, 1, result.n)
      end, math.huge)
    end)
    gen3UiRenderHudInstalled = renderHudOk
    readoutHookInstalled = true
  elseif mod.log and type(mod.log.warn) == "function" then
    mod.log:warn("Gold Move Category Readout unavailable: public battle.overlay hook API is missing")
  end

  mod.exports = mod.exports or {}
  mod.exports.specialSplitActive = function() return requestedSpecialActive end
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
  mod.exports.modernUiLevelUpOverrideEnabled = mod.exports.modernUiBattleWipOverrideEnabled
  mod.exports.getMoveCategory = function(move)
    if not moveSplitActive then return nil end
    local id = type(move) == "table" and move.id or nil
    local index = type(move) == "table" and goldMoveIndex(id, move) or tonumber(move)
    return index and GEN4_MOVE_CATEGORY_BY_INDEX[index] or nil
  end
  -- Legacy v1 contract: Gold does not turn the mod-owned Gen II stat table into
  -- gameplay authority.  Consumers needing native Gold stats should use v2.
  mod.exports.getSpecialBaseStats = function() return nil end
  mod.exports.attachSplitStats = function(mon) return mon end

  local function getGameplayConfig()
    return {
      specialStats = gameplayConfig.specialStats,
      moveCategories = gameplayConfig.moveCategories,
    }
  end
  local function getEffectiveGameplayConfig()
    return {
      specialStats = effectiveConfig.specialStats,
      moveCategories = effectiveConfig.moveCategories,
    }
  end
  local function getEffectiveSpecialBaseStats(species)
    local def = type(species) == "table" and species or nil
    if not def and mod.content and mod.content.pokemon
        and type(mod.content.pokemon.get) == "function" then
      local ok, value = pcall(mod.content.pokemon.get, mod.content.pokemon, species)
      if ok then def = value end
    end
    if type(def) ~= "table" then return nil end
    local spa = tonumber(def.specialAttack)
      or (type(def.baseStats) == "table" and tonumber(def.baseStats.specialAttack))
    local spd = tonumber(def.specialDefense)
      or (type(def.baseStats) == "table" and tonumber(def.baseStats.specialDefense))
    if not (spa and spd) then return nil end
    return { specialAttack = spa, specialDefense = spd }
  end
  local function getDiagnostics()
    local standaloneMoveCategory = type(mod.find) == "function"
      and mod.find("move_category") ~= nil or false
    local gen3Ui = gen3UiHandleForDiagnostics()
    return {
      modVersion = tostring(mod.version or "2.6.5"),
      apiVersion = 1,
      generation = "gold",
      requested = getGameplayConfig(),
      effective = getEffectiveGameplayConfig(),
      gameplay = getGameplayConfig(),
      gold = {
        nativeSpecialStats = true,
        gen1StatBackendInstalled = false,
        categoryBridgeActive = moveSplitActive,
        aiCategoryBridgeActive = moveSplitActive,
        categoryConsumers = {
          normalDamage = "covered",
          screens = "covered",
          damageHistory = "covered",
          counterMirrorCoat = "covered-via-damage-kind",
          aiExpectedDamage = "covered",
          smartAiHistory = "covered",
          readout = readoutHookInstalled and "covered-public-overlay+gen3-inline" or "hook-unavailable",
        },
        canonicalMovesSeen = canonicalCount,
        canonicalMovesExpected = 251,
        registryRowsChanged = registryChanged,
        registryConflictsObserved = registryConflicts,
        identitySkips = identitySkips,
        readoutHookInstalled = readoutHookInstalled,
        gen3RenderHudInstalled = gen3UiRenderHudInstalled,
        gen3RenderHudDrawn = gen3UiRenderHudDrawn,
        gen3RenderHudSource = gen3UiRenderHudSource,
      },
      link = {
        affectsLink = true,
        configRevision = gameplayConfigRevision,
        configRegistered = linkConfigRegistered,
      },
      integrations = {
        crystal251 = { detected = type(mod.find) == "function" and mod.find("CRYSTAL_251") ~= nil or false, applicable = false },
        modernUi = { detected = type(mod.find) == "function" and mod.find("gen1_modern_ui") ~= nil or false, applicable = false },
        gen3Ui = {
          detected = gen3UiRuntimeDetected or gen3Ui ~= nil,
          runtimeDetected = gen3UiRuntimeDetected,
          handleDetected = gen3Ui ~= nil,
          version = gen3Ui and tostring(gen3Ui.version or "unknown") or nil,
          applicable = true,
          presentation = gen3UiRenderHudDrawn and "gen3-render-hud-type-row" or (gen3UiRuntimeInline and "inline-type-row" or "native-gold-tab"),
          activation = gen3UiRenderHudSource or "automatic-render-capability",
        },
        standaloneMoveCategory = { detected = standaloneMoveCategory, integratedReadoutEnabled = mod.options:get("move_category_readout") ~= false },
      },
    }
  end

  mod.exports.getGameplayConfig = getGameplayConfig
  mod.exports.getEffectiveGameplayConfig = getEffectiveGameplayConfig
  mod.exports.getLinkConfigRevision = function() return gameplayConfigRevision end
  mod.exports.getDiagnostics = getDiagnostics
  mod.exports.getEffectiveSpecialBaseStats = getEffectiveSpecialBaseStats

  mod.exports.specialStatSplit = {
    apiVersion = 1,
    modVersion = tostring(mod.version or "2.6.5"),
    specialSplitActive = mod.exports.specialSplitActive,
    moveCategorySplitActive = mod.exports.moveCategorySplitActive,
    moveCategoryReadoutEnabled = mod.exports.moveCategoryReadoutEnabled,
    getMoveCategory = mod.exports.getMoveCategory,
    getSpecialBaseStats = mod.exports.getSpecialBaseStats,
    attachSplitStats = mod.exports.attachSplitStats,
    getGameplayConfig = getGameplayConfig,
    getLinkConfigRevision = mod.exports.getLinkConfigRevision,
    getDiagnostics = getDiagnostics,
  }
  mod.exports.specialStatSplitV2 = {
    apiVersion = 2,
    modVersion = tostring(mod.version or "2.6.5"),
    generation = function() return "gold" end,
    getRequestedGameplayConfig = getGameplayConfig,
    getEffectiveGameplayConfig = getEffectiveGameplayConfig,
    getEffectiveSpecialBaseStats = getEffectiveSpecialBaseStats,
    getMoveCategory = mod.exports.getMoveCategory,
    attachSplitStats = mod.exports.attachSplitStats,
    getDiagnostics = getDiagnostics,
  }

  if mod.log and type(mod.log.info) == "function" then
    mod.log:info(("Special Stat Split Gold backend: special requested=%s effective=native_gen2; move requested=%s effective=%s; canonical moves=%d/251; identity skips=%d; category bridge=%s; link=%s")
      :format(requestedSpecial, requestedMove, effectiveMove, canonicalCount,
        identitySkips, moveSplitActive and "active" or "native-type",
        linkConfigRegistered and gameplayConfigRevision or "unregistered"))
    if canonicalCount ~= 251 then
      mod.log:info("Gold move identity audit is incomplete at entry time; diagnostics will report the observed registry count. Do not claim Gold release compatibility until runtime data merge/live tests confirm 251/251.")
    end
  end
end

return function(mod)
  if activeGeneration() == 2 then
    return runGoldBackend(mod)
  end
  local Stats = require("src.pokemon.Stats")
  local Damage = require("src.battle.Damage")
  local Experience = require("src.battle.Experience")
  local ItemEffects = require("src.inventory.ItemEffects")
  local MoveEffects = require("src.battle.MoveEffects")
  local SummaryMenu = require("src.ui.SummaryMenu")
  local BattleState = require("src.battle.BattleState")
  local Font = require("src.render.Font")
  local Strings = require("src.core.Strings")
  local SaveData = require("src.core.SaveData")

  -- Optional Crystal 251 compatibility. Crystal's move runtime table is used
  -- for its battle bridge. Its split-stat export is captured only as a
  -- last-resort fallback/diagnostic source: canonical #001-251 SpA/SpD always
  -- come from this mod's own audited Generation II-V table.
  local crystalMod = type(mod.find) == "function" and mod.find("CRYSTAL_251") or nil
  local crystalExports = crystalMod and crystalMod.exports or nil
  local crystalBaseStats = crystalExports and crystalExports.crystalBaseStats or nil
  local crystalMoves = crystalExports and crystalExports.crystalMoves or nil
  local crystalStatCount = SplitStats.setCrystalBaseStats(crystalBaseStats)
  if crystalStatCount > 0 and mod.log and type(mod.log.info) == "function" then
    mod.log:info(("Crystal 251 split-stat export detected (%d records); canonical mod-owned #001-251 table has priority")
      :format(crystalStatCount))
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
      description = "Show PHYS/ or SPEC/ instead of TYPE/ for damaging moves in the battle move-select box. Status/fixed-damage moves keep TYPE/.",
    },
    {
      key = "modern_ui_override",
      label = "ModernUI Override",
      type = "toggle",
      default = true,
      description = "Surgically replace only Modern UI's legacy stat text on supported Party/Summary renderers while preserving Modern UI's own layout, sprites, bars, icons and styling. Party row layout is selectable below; OFF leaves Modern UI completely untouched.",
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
      description = "Choose how the five split stats are drawn in Modern UI's Party detail. 2 ROWS uses full labels; 1 ROW keeps compact ATK/DEF/SPD/SPATK/SPDEF labels. Both layouts adapt to the live panel width.",
    },
    {
      key = "modern_ui_battle_wip_override",
      label = "ModernUI BattleWIP Override",
      type = "toggle",
      default = false,
      description = "Opt in to compatibility overrides for Gen1 Modern UI's experimental Battle UI (WIP), including battle Party split-stat presentation and the level-up correction card. OFF leaves the experimental battle presentation untouched.",
    },
  })

  -- Capture the two gameplay modes once at load time: changing either requires save + restart.
  -- ModernUI presentation options are presentation-only and are read live.
  local active = tostring(mod.options:get("mode") or "gen2") == "gen2"
  local moveSplitActive = tostring(mod.options:get("move_split") or "gen4") == "gen4"

  -- Link battles are lockstep simulations, so presentation-only differences may
  -- safely diverge but gameplay options may not. Gen1Recomp has included since v0.1.75
  -- link_fields.rev in its public link fingerprint. Register only a deterministic
  -- revision string here: no handshake/fingerprint hook is replaced or wrapped.
  local gameplayConfig = {
    specialStats = active and "gen2" or "vanilla",
    moveCategories = moveSplitActive and "gen4" or "gen1",
  }
  local gameplayConfigRevision = ("special=%s;move=%s")
    :format(gameplayConfig.specialStats, gameplayConfig.moveCategories)
  local linkConfigRegistered = false
  if mod.content and mod.content.link_fields
      and type(mod.content.link_fields.register) == "function" then
    mod.content.link_fields:register("special_stat_split_rules", {
      rev = gameplayConfigRevision,
    })
    linkConfigRegistered = true
  elseif mod.log and type(mod.log.warn) == "function" then
    mod.log:warn("Link configuration fingerprint extension unavailable; same-version peers with different Special Stat Split gameplay options may not be rejected before battle")
  end

  -- Integrated Move Category Readout (formerly the standalone move_category mod).
  -- This is presentation-only and live-toggleable: it replaces BattleState's
  -- otherwise redundant TYPE/ label with PHYS/ or SPEC/ for damaging moves.
  -- Category resolution mirrors Damage.categoryOf: explicit move.category first,
  -- then the active type chart. Power-0/status/fixed-damage moves keep TYPE/.
  --
  -- Coexistence with the old standalone mod is intentionally composable. The
  -- standalone mod is an optional dependency, so when it is active it loads
  -- first. Both wrappers only transform the exact TYPE/ token. Whichever wrapper
  -- transforms it first passes PHYS/ or SPEC/ downstream, which the other wrapper
  -- ignores; therefore two installed copies never draw twice or raise a conflict.
  -- If either mod's readout toggle is ON, the readout is visible; if both are OFF,
  -- vanilla TYPE/ is preserved.
  do
    local gen1Gen3UiRuntimeDetected = false
    local function gen1Gen3UiDeclaredActive()
      if type(mod.find) == "function" then
        for _, id in ipairs({ "gen3_battle_ui", "gen3_battle_ui_overhaul", "gen3_ui" }) do
          local ok, handle = pcall(mod.find, id)
          if ok and handle then return true end
        end
      end
      local ok, Runtime = pcall(require, "src.mods.Runtime")
      local hooks = ok and Runtime and Runtime.hooks or nil
      local chain = hooks and hooks.chains and hooks.chains["render.hud"]
      if type(chain) == "table" then
        for _, entry in ipairs(chain) do
          if type(entry) == "table" and type(entry.callback) == "function"
              and tostring(entry.owner or "") == "gen3_battle_ui" then
            return true
          end
        end
      end
      return false
    end

    local LABELS = { physical = "PHYS/", special = "SPEC/" }
    local TYPE_LABEL = Strings("TYPE/")
    local TypeChart = require("src.battle.TypeChart")
    local readout = rawget(Font, MOVE_READOUT_PATCH_KEY)

    if not readout then
      readout = {
        originalDraw = Font.draw,
        currentBattle = nil,
        typeLabel = TYPE_LABEL,
        categoryLabel = nil,
      }
      rawset(Font, MOVE_READOUT_PATCH_KEY, readout)

      Font.draw = function(text, x, y, ...)
        if text == readout.typeLabel and type(readout.suppressNativeType) == "function"
            and readout.suppressNativeType() then
          -- Gen 3 UI owns the wide move footer.  Do not let our native Gen 1
          -- TYPE/ -> PHYS/SPEC shim (or a downstream standalone copy) leak out
          -- behind that replacement panel, especially in widescreen layouts.
          return nil
        end
        if text == readout.typeLabel and type(readout.categoryLabel) == "function" then
          text = readout.categoryLabel(readout.currentBattle) or text
        end
        return readout.originalDraw(text, x, y, ...)
      end
    end

    -- Hot reload updates behavior/state without stacking another Font.draw wrapper.
    readout.typeLabel = TYPE_LABEL
    readout.suppressNativeType = function()
      return gen1Gen3UiRuntimeDetected or gen1Gen3UiDeclaredActive()
    end
    readout.categoryLabel = function(battle)
      if mod.options:get("move_category_readout") == false then return nil end
      if not battle or battle.phase ~= "moveSelect" then return nil end

      local moves = battle.player and battle.player.curMoves
      local selected = moves and moves[battle.moveIndex]
      if not selected then return nil end

      local def = battle.data and battle.data.moves and battle.data.moves[selected.id]
      if not def then return nil end
      if (def.power or 0) == 0 or def.category == "status" then return nil end

      local category = def.category or (def.type and TypeChart.category(def.type))
      return LABELS[category] or LABELS.physical
    end

    if mod.events and type(mod.events.on) == "function" then
      mod.events:on("battle.started", function(payload)
        readout.currentBattle = payload and payload.battle or nil
      end)
      mod.events:on("battle.ended", function()
        readout.currentBattle = nil
      end)
    end

    local standalone = type(mod.find) == "function" and mod.find("move_category") or nil
    if standalone and mod.log and type(mod.log.info) == "function" then
      mod.log:info("Standalone Move Category Readout detected; integrated readout composes without duplicate output")
    end

    mod.exports.moveCategoryReadoutEnabled = function()
      return mod.options:get("move_category_readout") ~= false
    end

    -- Gen 3 Inspired UI compatibility for GEN 1.
    --
    -- Keep the proven native Gen 1 TYPE/ -> PHYS/SPEC Font.draw shim above
    -- completely intact.  A replacement Gen 3 UI does not use that tiny
    -- cartridge-style TYPE/ token; instead it paints a wide screen-space
    -- footer such as "TYPE  WATER ... PP 25 / 25" from render.hud.  Observe
    -- that real footer after all downstream HUD renderers have run and inject
    -- PHYSICAL / SPECIAL / STATUS into its actual free space.  This is the
    -- same live-proven presentation strategy as the Gold TEST K path, but is
    -- implemented independently inside the Gen 1 backend so Gold behavior is
    -- not changed by this compatibility extension.
    local gen1Gen3HudObserverInstalled = false

    local function gen1FullCategoryLabel(id, def)
      if type(def) ~= "table" then return nil end
      local index = tonumber(def.index)
      local audited = index and GEN4_MOVE_CATEGORY_BY_INDEX[index] or nil
      if index and index <= 165 and isCanonicalGen1Move(id, def, index)
          and audited == "status" then
        return "STATUS"
      end
      if def.category == "status" or (tonumber(def.power) or 0) == 0 then
        return "STATUS"
      end
      local category = def.category
      if category ~= "physical" and category ~= "special" then
        category = def.type and TypeChart.category(def.type) or nil
      end
      if category == "special" then return "SPECIAL" end
      if category == "physical" then return "PHYSICAL" end
      return nil
    end

    local function gen1UiText(value)
      if type(value) ~= "string" then return "" end
      return value:upper():gsub("[%c]", " ")
    end

    local function gen1MoveText(value)
      local out = tostring(value or ""):upper()
      out = out:gsub("[%c]", " "):gsub("[_%-]+", " ")
      out = out:gsub("[^A-Z0-9 '%.]", " ")
      out = out:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
      return out
    end

    local function gen1TypeToken(value)
      local out = gen1MoveText(value)
      out = out:gsub("%s+TYPE$", "")
      return out:gsub(" ", "")
    end

    local function gen1CloneTransform(G)
      if type(G.getTransform) ~= "function" then return nil end
      local ok, transform = pcall(G.getTransform)
      if not ok or not transform then return nil end
      if type(transform.clone) == "function" then
        local okClone, clone = pcall(transform.clone, transform)
        if okClone then return clone end
      end
      return transform
    end

    local function gen1CallWidth(call, value)
      local font = call and call.font
      if font and type(font.getWidth) == "function" then
        local ok, width = pcall(font.getWidth, font, tostring(value or ""))
        if ok and type(width) == "number" then return width end
      end
      return #tostring(value or "") * 6
    end

    local function gen1CallStart(call)
      if not call or type(call.x) ~= "number" then return nil end
      if call.kind ~= "printf" or type(call.limit) ~= "number" then
        return call.x
      end
      local width = gen1CallWidth(call, call.text)
      if call.align == "right" then return call.x + call.limit - width end
      if call.align == "center" then return call.x + (call.limit - width) / 2 end
      return call.x
    end

    local function gen1PointInStyleSpace(fromTransform, toTransform, x, y)
      if type(x) ~= "number" or type(y) ~= "number" then return x, y end
      if fromTransform and toTransform
          and type(fromTransform.transformPoint) == "function"
          and type(toTransform.inverseTransformPoint) == "function" then
        local okScreen, sx, sy = pcall(fromTransform.transformPoint,
          fromTransform, x, y)
        if okScreen and type(sx) == "number" and type(sy) == "number" then
          local okLocal, lx, ly = pcall(toTransform.inverseTransformPoint,
            toTransform, sx, sy)
          if okLocal and type(lx) == "number" and type(ly) == "number" then
            return lx, ly
          end
        end
      end
      return x, y
    end

    local function gen1SameBaseline(a, b)
      return type(a) == "number" and type(b) == "number"
        and math.abs(a - b) <= 3
    end

    local function gen1ColorLuma(color)
      if type(color) ~= "table" then return math.huge end
      local r = tonumber(color[1]) or 1
      local g = tonumber(color[2]) or 1
      local b = tonumber(color[3]) or 1
      return 0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    local function gen1StyleScore(call)
      if type(call) ~= "table" then return math.huge end
      local a = type(call.color) == "table" and tonumber(call.color[4]) or 1
      a = math.max(0, math.min(a or 1, 1))
      local fx = type(call.startX) == "number"
        and math.abs(call.startX - math.floor(call.startX + 0.5)) or 1
      local fy = type(call.y) == "number"
        and math.abs(call.y - math.floor(call.y + 0.5)) or 1
      return gen1ColorLuma(call.color) + ((1 - a) * 4) + fx * 0.5 + fy * 0.5
    end

    local function gen1CaptureHudCall(G, kind, value, x, y, limit, align)
      local call = {
        kind = kind, text = tostring(value or ""), x = x, y = y,
        limit = limit, align = align,
        font = type(G.getFont) == "function" and G.getFont() or nil,
        transform = gen1CloneTransform(G),
      }
      if type(G.getColor) == "function" then
        local r, g, b, a = G.getColor()
        call.color = { r, g, b, a }
      end
      call.startX = gen1CallStart(call)
      call.width = gen1CallWidth(call, call.text)
      call.upper = gen1UiText(call.text)
      return call
    end

    local function gen1MoveNameIndex(data)
      local byName = {}
      for id, def in pairs((data and data.moves) or {}) do
        if type(def) == "table" then
          -- Do not use ipairs({def.name, id}) here: many Gen 1 move records
          -- rely on the registry id and have no explicit name, and ipairs
          -- stops immediately when slot 1 is nil.
          for _, value in ipairs({ id, def.name or id }) do
            local key = gen1MoveText(value)
            if key ~= "" and byName[key] == nil then
              byName[key] = { id = id, def = def }
            end
          end
        end
      end
      return byName
    end

    local function gen1SelectedFromBattle(battle, data)
      if type(battle) ~= "table" then return nil, nil end
      local moves = battle.player and battle.player.curMoves
      local index = tonumber(battle.moveIndex)
      local selected = type(moves) == "table" and index and moves[index] or nil
      if type(selected) == "table" and selected.id and data and data.moves
          and data.moves[selected.id] then
        return selected, data.moves[selected.id]
      end
      return nil, nil
    end

    local function gen1SelectedFromHud(calls, data, typeY)
      local index = gen1MoveNameIndex(data)
      local best, bestScore
      for _, call in ipairs(calls) do
        local hit = index[gen1MoveText(call.text)]
        if hit and type(call.startX) == "number" and type(call.y) == "number" then
          local vertical = type(typeY) == "number" and math.abs(typeY - call.y) or 0
          local score = call.startX * 1000 + vertical
          if bestScore == nil or score < bestScore then
            bestScore = score
            best = hit
          end
        end
      end
      if best then return { id = best.id }, best.def end
      return nil, nil
    end

    local function gen1RowGeometry(calls, def)
      -- GEN 1 Gen3UI anchor source: the literal TYPE label is the stable left
      -- landmark of the footer row.  Do NOT derive category X from the visible
      -- type value or from PP: both of those move with their contents in the
      -- live v1.4.0 Gen 1 layout.
      local typeCall, typeCallScore
      for _, call in ipairs(calls) do
        local compact = tostring(call.upper or ""):gsub("%s+", "")
        if compact == "TYPE" then
          local score = gen1StyleScore(call)
          if typeCallScore == nil or score < typeCallScore then
            typeCallScore = score
            typeCall = call
          end
        end
      end
      if not typeCall then
        for _, call in ipairs(calls) do
          if call.upper:find("TYPE", 1, true) then
            typeCall = call
            break
          end
        end
      end
      if not typeCall then return nil end
      local rowY = typeCall.y
      local ppCall, ppScore
      for _, call in ipairs(calls) do
        if gen1SameBaseline(rowY, call.y) and call.upper:find("PP", 1, true) then
          local score = gen1StyleScore(call)
          if ppScore == nil or score < ppScore then
            ppScore = score
            ppCall = call
          end
        end
      end
      if not ppCall then return nil end

      for _, call in ipairs(calls) do
        if gen1SameBaseline(rowY, call.y) and
            (call.upper:find("PHYSICAL", 1, true)
             or call.upper:find("SPECIAL", 1, true)
             or call.upper:find("STATUS", 1, true)) then
          return { already = true }
        end
      end

      local token = gen1TypeToken(def and def.type)
      local typeStyle = typeCall
      local typeEnd
      local bestScore
      for _, call in ipairs(calls) do
        if gen1SameBaseline(rowY, call.y) then
          local compact = gen1MoveText(call.text):gsub(" ", "")
          local pos = token ~= "" and compact:find(token, 1, true) or nil
          if pos then
            local rawUpper = tostring(call.text):upper():gsub("_TYPE", "")
            local rawPos = rawUpper:find(token, 1, true)
            local candidateEnd
            if rawPos then
              candidateEnd = call.startX + gen1CallWidth(call,
                tostring(call.text):sub(1, rawPos + #token - 1))
            else
              candidateEnd = call.startX + call.width
            end
            local score = gen1StyleScore(call)
            if bestScore == nil or score < bestScore then
              bestScore = score
              typeStyle = call
              typeEnd = candidateEnd
            end
          end
        end
      end

      -- Fallback for a replacement UI whose display spelling is detached from
      -- the engine type id: use the first same-row text chunk between TYPE and
      -- PP as the visible type token/style.
      local ppX = ppCall.startX
      local ppPos = tostring(ppCall.text):upper():find("PP", 1, true)
      if ppPos and ppPos > 1 then
        ppX = ppCall.startX + gen1CallWidth(ppCall,
          tostring(ppCall.text):sub(1, ppPos - 1))
      end
      if not typeEnd then
        local typeRight = (typeCall.startX or 0) + (typeCall.width or 0)
        local fallback, fallbackScore
        for _, call in ipairs(calls) do
          if call ~= typeCall and call ~= ppCall and gen1SameBaseline(rowY, call.y)
              and type(call.startX) == "number" and call.startX >= typeRight
              and call.startX < ppX
              and not call.upper:find("TYPE", 1, true)
              and not call.upper:find("PP", 1, true) then
            local score = gen1StyleScore(call)
            if fallbackScore == nil or score < fallbackScore then
              fallbackScore = score
              fallback = call
            end
          end
        end
        if fallback then
          typeStyle = fallback
          typeEnd = fallback.startX + fallback.width
        else
          typeEnd = typeRight
        end
      end

      if type(typeEnd) ~= "number" or type(ppX) ~= "number" then
        return nil
      end

      -- Fixed footer-local column.  One "cell" is the average advance of the
      -- literal TYPE label itself, so the point scales naturally with the
      -- replacement UI font/transform.  Column 24 was chosen from the live
      -- Gen3UI v1.4.0 footer geometry and is intentionally independent of both
      -- the type VALUE and the PP text/position.
      local typeLabelWidth = gen1CallWidth(typeCall, "TYPE")
      local cell = type(typeLabelWidth) == "number" and typeLabelWidth / 4 or nil
      local fixedTypeX = type(cell) == "number" and cell > 0
          and (typeCall.startX + cell * 24) or nil
      local fixedStyleX, fixedStyleY
      if type(fixedTypeX) == "number" then
        fixedStyleX, fixedStyleY = gen1PointInStyleSpace(
          typeCall.transform, typeStyle and typeStyle.transform,
          fixedTypeX, typeCall.y)
      end
      if type(fixedStyleX) ~= "number" then return nil end

      return { y = (typeStyle and typeStyle.y) or fixedStyleY or rowY,
        typeEnd = typeEnd, fixedX = fixedStyleX, style = typeStyle }
    end

    local function gen1DrawObservedCategory(G, originalPrint, geom, label)
      if not (geom and geom.style and label) or geom.already then return false end
      local style = geom.style
      local x = tonumber(geom.fixedX)
      if type(x) ~= "number" or x <= 0 then return false end
      -- X is a footer-local fixed column.  PP remains useful only to identify
      -- that this is the Gen3UI footer row; its contents and position NEVER
      -- participate in horizontal category placement.
      local y = geom.y

      local pushed = false
      if type(G.push) == "function" then pushed = pcall(G.push, "all") end
      local oldFont = type(G.getFont) == "function" and G.getFont() or nil
      local oldColor
      if type(G.getColor) == "function" then oldColor = { G.getColor() } end
      if style.transform and type(G.replaceTransform) == "function" then
        pcall(G.replaceTransform, style.transform)
      end
      if style.font and type(G.setFont) == "function" then pcall(G.setFont, style.font) end
      if style.color and type(G.setColor) == "function" then
        pcall(G.setColor, style.color[1], style.color[2], style.color[3], style.color[4] or 1)
      end
      -- Same softened semibold treatment as the Gold path: preserve the
      -- replacement UI font/style, add only a half-pixel translucent shoulder.
      originalPrint(label, x, y)
      if style.color and type(G.setColor) == "function" then
        pcall(G.setColor, style.color[1], style.color[2], style.color[3],
          (style.color[4] or 1) * 0.55)
        originalPrint(label, x + 0.5, y)
        pcall(G.setColor, style.color[1], style.color[2], style.color[3],
          style.color[4] or 1)
      else
        originalPrint(label, x + 0.5, y)
      end
      if pushed and type(G.pop) == "function" then
        pcall(G.pop)
      else
        if oldFont and type(G.setFont) == "function" then pcall(G.setFont, oldFont) end
        if oldColor and type(G.setColor) == "function" then
          pcall(G.setColor, oldColor[1], oldColor[2], oldColor[3], oldColor[4] or 1)
        end
      end
      return true
    end

    if mod.hooks and type(mod.hooks.wrap) == "function" then
      local ok = pcall(function()
        mod.hooks:wrap("render.hud", function(next, game, viewport)
          if mod.options:get("move_category_readout") == false then
            return next(game, viewport)
          end
          local G = rawget(_G, "love") and love.graphics or nil
          if not (G and type(G.print) == "function") then
            return next(game, viewport)
          end

          local originalPrint = G.print
          local originalPrintf = type(G.printf) == "function" and G.printf or nil
          local calls = {}
          G.print = function(value, x, y, ...)
            calls[#calls + 1] = gen1CaptureHudCall(G, "print", value, x, y)
            return originalPrint(value, x, y, ...)
          end
          if originalPrintf then
            G.printf = function(value, x, y, limit, align, ...)
              calls[#calls + 1] = gen1CaptureHudCall(G, "printf", value, x, y, limit, align)
              return originalPrintf(value, x, y, limit, align, ...)
            end
          end

          local called = pack(pcall(next, game, viewport))
          G.print = originalPrint
          if originalPrintf then G.printf = originalPrintf end
          if not called[1] then error(called[2], 0) end

          local typeY
          for _, call in ipairs(calls) do
            if call.upper:find("TYPE", 1, true) then
              typeY = call.y
              break
            end
          end
          if typeY ~= nil then
            local data = game and game.data
            local selected, def = gen1SelectedFromBattle(readout.currentBattle, data)
            if not def then selected, def = gen1SelectedFromHud(calls, data, typeY) end
            local geom = def and gen1RowGeometry(calls, def) or nil
            local label = def and gen1FullCategoryLabel(selected and selected.id, def) or nil
            if geom then
              gen1Gen3UiRuntimeDetected = true
            end
            if geom and label and not geom.already then
              gen1DrawObservedCategory(G, originalPrint, geom, label)
            end
          end

          local result = { n = called.n - 1 }
          for i = 2, called.n do result[i - 1] = called[i] end
          return unpack(result, 1, result.n)
        end, math.huge)
      end)
      gen1Gen3HudObserverInstalled = ok
    end

    mod.exports.gen3UiMoveCategoryGen1Installed = function()
      return gen1Gen3HudObserverInstalled
    end
  end

  -- Generation IV introduced per-move damage categories. The standalone
  -- Gen I pool is still handled exactly as before (165 canonical moves). When
  -- Crystal 251 is present, the same audited table extends through move index
  -- 251 so every Generation II move receives its modern per-move category.
  --
  -- For Gen I records we retain the exact identity guard. For Crystal's new
  -- records, identity is validated against Crystal's own exported move table,
  -- avoiding accidental category assignment to an unrelated custom move that
  -- merely reuses an index in the 166..251 range.
  local function isCanonicalMergedMove(id, move, index)
    if index and index <= 165 then
      return isCanonicalGen1Move(id, move, index)
    end
    if not (index and index >= 166 and index <= 251
        and type(crystalMoves) == "table") then
      return false
    end
    local row = crystalMoves[id]
    return type(row) == "table" and tonumber(row.index) == index
  end

  -- Crystal keeps a private runtime copy of all 251 moves. Update that table
  -- too, otherwise reactive effects and Crystal's AI could observe the old
  -- Generation II category even while the merged registry says GEN IV+.
  if moveSplitActive and type(crystalMoves) == "table" then
    local runtimeChanged = 0
    for _, row in pairs(crystalMoves) do
      local index = type(row) == "table" and tonumber(row.index) or nil
      local category = index and GEN4_MOVE_CATEGORY_BY_INDEX[index] or nil
      if category then
        row.category = category
        runtimeChanged = runtimeChanged + 1
      end
    end
    if mod.log and type(mod.log.info) == "function" then
      mod.log:info(("Crystal 251 runtime categories updated: %d canonical moves")
        :format(runtimeChanged))
    end
  end

  if mod.content and mod.content.moves
      and type(mod.content.moves.each) == "function"
      and type(mod.content.moves.patch) == "function" then
    local changed, preexistingConflicts, identitySkips = 0, 0, 0
    for id, move in mod.content.moves:each() do
      local index = type(move) == "table" and tonumber(move.index) or nil
      local category = index and GEN4_MOVE_CATEGORY_BY_INDEX[index] or nil
      if category then
        if isCanonicalMergedMove(id, move, index) then
          if moveSplitActive then
            if move.category ~= nil and move.category ~= category then
              preexistingConflicts = preexistingConflicts + 1
            end
            mod.content.moves:patch(id, { category = category })
            changed = changed + 1
          elseif index <= 165 and mod.DELETE ~= nil then
            -- Preserve the historical standalone behavior: GEN I mode clears
            -- explicit categories on the original 165 moves. Crystal's new
            -- Gen II move records are already type-based and are left intact.
            if move.category ~= nil then preexistingConflicts = preexistingConflicts + 1 end
            mod.content.moves:patch(id, { category = mod.DELETE })
            changed = changed + 1
          elseif index <= 165 and move.category ~= nil
              and mod.log and type(mod.log.warn) == "function" then
            mod.log:warn("GEN I move-category mode could not clear explicit category: mod.DELETE unavailable")
          end
        else
          identitySkips = identitySkips + 1
        end
      end
    end
    if mod.log and type(mod.log.info) == "function" then
      if moveSplitActive then
        local scope = type(crystalMoves) == "table" and "Gen I+II" or "Gen I"
        mod.log:info(("GEN IV+ move split enabled: categorized %d canonical %s moves; %d preexisting category conflicts overridden; %d index/identity collisions skipped")
          :format(changed, scope, preexistingConflicts, identitySkips))
      else
        mod.log:info(("GEN I move-category mode enabled: cleared explicit category on %d canonical Gen I moves; %d preexisting categories removed; %d index/identity collisions skipped")
          :format(changed, preexistingConflicts, identitySkips))
      end
    end
  end

  -- Crystal's Generation II damage module normally derives the damage class
  -- from elemental type, ignoring move.category. In GEN IV+ mode we bridge that
  -- one internal decision without replacing Crystal's damage formula:
  --  * prepareMove is allowed to seed Crystal's row, then we restore the modern
  --    explicit category from the 1..251 table;
  --  * compute temporarily changes Crystal's private physical-type lookup for
  --    this synchronous calculation only, so its existing categoryOf() chooses
  --    the requested Physical/Special side while move.type itself remains
  --    untouched for STAB, weather, held-item boosts and effectiveness.
  --
  -- This intentionally uses engine_internals/debug only when Crystal is present.
  -- Standalone behavior takes the exact pre-2.2.0 path.
  do
    local CrystalDamage = nil
    if type(crystalMoves) == "table" then
      local ok, value = pcall(require, "mods.CRYSTAL_251.battle.crystal_damage")
      if ok and type(value) == "table" then CrystalDamage = value end
    end

    if CrystalDamage and type(CrystalDamage.prepareMove) == "function"
        and type(CrystalDamage.compute) == "function" then
      local BRIDGE_KEY = "__special_stat_split_crystal_damage_bridge_v1"
      local bridge = rawget(CrystalDamage, BRIDGE_KEY)

      if not bridge then
        local physicalTypes = nil
        if type(debug) == "table" and type(debug.getupvalue) == "function" then
          for i = 1, 64 do
            local name, value = debug.getupvalue(CrystalDamage.prepareMove, i)
            if not name then break end
            if name == "PHYSICAL_TYPES" and type(value) == "table" then
              physicalTypes = value
              break
            end
          end
        end

        if physicalTypes then
          bridge = {
            active = false,
            physicalTypes = physicalTypes,
            originalPrepareMove = CrystalDamage.prepareMove,
            originalCompute = CrystalDamage.compute,
            categoryFor = nil,
          }
          rawset(CrystalDamage, BRIDGE_KEY, bridge)

          CrystalDamage.prepareMove = function(move, moves)
            local token = bridge.originalPrepareMove(move, moves)
            if token and bridge.active and bridge.categoryFor and move then
              local category = bridge.categoryFor(move, moves)
              if category then move.category = category end
            end
            return token
          end

          CrystalDamage.compute = function(ctx, config)
            if not (bridge.active and bridge.categoryFor and ctx and ctx.move) then
              return bridge.originalCompute(ctx, config)
            end
            local move = ctx.move
            local category = bridge.categoryFor(move, config and config.moves)
            if (category ~= "physical" and category ~= "special") or not move.type then
              return bridge.originalCompute(ctx, config)
            end

            local had = bridge.physicalTypes[move.type] ~= nil
            local previous = bridge.physicalTypes[move.type]
            bridge.physicalTypes[move.type] = category == "physical"

            local result = pack(pcall(bridge.originalCompute, ctx, config))

            if had then bridge.physicalTypes[move.type] = previous
            else bridge.physicalTypes[move.type] = nil end

            if not result[1] then error(result[2], 0) end
            return unpack(result, 2, result.n)
          end
        elseif mod.log and type(mod.log.warn) == "function" then
          mod.log:warn("Crystal 251 detected, but its physical-type dispatcher could not be located; registry categories were patched but Crystal damage routing could not be bridged")
        end
      end

      if bridge then
        bridge.active = moveSplitActive
        bridge.categoryFor = function(move, moves)
          local index = type(move) == "table" and tonumber(move.index) or nil
          if not index and type(CrystalDamage.moveFor) == "function" then
            local row = CrystalDamage.moveFor(move, moves)
            index = type(row) == "table" and tonumber(row.index) or nil
          end
          return index and GEN4_MOVE_CATEGORY_BY_INDEX[index] or nil
        end
        if moveSplitActive and mod.log and type(mod.log.info) == "function" then
          mod.log:info("Crystal 251 damage router compatibility enabled for GEN IV+ move categories")
        end
      end
    end
  end

  -- A single shared dispatcher state means a hot-reloaded copy can update the
  -- implementation without stacking wrappers on top of wrappers.
  local state = rawget(Stats, PATCH_KEY)
  if not state then
    state = {
      active = false,
      split = nil,
      originalCalc = Stats.calc,
      originalEnsure = Stats.ensure,
      originalDamage = Damage.compute,
      originalExperience = Experience.apply,
      originalItemUse = ItemEffects.use,
      originalSummaryDraw = SummaryMenu.draw,
      originalStatBoxDraw = BattleState.StatBox and BattleState.StatBox.draw,
      originalSave = SaveData.save,
      derivedStats = setmetatable({}, { __mode = "k" }),
      nativeLevelUpDrawSeen = setmetatable({}, { __mode = "k" }),
      splitStatBoxDraw = nil,
    }
    rawset(Stats, PATCH_KEY, state)

    -- Track exactly which stat tables received fields from THIS mod. The weak
    -- set lets SaveData.save remove only our derived fields before serialization
    -- without touching another mod that might use similarly named keys.
    state.attach = function(stats, speciesDef, level, dvs, statExp)
      state.split.attach(stats, speciesDef, level, dvs, statExp)
      if type(stats) == "table" then state.derivedStats[stats] = true end
      return stats
    end

    -- Keep vanilla fields intact for compatibility. Add two derived fields.
    Stats.calc = function(speciesDef, level, dvs, statExp)
      local out = state.originalCalc(speciesDef, level, dvs, statExp)
      if state.active and state.split then
        state.attach(out, speciesDef, level, dvs, statExp)
      end
      return out
    end

    Stats.ensure = function(speciesDef, mon)
      local out = state.originalEnsure(speciesDef, mon)
      if state.active and state.split and type(out) == "table" and type(out.stats) == "table" then
        state.attach(out.stats, speciesDef, out.level or 1, out.dvs or {}, out.statExp or {})
      end
      return out
    end

    -- Do NOT reimplement Gen1Recomp's damage formula. For a special move,
    -- temporarily alias the legacy "special" operand to attacker SpA and
    -- defender SpD, call the exact upstream Damage.compute, then restore.
    Damage.compute = function(ruleset, attacker, defender, move, opts)
      if not state.active or not state.split or not attacker or not defender then
        return state.originalDamage(ruleset, attacker, defender, move, opts)
      end

      local category = move and move.category
      if category == nil and move and move.type then
        category = require("src.battle.TypeChart").category(move.type)
      end
      if category ~= "special" then
        return state.originalDamage(ruleset, attacker, defender, move, opts)
      end

      -- Existing saves may contain mon.stats without the new derived fields.
      -- Only fill missing split fields here.  `curStats` can be a transformed
      -- battle-stat table whose SpA/SpD deliberately belong to the copied
      -- target species; recomputing them from battler.def would silently
      -- revert Transform to the user's original species for special damage.
      local function ensureCurrentSplit(b)
        if not (b and b.mon and b.def and b.curStats) then return end
        if b.curStats.specialAttack == nil or b.curStats.specialDefense == nil then
          state.attach(b.curStats, b.def, b.mon.level or 1,
                       b.mon.dvs or {}, b.mon.statExp or {})
        end
      end
      ensureCurrentSplit(attacker)
      ensureCurrentSplit(defender)

      local acs, dcs = attacker.curStats, defender.curStats
      local ast, dst = attacker.stages or {}, defender.stages or {}
      attacker.stages, defender.stages = ast, dst

      local save = {
        acsSpecial = acs.special,
        dcsSpecial = dcs.special,
        astSpecial = ast.special,
        dstSpecial = dst.special,
      }

      acs.special = acs.specialAttack or acs.special
      dcs.special = dcs.specialDefense or dcs.special
      ast.special = ast.specialAttack or 0
      dst.special = dst.specialDefense or 0

      local result = pack(pcall(state.originalDamage, ruleset, attacker, defender, move, opts))

      acs.special = save.acsSpecial
      dcs.special = save.dcsSpecial
      ast.special = save.astSpecial
      dst.special = save.dstSpecial

      if not result[1] then error(result[2], 0) end
      return unpack(result, 2, result.n)
    end

    -- Summary page 1: replace only the legacy four-stat block after the
    -- frozen upstream screen has rendered. This avoids duplicating the rest
    -- of SummaryMenu (sprites, palettes, types, OT/ID, page 2). The compact
    -- one-line layout fits five stats into the original 10x10 tile box.
    SummaryMenu.draw = function(self)
      state.originalSummaryDraw(self)
      if not state.active or not state.split or self.page ~= 1 or not self.mon then
        return
      end
      local mon = self.mon
      local def = self.game and self.game.data and self.game.data.pokemon
                  and self.game.data.pokemon[mon.species]
      if def then
        mon.stats = mon.stats or Stats.calc(def, mon.level or 1, mon.dvs or {}, mon.statExp or {})
        state.attach(mon.stats, def, mon.level or 1, mon.dvs or {}, mon.statExp or {})
      end
      local st = mon.stats or {}
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 0, 64, 80, 80)
      Font.drawBox(0, 8, 10, 10)
      love.graphics.setColor(0, 0, 0, 1)
      local rows = {
        { "ATK", st.attack }, { "DEF", st.defense }, { "SPEED", st.speed },
        -- The summary box is only 10 tiles wide. Six fixed-width glyphs
        -- ("SP.ATK") would collide with the 3-digit value column, so the two
        -- split labels use compact five-glyph forms here only.
        { "SPATK", st.specialAttack or st.special },
        { "SPDEF", st.specialDefense or st.special },
      }
      for i, r in ipairs(rows) do
        -- Interior of Font.drawBox(0,8,10,10) is x=8..71, y=72..135.
        -- Five 8px labels occupy x=8..47; 3-digit values occupy x=48..71.
        local y = 72 + (i - 1) * 14
        Font.draw(Strings(r[1]), 8, y)
        Font.draw(("%3d"):format(r[2] or 0), 48, y)
      end
      love.graphics.setColor(1, 1, 1, 1)
    end

    -- Level-up StatBox: same principle as SummaryMenu. Keep the upstream
    -- state/update flow and replace only its draw routine with five rows.
    --
    -- `nativeLevelUpDrawSeen` is also a presentation signal owned entirely by
    -- this mod. If this draw actually runs in a frame, the native split card is
    -- visible and a Modern UI compatibility overlay must NOT be added. If a
    -- downstream UI decorator suppresses this draw, the signal stays false and
    -- the later render.hud compatibility layer can safely correct that foreign
    -- presentation without touching its implementation.
    if BattleState.StatBox and type(state.originalStatBoxDraw) == "function" then
      state.nativeLevelUpDrawSeen = state.nativeLevelUpDrawSeen
        or setmetatable({}, { __mode = "k" })
      state.splitStatBoxDraw = function(self)
        if not state.active or not state.split or not self.mon then
          return state.originalStatBoxDraw(self)
        end
        state.nativeLevelUpDrawSeen[self] = true
        local mon = self.mon
        local def = self.game and self.game.data and self.game.data.pokemon
                    and self.game.data.pokemon[mon.species]
        if def then
          mon.stats = mon.stats or Stats.calc(def, mon.level or 1, mon.dvs or {}, mon.statExp or {})
          state.attach(mon.stats, def, mon.level or 1, mon.dvs or {}, mon.statExp or {})
        end
        local st = mon.stats or {}
        Font.drawBox(9, 2, 11, 10)
        love.graphics.setColor(0, 0, 0, 1)
        local rows = {
          { "ATK", st.attack }, { "DEF", st.defense }, { "SPEED", st.speed },
          { "SP.ATK", st.specialAttack or st.special },
          { "SP.DEF", st.specialDefense or st.special },
        }
        for i, r in ipairs(rows) do
          -- Interior of Font.drawBox(9,2,11,10) is x=80..151, y=24..87.
          -- "SP.ATK"/"SP.DEF" occupy x=80..127; values x=128..151.
          local y = 24 + (i - 1) * 14
          Font.draw(Strings(r[1]), 80, y)
          Font.draw(("%3d"):format(r[2] or 0), 128, y)
        end
        love.graphics.setColor(1, 1, 1, 1)
      end
      BattleState.StatBox.draw = state.splitStatBoxDraw
    end

    -- Keep the on-disk save schema vanilla. Gen1Recomp serializes the full
    -- save table, including mon.stats, so derived SpA/SpD fields would otherwise
    -- leak into save.lua. Strip only stat tables tracked by this mod, call the
    -- exact upstream save routine, and restore in-memory fields even on error.
    SaveData.save = function(data, mods)
      if not state.active or not state.split then
        return state.originalSave(data, mods)
      end
      local removed, seen = {}, {}
      local function walk(value)
        if type(value) ~= "table" or seen[value] then return end
        seen[value] = true
        if state.derivedStats[value] then
          for _, key in ipairs({ "specialAttack", "specialDefense" }) do
            if value[key] ~= nil then
              removed[#removed + 1] = { tbl = value, key = key, value = value[key] }
              value[key] = nil
            end
          end
        end
        for _, child in pairs(value) do walk(child) end
      end
      walk(data)
      local result = pack(pcall(state.originalSave, data, mods))
      for i = #removed, 1, -1 do
        local r = removed[i]
        r.tbl[r.key] = r.value
      end
      if not result[1] then error(result[2], 0) end
      return unpack(result, 2, result.n)
    end

    -- Gen II keeps one shared Special Stat Exp. The defeated Pokémon's
    -- Special Attack base stat is the value added to that shared bucket.
    Experience.apply = function(data, mon, defeatedDef, level, isTrainer,
                                numParticipants, traded)
      if not state.active or not state.split or not defeatedDef then
        return state.originalExperience(data, mon, defeatedDef, level, isTrainer,
                                        numParticipants, traded)
      end
      local row = state.split.baseFor(defeatedDef)
      if not row or not defeatedDef.baseStats then
        return state.originalExperience(data, mon, defeatedDef, level, isTrainer,
                                        numParticipants, traded)
      end
      local old = defeatedDef.baseStats.special
      defeatedDef.baseStats.special = row.spa
      local result = pack(pcall(state.originalExperience, data, mon, defeatedDef,
                                level, isTrainer, numParticipants, traded))
      defeatedDef.baseStats.special = old
      if not result[1] then error(result[2], 0) end
      return unpack(result, 2, result.n)
    end

    -- X SPECIAL becomes a Sp. Atk stage boost. We preserve ItemEffects.use
    -- exactly and redirect only its temporary "special" stage slot.
    ItemEffects.use = function(data, saveData, itemId, target, battle, moveIndex, ow)
      if not state.active or itemId ~= "X_SPECIAL" or not battle or not battle.player then
        return state.originalItemUse(data, saveData, itemId, target, battle, moveIndex, ow)
      end
      local stages = battle.player.stages or {}
      battle.player.stages = stages
      local old = stages.special
      stages.special = stages.specialAttack or 0
      local result = pack(pcall(state.originalItemUse, data, saveData, itemId, target,
                                battle, moveIndex, ow))
      stages.specialAttack = stages.special or 0
      stages.special = old
      if result[1] then
        relabelMessages(result[3], Strings("SPECIAL"), Strings("SP. ATK"))
      end
      if not result[1] then error(result[2], 0) end
      return unpack(result, 2, result.n)
    end
  end

  state.active = active
  state.split = SplitStats
  state.nativeLevelUpDrawSeen = state.nativeLevelUpDrawSeen
    or setmetatable({}, { __mode = "k" })
  if not state.splitStatBoxDraw and BattleState.StatBox then
    -- Hot-reload bridge from pre-test4 builds: the existing shared dispatcher
    -- already owns BattleState.StatBox.draw, so remember that exact function as
    -- the native split draw identity instead of stacking another wrapper.
    state.splitStatBoxDraw = BattleState.StatBox.draw
  end

  -- Move-effect wrappers use the official move_effects registry. Calling the
  -- original record keeps Gen1Recomp's messages, Substitute/Mist behavior,
  -- chance rolls, and other edge cases; only the legacy stage slot is aliased.
  local function aliasStageRun(effectId, side, newKey)
    local originalRecord = MoveEffects.RECORDS[effectId]
    local originalRun = originalRecord and originalRecord.run
    if type(originalRun) ~= "function" then return end
    mod.content.move_effects:patch(effectId, {
      run = function(ctx)
        if not state.active then return originalRun(ctx) end
        local who = side == "user" and ctx.user or ctx.target
        if not who then return originalRun(ctx) end
        local stages = who.stages or {}
        who.stages = stages
        local old = stages.special
        stages.special = stages[newKey] or 0
        local result = pack(pcall(originalRun, ctx))
        stages[newKey] = stages.special or 0
        stages.special = old
        if result[1] then
          local label = newKey == "specialAttack" and "SP. ATK" or "SP. DEF"
          relabelMessages(result[2], Strings("SPECIAL"), Strings(label))
        end
        if not result[1] then error(result[2], 0) end
        return unpack(result, 2, result.n)
      end,
    })
  end

  -- Gen II meanings:
  -- Growth / SPECIAL_UP1 -> Sp. Atk +1
  -- Amnesia / SPECIAL_UP2 -> Sp. Def +2
  -- Psychic secondary Special drop -> Sp. Def -1
  aliasStageRun("SPECIAL_UP1_EFFECT", "user", "specialAttack")
  aliasStageRun("SPECIAL_UP2_EFFECT", "user", "specialDefense")
  aliasStageRun("SPECIAL_DOWN_SIDE_EFFECT", "target", "specialDefense")

  -- Transform copies both split stats and the target's stage table. The
  -- original effect already copies stages; we only add the two derived stats.
  do
    local originalRecord = MoveEffects.RECORDS.TRANSFORM_EFFECT
    local originalRun = originalRecord and originalRecord.run
    if type(originalRun) == "function" then
      mod.content.move_effects:patch("TRANSFORM_EFFECT", {
        run = function(ctx)
          local result = pack(pcall(originalRun, ctx))
          if result[1] and state.active and ctx.user and ctx.target then
            if ctx.target.curStats and ctx.user.curStats then
              ctx.user.curStats.specialAttack =
                ctx.target.curStats.specialAttack or ctx.target.curStats.special
              ctx.user.curStats.specialDefense =
                ctx.target.curStats.specialDefense or ctx.target.curStats.special
            end
          end
          if not result[1] then error(result[2], 0) end
          return unpack(result, 2, result.n)
        end,
      })
    end
  end

  -- Optional Pokédex Plus 1.3.x compatibility.  Pokédex Plus exposes
  -- its Base Stats page through the normal screens registry, so this can be
  -- composed without touching its private Lua locals.  The optional dependency
  -- guarantees Pokédex Plus registers the screen before this mod patches it.
  -- In VANILLA mode the original factory and draw path are returned untouched.
  do
    local pokedexPlus = type(mod.find) == "function" and mod.find("pokedex_plus") or nil
    local screens = mod.content and mod.content.screens
    if pokedexPlus and screens and type(screens.get) == "function"
        and type(screens.patch) == "function" then
      local originalRecord = screens:get("PokedexPlusStats")
      local originalNew = type(originalRecord) == "table" and originalRecord.new or nil
      if type(originalNew) == "function" then
        screens:patch("PokedexPlusStats", {
          new = function(game, opts)
            local screen = originalNew(game, opts)
            if not state.active or not state.split or type(screen) ~= "table" then
              return screen
            end

            local species = screen.species or (type(opts) == "table" and (opts.species or opts[1]))
            local def = game and game.data and game.data.pokemon and game.data.pokemon[species]
            local row = def and state.split.baseFor(def) or nil
            local stats = screen.stats
            local originalDraw = screen.draw
            if not row or type(stats) ~= "table" or type(originalDraw) ~= "function" then
              return screen
            end

            stats.specialAttack = row.spa
            stats.specialDefense = row.spd
            stats.total = (tonumber(stats.hp) or 0)
              + (tonumber(stats.attack) or 0)
              + (tonumber(stats.defense) or 0)
              + (tonumber(stats.speed) or 0)
              + row.spa + row.spd

            -- Let Pokédex Plus render its own header/type/footer exactly as-is,
            -- then replace only the legacy stat rows with a compact 7-row block.
            screen.draw = function(self)
              originalDraw(self)
              love.graphics.setColor(1, 1, 1, 1)
              love.graphics.rectangle("fill", 8, 40, 144, 88)
              love.graphics.setColor(0, 0, 0, 1)
              local labels = {
                { "HP", self.stats.hp },
                { "ATTACK", self.stats.attack },
                { "DEFENSE", self.stats.defense },
                { "SPEED", self.stats.speed },
                { "SP.ATK", self.stats.specialAttack },
                { "SP.DEF", self.stats.specialDefense },
                { "TOTAL", self.stats.total },
              }
              for i, statRow in ipairs(labels) do
                local y = 44 + (i - 1) * 12
                Font.draw(statRow[1], 16, y)
                local value = ("%03d"):format(statRow[2] or 0)
                Font.draw(value, 144 - Font.width(value), y)
              end
              love.graphics.setColor(1, 1, 1, 1)
            end
            return screen
          end,
        })
        mod.log:info("Pokédex Plus Base Stats compatibility enabled")
      else
        mod.log:warn("Pokédex Plus detected, but PokedexPlusStats screen was not available")
      end
    end
  end

  -- Optional Gen1 Modern UI compatibility.
  --
  -- IMPORTANT: ordinary Party/Summary compatibility intentionally does NOT use
  -- Modern UI's generic external-screen adapter. That adapter is useful for a
  -- source-owned custom screen, but replacing Modern UI's built-in Party or
  -- Summary presenter would throw away its authored sprites, HP bar, layout,
  -- spacing, frame and responsive detail card. `ModernUI Override` therefore
  -- uses a deliberately narrow, version-gated presentation shim: Modern UI
  -- renders its normal screen first, and this mod replaces only the legacy
  -- SPECIAL stat text inside Modern UI's own renderer.
  --
  -- This is temporary compatibility for Modern UI's current built-in renderer.
  -- It is intentionally capability-gated rather than release-number-gated: a
  -- future Modern UI release is allowed to keep using this shim automatically
  -- when the same renderer/helpers are still present. If upstream exposes an
  -- official built-in-detail augmentation contract, prefer that and remove
  -- this shim instead of expanding it.
  local function presentationStats(game, mon)
    if type(mon) ~= "table" then return {}, nil, nil end
    local stats = type(mon.stats) == "table" and mon.stats or {}
    local spa, spd = stats.specialAttack, stats.specialDefense
    if (spa == nil or spd == nil) and state.active and state.split then
      local def = game and game.data and game.data.pokemon
        and game.data.pokemon[mon.species]
      if def then
        spa, spd = state.split.calculate(def, mon.level or 1,
          mon.dvs or {}, mon.statExp or {}, stats.special)
      end
    end
    return stats, spa or stats.special, spd or stats.special
  end

  local function modernUiOverrideEnabled()
    return mod.options:get("modern_ui_override") ~= false
  end

  local function modernUiPartyStatsLayout()
    return tostring(mod.options:get("modern_ui_party_stats_layout") or "two_rows") == "one_row"
      and "one_row" or "two_rows"
  end

  local function modernUiBattleWipOverrideEnabled()
    return mod.options:get("modern_ui_battle_wip_override") == true
  end

  local modernUiHandle = type(mod.find) == "function" and mod.find("gen1_modern_ui") or nil
  local modernUiExports = modernUiHandle and modernUiHandle.exports or nil
  local modernUiApiVersion = modernUiExports
    and (modernUiExports.compatibilityApiVersion or modernUiExports.version) or nil

  -- Do not gate this private presentation shim on the Modern UI release number.
  -- Releases are informative only. Installation is decided from capabilities:
  -- the expected runtime, renderer functions and helper upvalues must still be
  -- present. This lets compatible future releases keep working automatically,
  -- while a structurally incompatible renderer fails closed without guessing.
  local MODERN_UI_SURGICAL_KEY = "__specialStatSplitModernUiSurgicalV1"

  local function closureUpvalue(fn, wanted)
    if type(fn) ~= "function" or type(debug) ~= "table"
        or type(debug.getupvalue) ~= "function" then
      return nil
    end
    for index = 1, 64 do
      local name, value = debug.getupvalue(fn, index)
      if name == nil then break end
      if name == wanted then return value end
    end
    return nil
  end

  local function closureUpvalueMatching(fn, predicate)
    if type(fn) ~= "function" or type(predicate) ~= "function"
        or type(debug) ~= "table" or type(debug.getupvalue) ~= "function" then
      return nil
    end
    for index = 1, 64 do
      local name, value = debug.getupvalue(fn, index)
      if name == nil then break end
      local ok, matched = pcall(predicate, value, name)
      if ok and matched then return value end
    end
    return nil
  end


  local function installModernUiSurgicalOverride()
    if not modernUiHandle then return false end

    -- The public compatibility API version is deliberately NOT a hard release
    -- gate here. We only need getScaleTokens plus the renderer structure below.
    -- If a future API revision preserves those capabilities, keep working; if
    -- it removes/changes them, the structural checks fail closed.
    local getter = modernUiExports and modernUiExports.getScaleTokens
    if type(getter) ~= "function" then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("ModernUI Override could not find the required getScaleTokens capability on Gen1 Modern UI %s (API %s); leaving its built-in UI untouched",
          tostring(modernUiHandle.version or "unknown"), tostring(modernUiApiVersion or "unknown"))
      end
      return false
    end
    local runtime = closureUpvalue(getter, "runtime")
    local function looksLikeModernRuntime(value)
      return type(value) == "table"
        and type(value.drawParty) == "function"
        and type(value.drawMonDetail) == "function"
        and type(value.drawSummary) == "function"
    end
    if not looksLikeModernRuntime(runtime) then
      -- Survive harmless upstream refactors that only rename the closure local
      -- from `runtime` to something else while preserving the same renderer.
      runtime = closureUpvalueMatching(getter, function(value)
        return looksLikeModernRuntime(value)
      end)
    end
    if not looksLikeModernRuntime(runtime) then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("ModernUI Override could not resolve the expected renderer capabilities on Gen1 Modern UI %s; leaving its built-in UI untouched",
          tostring(modernUiHandle.version or "unknown"))
      end
      return false
    end

    local previous = rawget(runtime, MODERN_UI_SURGICAL_KEY)
    if type(previous) == "table" and previous.owner == (mod.id or MOD_ID) then
      -- Hot reload: restore the exact upstream functions before installing the
      -- fresh wrapper so wrappers never stack around themselves.
      if runtime.drawParty == previous.wrappedParty and type(previous.originalParty) == "function" then
        runtime.drawParty = previous.originalParty
      end
      if runtime.drawMonDetail == previous.wrappedMonDetail and type(previous.originalMonDetail) == "function" then
        runtime.drawMonDetail = previous.originalMonDetail
      end
      if runtime.drawSummary == previous.wrappedSummary and type(previous.originalSummary) == "function" then
        runtime.drawSummary = previous.originalSummary
      end
    end

    local originalParty = runtime.drawParty
    local originalMonDetail = runtime.drawMonDetail
    local originalSummary = runtime.drawSummary

    -- Reuse Modern UI's own private drawing helpers/fonts from the active
    -- renderer closure. The shim is structure-gated rather than version-gated:
    -- we do not copy a second visual system, and we stop if required helpers
    -- disappear or change shape.
    local detailFont = closureUpvalue(originalMonDetail, "font")
    local detailFontCache = closureUpvalue(originalMonDetail, "fontCache")
    local detailDrawFitted = closureUpvalue(originalMonDetail, "drawFittedText")
    local detailDrawText = closureUpvalue(originalMonDetail, "drawText")
    local detailTextHeight = closureUpvalue(originalMonDetail, "textHeight")
    local detailStrings = closureUpvalue(originalMonDetail, "Strings")
    local detailSetColor = closureUpvalue(originalMonDetail, "setColor")

    local summaryPresenterRect = closureUpvalue(originalSummary, "presenterRect")
    local summaryPanelWidthFor = closureUpvalue(originalSummary, "panelWidthFor")
    local summaryFont = closureUpvalue(originalSummary, "font")
    local summaryFontCache = closureUpvalue(originalSummary, "fontCache")
    local summaryDrawFitted = closureUpvalue(originalSummary, "drawFittedText")
    local summaryTextHeight = closureUpvalue(originalSummary, "textHeight")
    local summarySetColor = closureUpvalue(originalSummary, "setColor")
    local summarySpriteFor = closureUpvalue(originalSummary, "spriteFor")

    local helpersOk = type(detailFont) == "function"
      and type(detailFontCache) == "table"
      and type(detailDrawFitted) == "function"
      and type(detailDrawText) == "function"
      and type(detailTextHeight) == "function"
      and type(detailStrings) == "table"
      and type(detailSetColor) == "function"
      and type(summaryPresenterRect) == "function"
      and type(summaryPanelWidthFor) == "function"
      and type(summaryFont) == "function"
      and type(summaryFontCache) == "table"
      and type(summaryDrawFitted) == "function"
      and type(summaryTextHeight) == "function"
      and type(summarySetColor) == "function"
      and type(summarySpriteFor) == "function"
      and type(runtime.maxMovePP) == "function"
      and type(runtime.summaryPokemon) == "function"
      and type(runtime.panelMaxWidth) == "function"
      and type(runtime.scaledPanelWidth) == "function"
      and type(runtime.pokemonDefinition) == "function"
    if not helpersOk then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("ModernUI Override supported renderer signature changed; leaving Modern UI untouched")
      end
      return false
    end

    local bridge = {
      owner = mod.id or MOD_ID,
      release = tostring(modernUiHandle.version or ""),
      originalParty = originalParty,
      originalMonDetail = originalMonDetail,
      originalSummary = originalSummary,
      inParty = false,
      partyIsBattle = false,
    }

    local function drawPartyStatRow(game, mon, x, y, w, h, theme, context)
      if context ~= "party" or not bridge.inParty
          or not (state.active and state.split and type(mon) == "table")
          or type(x) ~= "number" or type(y) ~= "number"
          or type(w) ~= "number" or type(h) ~= "number"
          or type(theme) ~= "table" then
        return
      end
      local enabled = bridge.partyIsBattle
        and modernUiBattleWipOverrideEnabled() or modernUiOverrideEnabled()
      if not enabled then return end
      local spacing, colors = theme and theme.spacing, theme and theme.colors
      if not (spacing and colors and love and love.graphics
          and type(love.graphics.rectangle) == "function") then return end

      local stats, spa, spd = presentationStats(game, mon)
      if spa == nil or spd == nil then return end
      local compact = h < 250 or w < 360
      local titleFont = detailFont(detailFontCache, compact and theme.typography.body
        or theme.typography.title)
      local baseStatSize = compact and theme.typography.caption
        or theme.typography.body
      local bodyFont = detailFont(detailFontCache, baseStatSize)
      local captionFont = detailFont(detailFontCache, theme.typography.caption)
      local artSize = math.max(54, math.min(compact and 92 or 150,
        h * (compact and 0.42 or 0.48), w * 0.30))
      local lowerY = y + math.max(artSize + spacing.md * 2,
        detailTextHeight(titleFont) + detailTextHeight(captionFont) * 2
          + spacing.xl * 2)
      local left = x + spacing.md
      local innerW = math.max(1, w - spacing.md * 2)
      local bottom = y + h - spacing.md

      -- Preserve Modern UI's exact card geometry, but use two stat rows with
      -- descriptive labels. Both rows share ONE dynamically fitted font size:
      -- whichever row needs more horizontal room determines the scale for both.
      -- This is measured from the live panel width every frame, so different
      -- devices, DPI/UI scales and aspect ratios stay aligned without a preset.
      local partyLayout = modernUiPartyStatsLayout()
      local statRows
      if partyLayout == "one_row" then
        statRows = {{
          ("ATK %s"):format(tostring(stats.attack or "—")),
          ("DEF %s"):format(tostring(stats.defense or "—")),
          ("SPD %s"):format(tostring(stats.speed or "—")),
          ("SPATK %s"):format(tostring(spa or "—")),
          ("SPDEF %s"):format(tostring(spd or "—")),
        }}
      else
        statRows = {
          {
            ("ATTACK %s"):format(tostring(stats.attack or "—")),
            ("DEFENSE %s"):format(tostring(stats.defense or "—")),
            ("SPEED %s"):format(tostring(stats.speed or "—")),
          },
          {
            ("SPEC. ATTACK %s"):format(tostring(spa or "—")),
            ("SPEC. DEFENSE %s"):format(tostring(spd or "—")),
          },
        }
      end

      local rowGeometry = {}
      for rowIndex, row in ipairs(statRows) do
        local gap = spacing.sm or 0
        rowGeometry[rowIndex] = {
          gap = gap,
          width = math.max(20, (innerW - gap * math.max(0, #row - 1)) / #row),
        }
      end

      local function rowFits(textFont)
        if not (textFont and type(textFont.getWidth) == "function") then
          return false
        end
        for rowIndex, row in ipairs(statRows) do
          local width = rowGeometry[rowIndex].width
          for _, value in ipairs(row) do
            if textFont:getWidth(value) > width then return false end
          end
        end
        return true
      end

      -- Modern UI's font factory rounds to whole logical pixels and bottoms at
      -- 10 px. Walk downward to the largest size that fits BOTH rows. In the
      -- pathological case where even 10 px is too wide, apply one final shared
      -- fractional draw scale rather than truncating either label with "...".
      local basePixels = math.max(10, math.floor((baseStatSize or 16) + 0.5))
      local statPixels = basePixels
      local statFont = detailFont(detailFontCache, statPixels)
      while statPixels > 10 and not rowFits(statFont) do
        statPixels = statPixels - 1
        statFont = detailFont(detailFontCache, statPixels)
      end
      local statDrawScale = 1
      if not rowFits(statFont) and statFont
          and type(statFont.getWidth) == "function" then
        for rowIndex, row in ipairs(statRows) do
          local width = rowGeometry[rowIndex].width
          for _, value in ipairs(row) do
            local measured = statFont:getWidth(value)
            if measured > 0 then
              statDrawScale = math.min(statDrawScale, width / measured)
            end
          end
        end
        -- Tiny safety margin for pixel snapping/rounding at fractional DPI.
        statDrawScale = math.max(0.01, math.min(1, statDrawScale * 0.985))
      end

      local statRowH = math.max(1, detailTextHeight(statFont) * statDrawScale)
      local statRowCount = #statRows
      local moveRowH = math.max(1, detailTextHeight(bodyFont))
      local moves = mon.moves or {}
      local desiredMoves = math.min(#moves, 4)
      local blockH = math.max(1, bottom - lowerY)
      local roomAfterStats = math.max(0, blockH - statRowH * statRowCount)
      local maxMoveLines = math.max(0,
        math.floor(roomAfterStats / math.max(1, moveRowH)))
      local moveCount = math.min(desiredMoves, maxMoveLines)
      local actualMoveLines = desiredMoves > 0 and moveCount
        or (maxMoveLines > 0 and 1 or 0)
      local lineCount = statRowCount + actualMoveLines
      local gapCount = math.max(1, lineCount - 1)
      local textH = statRowH * statRowCount + moveRowH * actualMoveLines
      local spare = math.max(0, blockH - textH)
      local lineGap = math.min(spacing.xs or 0, spare / gapCount)
      local movesY = lowerY + statRowCount * statRowH
        + (actualMoveLines > 0 and statRowCount * lineGap or 0)

      local function drawStatText(value, tx, ty, maxWidth)
        love.graphics.setFont(statFont)
        if statDrawScale < 0.999 then
          -- drawText forwards the standard LÖVE print transform arguments.
          -- Scaling about the text origin preserves column x/y alignment while
          -- allowing narrower-than-10px logical rendering as a last resort.
          detailDrawText(value, tx, ty, 0, statDrawScale, statDrawScale)
        else
          detailDrawFitted(value, tx, ty, maxWidth, statFont)
        end
      end

      love.graphics.push("all")
      -- Modern UI already rendered the complete selected-Pokémon card. Erase
      -- only its lower text block (legacy one-row stats + move text), leaving
      -- the sprite, HP bar, borders, icons and all surrounding geometry intact.
      detailSetColor(colors.surfaceRaised)
      love.graphics.rectangle("fill", left - 1, lowerY - 1,
        innerW + 2, math.max(1, bottom - lowerY + 2))

      detailSetColor(colors.textMuted)
      for rowIndex, row in ipairs(statRows) do
        local geometry = rowGeometry[rowIndex]
        local rowY = lowerY + (rowIndex - 1) * (statRowH + lineGap)
        for index, value in ipairs(row) do
          drawStatText(value,
            left + (index - 1) * (geometry.width + geometry.gap), rowY,
            geometry.width)
        end
      end

      -- Repaint the move list immediately below the selected stat block
      -- using Modern UI's own font, fitted-text helper, colors and PP format.
      if desiredMoves > 0 then
        love.graphics.setFont(bodyFont)
        for index = 1, moveCount do
          local move = moves[index]
          local moveDef = move and game.data and game.data.moves
            and game.data.moves[move.id]
          local moveName = moveDef and moveDef.name or move and move.id or "—"
          local pp = move and moveDef and ("PP %d/%d"):format(move.pp or 0,
            runtime.maxMovePP(move, moveDef)) or ""
          local lineY = movesY + (index - 1) * (moveRowH + lineGap)
          local ppWidth = bodyFont:getWidth(pp)
          local moveX = left
          local moveMax = math.max(20, x + w - spacing.md - ppWidth
            - (spacing.sm or 0) - moveX)
          detailSetColor(colors.text)
          detailDrawFitted(moveName, moveX, lineY, moveMax, bodyFont)
          detailSetColor(colors.textMuted)
          detailDrawText(pp, x + w - spacing.md - ppWidth, lineY)
        end
      elseif actualMoveLines > 0 then
        love.graphics.setFont(bodyFont)
        detailSetColor(colors.textMuted)
        detailDrawText(detailStrings("No moves."), left, movesY)
      end
      love.graphics.pop()
    end

    local function drawSummarySpecialRow(game, screen, viewport, theme)
      if not (modernUiOverrideEnabled() and state.active and state.split
          and type(screen) == "table" and type(theme) == "table") then return end
      local page = screen.page
      if not (page == nil or page == 1) then return end
      local mon = runtime.summaryPokemon(screen) or {}
      if type(mon) ~= "table" or mon.species == nil then return end
      local stats, spa, spd = presentationStats(game, mon)
      if spa == nil or spd == nil then return end

      local x, y, w, h = summaryPresenterRect(viewport)
      local spacing = theme.spacing
      local gutter = spacing.lg
      local panelW = summaryPanelWidthFor(viewport, w - gutter * 2,
        runtime.panelMaxWidth(theme, 780))
      local def = runtime.pokemonDefinition(game, mon.species)
      local summarySprite = summarySpriteFor(game, mon, nil, "summary")
      panelW = math.min(panelW, runtime.scaledPanelWidth(theme, 640))
      local compact = panelW < 620
      local titleFont = summaryFont(summaryFontCache,
        compact and theme.typography.title * 0.86 or theme.typography.title)
      local bodyFont = summaryFont(summaryFontCache,
        compact and theme.typography.body * 0.86 or theme.typography.body)
      local captionFont = summaryFont(summaryFontCache, theme.typography.caption)
      local titleH = summaryTextHeight(titleFont)
      local lineGap = compact and (summaryTextHeight(bodyFont) + spacing.xs)
        or (spacing.lg + 10)
      local bodyLine = summaryTextHeight(bodyFont) + spacing.xs
      local titleOffset = spacing.md + titleH + spacing.xs
      local pageOffset = titleOffset
      local levelOffset = pageOffset + summaryTextHeight(bodyFont) + spacing.xs
      local hpOffset = levelOffset + lineGap
      local statusOffset = hpOffset + lineGap
      local spriteSize = compact and math.min(112, panelW * 0.24) or 150
      local spriteBottom = summarySprite
        and (statusOffset + lineGap * 2 + spacing.sm + spriteSize)
        or (statusOffset + lineGap)
      local statGap = compact and bodyLine or 28
      local statsBottom = pageOffset + statGap * 5 + summaryTextHeight(bodyFont)
      local contentBottom = math.max(spriteBottom, statsBottom)
      local panelH = math.min(h - gutter * 2,
        contentBottom + spacing.lg + summaryTextHeight(captionFont) + spacing.md)
      local px, py = x + (w - panelW) / 2, y + (h - panelH) / 2
      local pageY = py + spacing.md + titleH + spacing.xs
      local infoX = compact and (px + panelW * 0.48) or (px + panelW * 0.52)
      local rowY = pageY + statGap * 3 -- exact upstream SPECIAL row
      local right = px + panelW - spacing.lg
      local available = math.max(24, right - infoX)
      local rowH = summaryTextHeight(bodyFont)

      love.graphics.push("all")
      love.graphics.setFont(bodyFont)
      -- Summary is intentionally NOT controlled by the Party 1-row/2-row
      -- preference. Once a Pokémon is opened into this detailed Trainer Data
      -- view, every stat gets its own row on every viewport size. This keeps
      -- desktop and mobile presentation identical and avoids ever pairing the
      -- two split-special values side-by-side again.
      summarySetColor(theme.colors.surface)
      love.graphics.rectangle("fill", infoX - 1, rowY - 1,
        available + 2, rowH + statGap * 3 + 2)

      local function drawSingle(label, value, lineY)
        -- Match Modern UI's native Summary row convention exactly: muted
        -- label first, then the value immediately after the label rather
        -- than pinning values to the far-right edge of the panel.
        summarySetColor(theme.colors.textMuted)
        summaryDrawFitted(label, infoX, lineY, available, bodyFont)
        local valueText = tostring(value or "—")
        local valueX = infoX + bodyFont:getWidth(label) + spacing.sm
        summarySetColor(theme.colors.text)
        summaryDrawFitted(valueText, valueX, lineY,
          math.max(24, right - valueX), bodyFont)
      end
      drawSingle("SP. ATTACK", spa, rowY)
      drawSingle("SP. DEFENSE", spd, rowY + statGap)

      local idY = rowY + statGap * 2
      local otY = rowY + statGap * 3
      -- Preserve Modern UI's own ID/OT fallback chain byte-for-byte so the
      -- override never changes ownership metadata while moving the rows.
      local trainerId = mon.otId or (game.save and game.save.player
        and game.save.player.id) or 0
      local trainerName = mon.ot or (game.save and game.save.player
        and game.save.player.name) or "RED"
      drawSingle("ID", trainerId, idY)
      drawSingle("OT", trainerName, otY)
      love.graphics.pop()
    end

    bridge.wrappedParty = function(game, screen, viewport, theme)
      local previousInParty, previousBattle = bridge.inParty, bridge.partyIsBattle
      bridge.inParty = true
      bridge.partyIsBattle = type(screen) == "table" and screen.battle ~= nil
      local results = pack(pcall(originalParty, game, screen, viewport, theme))
      bridge.inParty, bridge.partyIsBattle = previousInParty, previousBattle
      if not results[1] then error(results[2], 0) end
      return unpack(results, 2, results.n)
    end

    bridge.wrappedMonDetail = function(game, mon, x, y, w, h, theme, context)
      local results = pack(pcall(originalMonDetail, game, mon, x, y, w, h, theme, context))
      if not results[1] then error(results[2], 0) end
      drawPartyStatRow(game, mon, x, y, w, h, theme, context)
      return unpack(results, 2, results.n)
    end

    bridge.wrappedSummary = function(game, screen, viewport, theme)
      local results = pack(pcall(originalSummary, game, screen, viewport, theme))
      if not results[1] then error(results[2], 0) end
      drawSummarySpecialRow(game, screen, viewport, theme)
      return unpack(results, 2, results.n)
    end

    bridge.restore = function()
      if runtime.drawParty == bridge.wrappedParty then runtime.drawParty = originalParty end
      if runtime.drawMonDetail == bridge.wrappedMonDetail then runtime.drawMonDetail = originalMonDetail end
      if runtime.drawSummary == bridge.wrappedSummary then runtime.drawSummary = originalSummary end
    end

    runtime.drawParty = bridge.wrappedParty
    runtime.drawMonDetail = bridge.wrappedMonDetail
    runtime.drawSummary = bridge.wrappedSummary
    rawset(runtime, MODERN_UI_SURGICAL_KEY, bridge)

    if mod.log and type(mod.log.info) == "function" then
      mod.log:info("ModernUI Override enabled as a capability-checked surgical Gen1 Modern UI %s stat-row shim",
        tostring(modernUiHandle.version))
    end
    return true
  end

  local modernUiSurgicalInstalled = installModernUiSurgicalOverride()
  mod.exports = mod.exports or {}
  mod.exports.modernUiSurgicalInstalled = function() return modernUiSurgicalInstalled end

  -- Optional ModernUI BattleWIP Override. This is deliberately OFF by default
  -- so Special Stat Split never replaces another mod's experimental battle
  -- presentation unless the player explicitly opts in.
  --
  -- Modern UI 0.8.x has a dedicated battle LEVEL UP card that is not a
  -- generic presenter/adaptable screen. On the audited v0.1.75 baseline it suppresses
  -- the native BattleState.StatBox earlier than screen.render_visible: its
  -- public ui.state.decorate hook replaces the child state's draw method and
  -- later paints a four-row ATTACK/DEFENSE/SPEED/SPECIAL card from render.hud.
  --
  -- Do not modify Modern UI or call its private runtime. Observe two public
  -- seams plus our own native draw:
  --   1) ui.state.decorate records when a downstream decorator replaces our
  --      exact source-owned split StatBox draw;
  --   2) our native split draw marks the frame only when it actually executes;
  --   3) render.hud calls downstream first, then corrects the foreign card only
  --      when the decorator is still installed AND the native draw never ran.
  --
  -- This matters because Modern UI's BATTLE UI (WIP) is experimental and OFF
  -- by default. The player must ALSO opt into this mod's
  -- `ModernUI BattleWIP Override`; with either option off, or whenever the
  -- native StatBox remains visible, this path stays completely inert.
  --
  -- Compatibility is keyed to Modern UI's public compatibility API version,
  -- not its release number. A future Modern UI release that keeps API v1 and
  -- the same public decoration behavior can continue to work. If the public
  -- API version changes, this override fails closed instead of guessing.
  do
    local hooks = mod.hooks
    if modernUiHandle and tonumber(modernUiApiVersion) == 1
        and hooks and type(hooks.wrap) == "function"
        and BattleState.StatBox then
      local decoratedLevelUpBoxes = setmetatable({}, { __mode = "k" })
      local levelUpFonts = {}

      local function isStatBox(screen)
        if type(screen) ~= "table" then return false end
        local mt = getmetatable(screen)
        return mt == BattleState.StatBox
          or rawget(screen, "_specialStatSplitLevelUpProbe") == true
      end

      local function viewportRect(viewport)
        if viewport and type(viewport.safe) == "table" then
          local safe = viewport.safe
          return tonumber(safe.x) or 0, tonumber(safe.y) or 0,
            math.max(1, tonumber(safe.width) or tonumber(viewport.width) or 1),
            math.max(1, tonumber(safe.height) or tonumber(viewport.height) or 1)
        end
        if viewport and viewport.safeX ~= nil then
          return tonumber(viewport.safeX) or 0, tonumber(viewport.safeY) or 0,
            math.max(1, tonumber(viewport.safeWidth) or tonumber(viewport.width) or 1),
            math.max(1, tonumber(viewport.safeHeight) or tonumber(viewport.height) or 1)
        end
        local lg = love and love.graphics
        local w = viewport and tonumber(viewport.width)
          or (lg and type(lg.getWidth) == "function" and lg.getWidth()) or 640
        local h = viewport and tonumber(viewport.height)
          or (lg and type(lg.getHeight) == "function" and lg.getHeight()) or 360
        return 0, 0, math.max(1, w), math.max(1, h)
      end

      local function modernScaleTokens(viewport)
        local exports = modernUiHandle and modernUiHandle.exports
        local getter = exports and exports.getScaleTokens
        if type(getter) == "function" then
          local ok, tokens = pcall(getter, viewport)
          if ok and type(tokens) == "table" then return tokens end
        end
        return { uiScale = 1, fontScale = 1 }
      end

      local function levelUpFont(size)
        local lg = love and love.graphics
        if not (lg and type(lg.newFont) == "function") then return nil end
        local rounded = math.max(10, math.floor((tonumber(size) or 15) + 0.5))
        local raster = math.max(15, math.floor(rounded / 15 + 0.5) * 15)
        if levelUpFonts[raster] ~= nil then return levelUpFonts[raster] or nil end
        local path = Font.PLAINPIXEL or "assets/fonts/plainpixel/PlainPixel-Regular.ttf"
        local ok, font = pcall(lg.newFont, path, raster, "mono", 1)
        if not ok then ok, font = pcall(lg.newFont, path, raster, "mono") end
        if not ok then ok, font = pcall(lg.newFont, raster) end
        if ok and font then
          if type(font.setFilter) == "function" then
            pcall(font.setFilter, font, "nearest", "nearest", 0)
          end
          levelUpFonts[raster] = font
          return font
        end
        levelUpFonts[raster] = false
        return nil
      end

      local function fontHeight(font, fallback)
        if font and type(font.getHeight) == "function" then
          local ok, value = pcall(font.getHeight, font)
          if ok and tonumber(value) then return tonumber(value) end
        end
        return fallback
      end

      local function drawCorrectLevelUp(game, viewport, statBox)
        local lg = love and love.graphics
        if not (lg and type(lg.rectangle) == "function") then return false end
        local mon = statBox and (statBox.mon or statBox.pokemon)
        if type(mon) ~= "table" then return false end
        local def = game and game.data and game.data.pokemon
          and game.data.pokemon[mon.species]
        if def then
          mon.stats = mon.stats or Stats.calc(def, mon.level or 1,
            mon.dvs or {}, mon.statExp or {})
          state.attach(mon.stats, def, mon.level or 1,
            mon.dvs or {}, mon.statExp or {})
        end
        local stats = mon.stats
        if type(stats) ~= "table"
            or stats.specialAttack == nil or stats.specialDefense == nil then
          return false
        end

        local x, y, w, h = viewportRect(viewport)
        local touch = game and game.touchControls
        if touch and type(touch.visible) == "function" and type(touch.layout) == "function" then
          local stack = game and game.stack
          local hidden = stack and type(stack.touchControlsHidden) == "function"
            and stack:touchControlsHidden() or false
          local okVisible, visible = pcall(touch.visible, touch)
          if not hidden and okVisible and visible then
            local okLayout, controls = pcall(touch.layout, touch)
            if okLayout and type(controls) == "table" and h > w * 1.2 then
              local lowerTop = y + h
              for _, name in ipairs({ "dpad", "a", "b", "start", "select" }) do
                local zone = controls[name]
                if type(zone) == "table" and type(zone.cy) == "number"
                    and type(zone.w) == "number" and zone.cy > y + h * 0.52 then
                  local radius = zone.w * 0.58
                  if name == "start" or name == "select" then radius = radius + zone.w * 0.28 end
                  lowerTop = math.min(lowerTop, zone.cy - radius)
                end
              end
              local occupied = math.max(0, y + h - lowerTop + 10)
              if occupied > 12 then
                occupied = math.min(occupied, math.max(180, h * 0.30))
                h = math.max(1, h - occupied)
              end
            end
          end
        end

        local gx, gy = viewport and tonumber(viewport.gameX), viewport and tonumber(viewport.gameY)
        local gw, gh = viewport and tonumber(viewport.gameWidth), viewport and tonumber(viewport.gameHeight)
        if gx and gy and gw and gh and gw > 0 and gh > 0 then
          local right, bottom = math.min(x + w, gx + gw), math.min(y + h, gy + gh)
          local nx, ny = math.max(x, gx), math.max(y, gy)
          if right > nx and bottom > ny then x, y, w, h = nx, ny, right - nx, bottom - ny end
        end

        local tokens = modernScaleTokens(viewport)
        local uiScale = math.max(0.75, math.min(1.5, tonumber(tokens.uiScale) or 1))
        local fontScale = math.max(0.8, math.min(2.0, tonumber(tokens.fontScale) or 1))
        local md = math.max(10, math.floor(13 * uiScale + 0.5))
        local sm = math.max(7, math.floor(9 * uiScale + 0.5))
        local xs = math.max(4, math.floor(5 * uiScale + 0.5))
        local inset = math.max(md, math.floor(math.min(w, h) * 0.018))
        local titleFont = levelUpFont(24 * fontScale)
        local bodyFont = levelUpFont(17 * fontScale)
        local captionFont = levelUpFont(13 * fontScale)
        local titleH = fontHeight(titleFont, math.max(20, 24 * fontScale))
        local bodyH = fontHeight(bodyFont, math.max(14, 17 * fontScale))
        local captionH = fontHeight(captionFont, math.max(12, 13 * fontScale))
        local tileH = math.max(bodyH, captionH) + sm * 2

        local panelW = math.min(math.max(1, w - inset * 2),
          math.max(340, math.min(520, w * 0.55)))
        local panelH = md + titleH + xs + bodyH + md
          + tileH * 3 + sm * 2 + md
        panelH = math.min(math.max(1, h - inset * 2), panelH)
        local panelX
        if w < 640 then panelX = x + (w - panelW) / 2
        else panelX = x + w - panelW - inset end
        local panelY = y + math.max(inset, (h - panelH) * 0.30)

        local pushed = type(lg.push) == "function"
        if pushed then lg.push("all") end
        if type(lg.origin) == "function" then lg.origin() end

        if type(lg.setColor) == "function" then lg.setColor(0.035, 0.045, 0.055, 1) end
        lg.rectangle("fill", panelX, panelY, panelW, panelH, math.max(4, 8 * uiScale))
        if type(lg.setLineWidth) == "function" then lg.setLineWidth(math.max(2, 2 * uiScale)) end
        if type(lg.setColor) == "function" then lg.setColor(0.88, 0.92, 0.96, 1) end
        lg.rectangle("line", panelX, panelY, panelW, panelH, math.max(4, 8 * uiScale))
        if type(lg.setColor) == "function" then lg.setColor(0.30, 0.72, 0.94, 1) end
        lg.rectangle("fill", panelX, panelY, panelW, math.max(3, 4 * uiScale))

        local function setFont(f)
          if f and type(lg.setFont) == "function" then lg.setFont(f) end
        end
        local function printText(text, px, py)
          if type(lg.print) == "function" then lg.print(tostring(text or ""), px, py) end
        end
        local function textWidth(f, text)
          if f and type(f.getWidth) == "function" then
            local ok, value = pcall(f.getWidth, f, tostring(text or ""))
            if ok and tonumber(value) then return tonumber(value) end
          end
          return #tostring(text or "") * math.max(8, 8 * fontScale)
        end

        setFont(titleFont)
        if type(lg.setColor) == "function" then lg.setColor(1, 1, 1, 1) end
        printText("LEVEL UP!", panelX + md, panelY + md)
        local identityY = panelY + md + titleH + xs
        setFont(bodyFont)
        local nickname = tostring(mon.nickname or mon.name or mon.species or "POKEMON")
        local levelText = "Lv " .. tostring(mon.level or "")
        printText(nickname, panelX + md, identityY)
        if type(lg.setColor) == "function" then lg.setColor(0.72, 0.78, 0.84, 1) end
        printText(levelText, panelX + panelW - md - textWidth(bodyFont, levelText), identityY)

        local rows = {
          { { "ATTACK", stats.attack }, { "DEFENSE", stats.defense } },
          { { "SPEED", stats.speed }, { "SP. ATK", stats.specialAttack } },
          { { "SP. DEF", stats.specialDefense }, nil },
        }
        local gridY = identityY + bodyH + md
        local columnW = (panelW - md * 2 - sm) / 2
        for line, pair in ipairs(rows) do
          for column = 1, 2 do
            local row = pair[column]
            if row then
              local cellX = panelX + md + (column - 1) * (columnW + sm)
              local cellY = gridY + (line - 1) * (tileH + sm)
              if type(lg.setColor) == "function" then lg.setColor(0.10, 0.13, 0.16, 1) end
              lg.rectangle("fill", cellX, cellY, columnW, tileH, math.max(3, 5 * uiScale))
              if type(lg.setColor) == "function" then lg.setColor(0.28, 0.34, 0.40, 1) end
              lg.rectangle("line", cellX, cellY, columnW, tileH, math.max(3, 5 * uiScale))
              setFont(captionFont)
              if type(lg.setColor) == "function" then lg.setColor(0.72, 0.78, 0.84, 1) end
              printText(row[1], cellX + sm, cellY + (tileH - captionH) / 2)
              local valueText = tostring(row[2] or 0)
              setFont(bodyFont)
              if type(lg.setColor) == "function" then lg.setColor(1, 1, 1, 1) end
              printText(valueText, cellX + columnW - sm - textWidth(bodyFont, valueText),
                cellY + (tileH - bodyH) / 2)
            end
          end
        end

        if pushed and type(lg.pop) == "function" then lg.pop() end
        return true
      end

      hooks:wrap("ui.state.decorate", function(next, game, screen, model)
        local beforeDraw = isStatBox(screen) and screen.draw or nil
        local result = pack(next(game, screen, model))
        local decorated = type(result[1]) == "table" and result[1] or screen
        if not modernUiBattleWipOverrideEnabled() then
          if isStatBox(decorated) then decoratedLevelUpBoxes[decorated] = nil end
          return unpack(result, 1, result.n)
        end
        if isStatBox(decorated) then
          local afterDraw = decorated.draw
          -- The source-owned split draw is the only identity we treat as the
          -- native baseline. A downstream decorator changing THAT exact method
          -- records a candidate Modern Battle UI level-up wrapper. Conversely,
          -- if a later decoration pass restores our draw (Battle UI toggled
          -- back off), retire the candidate immediately.
          if type(state.splitStatBoxDraw) == "function"
              and beforeDraw == state.splitStatBoxDraw
              and type(afterDraw) == "function"
              and afterDraw ~= state.splitStatBoxDraw then
            decoratedLevelUpBoxes[decorated] = { draw = afterDraw }
          elseif afterDraw == state.splitStatBoxDraw then
            decoratedLevelUpBoxes[decorated] = nil
          end
        end
        return unpack(result, 1, result.n)
      end, 200)

      hooks:wrap("render.hud", function(next, game, viewport)
        -- Modern UI's priority-100 HUD paints its experimental battle layer
        -- downstream. Calling next first guarantees our correction lands on top
        -- of its obsolete four-stat card rather than underneath it.
        local result = pack(next(game, viewport))
        local stack = game and game.stack
        local top
        if stack and type(stack.top) == "function" then
          local ok, value = pcall(stack.top, stack)
          if ok then top = value end
        end
        if not top and stack and type(stack.states) == "table" then
          top = stack.states[#stack.states]
        end

        local nativeWasDrawn = top and state.nativeLevelUpDrawSeen[top] == true
        if top then state.nativeLevelUpDrawSeen[top] = nil end
        local decorated = top and decoratedLevelUpBoxes[top] or nil

        if modernUiBattleWipOverrideEnabled()
            and state.active and state.split and isStatBox(top)
            and type(decorated) == "table"
            and top.draw == decorated.draw
            and not nativeWasDrawn then
          -- This is the key fail-safe missing from test3: a mere Modern UI
          -- install is not enough. The correction appears only when the foreign
          -- decorator is still installed AND our own native five-stat draw did
          -- not execute in this frame. With the WIP Battle UI off (its default),
          -- or HIDE ORIGINAL UI allowing the native child to draw, this stays
          -- completely inert.
          drawCorrectLevelUp(game, viewport, top)
        end
        return unpack(result, 1, result.n)
      end, 200)
    end
  end

  mod.exports = mod.exports or {}
  mod.exports.specialSplitActive = function() return state.active end
  mod.exports.moveCategorySplitActive = function() return moveSplitActive end
  mod.exports.modernUiOverrideEnabled = modernUiOverrideEnabled
  mod.exports.modernUiPartyStatsLayout = modernUiPartyStatsLayout
  mod.exports.modernUiBattleWipOverrideEnabled = modernUiBattleWipOverrideEnabled
  -- Backward-compatible alias for prerelease consumers of the old test API.
  mod.exports.modernUiLevelUpOverrideEnabled = modernUiBattleWipOverrideEnabled
  mod.exports.getMoveCategory = function(move)
    if not moveSplitActive then return nil end
    local index = type(move) == "table" and move.index or move
    return GEN4_MOVE_CATEGORY_BY_INDEX[tonumber(index)]
  end
  -- Small inter-mod API for UI mods (for example a Pokédex base-stat page).
  -- Returns nil in VANILLA mode so consumers can fall back to legacy SPECIAL.
  mod.exports.getSpecialBaseStats = function(species)
    if not state.active or not state.split then return nil end
    local def = type(species) == "table" and species or { id = species }
    local row = state.split.baseFor(def)
    if not row then return nil end
    return { specialAttack = row.spa, specialDefense = row.spd }
  end
  mod.exports.attachSplitStats = function(mon, speciesDef)
    if not state.active or not mon or not speciesDef then return mon end
    mon.stats = mon.stats or Stats.calc(speciesDef, mon.level or 1, mon.dvs or {}, mon.statExp or {})
    state.attach(mon.stats, speciesDef, mon.level or 1, mon.dvs or {}, mon.statExp or {})
    return mon
  end

  -- Versioned inter-mod API. Legacy root exports above remain intact so existing
  -- consumers do not need to migrate immediately. New integrations should
  -- feature-detect this table and require apiVersion == 1.
  local function getGameplayConfig()
    return {
      specialStats = gameplayConfig.specialStats,
      moveCategories = gameplayConfig.moveCategories,
    }
  end

  local function getDiagnostics()
    local modernDetected = modernUiHandle ~= nil
    local standaloneMoveCategory = type(mod.find) == "function"
      and mod.find("move_category") ~= nil or false
    return {
      modVersion = tostring(mod.version or "2.6.5"),
      apiVersion = 1,
      gameplay = getGameplayConfig(),
      link = {
        affectsLink = true,
        configRevision = gameplayConfigRevision,
        configRegistered = linkConfigRegistered,
      },
      integrations = {
        crystal251 = {
          detected = crystalMod ~= nil,
          exportedSplitRecords = crystalStatCount,
        },
        modernUi = {
          detected = modernDetected,
          release = modernDetected and tostring(modernUiHandle.version or "") or nil,
          compatibilityApiVersion = modernDetected and tonumber(modernUiApiVersion) or nil,
          overrideEnabled = modernUiOverrideEnabled(),
          surgicalInstalled = modernUiSurgicalInstalled == true,
          battleWipOverrideEnabled = modernUiBattleWipOverrideEnabled(),
        },
        standaloneMoveCategory = {
          detected = standaloneMoveCategory,
          integratedReadoutEnabled = mod.options:get("move_category_readout") ~= false,
        },
      },
    }
  end

  mod.exports.getGameplayConfig = getGameplayConfig
  mod.exports.getLinkConfigRevision = function() return gameplayConfigRevision end
  mod.exports.getDiagnostics = getDiagnostics

  mod.exports.specialStatSplit = {
    apiVersion = 1,
    modVersion = tostring(mod.version or "2.6.5"),
    specialSplitActive = mod.exports.specialSplitActive,
    moveCategorySplitActive = mod.exports.moveCategorySplitActive,
    moveCategoryReadoutEnabled = mod.exports.moveCategoryReadoutEnabled,
    getMoveCategory = mod.exports.getMoveCategory,
    getSpecialBaseStats = mod.exports.getSpecialBaseStats,
    attachSplitStats = mod.exports.attachSplitStats,
    getGameplayConfig = getGameplayConfig,
    getLinkConfigRevision = mod.exports.getLinkConfigRevision,
    getDiagnostics = getDiagnostics,
  }

  if mod.log and type(mod.log.info) == "function" then
    local diag = getDiagnostics()
    local mui = diag.integrations.modernUi
    mod.log:info(("Special Stat Split diagnostics: special=%s move=%s link=%s%s ModernUI=%s%s Crystal251=%s")
      :format(
        gameplayConfig.specialStats,
        gameplayConfig.moveCategories,
        gameplayConfigRevision,
        linkConfigRegistered and "" or " (UNREGISTERED)",
        mui.detected and "detected" or "absent",
        mui.detected and ("/api" .. tostring(mui.compatibilityApiVersion or "?")) or "",
        diag.integrations.crystal251.detected and "detected" or "absent"
      ))
  end
end
