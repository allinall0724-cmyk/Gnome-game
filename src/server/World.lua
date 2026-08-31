--[[
	World
	Builds the whole map in code so the .rbxl place file can stay empty and
	everything lives in source control.

	Layout runs along the Z axis: the player's plot sits at z = 0, the road
	leads north to the Stage 1 gate at z = 34, and the creature waits in the
	arena beyond it.
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GnomeBuilder = require(Shared:WaitForChild("GnomeBuilder"))
local Parts = require(Shared:WaitForChild("Parts"))

local World = {}

World.PLOT_SLOTS = {
	Vector3.new(-5, 0.5, 2),
	Vector3.new(0, 0.5, 2),
	Vector3.new(5, 0.5, 2),
}

-- Where the gnomes line up when a gate fight starts.
World.ARENA_SLOTS = {
	Vector3.new(-4.5, 0.3, 38),
	Vector3.new(0, 0.3, 38),
	Vector3.new(4.5, 0.3, 38),
}

World.ENEMY_POSITION = Vector3.new(0, 0.3, 46)

local function solid(parent, name, size, position, color, material)
	local part = Parts.New({
		Name = name,
		Size = size,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		CFrame = CFrame.new(position),
		Parent = parent,
	})
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	return part
end

function World.Build()
	-- the default Baseplate template part would z-fight with our ground
	local existing = Workspace:FindFirstChild("Baseplate")
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = Workspace

	solid(map, "Ground", Vector3.new(220, 2, 220), Vector3.new(0, -1, 20),
		Color3.fromRGB(94, 132, 74), Enum.Material.Grass)

	-- the player's plot
	solid(map, "PlotBorder", Vector3.new(38, 0.5, 38), Vector3.new(0, 0.05, 0),
		Color3.fromRGB(108, 78, 52), Enum.Material.WoodPlanks)
	solid(map, "Plot", Vector3.new(36, 0.5, 36), Vector3.new(0, 0.15, 0),
		Color3.fromRGB(122, 92, 60), Enum.Material.Ground)

	-- pedestal under each gnome slot
	for index, slot in ipairs(World.PLOT_SLOTS) do
		local pad = solid(map, "Slot" .. index, Vector3.new(3, 0.4, 3),
			Vector3.new(slot.X, 0.3, slot.Z), Color3.fromRGB(146, 118, 82), Enum.Material.Slate)
		pad.CanCollide = false
	end

	-- road from the plot up to the gate
	solid(map, "Road", Vector3.new(8, 0.3, 34), Vector3.new(0, 0.15, 20),
		Color3.fromRGB(150, 138, 118), Enum.Material.Pebble)

	-- arena floor past the gate
	solid(map, "Arena", Vector3.new(34, 0.3, 34), Vector3.new(0, 0.15, 44),
		Color3.fromRGB(120, 116, 96), Enum.Material.Ground)

	-- the gate itself
	for _, side in ipairs({ -1, 1 }) do
		solid(map, "GatePillar", Vector3.new(2.4, 13, 2.4), Vector3.new(side * 6, 6.5, 34),
			Color3.fromRGB(126, 124, 118), Enum.Material.Rock)
	end
	solid(map, "GateLintel", Vector3.new(16, 2.4, 2.4), Vector3.new(0, 14.2, 34),
		Color3.fromRGB(126, 124, 118), Enum.Material.Rock)

	local veil = Parts.New({
		Name = "GateVeil",
		Size = Vector3.new(9.6, 12.6, 0.4),
		Color = Color3.fromRGB(126, 214, 176),
		Material = Enum.Material.Neon,
		Transparency = 0.72,
		CFrame = CFrame.new(0, 6.5, 34),
		Parent = map,
	})
	veil.Anchored = true

	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "PlotSpawn"
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.CFrame = CFrame.new(0, 0.7, -12)
	spawnPoint.Anchored = true
	spawnPoint.Color = Color3.fromRGB(196, 176, 140)
	spawnPoint.Material = Enum.Material.Slate
	spawnPoint.TopSurface = Enum.SurfaceType.Smooth
	spawnPoint.Duration = 0
	spawnPoint.Parent = map

	-- the stone you interact with to start the fight
	local stone = solid(map, "ChallengeStone", Vector3.new(3, 3.4, 1.6), Vector3.new(0, 1.7, 29),
		Color3.fromRGB(96, 94, 90), Enum.Material.Rock)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChallengePrompt"
	prompt.ActionText = "Challenge the Gate"
	prompt.ObjectText = "Stage 1"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = stone

	World.Map = map
	World.ChallengeStone = stone
	World.Prompt = prompt

	return map
end

-- Places one gnome model per plot slot and returns them in slot order.
function World.PlaceGnomes(defs)
	local folder = Instance.new("Folder")
	folder.Name = "Gnomes"
	folder.Parent = World.Map

	local models = {}
	for index, def in ipairs(defs) do
		local slot = World.PLOT_SLOTS[index]
		if not slot then
			break
		end
		local model = GnomeBuilder.Gnome(def)
		model.Parent = folder
		-- models are built facing -Z, which is back toward the spawn point
		model:PivotTo(CFrame.new(slot))
		models[index] = model
	end

	World.GnomeFolder = folder
	return models
end

function World.SpawnEnemy(stage)
	if World.Enemy then
		World.Enemy:Destroy()
	end
	local model = GnomeBuilder.Enemy(stage)
	model.Parent = World.Map
	model:PivotTo(CFrame.new(World.ENEMY_POSITION))
	World.Enemy = model
	return model
end

return World
