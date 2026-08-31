--[[
	Server bootstrap.

	Builds the map, hands the player their three starter gnomes, and wires
	the challenge stone up to the Stage 1 gate fight.

	Scope note: this first slice uses one shared plot and one shared squad.
	Per-player plots come with the Land system.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GnomeData = require(Shared:WaitForChild("GnomeData"))
local Stages = require(Shared:WaitForChild("Stages"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GnomesUpdated = Remotes:WaitForChild("GnomesUpdated")

local World = require(script.World)
local GateService = require(script.GateService)
local Economy = require(script.Economy)
local ShopService = require(script.ShopService)
local Weather = require(script.Weather)

local STAGE = Stages.Get(1)

-- The map is built at runtime rather than stored in the place file, so hold
-- character spawning until the ground actually exists. Otherwise a player who
-- joins mid-build drops through the void.
Players.CharacterAutoLoads = false

World.ApplyStyle()
World.Build()

-- The starter squad: three plain garden gnomes, one per biome.
local defs = {}
for _, id in ipairs(GnomeData.StarterLoadout) do
	table.insert(defs, GnomeData.Get(id))
end

local models = World.PlaceGnomes(defs)
World.SpawnEnemy(STAGE)

-- The economy layer runs independently of the plot: weather drives the
-- shared modifiers, Economy tills each player's gold, ShopService owns the
-- rotation clock and validates purchases.
Weather.Start()
Economy.Start()
ShopService.Start()

-- squad entries pair the data with the model so the fight can animate them
local squad = {}
for index, def in ipairs(defs) do
	squad[index] = { def = def, model = models[index] }
end

local function summary()
	local list = {}
	local totalPower, totalHealth = 0, 0
	for _, def in ipairs(defs) do
		totalPower += def.power
		totalHealth += def.health
		table.insert(list, {
			name = def.name,
			biome = def.biome,
			rarity = def.rarity,
			power = def.power,
			health = def.health,
		})
	end
	return {
		gnomes = list,
		totalPower = totalPower,
		totalHealth = totalHealth,
		stage = {
			name = STAGE.name,
			blurb = STAGE.blurb,
			enemyName = STAGE.enemyName,
			enemyHealth = STAGE.enemyHealth,
			enemyPower = STAGE.enemyPower,
		},
	}
end

Players.PlayerAdded:Connect(function(player)
	GnomesUpdated:FireClient(player, summary())
	GateService.PushState(player)
	Economy.PushFull(player)
	ShopService.Push(player)
end)

-- The world is ready: let characters spawn, and load anyone who joined while
-- the map was still being built.
Players.CharacterAutoLoads = true
for _, player in ipairs(Players:GetPlayers()) do
	if not player.Character then
		player:LoadCharacter()
	end
end

World.Prompt.Triggered:Connect(function(player)
	-- damage boosts and stormy weather both land here as one multiplier
	local power = Economy.Multiplier(player, "damage")
	local ok, reason = GateService.Fight(player, squad, STAGE, power)
	if not ok then
		warn(string.format("[Gate] %s could not start: %s", player.Name, reason))
	end
end)

-- The client asks for state once its UI is up, which avoids the race where
-- PlayerAdded fires before the LocalScript has connected its listeners.
Remotes:WaitForChild("RequestState").OnServerEvent:Connect(function(player)
	GnomesUpdated:FireClient(player, summary())
	GateService.PushState(player)
	Economy.PushFull(player)
	ShopService.Push(player)
end)
