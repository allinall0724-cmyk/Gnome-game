--[[
	GateService
	Resolves an Evolution Gate fight. Per the design doc the fight is fully
	automatic: the squad's total power is pitted against the gate creature,
	the player only chooses when to push in.

	All damage is rolled here on the server; the client is only ever told
	the resulting numbers so it can draw bars.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Stages = require(Shared:WaitForChild("Stages"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FightEvent = Remotes:WaitForChild("FightEvent")
local StageState = Remotes:WaitForChild("StageState")

local World = require(script.Parent.World)

local GateService = {}

local rng = Random.new()

local activeFight = nil -- the player currently pushing the gate
local cooldownUntil = {} -- [player] = os.clock() deadline after a loss

--[[
	No model animation happens here any more.

	Moving the models from the server meant every pose change had to survive
	replication before it could be drawn, which is what made the fight look
	choppy. The server now only decides what happened; the client owns how it
	looks and animates at frame rate from these events.
]]

function GateService.IsBusy()
	return activeFight ~= nil
end

function GateService.CooldownRemaining(player)
	local deadline = cooldownUntil[player]
	if not deadline then
		return 0
	end
	return math.max(0, deadline - os.clock())
end

function GateService.PushState(player)
	StageState:FireClient(player, {
		cooldown = GateService.CooldownRemaining(player),
		busy = activeFight ~= nil and activeFight ~= player,
	})
end

--[[
	Runs the whole fight. Returns true if the squad won.
	squad is an array of { def = <GnomeData entry>, model = <Model> }.
]]
function GateService.Fight(player, squad, stage)
	if activeFight then
		return false, "Another challenger is already at the gate."
	end
	local cooldown = GateService.CooldownRemaining(player)
	if cooldown > 0 then
		return false, string.format("The road is closed for %ds.", math.ceil(cooldown))
	end
	if #squad == 0 then
		return false, "You have no gnomes to send."
	end

	activeFight = player

	local squadPower, squadMaxHealth = 0, 0
	for _, entry in ipairs(squad) do
		squadPower += entry.def.power
		squadMaxHealth += entry.def.health
	end

	local squadHealth = squadMaxHealth
	local enemyHealth = stage.enemyHealth

	local names = {}
	for _, entry in ipairs(squad) do
		table.insert(names, entry.def.name)
	end

	FightEvent:FireClient(player, {
		phase = "start",
		stageName = stage.name,
		enemyName = stage.enemyName,
		enemyMaxHealth = stage.enemyHealth,
		squadMaxHealth = squadMaxHealth,
		squadPower = squadPower,
		enemyPower = stage.enemyPower,
		squadNames = names,
	})
	GateService.PushState(player)

	task.wait(1.8)

	local function roll(base)
		return base * (1 + rng:NextNumber(-Stages.VARIANCE, Stages.VARIANCE))
	end

	local won = false
	while true do
		if not player.Parent then
			break -- challenger left mid-fight
		end

		-- squad swings first
		local squadHit = math.max(1, math.floor(roll(squadPower * Stages.TICK) + 0.5))
		enemyHealth = math.max(0, enemyHealth - squadHit)

		local log = string.format("Your squad hits %s for %d.", stage.enemyName, squadHit)

		if enemyHealth <= 0 then
			FightEvent:FireClient(player, {
				phase = "tick",
				enemyHealth = 0,
				squadHealth = squadHealth,
				squadHit = squadHit,
				enemyHit = 0,
				log = log,
			})
			won = true
			break
		end

		-- creature swings back
		local enemyHit = math.max(1, math.floor(roll(stage.enemyPower * Stages.TICK) + 0.5))
		squadHealth = math.max(0, squadHealth - enemyHit)

		log = log .. string.format("  %s hits back for %d.", stage.enemyName, enemyHit)

		FightEvent:FireClient(player, {
			phase = "tick",
			enemyHealth = enemyHealth,
			squadHealth = squadHealth,
			squadHit = squadHit,
			enemyHit = enemyHit,
			log = log,
		})

		if squadHealth <= 0 then
			won = false
			break
		end

		task.wait(Stages.TICK)
	end

	task.wait(0.6)

	if not won then
		cooldownUntil[player] = os.clock() + Stages.LOSS_COOLDOWN
	end

	FightEvent:FireClient(player, {
		phase = "finish",
		won = won,
		enemyHealth = math.max(0, enemyHealth),
		squadHealth = math.max(0, squadHealth),
		cooldown = won and 0 or Stages.LOSS_COOLDOWN,
	})

	activeFight = nil

	if won then
		-- respawn the creature after a beat so the gate can be re-run
		task.delay(4, function()
			World.SpawnEnemy(stage)
		end)
	end

	GateService.PushState(player)
	return true
end

Players.PlayerRemoving:Connect(function(player)
	cooldownUntil[player] = nil
	if activeFight == player then
		activeFight = nil
	end
end)

-- keeps the client's cooldown readout honest without spamming the remote
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			GateService.PushState(player)
		end
	end
end)

return GateService
