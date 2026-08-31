--[[
	Stages
	The Evolution Gate road. Only the first gate exists so far; fights are
	auto-resolved from total gnome power vs. the gate's creature.
]]

local Stages = {}

Stages.TICK = 0.6 -- seconds per combat exchange
Stages.VARIANCE = 0.15 -- +/- damage roll per exchange, so fights aren't identical
Stages.LOSS_COOLDOWN = 180 -- design doc: losing sends you back with a 3 minute lockout

Stages.List = {
	{
		index = 1,
		name = "Stage 1 - The Mossy Gate",
		enemyName = "Thistle Sprite",
		enemyHealth = 260,
		enemyPower = 18,
		blurb = "A bramble creature squats in the first gate. Beat it to open the road.",
	},
}

function Stages.Get(index)
	return Stages.List[index]
end

return Stages
