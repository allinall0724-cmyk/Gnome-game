--[[
	GnomeBuilder
	Builds the actual models out of primitives - a classic garden gnome
	(red pointed hat, white beard, tunic, boots) and the Stage 1 creature.

	Models are built at a local origin with the feet at y = 0 and the face
	pointing down -Z, then moved into place with model:PivotTo().
]]

local Parts = require(script.Parent.Parts)
local AssetIds = require(script.Parent.AssetIds)

local GnomeBuilder = {}

local BIOME_COLOR = {
	Forest = Color3.fromRGB(122, 232, 122),
	Desert = Color3.fromRGB(255, 216, 110),
	Mountain = Color3.fromRGB(132, 198, 255),
	Swamp = Color3.fromRGB(140, 232, 190),
}

GnomeBuilder.BiomeColor = BIOME_COLOR

local GNOME_MESHES = { "gnome_boots", "gnome_body", "gnome_skin", "gnome_beard", "gnome_hat" }

--[[
	One MeshPart per colour region, tinted per gnome.

	This is the cheap path: five parts instead of the ~48 the primitive build
	needs, which matters because the client rewrites every part's CFrame each
	frame. It is only taken once the meshes have actually been uploaded;
	AssetIds.Ready is false until then and the primitive build runs instead.
]]
local function meshGnome(def)
	local c = def.colors
	local tint = {
		gnome_hat = c.hat,
		gnome_body = c.tunic,
		gnome_skin = c.skin,
		gnome_beard = c.beard,
		gnome_boots = c.boot,
	}

	local model = Instance.new("Model")
	model.Name = def.name

	local root = Parts.New({
		Name = "Root",
		Size = Vector3.new(0.4, 0.4, 0.4),
		Transparency = 1,
		CFrame = CFrame.new(0, 0, 0),
		Parent = model,
	})

	for _, key in ipairs(GNOME_MESHES) do
		local entry = AssetIds.Meshes[key]
		local mesh = Instance.new("MeshPart")
		mesh.Name = key
		mesh.MeshId = AssetIds.MeshId(key) or ""
		-- the modelled size, not whatever the importer decided
		mesh.Size = entry.size
		mesh.Color = tint[key]
		mesh.Material = Enum.Material.SmoothPlastic
		mesh.Anchored = true
		mesh.CanCollide = false
		mesh.CanQuery = false
		mesh.CanTouch = false
		mesh.CastShadow = false
		-- every mesh was modelled at final coordinates with its base at 0,
		-- so they all sit at the model origin and line up on their own
		mesh.CFrame = CFrame.new(0, entry.size.Y / 2, 0)
		mesh.Parent = model
	end

	-- eyes stay as primitives: they are tiny, and keeping them separate means
	-- the pupils can be tinted and moved without a re-upload
	for _, side in ipairs({ -1, 1 }) do
		Parts.Ball(model, {
			name = "Eye",
			d = 0.44,
			x = side * 0.29,
			y = 2.16,
			z = -0.5,
			color = Color3.fromRGB(255, 255, 255),
		})
		Parts.Ball(model, {
			name = "Pupil",
			d = 0.22,
			x = side * 0.31,
			y = 2.14,
			z = -0.66,
			color = Color3.fromRGB(26, 22, 22),
		})
	end

	Parts.Rig(model, root)
	Parts.Nameplate(
		model,
		root,
		def.name,
		string.format("%s  -  %d PWR", def.biome, def.power),
		BIOME_COLOR[def.biome]
	)
	model.Nameplate.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	model:SetAttribute("GnomeId", def.id)
	model:SetAttribute("Biome", def.biome)
	return model
end

function GnomeBuilder.Gnome(def)
	if AssetIds.Ready(GNOME_MESHES) then
		return meshGnome(def)
	end

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

	-- Cartoon proportions: a big head on a stubby body reads as friendly,
	-- where realistic proportions just read as small.

	-- boots, splayed outward like a clown's
	for _, side in ipairs({ -1, 1 }) do
		Parts.Ball(model, {
			name = "Boot",
			d = 0.72,
			x = side * 0.38,
			y = 0.3,
			z = -0.12,
			color = c.boot,
		})
	end

	-- tunic: a wide bell so the gnome looks bottom-heavy and stable
	Parts.Cone(model, {
		name = "Tunic",
		baseY = 0.36,
		radius = 0.92,
		tipRadius = 0.46,
		height = 1.0,
		slices = 8,
		color = c.tunic,
	})

	Parts.Disc(model, {
		name = "Belt",
		radius = 0.7,
		height = 0.2,
		y = 0.86,
		color = c.belt,
	})
	Parts.Block(model, {
		name = "Buckle",
		size = Vector3.new(0.3, 0.26, 0.14),
		y = 0.86,
		z = -0.66,
		color = Color3.fromRGB(255, 208, 92),
	})

	-- stubby arms with big mitten hands
	for _, side in ipairs({ -1, 1 }) do
		Parts.New({
			Name = "Arm",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.7, 0.36, 0.36),
			Color = c.tunic,
			CFrame = CFrame.new(side * 0.76, 1.0, 0)
				* CFrame.Angles(0, 0, math.pi / 2 + side * 0.3),
			Parent = model,
		})
		Parts.Ball(model, { name = "Hand", d = 0.42, x = side * 0.92, y = 0.66, color = c.skin })
	end

	-- oversized head
	Parts.Ball(model, { name = "Head", d = 1.34, y = 1.92, color = c.skin })

	-- big round nose, right in the middle of the face
	Parts.Ball(
		model,
		{ name = "Nose", d = 0.46, y = 1.84, z = -0.62, color = Color3.fromRGB(255, 166, 150) }
	)

	-- googly eyes: a white ball with a pupil sitting proud of it
	for _, side in ipairs({ -1, 1 }) do
		Parts.Ball(model, {
			name = "Eye",
			d = 0.44,
			x = side * 0.29,
			y = 2.16,
			z = -0.5,
			color = Color3.fromRGB(255, 255, 255),
		})
		Parts.Ball(model, {
			name = "Pupil",
			d = 0.22,
			x = side * 0.31,
			y = 2.14,
			z = -0.66,
			color = Color3.fromRGB(26, 22, 22),
		})
		-- a bushy eyebrow, tilted for a permanently surprised look
		Parts.Block(model, {
			name = "Brow",
			size = Vector3.new(0.42, 0.12, 0.16),
			x = side * 0.3,
			y = 2.44,
			z = -0.54,
			rot = CFrame.Angles(0, 0, side * 0.28),
			color = c.beard,
		})
		-- rosy cheek
		Parts.Ball(model, {
			name = "Cheek",
			d = 0.3,
			x = side * 0.5,
			y = 1.78,
			z = -0.44,
			color = Color3.fromRGB(255, 148, 148),
		})
	end

	-- a wide grin, drawn as an arc of little blocks
	for i = -2, 2 do
		local t = i / 2
		Parts.Block(model, {
			name = "Smile",
			size = Vector3.new(0.17, 0.12, 0.12),
			x = t * 0.34,
			y = 1.56 + t * t * 0.12,
			z = -0.58 + t * t * 0.07,
			rot = CFrame.Angles(0, 0, -t * 0.5),
			color = Color3.fromRGB(120, 52, 44),
		})
	end

	-- beard, hanging under the grin
	Parts.Cone(model, {
		name = "Beard",
		baseY = 1.6,
		radius = 0.56,
		height = 0.85,
		dir = -1,
		slices = 8,
		z = -0.22,
		color = c.beard,
	})

	-- a big floppy hat, taller than the gnome's head
	Parts.Disc(model, {
		name = "HatBrim",
		radius = 0.92,
		height = 0.16,
		y = 2.46,
		color = c.hat,
	})
	Parts.Cone(model, {
		name = "Hat",
		baseY = 2.44,
		radius = 0.84,
		height = 1.5,
		slices = 12,
		color = c.hat,
	})
	-- a pom-pom on the tip
	Parts.Ball(model, { name = "Pom", d = 0.34, y = 3.98, color = c.beard })

	Parts.Rig(model, root)
	Parts.Nameplate(
		model,
		root,
		def.name,
		string.format("%s  -  %d PWR", def.biome, def.power),
		BIOME_COLOR[def.biome]
	)
	-- lift the nameplate above the hat rather than the root
	model.Nameplate.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)

	model:SetAttribute("GnomeId", def.id)
	model:SetAttribute("Biome", def.biome)

	return model
end

function GnomeBuilder.Enemy(stage)
	if AssetIds.Ready({ "creature" }) then
		local entry = AssetIds.Meshes.creature
		local model = Instance.new("Model")
		model.Name = stage.enemyName

		local root = Parts.New({
			Name = "Root",
			Size = Vector3.new(0.6, 0.6, 0.6),
			Transparency = 1,
			CFrame = CFrame.new(0, 0, 0),
			Parent = model,
		})

		local mesh = Instance.new("MeshPart")
		mesh.Name = "Body"
		mesh.MeshId = AssetIds.MeshId("creature") or ""
		mesh.Size = entry.size
		mesh.Color = Color3.fromRGB(122, 214, 92)
		mesh.Material = Enum.Material.SmoothPlastic
		mesh.Anchored = true
		mesh.CanCollide = false
		mesh.CanQuery = false
		mesh.CanTouch = false
		mesh.CastShadow = false
		mesh.CFrame = CFrame.new(0, entry.size.Y / 2, 0)
		mesh.Parent = model

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

		Parts.Rig(model, root)
		Parts.Nameplate(
			model,
			mesh,
			stage.enemyName,
			string.format("%d HP  -  %d PWR", stage.enemyHealth, stage.enemyPower),
			Color3.fromRGB(255, 138, 120)
		)
		model.Nameplate.Size = UDim2.fromScale(10, 2.6)
		model.Nameplate.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
		return model
	end

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
