"""Procedural gnome + creature asset builder.

Run headless:

    blender --background --python tools/blender/build_gnome.py -- <key>
    blender --background --python tools/blender/build_gnome.py -- all

Produces, per asset:
    assets/blender/<key>.blend
    assets/exports/<key>.fbx        (Y up, -Z forward, i.e. Roblox axes)

Why the gnome is split into several meshes rather than one:

A mesh carries a single material, and a MeshPart with no texture can be tinted
with its Color property. Splitting the gnome by colour region therefore gives
one MeshPart per region, each tintable per gnome, which is how the three
biome variants share one set of uploads and differ only by tunic colour.

Built in Blender coordinates: Z up, -Y forward. That maps to Roblox Y up,
-Z forward on export, which is the direction the models already face. A Roblox
point (x, y, z) is written here as (x, z, y).

Everything sits with its base at z = 0 so the origin is the base centre, which
means a MeshPart dropped at a plot slot stands on the ground with no offset.
"""

import json
import math
import os
import sys

import bmesh
import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BLEND_DIR = os.path.join(ROOT, "assets", "blender")
EXPORT_DIR = os.path.join(ROOT, "assets", "exports")
MANIFEST = os.path.join(ROOT, "assets", "manifest.json")

# Triangle ceilings. These are small props seen at a distance; blowing past
# these means the shape got more detailed than it needs to be.
BUDGET = 2500

# Segment counts. Low enough to stay cheap, high enough that a cone silhouette
# reads as round rather than faceted.
SEG = 20
RING = 10


# --- primitive helpers -------------------------------------------------------


def _sphere(d, x, y, z):
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=d / 2.0, segments=SEG, ring_count=RING, location=(x, y, z)
    )
    return bpy.context.active_object


def _cone(r1, r2, height, x, y, z):
    """Cone with its BASE at z, growing upward."""
    bpy.ops.mesh.primitive_cone_add(
        radius1=r1,
        radius2=r2,
        depth=height,
        vertices=SEG,
        location=(x, y, z + height / 2.0),
    )
    return bpy.context.active_object


def _cylinder(r, height, x, y, z, rot=(0.0, 0.0, 0.0)):
    """Cylinder centred on z."""
    bpy.ops.mesh.primitive_cylinder_add(
        radius=r, depth=height, vertices=SEG, location=(x, y, z), rotation=rot
    )
    return bpy.context.active_object


def _cube(sx, sy, sz, x, y, z, rot=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, y, z), rotation=rot)
    obj = bpy.context.active_object
    obj.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return obj


# --- assembly ----------------------------------------------------------------


def _clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.objects):
        for item in list(block):
            if item.users == 0:
                block.remove(item)


def _join(objs, name):
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    for obj in objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name
    return obj


def _finish(obj, name, colour):
    """One material, welded verts, smooth shading, UVs, origin at base centre."""
    mesh = obj.data

    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0008)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    mesh.materials.clear()
    mat = bpy.data.materials.new(name=f"{name}_mat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = colour
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = 0.85
    mesh.materials.append(mat)

    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    bpy.ops.object.shade_smooth()
    if hasattr(mesh, "use_auto_smooth"):
        mesh.use_auto_smooth = True

    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")

    # origin to the centre of the footprint, at the lowest point
    lo = min((obj.matrix_world @ v.co).z for v in mesh.vertices)
    xs = [(obj.matrix_world @ v.co).x for v in mesh.vertices]
    ys = [(obj.matrix_world @ v.co).y for v in mesh.vertices]
    cx = (min(xs) + max(xs)) / 2.0
    cy = (min(ys) + max(ys)) / 2.0
    bpy.context.scene.cursor.location = (cx, cy, lo)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    # Each mesh is modelled at its final position in the assembly, but the
    # origin has to sit at its own base for the mesh to be usable on its own.
    # Zeroing the location here would throw that placement away and leave every
    # piece stacked at the ground, so the offset is recorded and reapplied in
    # Roblox instead. Blender (x, y, z) -> Roblox (x, z, y).
    origin = (round(cx, 4), round(lo, 4), round(cy, 4))

    obj.location = (0.0, 0.0, 0.0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    tris = len(mesh.polygons)
    if tris > BUDGET:
        raise SystemExit(f"{name}: {tris} tris exceeds budget {BUDGET}")
    return tris, origin


# --- the assets --------------------------------------------------------------
# Coordinates mirror src/shared/GnomeBuilder.luau, with Roblox (x, y, z)
# written as Blender (x, z, y).


def build_gnome_hat():
    brim = _cylinder(0.92, 0.16, 0.0, 0.0, 2.46)
    cone = _cone(0.84, 0.03, 1.5, 0.0, 0.0, 2.44)
    return _join([brim, cone], "gnome_hat")


def build_gnome_body():
    tunic = _cone(0.92, 0.46, 1.0, 0.0, 0.0, 0.36)
    parts = [tunic]
    for side in (-1, 1):
        arm = _cylinder(
            0.18, 0.7, side * 0.76, 0.0, 1.0, rot=(0.0, math.pi / 2 + side * 0.3, 0.0)
        )
        parts.append(arm)
    return _join(parts, "gnome_body")


def build_gnome_skin():
    head = _sphere(1.34, 0.0, 0.0, 1.92)
    nose = _sphere(0.46, 0.0, -0.62, 1.84)
    parts = [head, nose]
    for side in (-1, 1):
        parts.append(_sphere(0.42, side * 0.92, 0.0, 0.66))
    return _join(parts, "gnome_skin")


def build_gnome_beard():
    # cone pointing down: base at the top, tip below
    beard = _cone(0.03, 0.56, 0.85, 0.0, -0.22, 0.75)
    parts = [beard]
    pom = _sphere(0.34, 0.0, 0.0, 3.98)
    parts.append(pom)
    for side in (-1, 1):
        parts.append(
            _cube(0.42, 0.16, 0.12, side * 0.3, -0.54, 2.44, rot=(0.0, side * 0.28, 0.0))
        )
    return _join(parts, "gnome_beard")


def build_gnome_boots():
    parts = []
    for side in (-1, 1):
        parts.append(_sphere(0.72, side * 0.38, -0.12, 0.3))
    parts.append(_cylinder(0.7, 0.2, 0.0, 0.0, 0.86))
    parts.append(_cube(0.3, 0.14, 0.26, 0.0, -0.66, 0.86))
    return _join(parts, "gnome_boots")


def build_creature():
    body = _sphere(3.4, 0.0, 0.0, 2.5)
    parts = [body, _sphere(2.4, 0.0, -0.4, 3.5)]
    for side in (-1, 1):
        parts.append(_cylinder(0.42, 1.1, side * 0.8, 0.0, 0.55))
        parts.append(_cube(1.0, 1.4, 0.35, side * 0.8, -0.2, 0.17))
        parts.append(
            _cylinder(
                0.35, 2.2, side * 1.9, 0.0, 2.4, rot=(0.0, math.pi / 2 + side * 0.5, 0.0)
            )
        )
    for x, y, h, r in (
        (0.0, 0.9, 1.9, 0.4),
        (-1.0, 0.6, 1.5, 0.34),
        (1.0, 0.6, 1.5, 0.34),
        (-0.6, 1.2, 1.1, 0.3),
        (0.6, 1.2, 1.1, 0.3),
    ):
        parts.append(_cone(r, 0.03, h, x, y, 3.4))
    return _join(parts, "creature")


ASSETS = {
    "gnome_hat": (build_gnome_hat, (0.93, 0.27, 0.27, 1.0)),
    "gnome_body": (build_gnome_body, (0.36, 0.78, 0.38, 1.0)),
    "gnome_skin": (build_gnome_skin, (1.0, 0.82, 0.67, 1.0)),
    "gnome_beard": (build_gnome_beard, (0.99, 0.99, 0.98, 1.0)),
    "gnome_boots": (build_gnome_boots, (0.55, 0.35, 0.2, 1.0)),
    "creature": (build_creature, (0.48, 0.84, 0.36, 1.0)),
}


def build(key):
    fn, colour = ASSETS[key]
    _clear()
    obj = fn()
    tris, origin = _finish(obj, key, colour)

    os.makedirs(BLEND_DIR, exist_ok=True)
    os.makedirs(EXPORT_DIR, exist_ok=True)

    blend_path = os.path.join(BLEND_DIR, f"{key}.blend")
    fbx_path = os.path.join(EXPORT_DIR, f"{key}.fbx")

    bpy.ops.wm.save_as_mainfile(filepath=blend_path)

    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(
        filepath=fbx_path,
        use_selection=True,
        apply_unit_scale=True,
        global_scale=1.0,
        axis_forward="-Z",
        axis_up="Y",
        object_types={"MESH"},
        mesh_smooth_type="FACE",
        use_mesh_modifiers=True,
        bake_space_transform=True,
        path_mode="COPY",
    )

    dims = obj.dimensions
    print(f"[built] {key}: {tris} tris, dims {dims.x:.2f} x {dims.y:.2f} x {dims.z:.2f}")
    return {
        "key": key,
        "tris": tris,
        # reported in Roblox axes: blender (x, y, z) -> roblox (x, z, y)
        "size": [round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)],
        # base-centre of this piece within the assembly, Roblox axes
        "origin": [origin[0], origin[1], origin[2]],
        "source": f"assets/blender/{key}.blend",
        "export": f"assets/exports/{key}.fbx",
    }


def main():
    argv = sys.argv
    args = argv[argv.index("--") + 1 :] if "--" in argv else []
    if not args:
        raise SystemExit("usage: build_gnome.py -- <key|all>")

    keys = list(ASSETS) if args[0] == "all" else [args[0]]
    for key in keys:
        if key not in ASSETS:
            raise SystemExit(f"unknown asset '{key}'; known: {', '.join(ASSETS)}")

    results = [build(key) for key in keys]

    existing = {"_comment": "", "assets": {}}
    if os.path.exists(MANIFEST):
        with open(MANIFEST, "r", encoding="utf-8") as fh:
            existing = json.load(fh)
    existing.setdefault("assets", {})
    existing["_comment"] = (
        "Logical asset name -> uploaded Roblox asset ID. Import the FBX in "
        "Studio's 3D Importer, copy the resulting MeshId, and paste it here."
    )
    for res in results:
        entry = existing["assets"].get(res["key"], {})
        entry.update(
            {
                "id": entry.get("id", 0),
                "source": res["source"],
                "export": res["export"],
                "tris": res["tris"],
                "size": res["size"],
                "origin": res["origin"],
            }
        )
        existing["assets"][res["key"]] = entry

    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    with open(MANIFEST, "w", encoding="utf-8") as fh:
        json.dump(existing, fh, indent=2)
        fh.write("\n")
    print(f"[manifest] {MANIFEST}")


main()
