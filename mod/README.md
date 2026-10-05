# mod/ (the editor DLL)

Builds `dsound.dll`: a `dsound` ordinal proxy (the game exe statically imports it, so
we load at process start) plus the Spec Editor. One command, no IDE needed:

```powershell
cd mod
.\build.ps1          # dev build -> mod\dsound.dll
.\build.ps1 -Rift    # published build -> mod\rift\dsound.dll (needs eosredirect\ + GAME_EOS)
```

Needs: VS 2022 C++ toolset, `ThirdParty\imgui` (1.91.5, untracked),
`ThirdParty\MinHook` (untracked source), and your game's Dumper-7 SDK dump --
either at `gamesdk\YOUR_BUILD` or via `$env:GAME_SDK`. Missing pieces fail with an
explicit message before compiling.

## Files

| File | Role |
|---|---|
| `dllmain.cpp` | Entry: proxy init, window wait, hook install |
| `se_core.h` | Shared spine: snapshot + command queue (render/game thread contract) |
| `se_orion_build.h` | Orion-compatible build config: the only place for exe addresses/offsets |
| `se_render.cpp` | D3D12 `Present` hook, ImGui frame, input ownership, screenshots |
| `se_ui.cpp` | Menu bar, Place Actors, Outliner, Details, Levels, Game Modes, gizmo |
| `se_game.cpp` | `ProcessEvent` pump: discovery, command dispatch, replication, tests |
| `se_mcp_net.cpp` / `se_mcp_bridge.inc` | Loopback bridge for `luau/mcp/game_mcp.py` |
| `se_reflect.h` | Property reflection shared with the server counterpart |
| `se_sdk_glue.cpp` | The single SDK symbol implemented locally (avoids a 5 MB compile) |
| `se_icons_data.h` | Embedded palette icons (generated from the game's editor icons) |
| `le_catalogue.txt` | Placeable-class catalogue (built by `tools/make_catalogue.py`) |
| `thunks.asm` / `exports.def` | `dsound` ordinal forwards to the real system DLL |
| `imconfig_game.h` | Our ImGui config, copied over ThirdParty's at build time |

Threading rule (see the root README): the render thread reads the snapshot and pushes
commands; only the game thread touches `UObject`. `se_core.h` documents the contract.
