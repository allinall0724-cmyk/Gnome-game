--[[
	GnomeData
	The shared data table every other system reads from. Gnomes are fixed
	units (no leveling), so these numbers ARE the progression curve - keep
	them here and tunable.

	Fields:
		biome       Forest | Desert | Mountain | Swamp
		power       damage per second contributed to Evolution Gate fights
		health      hit points contributed to the squad's shared pool
		production  coins per second when placed on land (not wired up yet)
		sellValue   currency returned when dismantled
		colors      part colours used by GnomeBuilder
]]

local GnomeData = {}

-- Every gnome wears the classic red pointed hat and white beard; the tunic
-- colour is what tells the biomes apart at a glance.
local HAT = Color3.fromRGB(238, 68, 68)
local SKIN = Color3.fromRGB(255, 208, 172)
local BEARD = Color3.fromRGB(252, 252, 250)
local BOOT = Color3.fromRGB(140, 88, 52)
local BELT = Color3.fromRGB(96, 62, 40)

GnomeData.Gnomes = {
	pip = {
		id = "pip",
		name = "Pip Toadstool",
		biome = "Forest",
		rarity = "Common",
		power = 14,
		health = 60,
		production = 1.0,
		sellValue = 25,
		colors = {
			hat = HAT,
			tunic = Color3.fromRGB(92, 198, 96),
			skin = SKIN,
			beard = BEARD,
			boot = BOOT,
			belt = BELT,
		},
		-- eager and slightly cross-eyed, like he has just been handed a job
		face = {
			eyeW = 0.50,
			eyeH = 0.60,
			spread = 0.30,
			eyeY = 2.26,
			-- right eye a touch bigger than the left; nothing here is symmetric
			eyeBias = 0.08,
			pupilConverge = 0.09,
			pupilDrop = -0.02,
			browTilt = 0.62,
			browY = 2.62,
			browLen = 0.46,
			nose = { 0.42, 0.40, 0.50 },
			mouth = "openSmile",
			freckles = true,
		},
	},

	dustan = {
		id = "dustan",
		name = "Dustan Sandsock",
		biome = "Desert",
		rarity = "Common",
		power = 11,
		health = 50,
		production = 1.6,
		sellValue = 25,
		colors = {
			hat = HAT,
			tunic = Color3.fromRGB(250, 202, 92),
			skin = Color3.fromRGB(255, 200, 162),
			beard = BEARD,
			boot = BOOT,
			belt = BELT,
		},
		-- half asleep, one eye barely open, permanently unimpressed
		face = {
			eyeW = 0.44,
			eyeH = 0.30,
			spread = 0.32,
			eyeY = 2.22,
			eyeBias = 0.34,
			pupilConverge = -0.03,
			pupilDrop = -0.06,
			browTilt = -0.18,
			browY = 2.48,
			browLen = 0.52,
			nose = { 0.46, 0.44, 0.58 },
			mouth = "buckTeeth",
			lids = true,
		},
	},

	bruk = {
		id = "bruk",
		name = "Bruk Stonebeard",
		biome = "Mountain",
		rarity = "Common",
		power = 17,
		health = 85,
		production = 0.8,
		sellValue = 25,
		colors = {
			hat = HAT,
			tunic = Color3.fromRGB(104, 168, 244),
			skin = Color3.fromRGB(255, 212, 176),
			beard = BEARD,
			boot = BOOT,
			belt = BELT,
		},
		-- tiny beady eyes, heavy scowl, enormous nose. grumpy but not scary
		face = {
			eyeW = 0.30,
			eyeH = 0.32,
			spread = 0.38,
			eyeY = 2.24,
			eyeBias = -0.1,
			pupilConverge = 0.02,
			pupilDrop = 0.0,
			browTilt = -0.62,
			browY = 2.46,
			browLen = 0.58,
			nose = { 0.58, 0.54, 0.68 },
			mouth = "underbite",
			unibrow = true,
		},
	},
}

-- The gnomes a brand new player starts with, in placement order.
GnomeData.StarterLoadout = { "pip", "dustan", "bruk" }

function GnomeData.Get(id)
	return GnomeData.Gnomes[id]
end

return GnomeData
