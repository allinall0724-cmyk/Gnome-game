--[[
	ShopService
	The rotating shop's server half: it owns the rotation clock and
	validates every purchase.

	The stock itself is not broadcast. ShopData.StockFor(rotationIndex) is
	deterministic and ShopData lives in ReplicatedStorage, so the client
	derives the same four gnomes on its own. ShopState only carries the
	rotation index, which tells the client when to rebuild. The server
	still recomputes the stock for itself on every purchase - a client
	asking to buy something that is not actually in stock is rejected.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GnomeData = require(Shared:WaitForChild("GnomeData"))
local ShopData = require(Shared:WaitForChild("ShopData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopState = Remotes:WaitForChild("ShopState")
local ShopAction = Remotes:WaitForChild("ShopAction")
local InventoryAction = Remotes:WaitForChild("InventoryAction")

local Economy = require(script.Parent.Economy)

local ShopService = {}

ShopService.ACTION_COOLDOWN = 0.15 -- cheap guard against a spamming client

local lastAction = {} -- [player] = os.clock() of last accepted action
local started = false

local function notice(text, tone)
	return { text = text, tone = tone or "good" }
end

local function throttled(player)
	local now = os.clock()
	local previous = lastAction[player]
	if previous and now - previous < ShopService.ACTION_COOLDOWN then
		return true
	end
	lastAction[player] = now
	return false
end

function ShopService.Push(player)
	ShopState:FireClient(player, {
		rotationIndex = ShopData.RotationIndex(),
		secondsLeft = ShopData.SecondsUntilRotation(),
	})
end

local function pushAll()
	for _, player in ipairs(Players:GetPlayers()) do
		ShopService.Push(player)
	end
end

--------------------------------------------------------------------
-- Purchases
--------------------------------------------------------------------

local function inCurrentStock(gnomeId)
	for _, def in ipairs(ShopData.StockFor(ShopData.RotationIndex())) do
		if def.id == gnomeId then
			return def
		end
	end
	return nil
end

local function buyGnome(player, gnomeId)
	local def = inCurrentStock(gnomeId)
	if not def then
		return notice("That gnome is no longer in stock.", "bad")
	end
	if not def.price then
		return notice("That gnome is not for sale.", "bad")
	end
	if Economy.IsFull(player) then
		return notice("Your plot is full. Sell a gnome first.", "bad")
	end
	if not Economy.CanAfford(player, def.price) then
		return notice("Not enough gold.", "bad")
	end

	Economy.Spend(player, def.price)
	Economy.AddGnome(player, def.id)
	return notice(string.format("%s joined your plot!", def.name), "good"), nil
end

local function buyEgg(player, eggId)
	local egg = ShopData.GetEgg(eggId)
	if not egg then
		return notice("Unknown egg.", "bad")
	end
	if Economy.IsFull(player) then
		return notice("Your plot is full. Sell a gnome first.", "bad")
	end
	if not Economy.CanAfford(player, egg.price) then
		return notice("Not enough gold.", "bad")
	end

	Economy.Spend(player, egg.price)

	-- luck is a multiplier; the roll wants the bonus part of it
	local luck = Economy.Multiplier(player, "luck") - 1
	local def = ShopData.RollEgg(egg, luck)

	Economy.AddGnome(player, def.id)
	return notice(string.format("%s hatched a %s!", egg.name, def.rarity), "good"), def
end

local function buyBoost(player, boostId)
	local boost = ShopData.GetBoost(boostId)
	if not boost then
		return notice("Unknown boost.", "bad")
	end
	if not Economy.CanAfford(player, boost.price) then
		return notice("Not enough gold.", "bad")
	end

	Economy.Spend(player, boost.price)
	Economy.ApplyBoost(player, boost)
	return notice(
		string.format("%s active for %d minutes.", boost.name, boost.duration / 60),
		"good"
	)
end

--------------------------------------------------------------------
-- Wiring
--------------------------------------------------------------------

function ShopService.Start()
	if started then
		return
	end
	started = true

	ShopAction.OnServerEvent:Connect(function(player, request)
		if type(request) ~= "table" or throttled(player) then
			return
		end

		local kind, id = request.kind, request.id
		if type(kind) ~= "string" or type(id) ~= "string" then
			return
		end

		-- Each inventory card renders a live gnome model, so resending the
		-- list is expensive for the client. Only do it when the purchase
		-- actually changed what the player owns - a boost, or a rejected
		-- purchase, leaves the collection alone.
		local before = Economy.Count(player)

		local result, reveal
		if kind == "gnome" then
			result, reveal = buyGnome(player, id)
		elseif kind == "egg" then
			result, reveal = buyEgg(player, id)
		elseif kind == "boost" then
			result = buyBoost(player, id)
		else
			return
		end

		Economy.Push(player, {
			gnomes = Economy.Count(player) ~= before,
			notice = result,
			reveal = reveal,
		})
	end)

	InventoryAction.OnServerEvent:Connect(function(player, request)
		if type(request) ~= "table" or throttled(player) then
			return
		end
		if request.kind ~= "sell" or type(request.uids) ~= "table" then
			return
		end

		--[[
			Refuse a sale that would empty the plot. With no gnomes the
			player produces nothing, so if their gold is under the price
			of the cheapest gnome they could never buy their way back -
			an unrecoverable state reachable in two clicks.
		]]
		local owned = {}
		for _, gnome in ipairs(Economy.GnomeList(player)) do
			owned[gnome.uid] = true
		end

		local wanted = {}
		local matching = 0
		for _, uid in ipairs(request.uids) do
			if type(uid) == "number" and owned[uid] and not wanted[uid] then
				wanted[uid] = true
				matching += 1
			end
		end

		if matching > 0 and matching >= Economy.Count(player) then
			Economy.Push(player, {
				notice = notice("You must keep at least one gnome.", "bad"),
			})
			return
		end

		local earned, sold = Economy.SellGnomes(player, request.uids)
		if sold == 0 then
			Economy.Push(player, { notice = notice("Nothing was sold.", "bad") })
			return
		end

		Economy.PushFull(player, {
			notice = notice(
				string.format("Sold %d gnome%s for %d gold.", sold, sold == 1 and "" or "s", earned),
				"good"
			),
		})
	end)

	-- Nudge every client when the rotation flips so the shop rebuilds.
	task.spawn(function()
		local lastIndex = ShopData.RotationIndex()
		while true do
			task.wait(1)
			local index = ShopData.RotationIndex()
			if index ~= lastIndex then
				lastIndex = index
				pushAll()
			end
		end
	end)
end

-- Handy for the bootstrap and for anything that needs the roster.
function ShopService.CurrentStock()
	return ShopData.StockFor(ShopData.RotationIndex())
end

ShopService.GnomeData = GnomeData

Players.PlayerRemoving:Connect(function(player)
	lastAction[player] = nil
end)

return ShopService
