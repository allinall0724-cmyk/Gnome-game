--[[
	Theme
	The shared look of every screen: palette, type scale, and the handful of
	builders (panels, cards, buttons, pills, portraits) that all UI is
	assembled from.

	The style is dark and chunky - near-black panels, a colour-coded stroke
	per rarity or biome, gold for currency and purchases, green for
	consumables, red for selling. Route new UI through these builders so the
	whole game keeps reading as one interface.

	No imported assets anywhere: icons are coloured shapes, portraits are the
	real gnome models rendered in a ViewportFrame by GnomeBuilder.
]]

local GnomeBuilder = require(script.Parent.GnomeBuilder)

local Theme = {}

--------------------------------------------------------------------
-- Palette
--------------------------------------------------------------------

Theme.SCRIM = Color3.fromRGB(6, 9, 14) -- full-screen dim behind a modal
Theme.PAGE = Color3.fromRGB(12, 16, 23) -- backdrop of a full-screen page
Theme.PANEL = Color3.fromRGB(23, 29, 40) -- the big framed regions
Theme.WELL = Color3.fromRGB(15, 20, 28) -- inset areas inside a panel
Theme.CARD = Color3.fromRGB(28, 35, 48)
Theme.CARD_HI = Color3.fromRGB(38, 47, 63) -- hover state for a card
Theme.LINE = Color3.fromRGB(52, 62, 80) -- default stroke / divider

Theme.TEXT = Color3.fromRGB(238, 243, 250)
Theme.MUTED = Color3.fromRGB(146, 158, 176)
Theme.FAINT = Color3.fromRGB(96, 107, 124)

Theme.GOLD = Color3.fromRGB(247, 200, 74)
Theme.GOLD_DEEP = Color3.fromRGB(176, 126, 22)
Theme.GREEN = Color3.fromRGB(64, 178, 82)
Theme.RED = Color3.fromRGB(226, 66, 52)
Theme.PURPLE = Color3.fromRGB(146, 78, 220)
Theme.BLUE = Color3.fromRGB(74, 148, 236)

-- Text sat on top of a gold or green fill.
Theme.ON_GOLD = Color3.fromRGB(42, 28, 4)
Theme.ON_GREEN = Color3.fromRGB(240, 255, 242)

Theme.RARITY = {
	Common = Color3.fromRGB(104, 198, 118),
	Rare = Color3.fromRGB(196, 108, 240),
	Epic = Color3.fromRGB(246, 164, 54),
	Legendary = Color3.fromRGB(255, 104, 96),
}

Theme.BIOME = {
	Forest = Color3.fromRGB(88, 200, 96),
	Desert = Color3.fromRGB(238, 190, 84),
	Mountain = Color3.fromRGB(140, 186, 240),
	Swamp = Color3.fromRGB(168, 108, 236),
}

Theme.TITLE_FONT = Enum.Font.FredokaOne
Theme.DISPLAY_FONT = Enum.Font.Merriweather -- the big gilded page titles
Theme.BODY_FONT = Enum.Font.GothamMedium
Theme.BOLD_FONT = Enum.Font.GothamBold

function Theme.RarityColor(rarity)
	return Theme.RARITY[rarity] or Theme.LINE
end

function Theme.BiomeColor(biome)
	return Theme.BIOME[biome] or Theme.LINE
end

-- Lighten (amount > 0) or darken (amount < 0) toward white/black.
function Theme.Shade(color, amount)
	if amount >= 0 then
		return color:Lerp(Color3.new(1, 1, 1), amount)
	end
	return color:Lerp(Color3.new(0, 0, 0), -amount)
end

--------------------------------------------------------------------
-- Formatting
--------------------------------------------------------------------

function Theme.Comma(n)
	local text = tostring(math.floor(n or 0))
	local swaps
	repeat
		text, swaps = text:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
	until swaps == 0
	return text
end

-- 11:42:18 for a long timer, 04:31 for a short one.
function Theme.Clock(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor(seconds / 60) % 60
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%02d:%02d", minutes, secs)
end

function Theme.Rate(n)
	return string.format("%s/s", Theme.Comma(n))
end

function Theme.Percent(multiplier)
	return string.format("%+d%%", math.floor((multiplier - 1) * 100 + 0.5))
end

--------------------------------------------------------------------
-- Primitives
--------------------------------------------------------------------

function Theme.New(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	-- parent last so nothing renders half-configured
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function Theme.Corner(radius)
	return Theme.New("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function Theme.Stroke(thickness, color, transparency)
	return Theme.New("UIStroke", {
		Thickness = thickness or 2,
		Color = color or Theme.LINE,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.Pad(top, right, bottom, left)
	return Theme.New("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right or top),
		PaddingBottom = UDim.new(0, bottom or top),
		PaddingLeft = UDim.new(0, left or right or top),
	})
end

function Theme.Gradient(colors, rotation)
	local keypoints = {}
	for index, color in ipairs(colors) do
		local t = #colors == 1 and 0 or (index - 1) / (#colors - 1)
		table.insert(keypoints, ColorSequenceKeypoint.new(t, color))
	end
	return Theme.New("UIGradient", {
		Color = ColorSequence.new(keypoints),
		Rotation = rotation or 90,
	})
end

function Theme.List(padding, direction, alignment)
	return Theme.New("UIListLayout", {
		Padding = UDim.new(0, padding or 8),
		FillDirection = direction or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
	})
end

function Theme.Grid(cellSize, cellPadding)
	return Theme.New("UIGridLayout", {
		CellSize = cellSize,
		CellPadding = cellPadding or UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirectionMaxCells = 0,
	})
end

function Theme.Label(props)
	return Theme.New("TextLabel", {
		Name = props.Name or "Label",
		BackgroundTransparency = 1,
		Font = props.Font or Theme.BODY_FONT,
		Text = props.Text or "",
		TextColor3 = props.TextColor3 or Theme.TEXT,
		TextSize = props.TextSize or 14,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
		TextWrapped = props.TextWrapped or false,
		TextTruncate = props.TextTruncate or Enum.TextTruncate.None,
		RichText = props.RichText or false,
		Size = props.Size or UDim2.new(1, 0, 0, 18),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Visible = props.Visible ~= false,
		Parent = props.Parent,
	})
end

--------------------------------------------------------------------
-- Composites
--------------------------------------------------------------------

-- A framed dark region. The workhorse container for every screen.
function Theme.Panel(props)
	return Theme.New("Frame", {
		Name = props.Name or "Panel",
		BackgroundColor3 = props.Color or Theme.PANEL,
		BackgroundTransparency = props.Transparency or 0,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Visible = props.Visible ~= false,
		Parent = props.Parent,
	}, {
		Theme.Corner(props.Radius or 14),
		Theme.Stroke(props.StrokeThickness or 2, props.StrokeColor or Theme.LINE),
	})
end

-- Small rounded chip - "Limited!", "VERY RARE", a biome tag.
function Theme.Pill(props)
	local color = props.Color or Theme.PURPLE
	local pill = Theme.New("Frame", {
		Name = props.Name or "Pill",
		BackgroundColor3 = Theme.Shade(color, -0.55),
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(78, 20),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
		Visible = props.Visible ~= false,
		Parent = props.Parent,
	}, {
		Theme.Corner(props.Radius or 10),
		Theme.Stroke(1, color),
	})

	Theme.Label({
		Parent = pill,
		Text = props.Text or "",
		Font = Theme.BOLD_FONT,
		TextColor3 = Theme.Shade(color, 0.35),
		TextSize = props.TextSize or 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = (props.ZIndex or 2) + 1,
	})

	return pill
end

-- A small filled circle standing in for an icon. Biome and currency
-- markers are colour-coded dots rather than images, since the project
-- ships no assets.
function Theme.Dot(props)
	local size = props.Size or 14
	local dot = Theme.New("Frame", {
		Name = props.Name or "Dot",
		BackgroundColor3 = props.Color or Theme.GOLD,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size, size),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
		Parent = props.Parent,
	}, {
		Theme.Corner(size),
		Theme.Stroke(1, Theme.Shade(props.Color or Theme.GOLD, -0.4)),
	})
	return dot
end

-- Gold coin + amount, the standard way a price is written.
function Theme.Price(props)
	local holder = Theme.New("Frame", {
		Name = props.Name or "Price",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, 20),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
		Parent = props.Parent,
	}, {
		Theme.List(
			5,
			Enum.FillDirection.Horizontal,
			props.Align or Enum.HorizontalAlignment.Center
		),
	})
	holder:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Center

	Theme.Dot({
		Parent = holder,
		Size = props.DotSize or 14,
		Color = Theme.GOLD,
		LayoutOrder = 0,
		ZIndex = (props.ZIndex or 2) + 1,
	})
	local amount = Theme.Label({
		Parent = holder,
		Text = Theme.Comma(props.Amount or 0),
		Font = Theme.BOLD_FONT,
		TextColor3 = props.TextColor3 or Theme.TEXT,
		TextSize = props.TextSize or 15,
		Size = UDim2.fromOffset(0, props.TextSize or 15),
		LayoutOrder = 1,
		ZIndex = (props.ZIndex or 2) + 1,
	})
	amount.AutomaticSize = Enum.AutomaticSize.X

	return holder, amount
end

--[[
	A chunky button with a vertical gradient and hover/press feedback.
	Returns the TextButton; call Theme.SetButtonEnabled to grey it out.
]]
function Theme.Button(props)
	local base = props.Color or Theme.GOLD

	local button = Theme.New("TextButton", {
		Name = props.Name or "Button",
		AutoButtonColor = false,
		BackgroundColor3 = base,
		BorderSizePixel = 0,
		Font = props.Font or Theme.BOLD_FONT,
		Text = props.Text or "",
		TextColor3 = props.TextColor3 or Theme.ON_GOLD,
		TextSize = props.TextSize or 15,
		Size = props.Size or UDim2.new(1, 0, 0, 34),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
		Visible = props.Visible ~= false,
		Parent = props.Parent,
	}, {
		Theme.Corner(props.Radius or 9),
		Theme.Stroke(2, Theme.Shade(base, -0.45)),
		Theme.Gradient({ Theme.Shade(base, 0.16), Theme.Shade(base, -0.14) }, 90),
	})

	button:SetAttribute("BaseColor", base)
	button:SetAttribute("Enabled", true)
	-- captured once at build time: a disabled button can be re-disabled
	-- with a different reason, and reading Text at that point would
	-- save the placeholder as the real label
	button:SetAttribute("EnabledText", props.Text or "")

	button.MouseEnter:Connect(function()
		if button:GetAttribute("Enabled") then
			button.BackgroundColor3 = Theme.Shade(base, 0.14)
		end
	end)
	button.MouseLeave:Connect(function()
		if button:GetAttribute("Enabled") then
			button.BackgroundColor3 = base
		end
	end)
	button.MouseButton1Down:Connect(function()
		if button:GetAttribute("Enabled") then
			button.BackgroundColor3 = Theme.Shade(base, -0.18)
		end
	end)
	button.MouseButton1Up:Connect(function()
		if button:GetAttribute("Enabled") then
			button.BackgroundColor3 = Theme.Shade(base, 0.14)
		end
	end)

	return button
end

function Theme.SetButtonEnabled(button, enabled, disabledText)
	button:SetAttribute("Enabled", enabled)
	button.Active = enabled
	button.AutoButtonColor = false

	local base = button:GetAttribute("BaseColor")
	if enabled then
		button.BackgroundColor3 = base
		button.TextTransparency = 0
		button.BackgroundTransparency = 0
		button.Text = button:GetAttribute("EnabledText")
	else
		button.BackgroundColor3 = Color3.fromRGB(58, 66, 80)
		button.TextTransparency = 0.35
		button.Text = disabledText or button:GetAttribute("EnabledText")
	end
end

--[[
	Renders a real gnome model into a ViewportFrame, so cards show the
	actual in-world gnome instead of an icon. The model is built facing -Z
	with its feet at y = 0, so the camera sits on the -Z side looking back
	at it.
]]
function Theme.GnomePortrait(props)
	local viewport = Theme.New("ViewportFrame", {
		Name = props.Name or "Portrait",
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BackgroundColor3 = props.BackgroundColor3 or Theme.WELL,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(80, 96),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
		Ambient = Color3.fromRGB(178, 186, 202),
		LightColor = Color3.fromRGB(255, 250, 238),
		LightDirection = Vector3.new(-0.35, -1, -0.55),
		Parent = props.Parent,
	})

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local model = GnomeBuilder.Gnome(props.def)
	-- the world nameplate would be dead weight in here
	local plate = model:FindFirstChild("Nameplate")
	if plate then
		plate:Destroy()
	end
	model.Parent = world
	model:PivotTo(CFrame.new(0, 0, 0))

	-- gnomes stand about 3.3 studs tall; this frames one with a little air
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 1.85, -5.4), Vector3.new(0, 1.62, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	return viewport
end

--------------------------------------------------------------------
-- Screen scaffolding
--------------------------------------------------------------------

-- Full-screen dim + a centred panel. Returns the backdrop and the panel.
function Theme.Modal(props)
	local backdrop = Theme.New("Frame", {
		Name = props.Name or "Modal",
		BackgroundColor3 = Theme.SCRIM,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = props.ZIndex or 20,
		Parent = props.Parent,
	})

	local panel = Theme.Panel({
		Parent = backdrop,
		Name = "Sheet",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromOffset(880, 620),
		Radius = 18,
		StrokeThickness = 3,
		StrokeColor = Theme.Shade(Theme.LINE, 0.1),
		ZIndex = (props.ZIndex or 20) + 1,
	})

	return backdrop, panel
end

-- The round X in the corner of a modal.
function Theme.CloseButton(props)
	local button = Theme.New("TextButton", {
		Name = "Close",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.CARD_HI,
		BorderSizePixel = 0,
		Font = Theme.BOLD_FONT,
		Text = "X",
		TextColor3 = Theme.TEXT,
		TextSize = 18,
		Size = UDim2.fromOffset(40, 40),
		AnchorPoint = Vector2.new(1, 0),
		Position = props.Position or UDim2.new(1, -18, 0, 18),
		ZIndex = props.ZIndex or 24,
		Parent = props.Parent,
	}, {
		Theme.Corner(12),
		Theme.Stroke(2, Theme.LINE),
	})

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Theme.RED
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Theme.CARD_HI
	end)

	return button
end

-- A gilded page title, as on the shop.
function Theme.DisplayTitle(props)
	local title = Theme.Label({
		Parent = props.Parent,
		Name = "DisplayTitle",
		Text = props.Text or "",
		Font = Theme.DISPLAY_FONT,
		TextColor3 = Color3.fromRGB(255, 232, 168),
		TextSize = props.TextSize or 44,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		Size = props.Size or UDim2.new(1, 0, 0, 52),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
	})

	Theme.Gradient({
		Color3.fromRGB(255, 238, 186),
		Color3.fromRGB(246, 196, 78),
		Color3.fromRGB(198, 138, 30),
	}, 90).Parent =
		title

	local stroke = Theme.New("UIStroke", {
		Thickness = 2,
		Color = Color3.fromRGB(74, 46, 6),
		Transparency = 0.25,
	})
	stroke.Parent = title

	return title
end

-- Section heading inside a panel: "LIMITED TIME GNOMES".
function Theme.SectionHeader(props)
	return Theme.Label({
		Parent = props.Parent,
		Name = "Section",
		Text = string.upper(props.Text or ""),
		Font = Theme.BOLD_FONT,
		TextColor3 = props.TextColor3 or Theme.MUTED,
		TextSize = props.TextSize or 13,
		Size = props.Size or UDim2.new(1, 0, 0, 18),
		Position = props.Position or UDim2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 2,
	})
end

return Theme
