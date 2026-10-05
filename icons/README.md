# icons/ (placeholder palette art)

93 generic placeholder icons (64x64 RGBA: slate tile, accent square). They exist so the
palette, the `LoadIcons` path, and `mod/se_icons_data.h` all work out of the box with
no game art in the repo.

## Using your game's own icons

1. Export one PNG per placeable class into this folder (square, 64-96 px works well).
   Keep filenames aligned with your catalogue: `IconTexture()` tries the item name,
   then `aa_se_` + the name without its `LE_` prefix (see `se_render.cpp`).
2. Regenerate the embedded header:
   ```powershell
   python SpecEditor/tools/make_icons.py   # rewrites mod/se_icons_data.h
   ```
3. Rebuild the mod (`mod\build.ps1`) and refresh the editor build
   (`Install-SpecBuild.ps1 -ModOnly`).
