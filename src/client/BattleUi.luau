--[[
	BattleUi
	The resting squad and stage panels down the left side, plus the battle
	overlay that takes over the middle of the screen while a gate fight is
	resolving.

	This is the original parchment UI restyled onto the shared dark Theme;
	the behaviour and the information shown are unchanged. The client draws
	only - every number here was rolled on the server.

	Panels start below the HUD's gold card and boost strip.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))

local BattleUi = {}

local TOP = 130 -- clears the HUD

function BattleUi.Create(parent)
	local api = {}

	----------------------------------------------------------------
	-- Squad panel
	----------------------------------------------------------------

	local squadPanel = Theme.Panel({
		Parent = parent,
		Name = "SquadPanel",
		Position = UDim2.fromOffset(16, TOP),
		Size = UDim2.fromOffset(256, 240),
		ZIndex = 6,
	})

	Theme.Label({
		Parent = squadPanel,
		Text = "YOUR SQUAD",
		Font = Theme.TITLE_FONT,
		TextSize = 17,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 20),
		ZIndex = 7,
	})

	local squadTotals = Theme.Label({
		Parent = squadPanel,
		Text = "",
		TextSize = 12,
		TextColor3 = Theme.MUTED,
		Position = UDim2.fromOffset(14, 30),
		Size = UDim2.new(1, -28, 0, 16),
		ZIndex = 7,
	})

	local cardHolder = Theme.New("Frame", {
		Name = "Cards",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 52),
		Size = UDim2.new(1, -24, 1, -64),
		ZIndex = 7,
		Parent = squadPanel,
	}, {
		Theme.List(6, Enum.FillDirection.Vertical),
	})

	local function buildSquadCard(gnome, order)
		local accent = Theme.BiomeColor(gnome.biome)

		local card = Theme.Panel({
			Parent = cardHolder,
			Name = gnome.name,
			Color = Theme.CARD,
			Size = UDim2.new(1, 0, 0, 48),
			Radius = 10,
			StrokeColor = Theme.Shade(accent, -0.45),
			LayoutOrder = order,
			ZIndex = 8,
		})

		Theme.New("Frame", {
			Name = "Accent",
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(4, 30),
			Position = UDim2.fromOffset(8, 9),
			ZIndex = 9,
			Parent = card,
		}, { Theme.Corner(2) })

		Theme.Label({
			Parent = card,
			Text = gnome.name,
			Font = Theme.BOLD_FONT,
			TextSize = 13,
			Position = UDim2.fromOffset(20, 6),
			Size = UDim2.new(1, -28, 0, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 9,
		})

		Theme.Label({
			Parent = card,
			Text = string.format("%s  -  %s", gnome.biome, gnome.rarity),
			TextSize = 11,
			TextColor3 = accent,
			Position = UDim2.fromOffset(20, 25),
			Size = UDim2.new(0.55, 0, 0, 14),
			ZIndex = 9,
		})

		Theme.Label({
			Parent = card,
			Text = string.format("%d PWR   %d HP", gnome.power, gnome.health),
			TextSize = 11,
			TextColor3 = Theme.MUTED,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.45, 0, 0, 25),
			Size = UDim2.new(0.55, -10, 0, 14),
			ZIndex = 9,
		})
	end

	----------------------------------------------------------------
	-- Stage panel
	----------------------------------------------------------------

	local stagePanel = Theme.Panel({
		Parent = parent,
		Name = "StagePanel",
		Position = UDim2.fromOffset(16, TOP + 252),
		Size = UDim2.fromOffset(256, 150),
		ZIndex = 6,
	})

	local stageTitle = Theme.Label({
		Parent = stagePanel,
		Text = "STAGE 1",
		Font = Theme.TITLE_FONT,
		TextSize = 16,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 20),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	})

	local stageBlurb = Theme.Label({
		Parent = stagePanel,
		Text = "",
		TextSize = 11,
		TextColor3 = Theme.MUTED,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(14, 32),
		Size = UDim2.new(1, -28, 0, 34),
		ZIndex = 7,
	})

	local stageEnemy = Theme.Label({
		Parent = stagePanel,
		Text = "",
		Font = Theme.BOLD_FONT,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(246, 116, 100),
		Position = UDim2.fromOffset(14, 70),
		Size = UDim2.new(1, -28, 0, 16),
		ZIndex = 7,
	})

	local stageHint = Theme.Label({
		Parent = stagePanel,
		Text = "Walk up the road and hold E at the stone.",
		TextSize = 11,
		TextColor3 = Theme.GREEN,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(14, 92),
		Size = UDim2.new(1, -28, 0, 44),
		ZIndex = 7,
	})

	----------------------------------------------------------------
	-- Battle overlay
	----------------------------------------------------------------

	local overlay = Theme.Panel({
		Parent = parent,
		Name = "Battle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(460, 260),
		Radius = 16,
		StrokeThickness = 3,
		Visible = false,
		ZIndex = 15,
	})

	local battleTitle = Theme.Label({
		Parent = overlay,
		Text = "",
		Font = Theme.TITLE_FONT,
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = 16,
	})

	local function buildBar(y, barColor, nameText)
		local nameLabel = Theme.Label({
			Parent = overlay,
			Text = nameText,
			Font = Theme.BOLD_FONT,
			TextSize = 13,
			Position = UDim2.fromOffset(18, y),
			Size = UDim2.new(0.6, 0, 0, 16),
			ZIndex = 16,
		})

		local valueLabel = Theme.Label({
			Parent = overlay,
			Text = "",
			TextSize = 13,
			TextColor3 = Theme.MUTED,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.4, -18, 0, y),
			Size = UDim2.new(0.6, 0, 0, 16),
			ZIndex = 16,
		})

		local track = Theme.New("Frame", {
			BackgroundColor3 = Theme.WELL,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(18, y + 20),
			Size = UDim2.new(1, -36, 0, 14),
			ZIndex = 16,
			Parent = overlay,
		}, {
			Theme.Corner(7),
			Theme.Stroke(2, Theme.LINE),
		})

		local fill = Theme.New("Frame", {
			BackgroundColor3 = barColor,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 17,
			Parent = track,
		}, {
			Theme.Corner(7),
		})

		return { name = nameLabel, value = valueLabel, fill = fill }
	end

	local enemyBar = buildBar(46, Color3.fromRGB(238, 82, 74), "Enemy")
	local squadBar = buildBar(104, Theme.GREEN, "Your squad")

	local logBox = Theme.Label({
		Parent = overlay,
		Text = "",
		TextSize = 12,
		TextColor3 = Theme.MUTED,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.fromOffset(18, 162),
		Size = UDim2.new(1, -36, 0, 46),
		ZIndex = 16,
	})

	local resultLabel = Theme.Label({
		Parent = overlay,
		Text = "",
		Font = Theme.TITLE_FONT,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 214),
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 16,
	})

	local function setBar(bar, current, max)
		local ratio = max > 0 and math.clamp(current / max, 0, 1) or 0
		TweenService:Create(bar.fill, TweenInfo.new(0.18), {
			Size = UDim2.fromScale(ratio, 1),
		}):Play()
		bar.value.Text = string.format("%d / %d", math.max(0, math.floor(current + 0.5)), max)
	end

	----------------------------------------------------------------
	-- Public updates
	----------------------------------------------------------------

	local logLines = {}
	local fightState = { enemyMax = 1, squadMax = 1 }

	function api.SetSquad(data)
		for _, child in ipairs(cardHolder:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for index, gnome in ipairs(data.gnomes) do
			buildSquadCard(gnome, index)
		end

		squadTotals.Text =
			string.format("%d PWR total   -   %d HP total", data.totalPower, data.totalHealth)

		local height = 64 + #data.gnomes * 54
		squadPanel.Size = UDim2.fromOffset(256, height)
		stagePanel.Position = UDim2.fromOffset(16, TOP + height + 12)

		stageTitle.Text = string.upper(data.stage.name)
		stageBlurb.Text = data.stage.blurb
		stageEnemy.Text = string.format(
			"%s  -  %d HP  -  %d PWR",
			data.stage.enemyName,
			data.stage.enemyHealth,
			data.stage.enemyPower
		)
	end

	function api.SetStage(state)
		if state.cooldown and state.cooldown > 0 then
			stageHint.Text = string.format(
				"Road closed. %ds until you can push again.",
				math.ceil(state.cooldown)
			)
			stageHint.TextColor3 = Theme.RED
		elseif state.busy then
			stageHint.Text = "Another challenger is at the gate."
			stageHint.TextColor3 = Theme.GOLD
		else
			stageHint.Text = "Walk up the road and hold E at the stone."
			stageHint.TextColor3 = Theme.GREEN
		end
	end

	function api.Fight(payload)
		if payload.phase == "start" then
			logLines = {}
			fightState.enemyMax = payload.enemyMaxHealth
			fightState.squadMax = payload.squadMaxHealth

			battleTitle.Text = payload.stageName
			enemyBar.name.Text =
				string.format("%s  (%d PWR)", payload.enemyName, payload.enemyPower)
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
				resultLabel.TextColor3 = Theme.GREEN
			else
				resultLabel.Text = "DEFEATED"
				resultLabel.TextColor3 = Theme.RED
			end
			task.delay(3.5, function()
				overlay.Visible = false
			end)
		end
	end

	-- Hidden while a full-screen page is open, so the shop is not cluttered.
	function api.SetPanelsVisible(visible)
		squadPanel.Visible = visible
		stagePanel.Visible = visible
	end

	return api
end

return BattleUi
