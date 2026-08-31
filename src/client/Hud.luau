--[[
	Hud
	The always-on strip across the top: gold and production rate on the
	left, the live weather banner in the middle, and the buttons that open
	the Shop and the Inventory on the right. Active consumable boosts hang
	under the gold card as countdown pills.

	The gold figure counts up locally between server pushes so it reads as
	a live ticker, but it snaps to the server's number every time one
	arrives - the client never decides what the balance is.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))

local Hud = {}

function Hud.Create(parent)
	local api = {}

	local root = Theme.New("Frame", {
		Name = "Hud",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = parent,
	})

	----------------------------------------------------------------
	-- Gold card
	----------------------------------------------------------------

	local goldCard = Theme.Panel({
		Parent = root,
		Name = "Gold",
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(212, 68),
		Radius = 14,
		StrokeColor = Theme.Shade(Theme.GOLD, -0.5),
		ZIndex = 6,
	})

	Theme.Dot({
		Parent = goldCard,
		Size = 30,
		Color = Theme.GOLD,
		Position = UDim2.fromOffset(14, 19),
		ZIndex = 7,
	})

	local goldLabel = Theme.Label({
		Parent = goldCard,
		Text = "0",
		Font = Theme.TITLE_FONT,
		TextSize = 24,
		TextColor3 = Theme.TEXT,
		Position = UDim2.fromOffset(54, 10),
		Size = UDim2.new(1, -66, 0, 28),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	})

	local rateLabel = Theme.Label({
		Parent = goldCard,
		Text = "0/s",
		Font = Theme.BOLD_FONT,
		TextSize = 13,
		TextColor3 = Theme.GREEN,
		Position = UDim2.fromOffset(54, 38),
		Size = UDim2.new(1, -66, 0, 18),
		ZIndex = 7,
	})

	----------------------------------------------------------------
	-- Active boost pills
	----------------------------------------------------------------

	local boostStrip = Theme.New("Frame", {
		Name = "Boosts",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 92),
		Size = UDim2.fromOffset(212, 24),
		ZIndex = 6,
		Parent = root,
	}, {
		Theme.List(6, Enum.FillDirection.Horizontal),
	})

	----------------------------------------------------------------
	-- Weather banner
	----------------------------------------------------------------

	local weatherCard = Theme.Panel({
		Parent = root,
		Name = "Weather",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(400, 56),
		Radius = 14,
		ZIndex = 6,
	})

	local weatherDot = Theme.Dot({
		Parent = weatherCard,
		Size = 18,
		Color = Theme.MUTED,
		Position = UDim2.fromOffset(16, 19),
		ZIndex = 7,
	})

	local weatherName = Theme.Label({
		Parent = weatherCard,
		Text = "CLEAR SKIES",
		Font = Theme.BOLD_FONT,
		TextSize = 15,
		Position = UDim2.fromOffset(44, 9),
		Size = UDim2.new(1, -140, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	})

	local weatherBlurb = Theme.Label({
		Parent = weatherCard,
		Text = "No event running",
		TextSize = 12,
		TextColor3 = Theme.MUTED,
		Position = UDim2.fromOffset(44, 29),
		Size = UDim2.new(1, -140, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	})

	local weatherClock = Theme.Label({
		Parent = weatherCard,
		Text = "",
		Font = Theme.BOLD_FONT,
		TextSize = 15,
		TextColor3 = Theme.GOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(80, 20),
		ZIndex = 7,
	})

	----------------------------------------------------------------
	-- Screen buttons
	----------------------------------------------------------------

	local buttonRow = Theme.New("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(232, 56),
		ZIndex = 6,
		Parent = root,
	}, {
		Theme.List(10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right),
	})

	local function screenButton(text, color, order)
		local button = Theme.Button({
			Parent = buttonRow,
			Name = text,
			Text = text,
			Color = color,
			TextColor3 = Theme.ON_GREEN,
			TextSize = 15,
			Size = UDim2.fromOffset(110, 56),
			Radius = 14,
			LayoutOrder = order,
			ZIndex = 7,
		})
		return button
	end

	api.InventoryButton = screenButton("INVENTORY", Color3.fromRGB(58, 74, 100), 0)
	api.ShopButton = screenButton("SHOP", Theme.Shade(Theme.GOLD, -0.28), 1)
	api.ShopButton.TextColor3 = Theme.ON_GOLD

	----------------------------------------------------------------
	-- Toast
	----------------------------------------------------------------

	local toast = Theme.Panel({
		Parent = root,
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		Size = UDim2.fromOffset(460, 46),
		Radius = 12,
		Visible = false,
		ZIndex = 60,
	})

	local toastLabel = Theme.Label({
		Parent = toast,
		Text = "",
		Font = Theme.BOLD_FONT,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 61,
	})

	local toastToken = 0

	function api.Notice(notice)
		if not notice or not notice.text then
			return
		end

		toastToken += 1
		local token = toastToken

		local tone = notice.tone == "bad" and Theme.RED or Theme.GREEN
		toastLabel.Text = notice.text
		toastLabel.TextColor3 = tone
		toast:FindFirstChildOfClass("UIStroke").Color = tone
		toast.Visible = true
		toast.BackgroundTransparency = 0

		task.delay(3, function()
			if token == toastToken then
				toast.Visible = false
			end
		end)
	end

	----------------------------------------------------------------
	-- Updates
	----------------------------------------------------------------

	local displayGold = 0
	local targetGold = 0
	local rate = 0
	local weatherList = {}
	local boostList = {}
	local lastPush = os.clock()

	local function renderWeather()
		local top = weatherList[1]
		if not top then
			weatherDot.BackgroundColor3 = Theme.MUTED
			weatherName.Text = "CLEAR SKIES"
			weatherBlurb.Text = "No event running"
			weatherClock.Text = ""
			return
		end

		local elapsed = os.clock() - lastPush
		weatherDot.BackgroundColor3 = top.color
		weatherName.Text = top.name
		weatherClock.Text = Theme.Clock(top.remaining - elapsed)

		if #weatherList > 1 then
			weatherBlurb.Text = string.format("%s  (+%d more)", top.blurb, #weatherList - 1)
		else
			weatherBlurb.Text = top.blurb
		end
	end

	-- Pills are rebuilt only when the set of active boosts changes; their
	-- countdown text is refreshed in place each frame.
	local boostPills = {}

	local function boostSignature()
		local parts = {}
		for _, boost in ipairs(boostList) do
			table.insert(parts, boost.id)
		end
		return table.concat(parts, "|")
	end

	local pillSignature = ""

	local function rebuildBoostPills()
		for _, child in ipairs(boostStrip:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		table.clear(boostPills)

		for index, boost in ipairs(boostList) do
			local pill = Theme.Pill({
				Parent = boostStrip,
				Text = "",
				Color = boost.color,
				Size = UDim2.fromOffset(100, 22),
				LayoutOrder = index,
				ZIndex = 7,
			})
			boostPills[index] = pill:FindFirstChildOfClass("TextLabel")
		end
	end

	local function renderBoosts()
		local signature = boostSignature()
		if signature ~= pillSignature then
			pillSignature = signature
			rebuildBoostPills()
		end

		local elapsed = os.clock() - lastPush
		for index, boost in ipairs(boostList) do
			local label = boostPills[index]
			if label then
				label.Text = string.format(
					"%s %s",
					string.upper(boost.kind),
					Theme.Clock(boost.remaining - elapsed)
				)
			end
		end
	end

	--[[
		Applies a server push. gold is authoritative; rate is what the
		local ticker uses to fill in the gaps between pushes.
	]]
	function api.Update(state)
		targetGold = state.gold
		rate = state.rate or 0
		weatherList = state.weather or {}
		boostList = state.boosts or {}
		lastPush = os.clock()

		-- a big jump (a purchase, a sale) should land instantly rather
		-- than being counted up to
		if math.abs(targetGold - displayGold) > math.max(50, rate * 3) then
			displayGold = targetGold
		end

		rateLabel.Text = string.format("+%s", Theme.Rate(rate))
		renderWeather()
		renderBoosts()
	end

	RunService.RenderStepped:Connect(function(delta)
		displayGold += rate * delta
		-- drift back toward the server figure without a visible snap
		displayGold += (targetGold - displayGold) * math.min(1, delta * 2)
		goldLabel.Text = Theme.Comma(displayGold)

		if weatherList[1] or boostList[1] then
			renderWeather()
			renderBoosts()
		end
	end)

	api.Root = root
	return api
end

return Hud
