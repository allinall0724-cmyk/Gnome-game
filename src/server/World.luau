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
local Layout = require(Shared:WaitForChild("Layout"))

local World = {}

-- Poses live in the shared Layout module so the client animates between the
-- same points the server places things at.
World.PLOT_SLOTS = Layout.PLOT_SLOTS
World.ARENA_SLOTS = Layout.ARENA_SLOTS
World.ENEMY_POSITION = Layout.ENEMY_POSITION

-- Filled in at runtime by Build, PlaceGnomes and SpawnEnemy.
World.Map = nil :: Folder?
World.Enemy = nil :: Model?
World.GnomeFolder = nil :: Folder?
World.ChallengeStone = nil :: BasePart?
World.Prompt = nil :: ProximityPrompt?

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

-- Scatter props so the plot reads as a storybook garden rather than a flat
-- field. Positions are hand-placed to stay clear of the plot and the road.
local function decorate(map)
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = map

	local function mushroom(x, z, scale)
		Parts.Disc(props, {
			name = "MushroomStem",
			radius = 0.32 * scale,
			height = 1.5 * scale,
			x = x,
			y = 0.75 * scale,
			z = z,
			color = Color3.fromRGB(252, 246, 228),
		})
		Parts.Cone(props, {
			name = "MushroomCap",
			baseY = 1.3 * scale,
			radius = 1.15 * scale,
			tipRadius = 0.35 * scale,
			height = 0.95 * scale,
			slices = 9,
			x = x,
			z = z,
			color = Color3.fromRGB(240, 78, 88),
		})
	end

	local function bush(x, z, scale)
		for _, blob in ipairs({ { 0, 0, 1 }, { 0.75, 0.3, 0.72 }, { -0.7, -0.25, 0.66 } }) do
			Parts.Ball(props, {
				name = "Bush",
				d = 2.5 * scale * blob[3],
				x = x + blob[1] * scale,
				y = 0.95 * scale * blob[3],
				z = z + blob[2] * scale,
				color = Color3.fromRGB(86, 190, 92),
			})
		end
	end

	local function cloud(x, y, z, scale)
		for _, blob in ipairs({
			{ 0, 0, 1 },
			{ 3.2, -0.4, 0.78 },
			{ -3.0, -0.5, 0.72 },
			{ 1.4, 0.9, 0.66 },
		}) do
			local part = Parts.Ball(props, {
				name = "Cloud",
				d = 6 * scale * blob[3],
				x = x + blob[1] * scale,
				y = y + blob[2] * scale,
				z = z,
				color = Color3.fromRGB(255, 255, 255),
			})
			part.Anchored = true
			part.CastShadow = false
		end
	end

	for _, m in ipairs({
		{ -24, -6, 1.1 },
		{ 25, 4, 0.9 },
		{ -21, 22, 1.0 },
		{ 23, 26, 1.2 },
		{ -27, 40, 0.95 },
		{ 26, 46, 1.05 },
	}) do
		mushroom(m[1], m[2], m[3])
	end
	for _, b in ipairs({
		{ -28, 10, 1.2 },
		{ 29, 16, 1.0 },
		{ -25, 32, 1.1 },
		{ 27, 36, 0.9 },
		{ -30, -14, 1.0 },
		{ 30, -8, 1.15 },
	}) do
		bush(b[1], b[2], b[3])
	end
	for _, c in ipairs({
		{ -30, 44, 10, 1.0 },
		{ 34, 52, 30, 1.2 },
		{ -18, 48, 60, 0.9 },
		{ 22, 46, -20, 1.1 },
	}) do
		cloud(c[1], c[2], c[3], c[4])
	end
end

-- Bright, flat, saturated: high ambient so shadows stay soft, bloom for the
-- glow on neon parts, and a saturation lift so the flat colours pop.
function World.ApplyStyle()
	local Lighting = game:GetService("Lighting")

	Lighting.Brightness = 3
	Lighting.ExposureCompensation = 0.25
	Lighting.Ambient = Color3.fromRGB(120, 118, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(158, 156, 168)
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 12
	Lighting.EnvironmentDiffuseScale = 0.75
	Lighting.EnvironmentSpecularScale = 0.35
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 100000

	for _, name in ipairs({ "CartoonAtmosphere", "CartoonBloom", "CartoonColor", "CartoonSun" }) do
		local existing = Lighting:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "CartoonAtmosphere"
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Haze = 0.6
	atmosphere.Glare = 0.15
	atmosphere.Color = Color3.fromRGB(214, 236, 255)
	atmosphere.Decay = Color3.fromRGB(150, 190, 235)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "CartoonBloom"
	bloom.Intensity = 0.7
	bloom.Size = 26
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "CartoonColor"
	color.Saturation = 0.35
	color.Contrast = 0.1
	color.Brightness = 0.03
	color.Parent = Lighting

	local sun = Instance.new("SunRaysEffect")
	sun.Name = "CartoonSun"
	sun.Intensity = 0.06
	sun.Spread = 0.9
	sun.Parent = Lighting
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

	solid(
		map,
		"Ground",
		Vector3.new(220, 2, 220),
		Vector3.new(0, -1, 20),
		Color3.fromRGB(124, 214, 104),
		Enum.Material.SmoothPlastic
	)

	-- the player's plot
	solid(
		map,
		"PlotBorder",
		Vector3.new(38, 0.5, 38),
		Vector3.new(0, 0.05, 0),
		Color3.fromRGB(226, 170, 100),
		Enum.Material.SmoothPlastic
	)
	solid(
		map,
		"Plot",
		Vector3.new(36, 0.5, 36),
		Vector3.new(0, 0.15, 0),
		Color3.fromRGB(184, 130, 84),
		Enum.Material.SmoothPlastic
	)

	-- pedestal under each gnome slot
	for index, slot in ipairs(World.PLOT_SLOTS) do
		local pad = solid(
			map,
			"Slot" .. index,
			Vector3.new(3, 0.4, 3),
			Vector3.new(slot.X, 0.3, slot.Z),
			Color3.fromRGB(244, 206, 138),
			Enum.Material.SmoothPlastic
		)
		pad.CanCollide = false
	end

	-- road from the plot up to the gate
	solid(
		map,
		"Road",
		Vector3.new(8, 0.3, 34),
		Vector3.new(0, 0.15, 20),
		Color3.fromRGB(248, 228, 178),
		Enum.Material.SmoothPlastic
	)

	-- arena floor past the gate
	solid(
		map,
		"Arena",
		Vector3.new(34, 0.3, 34),
		Vector3.new(0, 0.15, 44),
		Color3.fromRGB(236, 198, 146),
		Enum.Material.SmoothPlastic
	)

	-- the gate itself
	for _, side in ipairs({ -1, 1 }) do
		solid(
			map,
			"GatePillar",
			Vector3.new(2.4, 13, 2.4),
			Vector3.new(side * 6, 6.5, 34),
			Color3.fromRGB(178, 148, 236),
			Enum.Material.SmoothPlastic
		)
	end
	solid(
		map,
		"GateLintel",
		Vector3.new(16, 2.4, 2.4),
		Vector3.new(0, 14.2, 34),
		Color3.fromRGB(156, 124, 224),
		Enum.Material.SmoothPlastic
	)

	local veil = Parts.New({
		Name = "GateVeil",
		Size = Vector3.new(9.6, 12.6, 0.4),
		Color = Color3.fromRGB(120, 240, 224),
		Material = Enum.Material.Neon,
		Transparency = 0.62,
		CFrame = CFrame.new(0, 6.5, 34),
		Parent = map,
	})
	veil.Anchored = true

	local spawnPoint = Instance.new("SpawnLocation")
	spawnPoint.Name = "PlotSpawn"
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.CFrame = CFrame.new(0, 0.7, -12)
	spawnPoint.Anchored = true
	spawnPoint.Color = Color3.fromRGB(255, 226, 130)
	spawnPoint.Material = Enum.Material.SmoothPlastic
	spawnPoint.TopSurface = Enum.SurfaceType.Smooth
	spawnPoint.Duration = 0
	spawnPoint.Parent = map

	-- the stone you interact with to start the fight
	local stone = solid(
		map,
		"ChallengeStone",
		Vector3.new(3, 3.4, 1.6),
		Vector3.new(0, 1.7, 29),
		Color3.fromRGB(255, 176, 92),
		Enum.Material.SmoothPlastic
	)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChallengePrompt"
	prompt.ActionText = "Challenge the Gate"
	prompt.ObjectText = "Stage 1"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = stone

	decorate(map)

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
