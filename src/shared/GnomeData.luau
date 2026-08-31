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
	},
}

-- The gnomes a brand new player starts with, in placement order.
GnomeData.StarterLoadout = { "pip", "dustan", "bruk" }

function GnomeData.Get(id)
	return GnomeData.Gnomes[id]
end

return GnomeData
