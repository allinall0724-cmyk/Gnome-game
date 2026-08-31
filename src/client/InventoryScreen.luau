--[[
	InventoryScreen
	The gnome collection: a biome filter rail down the left, a scrolling
	grid of owned gnomes, and a sell bar along the bottom.

	Cards are multi-select. Selection is tracked by uid rather than grid
	position, so a sale or a purchase arriving mid-selection cannot make
	the client sell the wrong gnome.

	Note the cards show PWR where the reference mockups show a level.
	Gnomes are fixed units in this game - the design doc is explicit that
	there is no leveling - so a level chip would be inventing a mechanic.

	The grid is only rebuilt when the server actually sends an inventory,
	which it does on change rather than on every tick: each card holds a
	ViewportFrame rendering a real gnome model and they are not free.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local GnomeData = require(Shared:WaitForChild("GnomeData"))

local InventoryScreen = {}

function InventoryScreen.Create(parent)
	local api = {}
	api.OnSell = function() end

	local gnomes = {} -- last inventory the server sent
	local selected = {} -- [uid] = true
	local activeBiome = nil -- nil means "all"
	local cards = {} -- [uid] = { stroke = UIStroke, check = Frame }

	local backdrop, sheet = Theme.Modal({
		Parent = parent,
		Name = "InventoryScreen",
		Size = UDim2.fromOffset(940, 660),
		ZIndex = 20,
	})

	----------------------------------------------------------------
	-- Header
	----------------------------------------------------------------

	Theme.Label({
		Parent = sheet,
		Text = "GNOME INVENTORY",
		Font = Theme.TITLE_FONT,
		TextSize = 34,
		Position = UDim2.fromOffset(28, 20),
		Size = UDim2.new(1, -100, 0, 40),
		ZIndex = 22,
	})

	local capacityDot = Theme.Dot({
		Parent = sheet,
		Size = 14,
		Color = Theme.GREEN,
		Position = UDim2.fromOffset(30, 66),
		ZIndex = 22,
	})

	local capacityLabel = Theme.Label({
		Parent = sheet,
		Text = "0/0",
		Font = Theme.BOLD_FONT,
		TextSize = 16,
		TextColor3 = Theme.GREEN,
		Position = UDim2.fromOffset(52, 58),
		Size = UDim2.fromOffset(120, 22),
		ZIndex = 22,
	})

	Theme.Label({
		Parent = sheet,
		Text = "CAPACITY",
		Font = Theme.BOLD_FONT,
		TextSize = 13,
		TextColor3 = Theme.MUTED,
		Position = UDim2.fromOffset(126, 58),
		Size = UDim2.fromOffset(120, 22),
		ZIndex = 22,
	})

	local close = Theme.CloseButton({ Parent = sheet, ZIndex = 24 })

	----------------------------------------------------------------
	-- Biome rail
	----------------------------------------------------------------

	local rail = Theme.New("Frame", {
		Name = "Rail",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 100),
		Size = UDim2.fromOffset(180, 440),
		ZIndex = 22,
		Parent = sheet,
	}, {
		Theme.List(10, Enum.FillDirection.Vertical),
	})

	local railButtons = {}

	local function setBiome(biome)
		activeBiome = biome
		for key, entry in pairs(railButtons) do
			local on = (key == "All" and biome == nil) or key == biome
			entry.frame.BackgroundColor3 = on and Theme.Shade(entry.color, -0.62) or Theme.PANEL
			entry.frame:FindFirstChildOfClass("UIStroke").Color = on and entry.color or Theme.LINE
			entry.label.TextColor3 = on and Theme.TEXT or Theme.MUTED
		end
		api.Rebuild()
	end

	local function railEntry(key, text, color, order)
		local button = Theme.New("TextButton", {
			Name = key,
			AutoButtonColor = false,
			BackgroundColor3 = Theme.PANEL,
			BorderSizePixel = 0,
			Text = "",
			Size = UDim2.new(1, 0, 0, 60),
			LayoutOrder = order,
			ZIndex = 22,
			Parent = rail,
		}, {
			Theme.Corner(12),
			Theme.Stroke(2, Theme.LINE),
		})

		Theme.Dot({
			Parent = button,
			Size = 18,
			Color = color,
			Position = UDim2.fromOffset(16, 21),
			ZIndex = 23,
		})

		local label = Theme.Label({
			Parent = button,
			Text = text,
			Font = Theme.BOLD_FONT,
			TextSize = 15,
			TextColor3 = Theme.MUTED,
			Position = UDim2.fromOffset(44, 0),
			Size = UDim2.new(1, -54, 1, 0),
			ZIndex = 23,
		})

		railButtons[key] = { frame = button, label = label, color = color }

		button.Activated:Connect(function()
			setBiome(key == "All" and nil or key)
		end)
	end

	railEntry("All", "ALL", Theme.GOLD, 0)
	for index, biome in ipairs(GnomeData.Biomes) do
		railEntry(biome, string.upper(biome), Theme.BiomeColor(biome), index)
	end

	----------------------------------------------------------------
	-- Grid
	----------------------------------------------------------------

	local grid = Theme.New("ScrollingFrame", {
		Name = "Grid",
		BackgroundColor3 = Theme.WELL,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(216, 100),
		Size = UDim2.new(1, -244, 0, 440),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.LINE,
		ZIndex = 22,
		Parent = sheet,
	}, {
		Theme.Corner(14),
		Theme.Stroke(2, Theme.LINE),
		Theme.Pad(12, 12, 12, 12),
		Theme.Grid(UDim2.new(1 / 3, -9, 0, 142), UDim2.fromOffset(12, 12)),
	})

	-- Sits over the grid rather than inside it: the UIGridLayout would
	-- otherwise lay this out as a cell.
	local emptyLabel = Theme.Label({
		Parent = sheet,
		Text = "",
		TextSize = 15,
		TextColor3 = Theme.FAINT,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(216, 290),
		Size = UDim2.new(1, -244, 0, 40),
		Visible = false,
		ZIndex = 23,
	})

	----------------------------------------------------------------
	-- Sell bar
	----------------------------------------------------------------

	local sellButton = Theme.Button({
		Parent = sheet,
		Name = "Sell",
		Text = "SELL GNOMES",
		Color = Theme.RED,
		TextColor3 = Color3.fromRGB(255, 240, 236),
		TextSize = 22,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -46),
		Size = UDim2.new(1, -56, 0, 54),
		Radius = 14,
		ZIndex = 23,
	})

	local sellHint = Theme.Label({
		Parent = sheet,
		Text = "Select gnomes to sell",
		Font = Theme.BOLD_FONT,
		TextSize = 14,
		TextColor3 = Theme.MUTED,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(1, -56, 0, 20),
		ZIndex = 23,
	})

	local function selectionTotals()
		local count, gold = 0, 0
		for _, gnome in ipairs(gnomes) do
			if selected[gnome.uid] then
				count += 1
				gold += gnome.sellValue
			end
		end
		return count, gold
	end

	local function refreshSellBar()
		local count, gold = selectionTotals()
		if count == 0 then
			Theme.SetButtonEnabled(sellButton, false, "SELL GNOMES")
			sellHint.Text = "Select gnomes to sell"
			sellHint.TextColor3 = Theme.MUTED
		else
			Theme.SetButtonEnabled(sellButton, true)
			sellButton.Text = string.format("SELL %d GNOME%s", count, count == 1 and "" or "S")
			sellHint.Text = string.format("Earns %s gold", Theme.Comma(gold))
			sellHint.TextColor3 = Theme.GOLD
		end
	end

	local function setSelected(uid, on)
		selected[uid] = on or nil
		local card = cards[uid]
		if card then
			card.stroke.Color = on and Theme.GOLD or card.accent
			card.stroke.Thickness = on and 4 or 2
			card.check.Visible = on
		end
		refreshSellBar()
	end

	----------------------------------------------------------------
	-- Cards
	----------------------------------------------------------------

	local function buildCard(gnome, order)
		local def = GnomeData.Get(gnome.id)
		local accent = Theme.RarityColor(gnome.rarity)

		local card = Theme.New("TextButton", {
			Name = tostring(gnome.uid),
			AutoButtonColor = false,
			BackgroundColor3 = Theme.CARD,
			BorderSizePixel = 0,
			Text = "",
			LayoutOrder = order,
			ZIndex = 23,
			Parent = grid,
		}, {
			Theme.Corner(12),
			Theme.Stroke(2, accent),
		})

		local stroke = card:FindFirstChildOfClass("UIStroke")

		if def then
			Theme.GnomePortrait({
				Parent = card,
				def = def,
				Position = UDim2.fromOffset(8, 18),
				Size = UDim2.fromOffset(78, 112),
				ZIndex = 24,
			})
		end

		Theme.Label({
			Parent = card,
			Text = gnome.name,
			Font = Theme.BOLD_FONT,
			TextSize = 15,
			Position = UDim2.fromOffset(92, 16),
			Size = UDim2.new(1, -104, 0, 20),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 24,
		})

		Theme.Label({
			Parent = card,
			Text = gnome.biome,
			TextSize = 13,
			TextColor3 = Theme.MUTED,
			Position = UDim2.fromOffset(92, 38),
			Size = UDim2.new(1, -104, 0, 16),
			ZIndex = 24,
		})

		Theme.Label({
			Parent = card,
			Text = gnome.rarity,
			Font = Theme.BOLD_FONT,
			TextSize = 13,
			TextColor3 = accent,
			Position = UDim2.fromOffset(92, 56),
			Size = UDim2.new(1, -104, 0, 16),
			ZIndex = 24,
		})

		-- the mockups show a level here; gnomes do not level, so this is
		-- the stat that actually matters
		Theme.Pill({
			Parent = card,
			Text = string.format("%d PWR", gnome.power),
			Color = Theme.BiomeColor(gnome.biome),
			Size = UDim2.fromOffset(70, 20),
			Position = UDim2.fromOffset(92, 78),
			ZIndex = 26,
		})

		Theme.Price({
			Parent = card,
			Amount = gnome.sellValue,
			TextSize = 14,
			Align = Enum.HorizontalAlignment.Right,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -10, 1, -8),
			Size = UDim2.fromOffset(110, 20),
			ZIndex = 24,
		})

		-- selection tick, hidden until the card is picked
		local check = Theme.New("Frame", {
			Name = "Check",
			BackgroundColor3 = Theme.GOLD,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(22, 22),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			Visible = false,
			ZIndex = 26,
			Parent = card,
		}, {
			Theme.Corner(11),
			Theme.Stroke(2, Theme.Shade(Theme.GOLD, -0.5)),
		})

		Theme.Label({
			Parent = check,
			Text = "v",
			Font = Theme.BOLD_FONT,
			TextSize = 14,
			TextColor3 = Theme.ON_GOLD,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 27,
		})

		cards[gnome.uid] = { stroke = stroke, check = check, accent = accent }

		card.Activated:Connect(function()
			setSelected(gnome.uid, not selected[gnome.uid])
		end)

		if selected[gnome.uid] then
			setSelected(gnome.uid, true)
		end
	end

	function api.Rebuild()
		for _, child in ipairs(grid:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		table.clear(cards)

		local shown = 0
		for _, gnome in ipairs(gnomes) do
			if activeBiome == nil or gnome.biome == activeBiome then
				shown += 1
				buildCard(gnome, shown)
			end
		end

		emptyLabel.Visible = shown == 0
		emptyLabel.Text = activeBiome
				and string.format("No %s gnomes yet. Try the shop.", string.lower(activeBiome))
			or "No gnomes yet. Try the shop."

		refreshSellBar()
	end

	----------------------------------------------------------------
	-- Wiring
	----------------------------------------------------------------

	function api.Update(economy)
		if economy.capacity then
			local count = economy.count or 0
			local full = count >= economy.capacity
			capacityLabel.Text = string.format("%d/%d", count, economy.capacity)
			capacityLabel.TextColor3 = full and Theme.RED or Theme.GREEN
			capacityDot.BackgroundColor3 = full and Theme.RED or Theme.GREEN
		end

		-- the server only sends the list when it changed
		if economy.gnomes then
			gnomes = economy.gnomes

			-- drop selections for gnomes that are no longer owned
			local live = {}
			for _, gnome in ipairs(gnomes) do
				live[gnome.uid] = true
			end
			for uid in pairs(selected) do
				if not live[uid] then
					selected[uid] = nil
				end
			end

			api.Rebuild()
		end
	end

	sellButton.Activated:Connect(function()
		if not sellButton:GetAttribute("Enabled") then
			return
		end
		local uids = {}
		for uid in pairs(selected) do
			table.insert(uids, uid)
		end
		if #uids > 0 then
			api.OnSell(uids)
			table.clear(selected)
			refreshSellBar()
		end
	end)

	function api.Open()
		backdrop.Visible = true
	end

	function api.Close()
		backdrop.Visible = false
	end

	function api.Toggle()
		if backdrop.Visible then
			api.Close()
		else
			api.Open()
		end
	end

	function api.IsOpen()
		return backdrop.Visible
	end

	close.Activated:Connect(api.Close)

	setBiome(nil)
	refreshSellBar()

	api.Root = backdrop
	return api
end

return InventoryScreen
