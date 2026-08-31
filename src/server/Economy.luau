--[[
	Economy
	Per-player gold, owned gnomes, and active consumable boosts, plus the
	passive production tick that turns owned gnomes into currency.

	Server-authoritative: every balance change happens in here and the
	client is only ever told the resulting numbers.

	Scope note: the Land system does not exist yet, so "owned" doubles as
	"placed on land" - production sums every gnome in the player's
	inventory. When plots arrive this should sum only the placed ones.

	State is in memory only. Nothing persists across a server restart;
	adding a DataStore is a separate job.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GnomeData = require(Shared:WaitForChild("GnomeData"))
local ShopData = require(Shared:WaitForChild("ShopData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EconomyState = Remotes:WaitForChild("EconomyState")

local Weather = require(script.Parent.Weather)

local Economy = {}

Economy.TICK = 1 -- seconds between production ticks and state pushes

local profiles = {} -- [player] = profile
local started = false

local function newProfile()
	local profile = {
		gold = ShopData.STARTING_GOLD,
		gnomes = {}, -- array of { uid = number, id = string }
		boosts = {}, -- [boostId] = { boost = <def>, expires = os.clock() }
		nextUid = 1,
	}
	for _, id in ipairs(GnomeData.StarterLoadout) do
		table.insert(profile.gnomes, { uid = profile.nextUid, id = id })
		profile.nextUid += 1
	end
	return profile
end

local function profileOf(player)
	local profile = profiles[player]
	if not profile then
		profile = newProfile()
		profiles[player] = profile
	end
	return profile
end

Economy.Profile = profileOf

local function expireBoosts(profile)
	local now = os.clock()
	for id, entry in pairs(profile.boosts) do
		if now >= entry.expires then
			profile.boosts[id] = nil
		end
	end
end

--------------------------------------------------------------------
-- Multipliers
--------------------------------------------------------------------

--[[
	Boost and weather bonuses add rather than compound, so a +50% boost
	during a +20% weather event reads as a plain +70%.
]]
function Economy.Multiplier(player, kind)
	local profile = profileOf(player)
	expireBoosts(profile)

	local bonus = 0
	for _, entry in pairs(profile.boosts) do
		if entry.boost.kind == kind then
			bonus += entry.boost.magnitude
		end
	end

	return 1 + bonus + (Weather.Multiplier(kind) - 1)
end

-- Gold per second before multipliers.
function Economy.BaseRate(player)
	local profile = profileOf(player)
	local rate = 0
	for _, entry in ipairs(profile.gnomes) do
		local def = GnomeData.Get(entry.id)
		if def then
			rate += def.production
		end
	end
	return rate
end

function Economy.Rate(player)
	return Economy.BaseRate(player) * Economy.Multiplier(player, "production")
end

--------------------------------------------------------------------
-- Balance and inventory
--------------------------------------------------------------------

function Economy.Gold(player)
	return profileOf(player).gold
end

function Economy.CanAfford(player, amount)
	return profileOf(player).gold >= amount
end

function Economy.Spend(player, amount)
	local profile = profileOf(player)
	if profile.gold < amount then
		return false
	end
	profile.gold -= amount
	return true
end

function Economy.Award(player, amount)
	local profile = profileOf(player)
	profile.gold += amount
	return profile.gold
end

function Economy.Count(player)
	return #profileOf(player).gnomes
end

function Economy.IsFull(player)
	return Economy.Count(player) >= ShopData.CAPACITY
end

-- Returns the new inventory entry, or nil when the player is at capacity.
function Economy.AddGnome(player, gnomeId)
	local def = GnomeData.Get(gnomeId)
	if not def then
		return nil
	end
	local profile = profileOf(player)
	if #profile.gnomes >= ShopData.CAPACITY then
		return nil
	end

	local entry = { uid = profile.nextUid, id = gnomeId }
	profile.nextUid += 1
	table.insert(profile.gnomes, entry)
	return entry
end

--[[
	Dismantles the listed gnomes and pays out their sell value. Returns the
	gold earned and how many were actually sold - unknown uids are ignored
	rather than failing the whole sale.
]]
function Economy.SellGnomes(player, uids)
	local profile = profileOf(player)

	local wanted = {}
	for _, uid in ipairs(uids) do
		if type(uid) == "number" then
			wanted[uid] = true
		end
	end

	local earned, sold = 0, 0
	local kept = {}
	for _, entry in ipairs(profile.gnomes) do
		if wanted[entry.uid] then
			local def = GnomeData.Get(entry.id)
			earned += def and def.sellValue or 0
			sold += 1
		else
			table.insert(kept, entry)
		end
	end

	profile.gnomes = kept
	profile.gold += earned
	return earned, sold
end

--------------------------------------------------------------------
-- Boosts
--------------------------------------------------------------------

-- Buying a boost that is already running extends it rather than stacking
-- a second copy of the same modifier.
function Economy.ApplyBoost(player, boost)
	local profile = profileOf(player)
	expireBoosts(profile)

	local existing = profile.boosts[boost.id]
	if existing then
		existing.expires += boost.duration
	else
		profile.boosts[boost.id] = {
			boost = boost,
			expires = os.clock() + boost.duration,
		}
	end
end

--------------------------------------------------------------------
-- Replication
--------------------------------------------------------------------

local function gnomeList(player)
	local profile = profileOf(player)
	local list = {}
	for _, entry in ipairs(profile.gnomes) do
		local def = GnomeData.Get(entry.id)
		if def then
			table.insert(list, {
				uid = entry.uid,
				id = def.id,
				name = def.name,
				biome = def.biome,
				rarity = def.rarity,
				power = def.power,
				health = def.health,
				production = def.production,
				sellValue = def.sellValue,
			})
		end
	end
	return list
end

Economy.GnomeList = gnomeList

local function boostList(player)
	local profile = profileOf(player)
	expireBoosts(profile)

	local now = os.clock()
	local list = {}
	for _, entry in pairs(profile.boosts) do
		table.insert(list, {
			id = entry.boost.id,
			name = entry.boost.name,
			kind = entry.boost.kind,
			blurb = entry.boost.blurb,
			color = entry.boost.color,
			remaining = math.max(0, entry.expires - now),
		})
	end
	table.sort(list, function(a, b)
		return a.remaining < b.remaining
	end)
	return list
end

--[[
	Pushes the player's economy state.

	extra may carry any of:
		gnomes  true to include the full inventory (only sent when it changed)
		notice  { text = string, tone = "good" | "bad" }
		reveal  a gnome definition to show in the egg-reveal panel
]]
function Economy.Push(player, extra)
	extra = extra or {}

	local payload = {
		gold = math.floor(profileOf(player).gold),
		rate = Economy.Rate(player),
		baseRate = Economy.BaseRate(player),
		count = Economy.Count(player),
		capacity = ShopData.CAPACITY,
		boosts = boostList(player),
		weather = Weather.Active(),
		notice = extra.notice,
	}

	if extra.gnomes then
		payload.gnomes = gnomeList(player)
	end

	if extra.reveal then
		local def = extra.reveal
		payload.reveal = {
			id = def.id,
			name = def.name,
			biome = def.biome,
			rarity = def.rarity,
			power = def.power,
			health = def.health,
			production = def.production,
		}
	end

	EconomyState:FireClient(player, payload)
end

-- Convenience for the common "something changed, resend everything" case.
function Economy.PushFull(player, extra)
	extra = extra or {}
	extra.gnomes = true
	Economy.Push(player, extra)
end

--------------------------------------------------------------------
-- Production loop
--------------------------------------------------------------------

function Economy.Start()
	if started then
		return
	end
	started = true

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(Economy.TICK)

			local now = os.clock()
			local delta = now - last
			last = now

			for _, player in ipairs(Players:GetPlayers()) do
				local profile = profileOf(player)
				profile.gold += Economy.Rate(player) * delta
				Economy.Push(player)
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	profiles[player] = nil
end)

return Economy
