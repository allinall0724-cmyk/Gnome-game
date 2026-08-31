--[[
	GnomeData
	The shared data table every other system reads from. Gnomes are fixed
	units (no leveling), so these numbers ARE the progression curve - keep
	them here and tunable.

	Fields:
		biome       Forest | Desert | Mountain | Swamp
		rarity      Common | Rare | Epic | Legendary
		power       damage per second contributed to Evolution Gate fights
		health      hit points contributed to the squad's shared pool
		production  coins per second while owned
		price       shop cost; absent means the gnome is egg-only
		sellValue   currency returned when dismantled
		colors      part colours used by GnomeBuilder

	price and sellValue default from RarityInfo below, so a gnome only
	spells them out when it should break the curve.

	The three starter gnomes keep their original power/health on purpose -
	Stage 1 is balanced against exactly those numbers.
]]

local GnomeData = {}

-- Every gnome wears the classic red pointed hat and white beard unless it
-- overrides them; the tunic colour is what tells the biomes apart at a
-- glance.
local HAT = Color3.fromRGB(238, 68, 68)
local SKIN = Color3.fromRGB(255, 208, 172)
local BEARD = Color3.fromRGB(252, 252, 250)
local BOOT = Color3.fromRGB(140, 88, 52)
local BELT = Color3.fromRGB(96, 62, 40)

local function look(tunic, overrides)
	local colors = {
		hat = HAT,
		tunic = tunic,
		skin = SKIN,
		beard = BEARD,
		boot = BOOT,
		belt = BELT,
	}
	for key, value in pairs(overrides or {}) do
		colors[key] = value
	end
	return colors
end

--[[
	Rarity drives the default economy numbers and the sort order used by
	the inventory. Legendary has no price: it only comes out of an egg.
]]
GnomeData.RarityInfo = {
	Common = { order = 1, price = 900, sell = 200 },
	Rare = { order = 2, price = 6500, sell = 1500 },
	Epic = { order = 3, price = 24000, sell = 5500 },
	Legendary = { order = 4, sell = 26000 },
}

GnomeData.Rarities = { "Common", "Rare", "Epic", "Legendary" }
GnomeData.Biomes = { "Forest", "Desert", "Mountain", "Swamp" }

GnomeData.Gnomes = {
	--------------------------------------------------------------
	-- Forest
	--------------------------------------------------------------
	pip = {
		name = "Pip Toadstool",
		biome = "Forest",
		rarity = "Common",
		power = 14,
		health = 60,
		production = 1.0,
		colors = look(Color3.fromRGB(92, 198, 96)),
	},
	leafkin = {
		name = "Leafkin",
		biome = "Forest",
		rarity = "Common",
		power = 12,
		health = 55,
		production = 1.2,
		colors = look(Color3.fromRGB(120, 206, 110), { hat = Color3.fromRGB(96, 176, 76) }),
	},
	fernling = {
		name = "Fernling",
		biome = "Forest",
		rarity = "Common",
		power = 13,
		health = 58,
		production = 1.1,
		colors = look(Color3.fromRGB(74, 176, 96)),
	},
	petalbeard = {
		name = "Petalbeard",
		biome = "Forest",
		rarity = "Rare",
		power = 34,
		health = 140,
		production = 3.4,
		colors = look(Color3.fromRGB(86, 190, 104), {
			hat = Color3.fromRGB(238, 120, 180),
			beard = Color3.fromRGB(250, 186, 214),
		}),
	},
	thorncrown = {
		name = "Thorncrown",
		biome = "Forest",
		rarity = "Epic",
		power = 78,
		health = 320,
		production = 7.6,
		colors = look(Color3.fromRGB(46, 132, 74), {
			hat = Color3.fromRGB(216, 86, 74),
			beard = Color3.fromRGB(226, 240, 226),
			belt = Color3.fromRGB(58, 40, 26),
		}),
	},

	--------------------------------------------------------------
	-- Desert
	--------------------------------------------------------------
	dustan = {
		name = "Dustan Sandsock",
		biome = "Desert",
		rarity = "Common",
		power = 11,
		health = 50,
		production = 1.6,
		colors = look(Color3.fromRGB(250, 202, 92), { skin = Color3.fromRGB(255, 200, 162) }),
	},
	cactusquill = {
		name = "Cactus Quill",
		biome = "Desert",
		rarity = "Common",
		power = 13,
		health = 48,
		production = 1.5,
		colors = look(Color3.fromRGB(226, 182, 86), { hat = Color3.fromRGB(104, 178, 96) }),
	},
	thornwick = {
		name = "Thornwick",
		biome = "Desert",
		rarity = "Rare",
		power = 31,
		health = 120,
		production = 4.0,
		colors = look(Color3.fromRGB(236, 178, 96), {
			hat = Color3.fromRGB(198, 142, 66),
			beard = Color3.fromRGB(244, 234, 206),
			skin = Color3.fromRGB(255, 198, 158),
		}),
	},
	emberdune = {
		name = "Emberdune",
		biome = "Desert",
		rarity = "Epic",
		power = 74,
		health = 290,
		production = 8.2,
		colors = look(Color3.fromRGB(238, 142, 58), {
			hat = Color3.fromRGB(232, 96, 52),
			beard = Color3.fromRGB(255, 226, 180),
		}),
	},

	--------------------------------------------------------------
	-- Mountain
	--------------------------------------------------------------
	bruk = {
		name = "Bruk Stonebeard",
		biome = "Mountain",
		rarity = "Common",
		power = 17,
		health = 85,
		production = 0.8,
		colors = look(Color3.fromRGB(104, 168, 244), { skin = Color3.fromRGB(255, 212, 176) }),
	},
	flintcap = {
		name = "Flintcap",
		biome = "Mountain",
		rarity = "Common",
		power = 16,
		health = 78,
		production = 0.9,
		colors = look(Color3.fromRGB(128, 148, 176), { hat = Color3.fromRGB(198, 92, 78) }),
	},
	icevein = {
		name = "Icevein",
		biome = "Mountain",
		rarity = "Rare",
		power = 38,
		health = 165,
		production = 3.0,
		colors = look(Color3.fromRGB(128, 206, 244), {
			hat = Color3.fromRGB(92, 166, 226),
			beard = Color3.fromRGB(232, 248, 255),
		}),
	},
	oldgranite = {
		name = "Old Granite",
		biome = "Mountain",
		rarity = "Epic",
		power = 88,
		health = 380,
		production = 6.4,
		colors = look(Color3.fromRGB(110, 120, 138), {
			hat = Color3.fromRGB(168, 96, 86),
			beard = Color3.fromRGB(222, 228, 236),
			belt = Color3.fromRGB(62, 52, 44),
		}),
	},

	--------------------------------------------------------------
	-- Swamp
	--------------------------------------------------------------
	muckle = {
		name = "Muckle",
		biome = "Swamp",
		rarity = "Common",
		power = 12,
		health = 66,
		production = 1.4,
		colors = look(Color3.fromRGB(118, 164, 110), {
			hat = Color3.fromRGB(176, 82, 78),
			skin = Color3.fromRGB(226, 214, 176),
		}),
	},
	dewdrop = {
		name = "Dewdrop",
		biome = "Swamp",
		rarity = "Rare",
		power = 33,
		health = 130,
		production = 3.6,
		colors = look(Color3.fromRGB(96, 186, 206), {
			hat = Color3.fromRGB(78, 150, 214),
			beard = Color3.fromRGB(206, 236, 244),
		}),
	},
	bramble = {
		name = "Bramble",
		biome = "Swamp",
		rarity = "Rare",
		power = 36,
		health = 145,
		production = 3.2,
		colors = look(Color3.fromRGB(126, 110, 168), {
			hat = Color3.fromRGB(150, 92, 206),
			beard = Color3.fromRGB(224, 216, 240),
		}),
	},
	mirelord = {
		name = "Mirelord",
		biome = "Swamp",
		rarity = "Epic",
		power = 80,
		health = 340,
		production = 7.0,
		colors = look(Color3.fromRGB(92, 124, 96), {
			hat = Color3.fromRGB(140, 196, 96),
			beard = Color3.fromRGB(214, 232, 206),
			belt = Color3.fromRGB(52, 44, 32),
		}),
	},

	--------------------------------------------------------------
	-- Legendary - egg only, never stocked in the shop
	--------------------------------------------------------------
	goldbeard = {
		name = "Aurus Goldbeard",
		biome = "Mountain",
		rarity = "Legendary",
		power = 165,
		health = 720,
		production = 16.0,
		colors = look(Color3.fromRGB(224, 178, 62), {
			hat = Color3.fromRGB(248, 206, 84),
			beard = Color3.fromRGB(255, 246, 214),
			belt = Color3.fromRGB(150, 104, 30),
			boot = Color3.fromRGB(120, 84, 36),
		}),
	},
	shroomking = {
		name = "Mystic Shroom King",
		biome = "Swamp",
		rarity = "Legendary",
		power = 158,
		health = 690,
		production = 18.0,
		colors = look(Color3.fromRGB(150, 96, 208), {
			hat = Color3.fromRGB(188, 108, 232),
			beard = Color3.fromRGB(238, 224, 252),
			belt = Color3.fromRGB(74, 44, 106),
		}),
	},
}

--[[
	A stable, explicitly ordered id list. pairs() order is not deterministic
	and the shop seeds its rotation off this, so every server has to walk
	the roster in the same sequence.
]]
GnomeData.Order = {
	"pip",
	"leafkin",
	"fernling",
	"petalbeard",
	"thorncrown",
	"dustan",
	"cactusquill",
	"thornwick",
	"emberdune",
	"bruk",
	"flintcap",
	"icevein",
	"oldgranite",
	"muckle",
	"dewdrop",
	"bramble",
	"mirelord",
	"goldbeard",
	"shroomking",
}

-- Fill in id and the rarity-driven economy defaults.
for id, def in pairs(GnomeData.Gnomes) do
	local info = GnomeData.RarityInfo[def.rarity]
	def.id = id
	def.rarityOrder = info.order
	if def.price == nil then
		def.price = info.price
	end
	if def.sellValue == nil then
		def.sellValue = info.sell
	end
end

-- The gnomes a brand new player starts with, in placement order.
GnomeData.StarterLoadout = { "pip", "dustan", "bruk" }

function GnomeData.Get(id)
	return GnomeData.Gnomes[id]
end

function GnomeData.RarityOrder(rarity)
	local info = GnomeData.RarityInfo[rarity]
	return info and info.order or 0
end

-- Every gnome matching a filter, in GnomeData.Order sequence.
-- filter fields are all optional: rarity, biome, buyable.
function GnomeData.Filter(filter)
	filter = filter or {}
	local out = {}
	for _, id in ipairs(GnomeData.Order) do
		local def = GnomeData.Gnomes[id]
		local ok = true
		if filter.rarity and def.rarity ~= filter.rarity then
			ok = false
		end
		if filter.biome and def.biome ~= filter.biome then
			ok = false
		end
		if filter.buyable and not def.price then
			ok = false
		end
		if ok then
			table.insert(out, def)
		end
	end
	return out
end

return GnomeData
