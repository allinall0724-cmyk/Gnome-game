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

--[[
	The gnome, built entirely from smooth ellipsoids.

	Every rounded form is one Parts.Blob rather than a stack of slices. That is
	both better looking - nothing reads as stairs any more - and cheaper, since
	the client rewrites every part's CFrame each frame and this build is about
	a third of the parts the sliced one needed.

	Proportions are deliberately caricatured: a big head, a round belly and
	oversized boots, because that reads as a character where realistic
	proportions just read as a small person.
]]
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

	-- big round boots, splayed outward
	for _, side in ipairs({ -1, 1 }) do
		Parts.Blob(model, {
			name = "Boot",
			sx = 0.62,
			sy = 0.44,
			sz = 0.86,
			x = side * 0.34,
			y = 0.22,
			z = -0.14,
			rot = CFrame.Angles(0, side * 0.18, 0),
			color = c.boot,
		})
	end

	-- one rounded belly instead of a stepped bell
	Parts.Blob(model, {
		name = "Tunic",
		sx = 1.72,
		sy = 1.42,
		sz = 1.6,
		y = 1.02,
		color = c.tunic,
	})
	-- a smaller blob at the hem widens the silhouette at the bottom
	Parts.Blob(model, {
		name = "Hem",
		sx = 1.86,
		sy = 0.78,
		sz = 1.72,
		y = 0.56,
		color = c.tunic,
	})

	Parts.Disc(model, {
		name = "Belt",
		radius = 0.86,
		height = 0.22,
		y = 0.92,
		color = c.belt,
	})
	Parts.Block(model, {
		name = "Buckle",
		size = Vector3.new(0.34, 0.28, 0.14),
		y = 0.92,
		z = -0.82,
		color = Color3.fromRGB(255, 208, 92),
	})

	-- arms as tapered capsules, hands as mittens
	for _, side in ipairs({ -1, 1 }) do
		Parts.Blob(model, {
			name = "Arm",
			sx = 0.86,
			sy = 0.4,
			sz = 0.4,
			x = side * 0.86,
			y = 1.16,
			z = -0.06,
			rot = CFrame.Angles(0, 0, side * -0.55),
			color = c.tunic,
		})
		Parts.Blob(model, {
			name = "Hand",
			sx = 0.44,
			sy = 0.4,
			sz = 0.44,
			x = side * 1.06,
			y = 0.78,
			color = c.skin,
		})
	end

	-- oversized head, very slightly egg shaped
	Parts.Blob(model, {
		name = "Head",
		sx = 1.36,
		sy = 1.3,
		sz = 1.3,
		y = 2.02,
		color = c.skin,
	})

	-- a big bulb of a nose
	Parts.Blob(model, {
		name = "Nose",
		sx = 0.44,
		sy = 0.42,
		sz = 0.52,
		y = 1.94,
		z = -0.66,
		color = Color3.fromRGB(255, 168, 152),
	})

	for _, side in ipairs({ -1, 1 }) do
		-- eye white, pupil, and a small highlight that makes them read as alive
		Parts.Blob(model, {
			name = "Eye",
			sx = 0.42,
			sy = 0.48,
			sz = 0.42,
			x = side * 0.3,
			y = 2.26,
			z = -0.48,
			color = Color3.fromRGB(255, 255, 255),
		})
		Parts.Blob(model, {
			name = "Pupil",
			sx = 0.22,
			sy = 0.24,
			sz = 0.22,
			x = side * 0.32,
			y = 2.24,
			z = -0.62,
			color = Color3.fromRGB(32, 26, 26),
		})
		Parts.Blob(model, {
			name = "Glint",
			sx = 0.09,
			sy = 0.09,
			sz = 0.09,
			x = side * 0.37,
			y = 2.32,
			z = -0.68,
			color = Color3.fromRGB(255, 255, 255),
		})
		-- bushy brow, tilted outward for a permanently startled look
		Parts.Blob(model, {
			name = "Brow",
			sx = 0.46,
			sy = 0.16,
			sz = 0.2,
			x = side * 0.31,
			y = 2.54,
			z = -0.5,
			rot = CFrame.Angles(0, 0, side * 0.3),
			color = c.beard,
		})
		Parts.Blob(model, {
			name = "Cheek",
			sx = 0.34,
			sy = 0.26,
			sz = 0.24,
			x = side * 0.52,
			y = 1.88,
			z = -0.42,
			color = Color3.fromRGB(255, 150, 150),
		})
	end

	-- The beard is a cluster of overlapping blobs rather than a cone, so it
	-- reads as soft and bushy and keeps a rounded silhouette from every angle.
	local beard = {
		{ sx = 1.0, sy = 0.72, sz = 0.62, y = 1.66, z = -0.42 },
		{ sx = 0.86, sy = 0.72, sz = 0.56, y = 1.3, z = -0.36 },
		{ sx = 0.62, sy = 0.6, sz = 0.46, y = 1.0, z = -0.3 },
		{ sx = 0.34, sy = 0.42, sz = 0.3, y = 0.76, z = -0.26 },
	}
	for _, blob in ipairs(beard) do
		Parts.Blob(model, {
			name = "Beard",
			sx = blob.sx,
			sy = blob.sy,
			sz = blob.sz,
			y = blob.y,
			z = blob.z,
			color = c.beard,
		})
	end
	-- moustache tufts either side of the nose
	for _, side in ipairs({ -1, 1 }) do
		Parts.Blob(model, {
			name = "Moustache",
			sx = 0.34,
			sy = 0.2,
			sz = 0.26,
			x = side * 0.22,
			y = 1.78,
			z = -0.62,
			rot = CFrame.Angles(0, 0, side * 0.4),
			color = c.beard,
		})
	end

	-- The hat is a chain of shrinking blobs following a curve, which gives a
	-- soft slouched cap. A straight stack of slices was the single worst
	-- looking thing in the old build.
	local HAT_SEGMENTS = 8
	for i = 0, HAT_SEGMENTS - 1 do
		local t = i / (HAT_SEGMENTS - 1)
		local width = 1.62 * (1 - t) ^ 0.7 + 0.1
		Parts.Blob(model, {
			name = "Hat",
			sx = width,
			sy = 0.52 + 0.2 * (1 - t),
			sz = width,
			-- leans back as it rises, so the tip flops behind the gnome
			y = 2.62 + t * 1.42,
			z = 0.34 * t * t,
			color = c.hat,
		})
	end
	Parts.Blob(model, {
		name = "HatBrim",
		sx = 1.92,
		sy = 0.3,
		sz = 1.92,
		y = 2.56,
		color = c.hat,
	})
	Parts.Blob(model, {
		name = "Pom",
		sx = 0.4,
		sy = 0.4,
		sz = 0.4,
		y = 4.06,
		z = 0.36,
		color = c.beard,
	})

	Parts.Rig(model, root)
	Parts.Nameplate(
		model,
		root,
		def.name,
		string.format("%s  -  %d PWR", def.biome, def.power),
		BIOME_COLOR[def.biome]
	)
	model.Nameplate.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)

	model:SetAttribute("GnomeId", def.id)
	model:SetAttribute("Biome", def.biome)

	return model
end

--[[
	The gate creature, same approach: rounded masses rather than slices, with
	the thorns as the only hard edges so they read as dangerous against all
	the soft shapes.
]]
function GnomeBuilder.Enemy(stage)
	local BODY = Color3.fromRGB(122, 214, 92)
	local DARK = Color3.fromRGB(72, 156, 62)
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

	for _, side in ipairs({ -1, 1 }) do
		Parts.Blob(model, {
			name = "Foot",
			sx = 1.2,
			sy = 0.7,
			sz = 1.7,
			x = side * 0.95,
			y = 0.35,
			z = -0.3,
			color = DARK,
		})
		Parts.Blob(model, {
			name = "Leg",
			sx = 0.8,
			sy = 1.2,
			sz = 0.8,
			x = side * 0.9,
			y = 1.0,
			color = DARK,
		})
		Parts.Blob(model, {
			name = "Arm",
			sx = 2.3,
			sy = 0.8,
			sz = 0.8,
			x = side * 2.0,
			y = 2.5,
			rot = CFrame.Angles(0, 0, side * -0.45),
			color = DARK,
		})
	end

	local body = Parts.Blob(model, {
		name = "Body",
		sx = 3.6,
		sy = 3.2,
		sz = 3.2,
		y = 2.7,
		color = BODY,
	})
	Parts.Blob(model, {
		name = "Brow",
		sx = 2.9,
		sy = 1.5,
		sz = 2.2,
		y = 3.85,
		z = -0.35,
		color = BODY,
	})

	-- thorns: the one angular shape on an otherwise round creature
	local thorns = {
		{ x = 0, z = 1.0, h = 2.0, r = 0.42 },
		{ x = -1.05, z = 0.65, h = 1.6, r = 0.36 },
		{ x = 1.05, z = 0.65, h = 1.6, r = 0.36 },
		{ x = -0.6, z = 1.3, h = 1.2, r = 0.3 },
		{ x = 0.6, z = 1.3, h = 1.2, r = 0.3 },
	}
	for i, thorn in ipairs(thorns) do
		Parts.Cone(model, {
			name = "Thorn" .. i,
			baseY = 3.6,
			radius = thorn.r,
			height = thorn.h,
			slices = 5,
			x = thorn.x,
			z = thorn.z,
			color = THORN,
		})
	end

	for _, side in ipairs({ -1, 1 }) do
		Parts.Blob(model, {
			name = "Eye",
			sx = 0.78,
			sy = 0.86,
			sz = 0.6,
			x = side * 0.68,
			y = 3.5,
			z = -1.5,
			color = Color3.fromRGB(255, 226, 120),
			material = Enum.Material.Neon,
		})
		Parts.Blob(model, {
			name = "Pupil",
			sx = 0.24,
			sy = 0.62,
			sz = 0.2,
			x = side * 0.7,
			y = 3.48,
			z = -1.72,
			color = Color3.fromRGB(30, 22, 30),
		})
	end

	Parts.Blob(model, {
		name = "Mouth",
		sx = 1.9,
		sy = 0.5,
		sz = 0.5,
		y = 2.5,
		z = -1.7,
		color = Color3.fromRGB(48, 26, 40),
	})
	for i = -1, 1 do
		Parts.Cone(model, {
			name = "Tooth",
			baseY = 2.72,
			radius = 0.17,
			height = 0.44,
			slices = 4,
			dir = -1,
			x = i * 0.58,
			z = -1.76,
			color = Color3.fromRGB(245, 242, 226),
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
