"""Generic GLB exporter for headless Blender.
Usage:
  blender --background [blendfile] --python export_glb.py -- --out /path/to/out.glb [--only NAME]
If no blendfile is given, exports current scene.
"""
import argparse
import os
import sys

import bpy


def parse_args():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
    else:
        argv = []
    p = argparse.ArgumentParser()
    p.add_argument("--out", required=True, help="output .glb path")
    p.add_argument("--only", default="", help="only export object with this name (optional)")
    return p.parse_args(argv)


def main():
    args = parse_args()
    out = os.path.abspath(args.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)

    if args.only:
        obj = bpy.data.objects.get(args.only)
        if not obj:
            raise SystemExit(f"object not found: {args.only}")
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        use_selection = True
    else:
        use_selection = False

    bpy.ops.export_scene.gltf(
        filepath=out,
        export_format="GLB",
        use_selection=use_selection,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_materials="EXPORT",
    )
    print(f"EXPORT_GLB_OK {out}")


if __name__ == "__main__":
    main()
