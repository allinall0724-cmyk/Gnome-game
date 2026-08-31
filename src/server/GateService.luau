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
local TweenService = game:GetService("TweenService")

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

-- Durations are generous and eased on both ends. Anchored-part CFrames
-- replicate slowly, so short abrupt tweens arrive as a jump; longer arcs give
-- the client something continuous to interpolate along.
local HOP = TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local RETURN = TweenInfo.new(0.34, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local MARCH = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local FLASH_IN = TweenInfo.new(0.09, Enum.EasingStyle.Sine)
local FLASH_OUT = TweenInfo.new(0.38, Enum.EasingStyle.Sine)

local function highlightOf(model, color)
	local highlight = model:FindFirstChildOfClass("Highlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.OutlineTransparency = 1
		highlight.Parent = model
	end
	highlight.FillColor = color
	highlight.FillTransparency = 1
	return highlight
end

local function flash(model, color)
	local highlight = highlightOf(model, color)
	TweenService:Create(highlight, FLASH_IN, { FillTransparency = 0.35 }):Play()
	task.delay(0.09, function()
		if highlight.Parent then
			TweenService:Create(highlight, FLASH_OUT, { FillTransparency = 1 }):Play()
		end
	end)
end

-- A short forward hop, used for both the squad's swings and the creature's.
local function lunge(model, home, distance)
	local root = model.PrimaryPart
	if not root then
		return
	end
	TweenService:Create(root, HOP, {
		CFrame = home * CFrame.new(0, 0.6, -distance),
	}):Play()
	task.delay(0.22, function()
		if root.Parent then
			TweenService:Create(root, RETURN, { CFrame = home }):Play()
		end
	end)
end

local function moveTo(model, cframe)
	local root = model.PrimaryPart
	if root then
		TweenService:Create(root, MARCH, { CFrame = cframe }):Play()
	end
end

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

	local enemy = World.Enemy
	local enemyHome = CFrame.new(World.ENEMY_POSITION)

	local squadPower, squadMaxHealth = 0, 0
	for _, entry in ipairs(squad) do
		squadPower += entry.def.power
		squadMaxHealth += entry.def.health
	end

	local squadHealth = squadMaxHealth
	local enemyHealth = stage.enemyHealth

	-- march the gnomes into the arena, facing the creature
	local homes = {}
	for index, entry in ipairs(squad) do
		local slot = World.ARENA_SLOTS[index]
		homes[index] = CFrame.new(slot) * CFrame.Angles(0, math.pi, 0)
		moveTo(entry.model, homes[index])
	end

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

		for index, entry in ipairs(squad) do
			lunge(entry.model, homes[index], 1.6)
		end
		if enemy then
			flash(enemy, Color3.fromRGB(255, 96, 80))
		end

		local log = string.format("Your squad hits %s for %d.", stage.enemyName, squadHit)

		if enemyHealth <= 0 then
			FightEvent:FireClient(player, {
				phase = "tick",
				enemyHealth = 0,
				squadHealth = squadHealth,
				log = log,
			})
			won = true
			break
		end

		-- creature swings back
		local enemyHit = math.max(1, math.floor(roll(stage.enemyPower * Stages.TICK) + 0.5))
		squadHealth = math.max(0, squadHealth - enemyHit)

		task.delay(Stages.TICK * 0.45, function()
			if enemy and enemy.Parent then
				lunge(enemy, enemyHome, 2.4)
			end
			for _, entry in ipairs(squad) do
				if entry.model.Parent then
					flash(entry.model, Color3.fromRGB(255, 120, 120))
				end
			end
		end)

		log = log .. string.format("  %s hits back for %d.", stage.enemyName, enemyHit)

		FightEvent:FireClient(player, {
			phase = "tick",
			enemyHealth = enemyHealth,
			squadHealth = squadHealth,
			log = log,
		})

		if squadHealth <= 0 then
			won = false
			break
		end

		task.wait(Stages.TICK)
	end

	task.wait(0.6)

	if won then
		if enemy then
			-- the creature sinks out of the arena
			local root = enemy.PrimaryPart
			if root then
				TweenService:Create(root, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {
					CFrame = enemyHome * CFrame.new(0, -8, 0),
				}):Play()
			end
		end
	else
		cooldownUntil[player] = os.clock() + Stages.LOSS_COOLDOWN
	end

	-- send the gnomes home to the plot
	for index, entry in ipairs(squad) do
		local slot = World.PLOT_SLOTS[index]
		if slot then
			moveTo(entry.model, CFrame.new(slot))
		end
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
