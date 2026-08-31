--[[
	Layout
	Where things stand in the world. Shared because the server places the
	models here and the client animates them between these same poses.
]]

local Layout = {}

Layout.PLOT_SLOTS = {
	Vector3.new(-5, 0.5, 2),
	Vector3.new(0, 0.5, 2),
	Vector3.new(5, 0.5, 2),
}

-- Where the gnomes line up when a gate fight starts.
Layout.ARENA_SLOTS = {
	Vector3.new(-4.5, 0.3, 38),
	Vector3.new(0, 0.3, 38),
	Vector3.new(4.5, 0.3, 38),
}

Layout.ENEMY_POSITION = Vector3.new(0, 0.3, 46)

-- Models are built facing -Z. On the plot that faces the spawn point; in the
-- arena they need to turn around to face the creature.
Layout.PLOT_FACING = CFrame.new()
Layout.ARENA_FACING = CFrame.Angles(0, math.pi, 0)

function Layout.PlotPose(index)
	local slot = Layout.PLOT_SLOTS[index]
	if not slot then
		return nil
	end
	return CFrame.new(slot) * Layout.PLOT_FACING
end

function Layout.ArenaPose(index)
	local slot = Layout.ARENA_SLOTS[index]
	if not slot then
		return nil
	end
	return CFrame.new(slot) * Layout.ARENA_FACING
end

return Layout
