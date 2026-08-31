--[[
	Client bootstrap.

	Creates the one ScreenGui, builds the four screens, and wires them to
	the remotes. All drawing lives in the modules; this file only routes
	payloads and forwards player intent back to the server.

	Screens, back to front:
		BattleUi          squad + stage panels, battle overlay
		Hud               gold, weather, boosts, screen buttons
		InventoryScreen   modal
		ShopScreen        full page
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestState = Remotes:WaitForChild("RequestState")
local GnomesUpdated = Remotes:WaitForChild("GnomesUpdated")
local StageState = Remotes:WaitForChild("StageState")
local FightEvent = Remotes:WaitForChild("FightEvent")
local EconomyState = Remotes:WaitForChild("EconomyState")
local ShopState = Remotes:WaitForChild("ShopState")
local ShopAction = Remotes:WaitForChild("ShopAction")
local InventoryAction = Remotes:WaitForChild("InventoryAction")

local Hud = require(script.Hud)
local BattleUi = require(script.BattleUi)
local ShopScreen = require(script.ShopScreen)
local InventoryScreen = require(script.InventoryScreen)

local screen = Instance.new("ScreenGui")
screen.Name = "GnomeGameUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local battle = BattleUi.Create(screen)
local hud = Hud.Create(screen)
local inventory = InventoryScreen.Create(screen)
local shop = ShopScreen.Create(screen)

--------------------------------------------------------------------
-- Screen switching
--------------------------------------------------------------------

-- The shop is a full page rather than a modal, so the resting panels step
-- out of the way while it is up.
local function syncPanels()
	battle.SetPanelsVisible(not shop.IsOpen())
end

hud.ShopButton.Activated:Connect(function()
	if inventory.IsOpen() then
		inventory.Close()
	end
	shop.Toggle()
	syncPanels()
end)

hud.InventoryButton.Activated:Connect(function()
	if shop.IsOpen() then
		shop.Close()
		syncPanels()
	end
	inventory.Toggle()
end)

--------------------------------------------------------------------
-- Player intent out
--------------------------------------------------------------------

shop.OnAction = function(kind, id)
	ShopAction:FireServer({ kind = kind, id = id })
end

inventory.OnSell = function(uids)
	InventoryAction:FireServer({ kind = "sell", uids = uids })
end

--------------------------------------------------------------------
-- Server state in
--------------------------------------------------------------------

GnomesUpdated.OnClientEvent:Connect(function(data)
	battle.SetSquad(data)
end)

StageState.OnClientEvent:Connect(function(state)
	battle.SetStage(state)
end)

FightEvent.OnClientEvent:Connect(function(payload)
	battle.Fight(payload)
end)

EconomyState.OnClientEvent:Connect(function(state)
	hud.Update(state)
	shop.Update(state)
	inventory.Update(state)

	if state.notice then
		hud.Notice(state.notice)
	end
	if state.reveal then
		shop.Reveal(state.reveal)
	end
end)

ShopState.OnClientEvent:Connect(function(state)
	shop.SetRotation(state.rotationIndex)
end)

-- Ask for state once the listeners above are connected, which avoids the
-- race where PlayerAdded fires before this script is ready.
RequestState:FireServer()

syncPanels()
