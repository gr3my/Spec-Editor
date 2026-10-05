# tools/ (repo utilities)

- `make_catalogue.py` -- builds `mod/le_catalogue.txt`: every placeable class your
  game ships, for the Place Actors palette. Without it the palette only lists classes
  already loaded in memory (usually a handful).

  ```powershell
  python SpecEditor/tools/make_catalogue.py [FModel-export-root]
  ```

  The export root defaults to `Output/Exports` (FModel's *Export Raw Data (.json)* of
  `YourGame/Content`). Each output line is `<category>|<class path>`, e.g.
  `Meshes / Golf|/Game/YourGame/Prefabs/Meshes/Golf/LE_SM_GolfRampA.LE_SM_GolfRampA_C`.
  Re-run after your game adds placeables, then refresh the editor build with
  `Install-SpecBuild.ps1 -ModOnly`.

- `make_icons.py` -- rebuilds `mod/se_icons_data.h` from `icons/*.png` (see
  `icons/README.md`). Run it after replacing the placeholder art.
