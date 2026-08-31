--[[
	Client UI.

	Two resting panels - your squad and the current stage - plus a battle
	overlay that appears while a gate fight is resolving. The client draws
	only; every number shown here was rolled on the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestState = Remotes:WaitForChild("RequestState")
local GnomesUpdated = Remotes:WaitForChild("GnomesUpdated")
local StageState = Remotes:WaitForChild("StageState")
local FightEvent = Remotes:WaitForChild("FightEvent")

local BIOME_COLOR = {
	Forest = Color3.fromRGB(62, 176, 76),
	Desert = Color3.fromRGB(226, 158, 30),
	Mountain = Color3.fromRGB(48, 146, 226),
	Swamp = Color3.fromRGB(46, 176, 132),
}

local INK = Color3.fromRGB(74, 48, 34)
local MUTED = Color3.fromRGB(150, 112, 82)
local PANEL = Color3.fromRGB(255, 246, 224)

local function new(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

local function stroke(thickness, color)
	return new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or Color3.fromRGB(74, 48, 34),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(px)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

local function label(props)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.Font or Enum.Font.GothamMedium,
		Text = props.Text or "",
		TextColor3 = props.TextColor3 or INK,
		TextSize = props.TextSize or 14,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
		TextWrapped = props.TextWrapped or false,
		Size = props.Size or UDim2.new(1, 0, 0, 18),
		Position = props.Position or UDim2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		Name = props.Name or "Label",
		Parent = props.Parent,
	})
end

local screen = new("ScreenGui", {
	Name = "GnomeGameUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

--------------------------------------------------------------------
-- Squad panel
--------------------------------------------------------------------

local squadPanel = new("Frame", {
	Name = "SquadPanel",
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0,
	Position = UDim2.fromOffset(16, 16),
	Size = UDim2.fromOffset(250, 232),
	Parent = screen,
}, { corner(14), stroke(3), padding(12) })

new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = squadPanel,
})

label({
	Parent = squadPanel,
	Text = "YOUR GNOMES",
	Font = Enum.Font.FredokaOne,
	TextSize = 16,
	LayoutOrder = 0,
})

local squadTotals = label({
	Parent = squadPanel,
	Text = "",
	TextColor3 = MUTED,
	TextSize = 12,
	Size = UDim2.new(1, 0, 0, 14),
	LayoutOrder = 1,
})

local cardHolder = new("Frame", {
	Name = "Cards",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 160),
	LayoutOrder = 2,
	Parent = squadPanel,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local function buildCard(gnome, order)
	local accent = BIOME_COLOR[gnome.biome] or INK

	local card = new("Frame", {
		Name = gnome.name,
		BackgroundColor3 = Color3.fromRGB(255, 232, 186),
		Size = UDim2.new(1, 0, 0, 46),
		LayoutOrder = order,
		Parent = cardHolder,
	}, { corner(10), stroke(2) })

	new("Frame", {
		Name = "Accent",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, -12),
		Position = UDim2.fromOffset(6, 6),
		Parent = card,
	}, { corner(2) })

	label({
		Parent = card,
		Text = gnome.name,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Position = UDim2.fromOffset(18, 6),
		Size = UDim2.new(1, -24, 0, 16),
	})
	label({
		Parent = card,
		Text = string.format("%s  -  %s", gnome.biome, gnome.rarity),
		TextColor3 = accent,
		TextSize = 11,
		Position = UDim2.fromOffset(18, 24),
		Size = UDim2.new(0.55, 0, 0, 14),
	})
	label({
		Parent = card,
		Text = string.format("%d PWR   %d HP", gnome.power, gnome.health),
		TextColor3 = MUTED,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(0.45, 0, 0, 24),
		Size = UDim2.new(0.55, -8, 0, 14),
	})
end

--------------------------------------------------------------------
-- Stage panel
--------------------------------------------------------------------

local stagePanel = new("Frame", {
	Name = "StagePanel",
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0,
	Position = UDim2.fromOffset(16, 260),
	Size = UDim2.fromOffset(250, 138),
	Parent = screen,
}, { corner(14), stroke(3), padding(12) })

new("UIListLayout", {
	Padding = UDim.new(0, 5),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = stagePanel,
})

local stageTitle = label({
	Parent = stagePanel,
	Text = "STAGE 1",
	Font = Enum.Font.FredokaOne,
	TextSize = 15,
	LayoutOrder = 0,
})
local stageBlurb = label({
	Parent = stagePanel,
	Text = "",
	TextColor3 = MUTED,
	TextSize = 11,
	TextWrapped = true,
	Size = UDim2.new(1, 0, 0, 32),
	LayoutOrder = 1,
})
local stageEnemy = label({
	Parent = stagePanel,
	Text = "",
	TextSize = 12,
	TextColor3 = Color3.fromRGB(214, 66, 54),
	LayoutOrder = 2,
})
local stageHint = label({
	Parent = stagePanel,
	Text = "Walk up the road and hold E at the stone.",
	TextColor3 = Color3.fromRGB(28, 158, 118),
	TextSize = 11,
	TextWrapped = true,
	Size = UDim2.new(1, 0, 0, 30),
	LayoutOrder = 3,
})

--------------------------------------------------------------------
-- Battle overlay
--------------------------------------------------------------------

local overlay = new("Frame", {
	Name = "Battle",
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 24),
	Size = UDim2.fromOffset(420, 214),
	Visible = false,
	Parent = screen,
}, { corner(16), stroke(3), padding(14) })

local battleTitle = label({
	Parent = overlay,
	Text = "",
	Font = Enum.Font.FredokaOne,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.new(1, 0, 0, 20),
})

local function buildBar(parent, y, barColor, nameText)
	local nameLabel = label({
		Parent = parent,
		Text = nameText,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(0.6, 0, 0, 14),
	})
	local valueLabel = label({
		Parent = parent,
		Text = "",
		TextColor3 = MUTED,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(0.4, 0, 0, y),
		Size = UDim2.new(0.6, 0, 0, 14),
	})
	local track = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(236, 214, 176),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, y + 17),
		Size = UDim2.new(1, 0, 0, 12),
		Parent = parent,
	}, { corner(6), stroke(2) })
	local fill = new("Frame", {
		BackgroundColor3 = barColor,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = track,
	}, { corner(6), stroke(2) })
	return { name = nameLabel, value = valueLabel, fill = fill }
end

local enemyBar = buildBar(overlay, 28, Color3.fromRGB(246, 82, 74), "Enemy")
local squadBar = buildBar(overlay, 80, Color3.fromRGB(74, 202, 96), "Your squad")

local logBox = label({
	Parent = overlay,
	Text = "",
	TextColor3 = MUTED,
	TextSize = 11,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Position = UDim2.fromOffset(0, 130),
	Size = UDim2.new(1, 0, 0, 44),
})

local resultLabel = label({
	Parent = overlay,
	Text = "",
	Font = Enum.Font.FredokaOne,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.fromOffset(0, 176),
	Size = UDim2.new(1, 0, 0, 24),
})

local function setBar(bar, current, max)
	local ratio = max > 0 and math.clamp(current / max, 0, 1) or 0
	TweenService:Create(bar.fill, TweenInfo.new(0.18), {
		Size = UDim2.fromScale(ratio, 1),
	}):Play()
	bar.value.Text = string.format("%d / %d", math.max(0, math.floor(current + 0.5)), max)
end

--------------------------------------------------------------------
-- Wiring
--------------------------------------------------------------------

local logLines = {}
local fightState = { enemyMax = 1, squadMax = 1 }

GnomesUpdated.OnClientEvent:Connect(function(data)
	for _, child in ipairs(cardHolder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for index, gnome in ipairs(data.gnomes) do
		buildCard(gnome, index)
	end

	squadTotals.Text =
		string.format("%d PWR total   -   %d HP total", data.totalPower, data.totalHealth)
	cardHolder.Size = UDim2.new(1, 0, 0, #data.gnomes * 52)
	squadPanel.Size = UDim2.fromOffset(250, 76 + #data.gnomes * 52)
	stagePanel.Position = UDim2.fromOffset(16, 16 + squadPanel.Size.Y.Offset + 12)

	stageTitle.Text = string.upper(data.stage.name)
	stageBlurb.Text = data.stage.blurb
	stageEnemy.Text = string.format(
		"%s  -  %d HP  -  %d PWR",
		data.stage.enemyName,
		data.stage.enemyHealth,
		data.stage.enemyPower
	)
end)

StageState.OnClientEvent:Connect(function(state)
	if state.cooldown and state.cooldown > 0 then
		stageHint.Text =
			string.format("Road closed. %ds until you can push again.", math.ceil(state.cooldown))
		stageHint.TextColor3 = Color3.fromRGB(214, 66, 54)
	elseif state.busy then
		stageHint.Text = "Another challenger is at the gate."
		stageHint.TextColor3 = Color3.fromRGB(206, 138, 24)
	else
		stageHint.Text = "Walk up the road and hold E at the stone."
		stageHint.TextColor3 = Color3.fromRGB(28, 158, 118)
	end
end)

FightEvent.OnClientEvent:Connect(function(payload)
	if payload.phase == "start" then
		logLines = {}
		fightState.enemyMax = payload.enemyMaxHealth
		fightState.squadMax = payload.squadMaxHealth

		battleTitle.Text = payload.stageName
		enemyBar.name.Text = string.format("%s  (%d PWR)", payload.enemyName, payload.enemyPower)
		squadBar.name.Text = string.format("Your squad  (%d PWR)", payload.squadPower)
		setBar(enemyBar, payload.enemyMaxHealth, payload.enemyMaxHealth)
		setBar(squadBar, payload.squadMaxHealth, payload.squadMaxHealth)
		logBox.Text = string.format("%s blocks the gate.", payload.enemyName)
		resultLabel.Text = ""
		overlay.Visible = true
	elseif payload.phase == "tick" then
		setBar(enemyBar, payload.enemyHealth, fightState.enemyMax)
		setBar(squadBar, payload.squadHealth, fightState.squadMax)
		table.insert(logLines, payload.log)
		while #logLines > 3 do
			table.remove(logLines, 1)
		end
		logBox.Text = table.concat(logLines, "\n")
	elseif payload.phase == "finish" then
		setBar(enemyBar, payload.enemyHealth, fightState.enemyMax)
		setBar(squadBar, payload.squadHealth, fightState.squadMax)
		if payload.won then
			resultLabel.Text = "GATE CLEARED"
			resultLabel.TextColor3 = Color3.fromRGB(46, 178, 74)
		else
			resultLabel.Text = "DEFEATED"
			resultLabel.TextColor3 = Color3.fromRGB(232, 62, 52)
		end
		task.delay(3.5, function()
			overlay.Visible = false
		end)
	end
end)

RequestState:FireServer()
