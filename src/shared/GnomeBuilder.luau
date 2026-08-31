--[[
	GnomeBuilder
	Builds the actual models out of primitives - a classic garden gnome
	(red pointed hat, white beard, tunic, boots) and the Stage 1 creature.

	Models are built at a local origin with the feet at y = 0 and the face
	pointing down -Z, then moved into place with model:PivotTo().
]]

local Parts = require(script.Parent.Parts)

local GnomeBuilder = {}

local BIOME_COLOR = {
	Forest = Color3.fromRGB(122, 232, 122),
	Desert = Color3.fromRGB(255, 216, 110),
	Mountain = Color3.fromRGB(132, 198, 255),
	Swamp = Color3.fromRGB(140, 232, 190),
}

GnomeBuilder.BiomeColor = BIOME_COLOR

function GnomeBuilder.Gnome(def)
	local c = def.colors

	local model = Instance.new("Model")
	model.Name = def.name

	local root = Parts.New({
		Name = "Root",
		Size = Vector3.new(0.4, 0.4, 0.4),
		Transparency = 1,
		CFrame = CFrame.new(0, 0, 0),
		Parent = model,
	})

	-- boots
	for _, side in ipairs({ -1, 1 }) do
		Parts.Block(model, {
			name = "Boot",
			size = Vector3.new(0.5, 0.3, 0.78),
			x = side * 0.31,
			y = 0.15,
			z = -0.06,
			color = c.boot,
			material = Enum.Material.SmoothPlastic,
		})
	end

	-- tunic: a frustum, wide at the hem and narrow at the shoulders
	Parts.Cone(model, {
		name = "Tunic",
		baseY = 0.3,
		radius = 0.74,
		tipRadius = 0.42,
		height = 1.2,
		slices = 12,
		color = c.tunic,
		material = Enum.Material.SmoothPlastic,
	})

	Parts.Disc(model, {
		name = "Belt",
		radius = 0.62,
		height = 0.17,
		y = 0.95,
		color = c.belt,
		material = Enum.Material.SmoothPlastic,
	})
	Parts.Block(model, {
		name = "Buckle",
		size = Vector3.new(0.26, 0.22, 0.12),
		y = 0.95,
		z = -0.58,
		color = Color3.fromRGB(214, 179, 92),
		material = Enum.Material.SmoothPlastic,
	})

	-- arms, splayed slightly out from the body
	for _, side in ipairs({ -1, 1 }) do
		Parts.New({
			Name = "Arm",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.85, 0.33, 0.33),
			Color = c.tunic,
			Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(side * 0.66, 1.0, 0)
				* CFrame.Angles(0, 0, math.pi / 2 + side * 0.22),
			Parent = model,
		})
		Parts.Ball(model, {
			name = "Hand",
			d = 0.31,
			x = side * 0.79,
			y = 0.58,
			color = c.skin,
		})
	end

	-- head
	Parts.Ball(model, { name = "Head", d = 0.92, y = 1.8, color = c.skin })
	Parts.Ball(model, { name = "Nose", d = 0.3, y = 1.78, z = -0.42, color = c.skin })
	for _, side in ipairs({ -1, 1 }) do
		Parts.Ball(model, {
			name = "Eye",
			d = 0.15,
			x = side * 0.17,
			y = 1.98,
			z = -0.40,
			color = Color3.fromRGB(30, 26, 24),
		})
	end

	-- beard, a cone hanging from under the nose
	Parts.Cone(model, {
		name = "Beard",
		baseY = 1.72,
		radius = 0.46,
		height = 0.95,
		dir = -1,
		slices = 14,
		z = -0.18,
		color = c.beard,
		material = Enum.Material.SmoothPlastic,
	})
	Parts.Disc(model, {
		name = "Moustache",
		radius = 0.22,
		height = 0.5,
		y = 1.66,
		z = -0.4,
		color = c.beard,
		material = Enum.Material.SmoothPlastic,
	})

	-- the hat: brim plus a tall pointed cone
	Parts.Disc(model, {
		name = "HatBrim",
		radius = 0.7,
		height = 0.14,
		y = 2.06,
		color = c.hat,
		material = Enum.Material.SmoothPlastic,
	})
	Parts.Cone(model, {
		name = "Hat",
		baseY = 2.04,
		radius = 0.63,
		height = 1.3,
		slices = 20,
		color = c.hat,
		material = Enum.Material.SmoothPlastic,
	})

	Parts.Rig(model, root)
	Parts.Nameplate(
		model,
		root,
		def.name,
		string.format("%s  -  %d PWR", def.biome, def.power),
		BIOME_COLOR[def.biome]
	)
	-- lift the nameplate above the hat rather than the root
	model.Nameplate.StudsOffsetWorldSpace = Vector3.new(0, 3.9, 0)

	model:SetAttribute("GnomeId", def.id)
	model:SetAttribute("Biome", def.biome)

	return model
end

function GnomeBuilder.Enemy(stage)
	local BODY = Color3.fromRGB(122, 214, 92)
	local THORN = Color3.fromRGB(196, 84, 220)

	local model = Instance.new("Model")
	model.Name = stage.enemyName

	local root = Parts.New({
		Name = "Root",
		Size = Vector3.new(0.6, 0.6, 0.6),
		Transparency = 1,
		CFrame = CFrame.new(0, 0, 0),
		Parent = model,
	})

	-- squat legs
	for _, side in ipairs({ -1, 1 }) do
		Parts.Disc(model, {
			name = "Leg",
			radius = 0.42,
			height = 1.1,
			x = side * 0.8,
			y = 0.55,
			color = THORN,
			material = Enum.Material.SmoothPlastic,
		})
		Parts.Block(model, {
			name = "Foot",
			size = Vector3.new(1.0, 0.35, 1.4),
			x = side * 0.8,
			y = 0.17,
			z = -0.2,
			color = THORN,
			material = Enum.Material.SmoothPlastic,
		})
	end

	local body = Parts.Ball(model, {
		name = "Body",
		d = 3.4,
		y = 2.5,
		color = BODY,
		material = Enum.Material.SmoothPlastic,
	})
	Parts.Ball(model, {
		name = "Brow",
		d = 2.4,
		y = 3.5,
		z = -0.4,
		color = BODY,
		material = Enum.Material.SmoothPlastic,
	})

	-- thorns across the back and crown
	local thorns = {
		{ x = 0, z = 0.9, h = 1.9, r = 0.4 },
		{ x = -1.0, z = 0.6, h = 1.5, r = 0.34 },
		{ x = 1.0, z = 0.6, h = 1.5, r = 0.34 },
		{ x = -0.6, z = 1.2, h = 1.1, r = 0.3 },
		{ x = 0.6, z = 1.2, h = 1.1, r = 0.3 },
	}
	for i, thorn in ipairs(thorns) do
		Parts.Cone(model, {
			name = "Thorn" .. i,
			baseY = 3.4,
			radius = thorn.r,
			height = thorn.h,
			slices = 9,
			x = thorn.x,
			z = thorn.z,
			color = THORN,
			material = Enum.Material.SmoothPlastic,
		})
	end

	-- face
	for _, side in ipairs({ -1, 1 }) do
		Parts.Ball(model, {
			name = "Eye",
			d = 0.55,
			x = side * 0.62,
			y = 3.35,
			z = -1.42,
			color = Color3.fromRGB(255, 214, 92),
			material = Enum.Material.Neon,
		})
	end
	Parts.Block(model, {
		name = "Mouth",
		size = Vector3.new(1.7, 0.42, 0.35),
		y = 2.4,
		z = -1.55,
		color = Color3.fromRGB(28, 22, 20),
	})
	-- teeth
	for i = -1, 1 do
		Parts.Cone(model, {
			name = "Tooth",
			baseY = 2.62,
			radius = 0.16,
			height = 0.42,
			slices = 5,
			dir = -1,
			x = i * 0.55,
			z = -1.6,
			color = Color3.fromRGB(240, 236, 214),
		})
	end

	-- arms
	for _, side in ipairs({ -1, 1 }) do
		Parts.New({
			Name = "Arm",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.2, 0.7, 0.7),
			Color = THORN,
			Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(side * 1.9, 2.4, 0) * CFrame.Angles(0, 0, math.pi / 2 + side * 0.5),
			Parent = model,
		})
	end

	Parts.Rig(model, root)
	Parts.Nameplate(
		model,
		body,
		stage.enemyName,
		string.format("%d HP  -  %d PWR", stage.enemyHealth, stage.enemyPower),
		Color3.fromRGB(255, 138, 120)
	)
	model.Nameplate.Size = UDim2.fromScale(10, 2.6)
	model.Nameplate.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)

	return model
end

return GnomeBuilder
