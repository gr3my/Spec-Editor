# SpecEditor

An in-game level editor for **Orion Drift-compatible projects/reimplementations**:
a Dear ImGui overlay that places, moves, and edits replicated actors through the
game's own server, plus a Luau scripting kit, game-mode authoring, AI-agent (MCP)
integration, and a scriptable test suite.

The Orion Drift / A2 class names in this repo (`AVRPlayerController`,
`ALevelEditorPawn`, `AVRPawn`, `ADiscEntity`, `ULuauBehavior`, the `LE_*`
placeables, `ABP_*` blueprints, ...) are **compatibility requirements**, not
placeholders. The editor drives the game through its own RPCs and reflection
data, so those names must match the build you run it against.

> You are responsible for supplying compatible game files/build data. This repo
> ships no game binaries, no SDK dump, and no art from any game build. Point it
> at an Orion Drift-compatible build you have the right to use, then configure
> and build as described below.

## Supported builds

No Orion-compatible build is pinned in this release. All build-specific values
default to safe/off (see "Build-specific offsets"), so the editor compiles and
runs against any compatible build, with the address-dependent helpers disabled
until you configure them.

| Item | Status |
|---|---|
| Orion Drift-compatible client (Dumper-7 SDK + stock client build) | Bring your own; see Requirements |
| `SE_ORION_BUILD_ID` in `mod/se_orion_build.h` | Empty (no build pinned) |
| Executable addresses (`k*Fn` in `mod/se_orion_build.h`) | `0` = helper stays off (fail-safe) |
| Data-layout offsets (`k*Off`) | Last verified values; re-check per build |

If you verify a build, set `SE_ORION_BUILD_ID` to it and list it here.

## Build-specific offsets

Everything build-specific lives in one place: `mod/se_orion_build.h`.

- `SE_ORION_BUILD_ID` -- free-form label for the build the values were verified
  against. Empty means no build is pinned.
- `gameaddr::k*Fn` -- executable addresses (exe RVAs off the module base).
  `0` keeps the helper off: it logs one line and skips, never calling address 0.
- `gameaddr::k*Off` -- data-layout offsets used alongside those addresses.

To target another Orion-compatible build:

1. Dump the build's SDK with Dumper-7 into `gamesdk/<BUILD>/SDK` and point
   `mod/build.ps1` at it (`$env:GAME_SDK`, default `gamesdk/YOUR_BUILD`).
2. Re-derive each `k*Fn` address and check each `k*Off` offset against the new
   SDK dump (`se_reflect.h` lists the field offsets it depends on).
3. Set `SE_ORION_BUILD_ID` to the build you verified against.
4. Rebuild the mod and run `tests/e2e.txt` before publishing levels.

Never ship nonzero guesses: calling a wrong executable address crashes the
process, while a `0` costs a log line. Also regenerate the API definitions from
your SDK dump (`python luau/generate_defs.py --sdk <your Dumper-7 folder>`);
the checked-in `luau/types/` files are examples.

Remaining per-build names before use (15 minutes, all find-replace):

| Placeholder | Meaning | Where it appears |
|---|---|---|
| `Game` / `game` / `GAME` | Script API global and folder names | `Game.state()`, `GameScripts/`, `GameLevels/`, `GAME_MCP_PORT` |
| `/Game/YourGame/` | Content path | `le_catalogue.txt`, palette discovery, docs |
| `YourGame-Win64-Shipping.exe` | Client binary | `Install-SpecBuild.ps1`, tests, docs |
| `YOUR_BUILD` | Build number | `generate_defs.py`, `gamesdk/YOUR_BUILD`, docs |
| `YourGame_structs.hpp` etc. | SDK module names | `generate_defs.py` `STRUCT_PACKAGES` |
| `%LOCALAPPDATA%\YourGame\...` | Log folder | MCP log readers, tests, C++ log watchers |
| `YourServer` | Server counterpart | log names, launch script refs |

## How it works

Two halves that never touch each other's data (breaking this rule is the classic UE mod crash):

- **Render thread** (inside the `IDXGISwapChain::Present` hook) draws ImGui. It reads the
  published snapshot and pushes commands. It never touches a `UObject`.
- **Game thread** (inside the `UObject::ProcessEvent` hook) owns everything `UObject`:
  it drains commands, spawns/transforms/replicates, and republishes the snapshot.

Editor commands tunnel through replicated RPCs that already take a free-form string
(`SE|SPAWN|...`, `SE|XFORM|...`, ...), so the **server** does the spawning and every
client -- modded or not -- sees the result. Actors are addressed as `Class@position`,
never by name (UE does not replicate actor names).

## Loading the editor

The mod ships as `dsound.dll` next to the client exe: the exe statically imports
`dsound` by ordinal, so ours loads first and forwards every ordinal to the real system
DLL (`mod/thunks.asm`). No launcher, no injector for the client.

```powershell
# 1. Adopt the placeholders (table above), then regenerate the API:
cd luau
python generate_defs.py --sdk <your Dumper-7 SDK folder>

# 2. Fetch the untracked deps (see luau/vendor/README.md), then build the mod:
cd ..\mod
.\build.ps1                       # -> mod\dsound.dll (dev build)
.\build.ps1 -Rift                 # -> mod\rift\dsound.dll (published + eosredirect)

# 3. Make an editor build from a stock compatible client:
cd ..
.\Install-SpecBuild.ps1 -Source <your stock build>   # hard-links, takes seconds
.\Install-SpecBuild.ps1 -ModOnly                      # refresh just the DLL later

# 4. Launch the editor build, press INSERT for the UI. Log: %TEMP%\spec_editor.log
```

Scripting kit: open `SpecEditor\luau` itself in VS Code (luau-lsp extension), write `.luau`,
attach from Details > Luau script. AI agents: `claude mcp add game -- python
"%USERPROFILE%\Documents\GameScripts\mcp\game_mcp.py"` (see `luau/mcp/MCP.md`).

Self-test without a human: launch a server, then run the client with
`-SpecEditConnect=127.0.0.1:7777 -SpecEditScript=SpecEditor\tests\e2e.txt`
and read `[script] PASS/FAIL` in `%TEMP%\spec_editor.log`. See `tests/README.md`.

## Layout

```
SpecEditor/
  mod/                the C++ editor DLL source -> mod\dsound.dll (see mod/README.md)
    se_core.h         thread-split spine: snapshot + command queue
    se_orion_build.h  Orion-compatible build config: exe addresses + offsets (edit this per build)
    se_render.cpp     D3D12 Present hook, ImGui, Unreal-styled theme
    se_ui.cpp         menu bar, Place Actors, Outliner, Details, Quests, gizmo
    se_game.cpp       ProcessEvent pump: palette, object list, command dispatch
    se_mcp_net.cpp    loopback bridge the MCP server talks to (127.0.0.1:47650+)
    le_catalogue.txt  placeable-class catalogue (built by tools/make_catalogue.py)
    build.ps1         one-command build (needs VS 2022 C++, imgui, MinHook, your SDK)
  eosredirect/        OPTIONAL published-build redirect (server browser, app id)
  luau/               the Luau scripting kit (see luau/README.md)
    examples/         tutorial scripts + gamemodes/ with matching levels/
    levels/           example .gamelevel projects (open from the Levels tab)
    game-scripts/     dumped real-game scripts: idiomatic API usage examples
    types/            game.d.luau + api_index.json (REGENERATE for your build)
    mcp/              game_mcp.py: MCP server so AI agents can drive the editor
    tools/            guide builders, game-check, screenshot helpers
    vendor/           Luau binaries (downloaded, not tracked)
  tests/              scripted editor tests + Python harnesses (see tests/README.md)
  tools/              repo utilities (make_catalogue.py)
  icons/              placeholder palette art (replace with your game's icons)
  Install-SpecBuild.ps1  hard-link a stock build + install the mod into it
```

## Requirements

- Visual Studio 2022 with C++ desktop workload (MSVC v143), Windows 10/11 SDK
- An Orion Drift-compatible client build (stock) plus its Dumper-7 SDK dump
  (`*_classes.hpp` / `*_structs.hpp`) -- you supply both
- Python 3.9+ (kit tooling, catalogue, tests)
- Dear ImGui 1.91.5 (`git clone --branch v1.91.5 ... ThirdParty\imgui`, untracked)
- MinHook source at `ThirdParty\MinHook` (untracked)
- Microsoft Edge (only to print the PDF guides)

## Framework vs example content

Framework (reuse as-is): threading split, command queue, `SE|` transport, gizmo math,
replication/broadcast/replay, MCP bridge protocol, checker rules engine, test runner.

Replace for your build: `STRUCT_PACKAGES` / `EXTRA_CLASSES` / `BLUEPRINT_TYPES` in
`generate_defs.py`, palette discovery roots, `LE_` prefix assumption, example levels /
game modes (yours will differ), guide text (rebuild with `luau/tools/build_*.py`),
and the `gameaddr` addresses in `mod/se_orion_build.h` (`0` = helper stays off).

Everything else in the repo is original sample content: the `game-scripts/` samples,
the `icons/` placeholder art, the `types/` stubs, and the example levels/modes/tests
were written for this project. Regenerate the catalogue, icons, and API definitions
from your own compatible build before use.

## Known limitations

- Address-dependent helpers (quest-definition probe, toggle writers, team-list
  join guard) stay off until you configure `mod/se_orion_build.h` for your build.
- The palette falls back to classes already loaded in memory (a handful) until you
  build `le_catalogue.txt` with `tools/make_catalogue.py` against your build.
- The MCP bridge listens on loopback only (`127.0.0.1:47650`-`47654`); agents run
  on the same PC as the editor.
- `-Rift` (published) builds need your redirect source at `eosredirect/dllmain.cpp`;
  this repo ships none (see `eosredirect/README.md`).
- Offsets drift between game builds: after any game update, re-verify
  `se_orion_build.h` and re-run `tests/e2e.txt`.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Client exits during start-up, mod suspected | Missing platform DLLs next to the exe (see `Install-SpecBuild.ps1`), or `mod\build.ps1` SDK mismatch |
| Palette shows a handful of items | `le_catalogue.txt` missing/stale -- run `tools\make_catalogue.py` on an FModel export |
| No Luau completions | Wrong folder opened -- open `SpecEditor\luau` itself, restart the language server |
| Script slot stays nil | Unwired External Dependency, or target outside the mode area |
| `-Rift` build fails on `eosredirect` | Expected: add your redirect source (see `eosredirect\README.md`) or build dev |

## License

MIT -- see `LICENSE`. Set the copyright holder name before publishing your fork.
