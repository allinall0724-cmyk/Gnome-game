--[[
	ShopData
	Everything the rotating shop sells, plus the economy constants that
	balance it. Like GnomeData this is a plain data table: tune the numbers
	here, never inside a service.

	The shop rotates on a fixed wall-clock schedule so every server agrees
	on the current stock without any coordination - see ShopService.
]]

local GnomeData = require(script.Parent.GnomeData)

local ShopData = {}

ShopData.ROTATION = 900 -- seconds per shop rotation (15 minutes)
ShopData.STOCK_SIZE = 4 -- gnomes offered per rotation
ShopData.CAPACITY = 60 -- how many gnomes a player can hold
ShopData.STARTING_GOLD = 2500

--[[
	Eggs roll a rarity from these weights, then a random gnome of that
	rarity. Legendary gnomes have no shop price, so eggs are the only way
	to get one.
]]
ShopData.Eggs = {
	{
		id = "biome",
		name = "BIOME EGG",
		blurb = "Chance for Biome Gnomes!",
		price = 3000,
		color = Color3.fromRGB(146, 78, 220),
		weights = { Common = 70, Rare = 26, Epic = 4 },
	},
	{
		id = "ancient",
		name = "ANCIENT EGG",
		blurb = "Chance for Rare Gnomes!",
		price = 9000,
		color = Color3.fromRGB(212, 158, 52),
		weights = { Common = 30, Rare = 50, Epic = 19, Legendary = 1 },
	},
	{
		id = "void",
		name = "VOID EGG",
		blurb = "Chance for Epic & Legendary!",
		price = 20000,
		color = Color3.fromRGB(120, 78, 208),
		weights = { Rare = 40, Epic = 52, Legendary = 8 },
	},
}

-- Called out in its own panel on the shop page.
ShopData.FeaturedEgg = {
	id = "boss",
	name = "BOSS GNOME EGG",
	blurb = "Guaranteed Epic or Legendary!",
	tag = "VERY RARE",
	price = 45000,
	color = Color3.fromRGB(236, 176, 52),
	weights = { Epic = 80, Legendary = 20 },
}

--[[
	Consumable boosts. Temporary and rebuyable per the design doc - nothing
	here is a permanent upgrade.

	kind       which multiplier it feeds
	magnitude  added on top of 1.0, so 0.5 means +50%
]]
ShopData.Boosts = {
	{
		id = "damage",
		name = "DAMAGE BOOST",
		kind = "damage",
		magnitude = 0.5,
		duration = 900,
		price = 6000,
		blurb = "+50% Damage",
		color = Color3.fromRGB(226, 88, 72),
	},
	{
		id = "production",
		name = "PRODUCTION BOOST",
		kind = "production",
		magnitude = 0.5,
		duration = 900,
		price = 6000,
		blurb = "+50% Gold Production",
		color = Color3.fromRGB(72, 162, 232),
	},
	{
		id = "luck",
		name = "LUCK BOOST",
		kind = "luck",
		magnitude = 0.25,
		duration = 900,
		price = 4500,
		blurb = "+25% Luck",
		color = Color3.fromRGB(72, 186, 96),
	},
}

--[[
	How much a point of luck shifts each rarity's weight. Negative pushes
	Common down, so luck both raises the ceiling and thins the floor.
]]
ShopData.LuckBias = {
	Common = -0.6,
	Rare = 0.8,
	Epic = 1.6,
	Legendary = 2.6,
}

function ShopData.GetEgg(id)
	if ShopData.FeaturedEgg.id == id then
		return ShopData.FeaturedEgg
	end
	for _, egg in ipairs(ShopData.Eggs) do
		if egg.id == id then
			return egg
		end
	end
	return nil
end

function ShopData.GetBoost(id)
	for _, boost in ipairs(ShopData.Boosts) do
		if boost.id == id then
			return boost
		end
	end
	return nil
end

--[[
	Rolls an egg and returns the gnome definition it hatched.

	luck is the player's luck bonus (0.25 for a +25% luck boost). rng lets
	the caller supply a seeded Random; it defaults to a shared one.
]]
local sharedRng = Random.new()

function ShopData.RollEgg(egg, luck, rng)
	rng = rng or sharedRng
	luck = luck or 0

	-- Walk rarities in GnomeData order so the roll is reproducible for a
	-- given rng state rather than depending on pairs().
	local total = 0
	local weighted = {}
	for _, rarity in ipairs(GnomeData.Rarities) do
		local weight = egg.weights[rarity]
		if weight then
			local bias = ShopData.LuckBias[rarity] or 0
			local adjusted = weight * math.max(0.05, 1 + luck * bias)
			total += adjusted
			table.insert(weighted, { rarity = rarity, weight = adjusted })
		end
	end

	local roll = rng:NextNumber() * total
	local picked = weighted[#weighted].rarity
	for _, entry in ipairs(weighted) do
		roll -= entry.weight
		if roll <= 0 then
			picked = entry.rarity
			break
		end
	end

	local pool = GnomeData.Filter({ rarity = picked })
	if #pool == 0 then
		-- a rarity with nothing in the roster should never ship, but do
		-- not hand the caller a nil gnome if it does
		pool = GnomeData.Filter({ rarity = "Common" })
	end
	return pool[rng:NextInteger(1, #pool)]
end

--[[
	The stock for a given rotation index. Deterministic: seeding off the
	index means every server and every client computes the same four
	gnomes without the server having to broadcast a roll.
]]
function ShopData.StockFor(rotationIndex)
	local pool = GnomeData.Filter({ buyable = true })
	local rng = Random.new(rotationIndex * 7919)

	-- Fisher-Yates over a copy, then take the first STOCK_SIZE.
	local shuffled = table.clone(pool)
	for i = #shuffled, 2, -1 do
		local j = rng:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	local stock = {}
	for index = 1, math.min(ShopData.STOCK_SIZE, #shuffled) do
		table.insert(stock, shuffled[index])
	end
	return stock
end

function ShopData.RotationIndex(now)
	return math.floor((now or os.time()) / ShopData.ROTATION)
end

function ShopData.SecondsUntilRotation(now)
	now = now or os.time()
	return ShopData.ROTATION - (now % ShopData.ROTATION)
end

return ShopData
