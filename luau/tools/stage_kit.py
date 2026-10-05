#!/usr/bin/env python3
r"""stage_kit.py -- copy the scripting kit into the game folders as GameLuau (the editor copies it into each
user's Documents\GameScripts on launch). Usage: python tools/stage_kit.py <game root> [<game root> ...]"""
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
READY = {"07_light_switch.luau": "LightSwitch.luau", "08_vanishing_platform.luau": "VanishingPlatform.luau",
         "09_blinker.luau": "Blinker.luau", "10_secret_door.luau": "SecretDoor.luau"}


def stage(game_root: str) -> None:
    kit = os.path.join(game_root, "GameLuau")
    os.makedirs(kit, exist_ok=True)
    for f in ("README.md", "GAMEMODES.md", "Luau-Guide.pdf", "Quest-Guide.pdf", "GameModes-Guide.pdf",
              "MCP-Guide.pdf", ".luaurc"):
        src = os.path.join(ROOT, f)
        if os.path.exists(src):                       # PDFs are built, not tracked: python tools/build_guide.py
            shutil.copy2(src, os.path.join(kit, f))
    for d in ("types", "examples", ".vscode", "levels", "mcp", "doc-images", "tools"):
        shutil.copytree(os.path.join(ROOT, d), os.path.join(kit, d), dirs_exist_ok=True)
    shutil.copytree(os.path.join(ROOT, "vendor"), os.path.join(kit, "tools"), dirs_exist_ok=True)   # Luau binaries (see vendor/README.md)
    for src, dst in READY.items():                          # ready-to-attach copies at the top level
        shutil.copy2(os.path.join(ROOT, "examples", src), os.path.join(kit, dst))
    print("staged", kit)


if __name__ == "__main__":
    for r in sys.argv[1:]:
        stage(r)
