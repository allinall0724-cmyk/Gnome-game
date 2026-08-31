--!strict
-- GENERATED FILE - DO NOT EDIT BY HAND.
-- Source: assets/manifest.json (meshes built by tools/blender/build_gnome.py)
-- Regenerate: py tools/gen_asset_ids.py

--[[
	Uploaded mesh IDs, and the true size each mesh was modelled at.

	An id of 0 means "not uploaded yet". GnomeBuilder checks for that and falls
	back to building the model out of plain parts, so the game keeps working
	before the meshes have been through Studio's 3D Importer.

	Sizes are recorded here because a MeshPart's natural Size is not the size
	the mesh was modelled at - Studio's importer applies its own scale - so
	anything sizing a MeshPart from mesh.Size comes out wrong.
]]

local AssetIds = {}

AssetIds.Meshes = {
	creature = {
		id = 0,
		size = Vector3.new(6.066, 5.305, 3.4),
		origin = Vector3.new(0.0, -0.005, 0.0),
		tris = 1428,
	},
	gnome_beard = {
		id = 0,
		size = Vector3.new(1.12, 3.4, 1.12),
		origin = Vector3.new(0.0, 0.75, -0.22),
		tris = 460,
	},
	gnome_body = {
		id = 0,
		size = Vector3.new(2.295, 1.0, 1.84),
		origin = Vector3.new(0.0, 0.36, 0.0),
		tris = 228,
	},
	gnome_boots = {
		id = 0,
		size = Vector3.new(1.48, 1.05, 1.43),
		origin = Vector3.new(-0.0, -0.06, -0.015),
		tris = 808,
	},
	gnome_hat = {
		id = 0,
		size = Vector3.new(1.84, 1.56, 1.84),
		origin = Vector3.new(0.0, 2.38, 0.0),
		tris = 152,
	},
	gnome_skin = {
		id = 0,
		size = Vector3.new(2.26, 2.14, 1.52),
		origin = Vector3.new(0.0, 0.45, -0.09),
		tris = 1440,
	},
}

-- True if every listed asset has a real uploaded id.
function AssetIds.Ready(keys: { string }): boolean
	for _, key in ipairs(keys) do
		local entry = AssetIds.Meshes[key]
		if not entry or entry.id == 0 then
			return false
		end
	end
	return true
end

function AssetIds.MeshId(key: string): string?
	local entry = AssetIds.Meshes[key]
	if not entry or entry.id == 0 then
		return nil
	end
	return "rbxassetid://" .. tostring(entry.id)
end

return AssetIds
