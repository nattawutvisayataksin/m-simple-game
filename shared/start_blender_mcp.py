# Blender service helper: enable MCP addon + start its socket server (port 9876)
# Run: blender.exe --background --python start_blender_mcp.py
import addon_utils

addon_utils.enable("blender_mcp", default_set=True, persistent=True)

import bpy

scene = bpy.context.scene
scene.blendermcp_auto_start_server = True

try:
    bpy.ops.blendermcp.start_server()
    print("BLENDERMCP_SERVER_ON")
except Exception as e:
    print("BLENDERMCP_SERVER_FAIL", e)
