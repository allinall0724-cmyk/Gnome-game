#!/usr/bin/env python3
"""Generate src/shared/AssetIds.luau from assets/manifest.json.

Run after uploading any mesh and pasting its ID into the manifest:

    py tools/gen_asset_ids.py

Never hand-edit the generated module.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "assets" / "manifest.json"
OUT = ROOT / "src" / "shared" / "AssetIds.luau"

HEADER = """--!strict
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

"""

FOOTER = """
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
"""


def main() -> int:
    if not MANIFEST.exists():
        print(f"missing manifest: {MANIFEST}", file=sys.stderr)
        return 1

    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = data.get("assets", {})
    if not assets:
        print("manifest has no assets", file=sys.stderr)
        return 1

    lines = [HEADER, "AssetIds.Meshes = {\n"]
    pending = []
    for key in sorted(assets):
        entry = assets[key]
        asset_id = int(entry.get("id", 0) or 0)
        size = entry.get("size") or [1, 1, 1]
        tris = entry.get("tris", 0)
        if asset_id == 0:
            pending.append(key)
        lines.append(
            f"\t{key} = {{\n"
            f"\t\tid = {asset_id},\n"
            f"\t\tsize = Vector3.new({size[0]}, {size[1]}, {size[2]}),\n"
            f"\t\ttris = {tris},\n"
            f"\t}},\n"
        )
    lines.append("}\n")
    lines.append(FOOTER)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("".join(lines), encoding="utf-8")

    print(f"wrote {OUT.relative_to(ROOT)} ({len(assets)} assets)")
    if pending:
        print("\nNOT UPLOADED YET (id = 0), still using part fallback:")
        for key in pending:
            print(f"  {key:<14} assets/exports/{key}.fbx")
        print(
            "\nTo upload: Studio -> Avatar tab -> 3D Importer -> pick the .fbx,\n"
            "then copy the MeshPart's MeshId number into assets/manifest.json\n"
            "and re-run this script."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
