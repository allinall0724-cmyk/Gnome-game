--[[
	Weather
	The live-event layer: a random event fires every ~10 minutes and runs
	for 3-5 minutes, granting stacking modifiers while it is up.

	Per the design doc the modifiers stack freely but never duplicate - the
	same event cannot be running twice at once. Bonuses add rather than
	multiply, so two production events read as the obvious sum.

	Nothing here touches currency directly; Economy asks for a multiplier.
]]

local Weather = {}

Weather.MIN_GAP = 480 -- seconds between events (design doc: ~10 min)
Weather.MAX_GAP = 720
Weather.MIN_DURATION = 180 -- design doc: 3-5 minutes
Weather.MAX_DURATION = 300
Weather.MAX_ACTIVE = 3
Weather.FIRST_EVENT_DELAY = 30 -- so a fresh server shows something quickly

--[[
	Each event contributes a bonus to one or more multiplier kinds. The
	kinds match the boost kinds in ShopData so Economy can total them the
	same way.
]]
Weather.Events = {
	{
		id = "sunny",
		name = "SUNNY SPELL",
		blurb = "+20% Gold Production",
		color = Color3.fromRGB(250, 202, 74),
		bonuses = { production = 0.20 },
	},
	{
		id = "cloudy",
		name = "CLOUD COVER",
		blurb = "+10% Gold Production",
		color = Color3.fromRGB(158, 176, 200),
		bonuses = { production = 0.10 },
	},
	{
		id = "winterchill",
		name = "WINTER CHILL",
		blurb = "+15% Production, +10% Damage",
		color = Color3.fromRGB(140, 206, 244),
		bonuses = { production = 0.15, damage = 0.10 },
	},
	{
		id = "thunderhead",
		name = "THUNDERHEAD",
		blurb = "+30% Damage",
		color = Color3.fromRGB(168, 128, 244),
		bonuses = { damage = 0.30 },
	},
	{
		id = "harvestmoon",
		name = "HARVEST MOON",
		blurb = "+35% Gold Production",
		color = Color3.fromRGB(244, 154, 76),
		bonuses = { production = 0.35 },
	},
	{
		id = "fourleaffog",
		name = "FOUR-LEAF FOG",
		blurb = "+30% Luck",
		color = Color3.fromRGB(96, 202, 118),
		bonuses = { luck = 0.30 },
	},
}

local rng = Random.new()

-- [eventId] = { event = <def>, expires = os.clock() deadline }
local active = {}
local started = false

local function isActive(id)
	return active[id] ~= nil
end

local function expireFinished()
	local now = os.clock()
	for id, entry in pairs(active) do
		if now >= entry.expires then
			active[id] = nil
		end
	end
end

local function beginRandomEvent()
	expireFinished()

	local count = 0
	for _ in pairs(active) do
		count += 1
	end
	if count >= Weather.MAX_ACTIVE then
		return
	end

	-- candidates are every event not already running: the "no duplicates"
	-- half of the stacking rule
	local candidates = {}
	for _, event in ipairs(Weather.Events) do
		if not isActive(event.id) then
			table.insert(candidates, event)
		end
	end
	if #candidates == 0 then
		return
	end

	local event = candidates[rng:NextInteger(1, #candidates)]
	local duration = rng:NextNumber(Weather.MIN_DURATION, Weather.MAX_DURATION)
	active[event.id] = { event = event, expires = os.clock() + duration }
end

function Weather.Start()
	if started then
		return
	end
	started = true

	task.spawn(function()
		task.wait(Weather.FIRST_EVENT_DELAY)
		beginRandomEvent()
		while true do
			task.wait(rng:NextNumber(Weather.MIN_GAP, Weather.MAX_GAP))
			beginRandomEvent()
		end
	end)

	-- sweep expiries even when no new event is due, so Active() and the
	-- multipliers never report something that already ended
	task.spawn(function()
		while true do
			task.wait(1)
			expireFinished()
		end
	end)
end

-- Sum of every active event's bonus for one kind, as a multiplier.
function Weather.Multiplier(kind)
	expireFinished()
	local bonus = 0
	for _, entry in pairs(active) do
		bonus += entry.event.bonuses[kind] or 0
	end
	return 1 + bonus
end

-- Replication-ready list for the HUD, soonest to expire first.
function Weather.Active()
	expireFinished()
	local now = os.clock()
	local list = {}
	for _, entry in pairs(active) do
		table.insert(list, {
			id = entry.event.id,
			name = entry.event.name,
			blurb = entry.event.blurb,
			color = entry.event.color,
			remaining = math.max(0, entry.expires - now),
		})
	end
	table.sort(list, function(a, b)
		return a.remaining < b.remaining
	end)
	return list
end

return Weather
