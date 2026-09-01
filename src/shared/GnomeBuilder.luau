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
	Builds one gnome's face from its `face` table in GnomeData.

	Each gnome gets a different expression, and every one of them is uneven on
	purpose: `eyeBias` makes one eye larger than the other, and the mouths all
	sit slightly off centre. Matched, centred features read as neutral; the
	mismatch is what makes a face read as goofy rather than blank.
]]
local function buildFace(model, def)
	local c = def.colors
	local f = def.face

	-- nose first, since the mouth and moustache hang off its position
	Parts.Blob(model, {
		name = "Nose",
		sx = f.nose[1],
		sy = f.nose[2],
		sz = f.nose[3],
		y = 1.94,
		z = -0.66,
		color = Color3.fromRGB(255, 168, 152),
	})

	for index, side in ipairs({ -1, 1 }) do
		-- one eye bigger than the other; index 2 is the gnome's left
		local bias = index == 2 and (1 + f.eyeBias) or 1
		local eyeW = f.eyeW * bias
		local eyeH = f.eyeH * bias

		Parts.Blob(model, {
			name = "Eye",
			sx = eyeW,
			sy = eyeH,
			sz = 0.42,
			x = side * f.spread,
			y = f.eyeY,
			z = -0.48,
			color = Color3.fromRGB(255, 255, 255),
		})

		-- pupils pull toward the nose by pupilConverge, which is what reads
		-- as cross-eyed when positive and wall-eyed when negative
		Parts.Blob(model, {
			name = "Pupil",
			sx = eyeW * 0.46,
			sy = math.min(eyeH * 0.5, 0.26),
			sz = 0.2,
			x = side * (f.spread - f.pupilConverge),
			y = f.eyeY + f.pupilDrop,
			z = -0.62,
			color = Color3.fromRGB(32, 26, 26),
		})
		Parts.Blob(model, {
			name = "Glint",
			sx = 0.09,
			sy = 0.09,
			sz = 0.09,
			x = side * (f.spread + 0.07),
			y = f.eyeY + 0.07,
			z = -0.66,
			color = Color3.fromRGB(255, 255, 255),
		})

		-- a heavy lid drooping over the top half of the eye
		if f.lids then
			Parts.Blob(model, {
				name = "Lid",
				sx = eyeW * 1.05,
				sy = eyeH * 0.62,
				sz = 0.44,
				x = side * f.spread,
				y = f.eyeY + eyeH * 0.28,
				z = -0.46,
				rot = CFrame.Angles(0, 0, side * 0.18),
				color = c.skin,
			})
		end

		if not f.unibrow then
			Parts.Blob(model, {
				name = "Brow",
				sx = f.browLen,
				sy = 0.17,
				sz = 0.2,
				x = side * (f.spread + 0.02),
				y = f.browY,
				z = -0.5,
				rot = CFrame.Angles(0, 0, side * f.browTilt),
				color = c.beard,
			})
		end

		if f.freckles then
			for i = 1, 3 do
				Parts.Blob(model, {
					name = "Freckle",
					sx = 0.08,
					sy = 0.07,
					sz = 0.07,
					x = side * (0.44 + i * 0.09),
					y = 1.92 + (i % 2) * 0.09,
					z = -0.5,
					color = Color3.fromRGB(214, 132, 108),
				})
			end
		end

		Parts.Blob(model, {
			name = "Cheek",
			sx = 0.34,
			sy = 0.26,
			sz = 0.24,
			x = side * 0.54,
			y = 1.86,
			z = -0.42,
			color = Color3.fromRGB(255, 150, 150),
		})
	end

	-- one continuous brow across both eyes
	if f.unibrow then
		Parts.Blob(model, {
			name = "Unibrow",
			sx = f.spread * 2 + f.browLen,
			sy = 0.2,
			sz = 0.22,
			y = f.browY,
			z = -0.5,
			rot = CFrame.Angles(0, 0, 0.06),
			color = c.beard,
		})
	end

	-- mouths, each sitting a little off centre
	if f.mouth == "openSmile" then
		Parts.Blob(model, {
			name = "Mouth",
			sx = 0.72,
			sy = 0.44,
			sz = 0.3,
			x = 0.04,
			y = 1.62,
			z = -0.58,
			color = Color3.fromRGB(112, 46, 44),
		})
		Parts.Blob(model, {
			name = "Tongue",
			sx = 0.42,
			sy = 0.2,
			sz = 0.24,
			x = 0.04,
			y = 1.53,
			z = -0.64,
			color = Color3.fromRGB(238, 116, 132),
		})
	elseif f.mouth == "buckTeeth" then
		Parts.Blob(model, {
			name = "Mouth",
			sx = 0.5,
			sy = 0.2,
			sz = 0.24,
			x = -0.05,
			y = 1.66,
			z = -0.58,
			color = Color3.fromRGB(112, 46, 44),
		})
		for _, side in ipairs({ -1, 1 }) do
			Parts.Block(model, {
				name = "Tooth",
				size = Vector3.new(0.19, 0.26, 0.1),
				x = -0.05 + side * 0.1,
				y = 1.52,
				z = -0.63,
				color = Color3.fromRGB(250, 248, 236),
			})
		end
	else -- underbite
		Parts.Blob(model, {
			name = "Mouth",
			sx = 0.92,
			sy = 0.26,
			sz = 0.26,
			x = -0.03,
			y = 1.6,
			z = -0.56,
			rot = CFrame.Angles(0, 0, -0.1),
			color = Color3.fromRGB(96, 40, 40),
		})
		Parts.Block(model, {
			name = "Tooth",
			size = Vector3.new(0.17, 0.24, 0.1),
			x = 0.2,
			y = 1.68,
			z = -0.6,
			color = Color3.fromRGB(250, 248, 236),
		})
	end

	-- moustache tufts, tucked under the nose
	for _, side in ipairs({ -1, 1 }) do
		Parts.Blob(model, {
			name = "Moustache",
			sx = 0.36,
			sy = 0.2,
			sz = 0.26,
			x = side * 0.24,
			y = 1.79,
			z = -0.62,
			rot = CFrame.Angles(0, 0, side * 0.45),
			color = c.beard,
		})
	end
end

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

	buildFace(model, def)

	--[[
		The hat is a chain of shrinking blobs following a curve.

		Smoothness here is entirely about overlap. Each segment steps up by
		much less than its own height, so neighbouring ellipsoids bury each
		other's ends and the union reads as one continuous surface instead of
		a row of beads. Widening the step or shrinking sy is what makes it
		look lumpy.
	]]
	local HAT_SEGMENTS = 16
	local HAT_RISE = 1.5
	for i = 0, HAT_SEGMENTS - 1 do
		local t = i / (HAT_SEGMENTS - 1)
		-- taper is eased so the cap is fat at the base and needle-fine at the
		-- tip, rather than shrinking linearly
		local width = 1.66 * (1 - t) ^ 0.78 + 0.07
		Parts.Blob(model, {
			name = "Hat",
			sx = width,
			-- each blob is far taller than the gap to the next one
			sy = 0.42,
			sz = width,
			-- leans back as it rises so the tip flops behind the gnome
			y = 2.6 + t * HAT_RISE,
			z = 0.42 * t * t,
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
		sx = 0.42,
		sy = 0.42,
		sz = 0.42,
		y = 4.12,
		z = 0.44,
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
