# luau/vendor/ (downloaded tools, not tracked)

`*.exe` is git-ignored on purpose. Fetch the two Luau binaries once; everything that
needs them looks in `luau/tools/` (staged kit) first, then here:

- **luau-lsp** (type checker behind `check_luau` and VS Code IntelliSense):
  release zip from `github.com/JohnnyMorganz/luau-lsp` -- unpack `luau-lsp.exe` here.
- **luau-compile** (used by the staged kit copy in `tools/`):
  from `github.com/luau-lang/luau` releases -- unpack `luau-compile.exe` here.

Keep the `LUAU-*-LICENSE.txt` files with them.

`game-check.ps1` lives in `luau/tools/` (tracked): the game-specific static checks the language server
cannot know (typed locals becoming nil properties, client-side ball spawns,
`BeginPlay` in mode code). It runs as the VS Code task **Game: check scripts**
(`luau/.vscode/tasks.json`, `-Watch` mode) and is mirrored by the editor's own
attach-time warnings. Extend its rule list as your game gains new traps.
