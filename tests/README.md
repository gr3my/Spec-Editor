# tests/ (scripted editor tests)

225 `.txt` scripts plus Python harnesses. A script runs inside the editor through the
same queue the UI uses:

```powershell
YourGame-Win64-Shipping.exe -windowed -nohmd `
  -SpecEditConnect=127.0.0.1:7777 `
  -SpecEditScript=SpecEditor\tests\e2e.txt
```

Results go to `%TEMP%\spec_editor.log` as `[script] PASS/FAIL` and `[repl]` lines
(what this client can see); the server logs `[SPECEDIT]` lines. Start with `e2e.txt`,
then `all.txt`, then the family you touched.

## Families

| Prefix / file | What it covers |
|---|---|
| `e2e.txt`, `e2e_editor/observer`, `all.txt`, `full.txt`, `regress.txt` | Entry points: full spawn/replicate/move/delete loop |
| `t_gm_*.txt`, `t_ex_*.txt`, `modes.txt` | Game modes: controller, roles, hooks, each example mode |
| `t_gizmo_ed`, `t_fly_ed`, `t_scene_ed`, `t_cam_ed`, `ui.txt`, `uiflow_*` | Camera, viewport, gizmo handles, UI flows (some need `Send-Mouse.ps1`) |
| `multisel_*`, `t_multisel_*`, `moves.txt`, `placeclick`, `nearwire` | Selection, dragging, placement |
| `mkslot_*`, `t_mkslot*`, `t_marker_*`, `t_loadslot*`, `slots*` | Slots, markers, level load/save slots |
| `sb_*.txt`, `sbtypes.txt`, `sbadd.txt` | Scoreboards and their bindings |
| `t_ball*`, `ballspawner_*`, `t_grav*`, `probe*` | Balls, spawners, gravity, collision probes |
| `coin*.txt`, `q*.txt`, `quest*.txt`, `props.txt` | Coins, quests, editable properties |
| `text.txt`, `t_text*`, `sb_text*`, `ldesc*` | Text rendering, labels, descriptions |
| `edarea_*`, `crossarea*`, `t_level_*`, `levels.txt`, `join.txt` | Level areas, loading, joining |
| `ownlock_*`, `t_own_*`, `t_lock_*` | Object locking and ownership |
| `diag_*`, `t_mi_*`, `t_mem*`, `dump.txt`, `probe_crash.txt` | Diagnostics, memory, crash probes |
| `t_docshots*.txt` | Screenshot-driven doc images (see `luau/tools/annotate_shots.py`) |

Suffix convention: `_editor` runs the editor side, `_observer` the second client that
verifies replication. `t_` = focused topic test.

## Python harnesses

- `build_wall_jakeball.py` -- reference arena builder (56 x 34 m arena); the canonical
  example of driving the editor from code. `verify_wall_jakeball.py` checks the result.
- `make_example_levels.py` -- regenerates the example `.gamelevel` projects.
- `mcp_full_test.py`, `mcp_live_test.py` -- exercise the MCP bridge end to end.
- `Send-Mouse.ps1` -- external mouse driver for click/drag UI tests.

The example levels, mode names, and coordinates are sample content illustrating the
original game -- replace with your own when adopting the template.
