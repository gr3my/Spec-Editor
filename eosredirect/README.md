# eosredirect/ (optional)

Source for the **published-build** redirect DLL. The editor mod and a server-browser /
platform redirect are both `dsound.dll`, and only one can load -- so the published
(`mod\build.ps1 -Rift`) build compiles this source INTO the editor DLL behind `GAME_EOS`
(`GameEos_Attach()` in `mod\dllmain.cpp`). A dev build never touches this folder.

## What belongs here

- `dllmain.cpp` -- required for `-Rift`. Loaded at process start; repoints your
  platform/EOS SDK's backend host to your gateway and applies your platform app-id
  config. Keep it silent (no console, no log window); a `%TEMP%` diag file behind an
  env-var flag is enough for the one validation run.
- Forward the OS `dsound` ordinals you import (see `mod\thunks.asm` / `mod\exports.def`
  for the pattern) so system audio is unchanged.

## Notes

- The redirect must find its target by **signature scan with a mismatch = do nothing**
  rule, never by hardcoded address alone: a game update moves code, and writing to a
  stale address corrupts the process.
- Version-guard it: log the SDK/module version it validated against, and refuse to
  hook anything else.
- This folder is empty in the template. `mod\build.ps1 -Rift` fails with a clear
  error until you add `dllmain.cpp`.
