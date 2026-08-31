--[[
	Parts
	Small primitive helpers for building models out of plain parts, so the
	game needs zero imported meshes or assets.

	Everything is built around a local origin where y = 0 is the ground and
	-Z is the front of the model.
]]

local Parts = {}

function Parts.New(props)
	local part = Instance.new("Part")
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	-- Animated models rewrite every part CFrame each frame, and a moving
	-- shadow caster invalidates the shadow map every time. The flat cartoon
	-- look does not need per-detail shadows; World re-enables them on the
	-- large static structures.
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		if key ~= "Parent" then
			part[key] = value
		end
	end
	-- parent last, so the part never replicates half-configured
	part.Parent = props.Parent
	return part
end

-- An upright cylinder. Roblox cylinders run along their X axis, so the part
-- is rotated a quarter turn to stand it up.
function Parts.Disc(parent, opts)
	return Parts.New({
		Name = opts.name or "Disc",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(opts.height, opts.radius * 2, opts.radius * 2),
		Color = opts.color,
		Material = opts.material or Enum.Material.SmoothPlastic,
		CFrame = CFrame.new(opts.x or 0, opts.y, opts.z or 0) * CFrame.Angles(0, 0, math.pi / 2),
		Parent = parent,
	})
end

function Parts.Ball(parent, opts)
	return Parts.New({
		Name = opts.name or "Ball",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(opts.d, opts.d, opts.d),
		Color = opts.color,
		Material = opts.material or Enum.Material.SmoothPlastic,
		CFrame = CFrame.new(opts.x or 0, opts.y, opts.z or 0),
		Parent = parent,
	})
end

function Parts.Block(parent, opts)
	return Parts.New({
		Name = opts.name or "Block",
		Size = opts.size,
		Color = opts.color,
		Material = opts.material or Enum.Material.SmoothPlastic,
		CFrame = CFrame.new(opts.x or 0, opts.y, opts.z or 0) * (opts.rot or CFrame.new()),
		Parent = parent,
	})
end

--[[
	A stepped cone made of stacked cylinder slices. Roblox has no cone
	primitive and this keeps the chunky look of the rest of the model
	without depending on a mesh asset.

	opts.baseY      y of the wide end
	opts.radius     radius at the wide end
	opts.tipRadius  radius at the narrow end (default 0.03)
	opts.height     total length
	opts.dir        1 = tapers upward, -1 = tapers downward
	opts.slices     how chunky the taper looks
]]
function Parts.Cone(parent, opts)
	local slices = opts.slices or 7
	local dir = opts.dir or 1
	local tipRadius = opts.tipRadius or 0.03
	local sliceHeight = opts.height / slices

	for i = 0, slices - 1 do
		local t = (i + 0.5) / slices -- 0 at the wide end, 1 at the tip
		local radius = opts.radius * (1 - t) + tipRadius * t
		Parts.Disc(parent, {
			name = (opts.name or "Cone") .. i,
			radius = radius,
			-- overlap slices slightly so there is no gap between them
			height = sliceHeight + 0.03,
			y = opts.baseY + dir * (i + 0.5) * sliceHeight,
			x = opts.x,
			z = opts.z,
			color = opts.color,
			material = opts.material,
		})
	end
end

--[[
	Makes the model a rigid, fully anchored assembly and marks the root as its
	PrimaryPart.

	Everything is anchored and nothing is welded on purpose. Welding dozens of
	unanchored parts to a moving anchored root makes the physics engine
	reposition every one of them each step, a frame behind whatever moved the
	root, which is exactly what reads as choppy. Anchored parts moved together
	by Model:PivotTo() skip physics entirely and land on the same frame.
]]
function Parts.Rig(model, root)
	model.PrimaryPart = root
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
end

function Parts.Nameplate(model, adornee, text, subtext, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Nameplate"
	billboard.Adornee = adornee
	billboard.Size = UDim2.fromScale(7, 2)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 90
	billboard.Parent = model

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.6)
	title.Font = Enum.Font.FredokaOne
	title.Text = text
	title.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.2
	title.TextScaled = true
	title.Parent = billboard

	if subtext then
		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Position = UDim2.fromScale(0, 0.58)
		sub.Size = UDim2.fromScale(1, 0.32)
		sub.Font = Enum.Font.GothamMedium
		sub.Text = subtext
		sub.TextColor3 = Color3.fromRGB(225, 225, 230)
		sub.TextStrokeTransparency = 0.4
		sub.TextScaled = true
		sub.Parent = billboard
	end

	return billboard
end

return Parts
