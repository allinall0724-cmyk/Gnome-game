--[[
	ShopScreen
	The full-page Rotating Shop: limited-time gnomes on rotation, mystery
	eggs, a featured boss egg, and consumable boosts.

	The stock is not sent by the server. ShopData.StockFor(rotationIndex)
	is deterministic and the rotation runs on wall-clock time, so this
	screen derives the same four gnomes the server will validate against.
	ShopState only tells us when the rotation flipped.

	Purchases go out through api.OnAction(kind, id); the caller owns the
	remote. Every button re-checks affordability against the last economy
	push, but the server is what actually decides.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local GnomeData = require(Shared:WaitForChild("GnomeData"))
local ShopData = require(Shared:WaitForChild("ShopData"))

local ShopScreen = {}

local NAV = {
	{ id = "rotating", text = "ROTATING SHOP", ready = true },
	{ id = "daily", text = "DAILY DEALS", ready = false },
	{ id = "season", text = "SEASON PASS", ready = false },
	{ id = "bundles", text = "BUNDLES", ready = false },
}

function ShopScreen.Create(parent)
	local api = {}
	api.OnAction = function() end

	-- every purchasable control, so one economy push can grey them all out
	local offers = {}

	local state = { gold = 0, count = 0, capacity = ShopData.CAPACITY }

	local root = Theme.New("Frame", {
		Name = "ShopScreen",
		BackgroundColor3 = Theme.PAGE,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 30,
		Parent = parent,
	})

	----------------------------------------------------------------
	-- Header
	----------------------------------------------------------------

	local back = Theme.Button({
		Parent = root,
		Name = "Back",
		Text = "<",
		Color = Theme.CARD_HI,
		TextColor3 = Theme.TEXT,
		TextSize = 22,
		Size = UDim2.fromOffset(48, 48),
		Position = UDim2.fromOffset(20, 20),
		Radius = 24,
		ZIndex = 31,
	})

	Theme.DisplayTitle({
		Parent = root,
		Text = "ROTATING SHOP",
		TextSize = 46,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, -60, 0, 22),
		Size = UDim2.fromOffset(560, 56),
		ZIndex = 31,
	})

	local timerChip = Theme.Panel({
		Parent = root,
		Name = "Timer",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 300, 0, 30),
		Size = UDim2.fromOffset(180, 42),
		Radius = 12,
		ZIndex = 31,
	})

	Theme.Dot({
		Parent = timerChip,
		Size = 14,
		Color = Theme.GOLD,
		Position = UDim2.fromOffset(16, 14),
		ZIndex = 32,
	})

	local timerLabel = Theme.Label({
		Parent = timerChip,
		Text = "--:--",
		Font = Theme.TITLE_FONT,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(34, 0),
		Size = UDim2.new(1, -44, 1, 0),
		ZIndex = 32,
	})

	Theme.Label({
		Parent = root,
		Text = "New stock available soon!",
		Font = Theme.BOLD_FONT,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(196, 172, 236),
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, -60, 0, 78),
		Size = UDim2.fromOffset(560, 22),
		ZIndex = 31,
	})

	----------------------------------------------------------------
	-- Left rail
	----------------------------------------------------------------

	local rail = Theme.New("Frame", {
		Name = "Rail",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 116),
		Size = UDim2.new(0, 200, 1, -136),
		ZIndex = 31,
		Parent = root,
	}, {
		Theme.List(12, Enum.FillDirection.Vertical),
	})

	for index, entry in ipairs(NAV) do
		local active = entry.ready
		local item = Theme.Panel({
			Parent = rail,
			Name = entry.id,
			Size = UDim2.new(1, 0, 0, 62),
			Radius = 14,
			Color = active and Color3.fromRGB(52, 32, 86) or Theme.PANEL,
			StrokeColor = active and Theme.PURPLE or Theme.LINE,
			StrokeThickness = active and 3 or 2,
			LayoutOrder = index,
			ZIndex = 31,
		})

		Theme.Dot({
			Parent = item,
			Size = 16,
			Color = active and Theme.PURPLE or Theme.FAINT,
			Position = UDim2.fromOffset(16, 23),
			ZIndex = 32,
		})

		Theme.Label({
			Parent = item,
			Text = entry.text,
			Font = Theme.BOLD_FONT,
			TextSize = 15,
			TextColor3 = active and Theme.TEXT or Theme.FAINT,
			Position = UDim2.fromOffset(42, 0),
			Size = UDim2.new(1, -52, 1, 0),
			ZIndex = 32,
		})

		if not active then
			-- these tabs are in the design doc but not built; say so
			-- rather than offering a button that does nothing
			Theme.Pill({
				Parent = item,
				Text = "SOON",
				Color = Theme.FAINT,
				Size = UDim2.fromOffset(52, 18),
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -10, 1, -8),
				ZIndex = 33,
			})
		end
	end

	-- gold readout under the rail
	local goldCard = Theme.Panel({
		Parent = root,
		Name = "GoldCard",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 20, 1, -20),
		Size = UDim2.fromOffset(200, 84),
		Radius = 14,
		StrokeColor = Theme.Shade(Theme.GOLD, -0.5),
		ZIndex = 32,
	})

	Theme.Label({
		Parent = goldCard,
		Text = "YOUR GOLD",
		Font = Theme.BOLD_FONT,
		TextSize = 12,
		TextColor3 = Theme.MUTED,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -24, 0, 16),
		ZIndex = 33,
	})

	Theme.Dot({
		Parent = goldCard,
		Size = 26,
		Color = Theme.GOLD,
		Position = UDim2.fromOffset(16, 36),
		ZIndex = 33,
	})

	local shopGoldLabel = Theme.Label({
		Parent = goldCard,
		Text = "0",
		Font = Theme.TITLE_FONT,
		TextSize = 24,
		Position = UDim2.fromOffset(50, 32),
		Size = UDim2.new(1, -60, 0, 32),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 33,
	})

	----------------------------------------------------------------
	-- Body
	----------------------------------------------------------------

	local body = Theme.New("ScrollingFrame", {
		Name = "Body",
		BackgroundColor3 = Theme.WELL,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(236, 116),
		Size = UDim2.new(1, -256, 1, -136),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.LINE,
		ZIndex = 31,
		Parent = root,
	}, {
		Theme.Corner(16),
		Theme.Stroke(2, Theme.LINE),
		Theme.Pad(14, 14, 14, 14),
		Theme.List(14, Enum.FillDirection.Vertical),
	})

	--[[
		Registers a purchase control so Refresh() can enable or disable it
		from the latest gold figure. needsSlot marks offers that also
		require inventory space.
	]]
	local function registerOffer(button, cost, needsSlot)
		table.insert(offers, { button = button, cost = cost, needsSlot = needsSlot })
	end

	local function section(titleText, height, order)
		local panel = Theme.Panel({
			Parent = body,
			Name = titleText,
			Size = UDim2.new(1, 0, 0, height),
			Radius = 14,
			LayoutOrder = order,
			ZIndex = 32,
		})
		Theme.SectionHeader({
			Parent = panel,
			Text = titleText,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 16),
			ZIndex = 33,
		})
		return panel
	end

	----------------------------------------------------------------
	-- Limited time gnomes
	----------------------------------------------------------------

	local gnomeSection = section("LIMITED TIME GNOMES", 298, 1)

	local gnomeRow = Theme.New("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 1, -48),
		ZIndex = 33,
		Parent = gnomeSection,
	}, {
		Theme.List(10, Enum.FillDirection.Horizontal),
	})

	local function buildGnomeCard(def, order)
		local accent = Theme.RarityColor(def.rarity)

		local card = Theme.Panel({
			Parent = gnomeRow,
			Name = def.id,
			Size = UDim2.new(0.25, -8, 1, 0),
			Color = Theme.CARD,
			Radius = 14,
			StrokeColor = accent,
			StrokeThickness = 3,
			LayoutOrder = order,
			ZIndex = 34,
		})

		Theme.Pill({
			Parent = card,
			Text = "Limited!",
			Color = Theme.PURPLE,
			Size = UDim2.fromOffset(72, 20),
			Position = UDim2.fromOffset(8, 8),
			ZIndex = 36,
		})

		Theme.GnomePortrait({
			Parent = card,
			def = def,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 30),
			Size = UDim2.fromOffset(112, 104),
			ZIndex = 35,
		})

		Theme.Label({
			Parent = card,
			Text = string.upper(def.name),
			Font = Theme.BOLD_FONT,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(6, 138),
			Size = UDim2.new(1, -12, 0, 18),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 35,
		})

		Theme.Label({
			Parent = card,
			Text = string.format("%s  -  %s", def.biome, def.rarity),
			TextSize = 11,
			TextColor3 = accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(6, 156),
			Size = UDim2.new(1, -12, 0, 14),
			ZIndex = 35,
		})

		Theme.Label({
			Parent = card,
			Text = string.format("%d PWR   %d HP", def.power, def.health),
			TextSize = 11,
			TextColor3 = Theme.MUTED,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(6, 172),
			Size = UDim2.new(1, -12, 0, 14),
			ZIndex = 35,
		})

		Theme.Price({
			Parent = card,
			Amount = def.price,
			Position = UDim2.fromOffset(6, 190),
			Size = UDim2.new(1, -12, 0, 20),
			ZIndex = 35,
		})

		local buy = Theme.Button({
			Parent = card,
			Text = "BUY",
			Color = Theme.GOLD,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(1, -20, 0, 32),
			ZIndex = 35,
		})
		buy.Activated:Connect(function()
			if buy:GetAttribute("Enabled") then
				api.OnAction("gnome", def.id)
			end
		end)

		registerOffer(buy, def.price, true)
	end

	----------------------------------------------------------------
	-- Eggs
	----------------------------------------------------------------

	local eggHolder = Theme.New("Frame", {
		Name = "EggRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 250),
		LayoutOrder = 2,
		ZIndex = 32,
		Parent = body,
	}, {
		Theme.List(14, Enum.FillDirection.Horizontal),
	})

	local eggSection = Theme.Panel({
		Parent = eggHolder,
		Name = "MysteryEggs",
		Size = UDim2.new(0.6, -7, 1, 0),
		Radius = 14,
		LayoutOrder = 1,
		ZIndex = 33,
	})

	Theme.SectionHeader({
		Parent = eggSection,
		Text = "MYSTERY EGGS",
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 16),
		ZIndex = 34,
	})

	local eggRow = Theme.New("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 1, -48),
		ZIndex = 34,
		Parent = eggSection,
	}, {
		Theme.List(10, Enum.FillDirection.Horizontal),
	})

	-- An egg drawn from a rounded frame - no imported art anywhere.
	local function eggShape(holder, color, size, position, zIndex)
		local egg = Theme.New("Frame", {
			Name = "Egg",
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Size = size,
			Position = position,
			AnchorPoint = Vector2.new(0.5, 0),
			ZIndex = zIndex,
			Parent = holder,
		}, {
			Theme.Corner(math.floor(size.X.Offset * 0.48)),
			Theme.Stroke(2, Theme.Shade(color, -0.4)),
			Theme.Gradient({ Theme.Shade(color, 0.35), Theme.Shade(color, -0.25) }, 90),
		})
		return egg
	end

	local function buildEggCard(egg, order)
		local card = Theme.Panel({
			Parent = eggRow,
			Name = egg.id,
			Size = UDim2.new(1 / #ShopData.Eggs, -7, 1, 0),
			Color = Theme.CARD,
			Radius = 12,
			StrokeColor = Theme.Shade(egg.color, -0.2),
			LayoutOrder = order,
			ZIndex = 35,
		})

		Theme.Label({
			Parent = card,
			Text = egg.name,
			Font = Theme.BOLD_FONT,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(4, 10),
			Size = UDim2.new(1, -8, 0, 16),
			ZIndex = 36,
		})

		eggShape(card, egg.color, UDim2.fromOffset(52, 66), UDim2.new(0.5, 0, 0, 32), 36)

		Theme.Label({
			Parent = card,
			Text = egg.blurb,
			TextSize = 11,
			TextColor3 = Theme.MUTED,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(8, 102),
			Size = UDim2.new(1, -16, 0, 30),
			ZIndex = 36,
		})

		local reveal = Theme.Button({
			Parent = card,
			Text = "REVEAL",
			Color = egg.color,
			TextColor3 = Theme.ON_GREEN,
			TextSize = 13,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -34),
			Size = UDim2.new(1, -16, 0, 28),
			ZIndex = 36,
		})
		reveal.Activated:Connect(function()
			if reveal:GetAttribute("Enabled") then
				api.OnAction("egg", egg.id)
			end
		end)
		registerOffer(reveal, egg.price, true)

		Theme.Price({
			Parent = card,
			Amount = egg.price,
			TextSize = 13,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -16, 0, 20),
			ZIndex = 36,
		})
	end

	for index, egg in ipairs(ShopData.Eggs) do
		buildEggCard(egg, index)
	end

	----------------------------------------------------------------
	-- Featured egg
	----------------------------------------------------------------

	local featured = ShopData.FeaturedEgg

	local featuredPanel = Theme.Panel({
		Parent = eggHolder,
		Name = "Featured",
		Size = UDim2.new(0.4, -7, 1, 0),
		Color = Color3.fromRGB(46, 34, 12),
		Radius = 14,
		StrokeColor = Theme.GOLD,
		StrokeThickness = 3,
		LayoutOrder = 2,
		ZIndex = 33,
	})

	Theme.Pill({
		Parent = featuredPanel,
		Text = "FEATURED",
		Color = Theme.GOLD,
		Size = UDim2.fromOffset(94, 22),
		Position = UDim2.fromOffset(12, 12),
		ZIndex = 35,
	})

	Theme.Label({
		Parent = featuredPanel,
		Text = featured.name,
		Font = Theme.DISPLAY_FONT,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(252, 214, 122),
		Position = UDim2.fromOffset(12, 42),
		Size = UDim2.new(1, -150, 0, 28),
		ZIndex = 34,
	})

	Theme.Label({
		Parent = featuredPanel,
		Text = featured.blurb,
		TextSize = 12,
		TextColor3 = Theme.MUTED,
		TextWrapped = true,
		Position = UDim2.fromOffset(12, 72),
		Size = UDim2.new(1, -150, 0, 32),
		ZIndex = 34,
	})

	Theme.Pill({
		Parent = featuredPanel,
		Text = featured.tag,
		Color = Color3.fromRGB(206, 154, 46),
		Size = UDim2.fromOffset(96, 20),
		Position = UDim2.fromOffset(12, 108),
		ZIndex = 35,
	})

	eggShape(featuredPanel, featured.color, UDim2.fromOffset(96, 122), UDim2.new(1, -80, 0, 46), 34)

	local featuredButton = Theme.Button({
		Parent = featuredPanel,
		Text = "REVEAL",
		Color = Theme.GOLD,
		Position = UDim2.fromOffset(12, 136),
		Size = UDim2.fromOffset(132, 32),
		ZIndex = 35,
	})
	featuredButton.Activated:Connect(function()
		if featuredButton:GetAttribute("Enabled") then
			api.OnAction("egg", featured.id)
		end
	end)
	registerOffer(featuredButton, featured.price, true)

	Theme.Price({
		Parent = featuredPanel,
		Amount = featured.price,
		TextSize = 14,
		Align = Enum.HorizontalAlignment.Left,
		Position = UDim2.fromOffset(12, 174),
		Size = UDim2.fromOffset(140, 20),
		ZIndex = 35,
	})

	----------------------------------------------------------------
	-- Consumable boosts
	----------------------------------------------------------------

	local boostSection = section("CONSUMABLE BOOSTS", 160, 3)

	local boostRow = Theme.New("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 1, -48),
		ZIndex = 33,
		Parent = boostSection,
	}, {
		Theme.List(10, Enum.FillDirection.Horizontal),
	})

	for index, boost in ipairs(ShopData.Boosts) do
		local card = Theme.Panel({
			Parent = boostRow,
			Name = boost.id,
			Size = UDim2.new(1 / #ShopData.Boosts, -7, 1, 0),
			Color = Theme.CARD,
			Radius = 12,
			StrokeColor = Theme.Shade(boost.color, -0.25),
			LayoutOrder = index,
			ZIndex = 34,
		})

		Theme.Dot({
			Parent = card,
			Size = 22,
			Color = boost.color,
			Position = UDim2.fromOffset(14, 14),
			ZIndex = 35,
		})

		Theme.Label({
			Parent = card,
			Text = boost.name,
			Font = Theme.BOLD_FONT,
			TextSize = 13,
			TextColor3 = boost.color,
			Position = UDim2.fromOffset(44, 12),
			Size = UDim2.new(1, -54, 0, 16),
			ZIndex = 35,
		})

		Theme.Label({
			Parent = card,
			Text = boost.blurb,
			TextSize = 12,
			TextColor3 = Theme.TEXT,
			Position = UDim2.fromOffset(44, 30),
			Size = UDim2.new(1, -54, 0, 16),
			ZIndex = 35,
		})

		Theme.Label({
			Parent = card,
			Text = string.format("Duration: %d Minutes", boost.duration / 60),
			TextSize = 11,
			TextColor3 = Theme.MUTED,
			Position = UDim2.fromOffset(44, 46),
			Size = UDim2.new(1, -54, 0, 14),
			ZIndex = 35,
		})

		local use = Theme.Button({
			Parent = card,
			Text = string.format("USE   %s", Theme.Comma(boost.price)),
			Color = Theme.GREEN,
			TextColor3 = Theme.ON_GREEN,
			TextSize = 14,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.new(1, -24, 0, 30),
			ZIndex = 35,
		})
		use.Activated:Connect(function()
			if use:GetAttribute("Enabled") then
				api.OnAction("boost", boost.id)
			end
		end)
		registerOffer(use, boost.price, false)
	end

	----------------------------------------------------------------
	-- Reveal overlay
	----------------------------------------------------------------

	local revealBackdrop, revealPanel = Theme.Modal({
		Parent = root,
		Name = "Reveal",
		Size = UDim2.fromOffset(340, 400),
		ZIndex = 40,
	})

	local revealClose = Theme.New("TextButton", {
		Name = "Dismiss",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 40,
		Parent = revealBackdrop,
	})

	local revealToken = 0

	function api.Reveal(def)
		if not def then
			return
		end

		-- rebuild the panel contents, leaving its corner and stroke alone
		for _, child in ipairs(revealPanel:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local full = GnomeData.Get(def.id)
		local accent = Theme.RarityColor(def.rarity)
		revealPanel:FindFirstChildOfClass("UIStroke").Color = accent

		Theme.Label({
			Parent = revealPanel,
			Text = "IT HATCHED!",
			Font = Theme.TITLE_FONT,
			TextSize = 22,
			TextColor3 = Theme.GOLD,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 18),
			Size = UDim2.new(1, 0, 0, 28),
			ZIndex = 42,
		})

		if full then
			Theme.GnomePortrait({
				Parent = revealPanel,
				def = full,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 56),
				Size = UDim2.fromOffset(180, 190),
				ZIndex = 42,
			})
		end

		Theme.Label({
			Parent = revealPanel,
			Text = def.name,
			Font = Theme.BOLD_FONT,
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 254),
			Size = UDim2.new(1, 0, 0, 24),
			ZIndex = 42,
		})

		Theme.Pill({
			Parent = revealPanel,
			Text = string.upper(def.rarity),
			Color = accent,
			Size = UDim2.fromOffset(120, 24),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 284),
			ZIndex = 42,
		})

		Theme.Label({
			Parent = revealPanel,
			Text = string.format(
				"%s  -  %d PWR  -  %.1f gold/s",
				def.biome,
				def.power,
				def.production
			),
			TextSize = 13,
			TextColor3 = Theme.MUTED,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 318),
			Size = UDim2.new(1, 0, 0, 18),
			ZIndex = 42,
		})

		Theme.Label({
			Parent = revealPanel,
			Text = "Added to your plot",
			TextSize = 12,
			TextColor3 = Theme.FAINT,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 348),
			Size = UDim2.new(1, 0, 0, 18),
			ZIndex = 42,
		})

		revealBackdrop.Visible = true
		revealToken += 1
		local token = revealToken
		task.delay(6, function()
			if token == revealToken then
				revealBackdrop.Visible = false
			end
		end)
	end

	revealClose.Activated:Connect(function()
		revealToken += 1
		revealBackdrop.Visible = false
	end)

	----------------------------------------------------------------
	-- Stock and refresh
	----------------------------------------------------------------

	local shownRotation = nil

	local function refreshOffers()
		for _, offer in ipairs(offers) do
			local affordable = state.gold >= offer.cost
			local roomy = not offer.needsSlot or state.count < state.capacity

			if not roomy then
				Theme.SetButtonEnabled(offer.button, false, "FULL")
			elseif not affordable then
				Theme.SetButtonEnabled(offer.button, false, "TOO POOR")
			else
				Theme.SetButtonEnabled(offer.button, true)
			end
		end
	end

	local function buildStock(rotationIndex)
		if shownRotation == rotationIndex then
			return
		end
		shownRotation = rotationIndex

		for _, child in ipairs(gnomeRow:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		-- Destroying a card orphans its button, so drop the offers that
		-- went with it. Egg and boost offers live outside gnomeRow and
		-- survive the rotation.
		for index = #offers, 1, -1 do
			if offers[index].button.Parent == nil then
				table.remove(offers, index)
			end
		end

		for index, def in ipairs(ShopData.StockFor(rotationIndex)) do
			buildGnomeCard(def, index)
		end
		refreshOffers()
	end

	function api.SetRotation(rotationIndex)
		buildStock(rotationIndex)
	end

	function api.Update(economy)
		state.gold = economy.gold or 0
		state.count = economy.count or 0
		state.capacity = economy.capacity or ShopData.CAPACITY
		shopGoldLabel.Text = Theme.Comma(state.gold)
		refreshOffers()
	end

	function api.Open()
		root.Visible = true
	end

	function api.Close()
		root.Visible = false
		revealBackdrop.Visible = false
	end

	function api.Toggle()
		if root.Visible then
			api.Close()
		else
			api.Open()
		end
	end

	function api.IsOpen()
		return root.Visible
	end

	back.Activated:Connect(api.Close)

	-- The rotation runs on wall-clock time, so the countdown and the
	-- rebuild can both be driven locally; ShopState is only a nudge.
	task.spawn(function()
		while true do
			timerLabel.Text = Theme.Clock(ShopData.SecondsUntilRotation())
			buildStock(ShopData.RotationIndex())
			task.wait(1)
		end
	end)

	api.Root = root
	return api
end

return ShopScreen
