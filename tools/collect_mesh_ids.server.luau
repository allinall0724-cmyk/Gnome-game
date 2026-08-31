--!strict
--[[
	Read the MeshId off every imported MeshPart in a place.

	Quick version - paste into Studio's command bar after importing:

		for _,d in ipairs(game:GetDescendants()) do if d:IsA("MeshPart") and d.MeshId ~= "" then print(d.Name.." = "..d.MeshId) end end

	Automated version, once run-in-roblox is in rokit.toml:

		rojo build default.project.json -o build/dev.rbxl
		run-in-roblox --place build/dev.rbxl --script tools/collect_mesh_ids.server.luau

	Studio assigns a real rbxassetid when you import an FBX, and the only place
	that ID exists afterwards is on the MeshPart itself. This walks the
	DataModel, matches MeshParts against the asset names the manifest knows,
	and prints one MESHID line per match.

	Matching is by name, so imported MeshParts must keep the FBX filename -
	Studio names them after the file, so this works unless they get renamed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AssetIds"))

local wanted: { [string]: boolean } = {}
for name in pairs(AssetIds.Meshes) do
	wanted[name] = true
end

local found: { [string]: string } = {}
local extras: { string } = {}

for _, descendant in game:GetDescendants() do
	if not descendant:IsA("MeshPart") then
		continue
	end
	local mesh = descendant :: MeshPart
	if mesh.MeshId == "" then
		continue
	end
	if wanted[mesh.Name] then
		-- first match wins; repeat imports of one file are identical
		if not found[mesh.Name] then
			found[mesh.Name] = mesh.MeshId
		end
	else
		table.insert(extras, string.format("%s (%s)", mesh.Name, mesh.MeshId))
	end
end

for name, id in pairs(found) do
	-- the numeric id is what belongs in assets/manifest.json
	print(string.format("MESHID %s %s", name, (id:gsub("%D", ""))))
end

for name in pairs(wanted) do
	if not found[name] then
		warn(string.format("missing: %s was not found in this place", name))
	end
end

if #extras > 0 then
	print("unmatched MeshParts (renamed, or not one of ours):")
	for _, line in ipairs(extras) do
		print("  " .. line)
	end
end
