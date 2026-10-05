<#
.SYNOPSIS
  Build the Spec Editor mod (dsound.dll).
.DESCRIPTION
  Compiles the proxy + editor (render half, UI, game half) together with Dear ImGui and MinHook into a
  single dsound.dll. Same one-cmd-session shape as the Game EOS redirect build: vcvars64, then ml64 for
  the ordinal thunks, then cl, chained with && only so the first failure stops everything, finishing
  with a BUILD_OK marker. Do NOT add `if errorlevel` steps to that chain - cmd folds the next command
  into the if's body and silently skips the compile, which once shipped a stale DLL that looked fine.
.EXAMPLE
  .\build.ps1          # dev build -> mod\dsound.dll
  .\build.ps1 -Rift    # published build -> mod\rift\dsound.dll: the editor PLUS your
                        # platform/EOS redirect (see eosredirect\README.md). The redirect
                        # is also a dsound.dll, and only one can load, so the two are
                        # compiled into one DLL here.
#>
param([switch] $Rift)
$ErrorActionPreference = 'Stop'
$here   = $PSScriptRoot
$root   = Resolve-Path (Join-Path $here '..')
# MinHook (vendored): place MinHook source at ThirdParty\MinHook (include\ + src\).
#   git clone https://github.com/TsudaKageyu/minhook ThirdParty\MinHook
$mh     = (Resolve-Path (Join-Path $root 'ThirdParty\MinHook')).Path
$imgui  = (Resolve-Path (Join-Path $root 'ThirdParty\imgui')).Path
# Your game's Dumper-7 SDK dump (contains SDK\Basic.cpp etc.).
# Generate it from your game build, or set $env:GAME_SDK to its path.
$envSdk = $env:GAME_SDK
$sdk    = if ($envSdk) { (Resolve-Path $envSdk -ErrorAction Stop).Path } else {
    $defaultSdk = Join-Path $root 'gamesdk\YOUR_BUILD'
    if (-not (Test-Path -LiteralPath $defaultSdk)) {
        throw ("game SDK not found at $defaultSdk - dump your game's SDK with Dumper-7 " +
               "or set `$env:GAME_SDK to its folder (it must contain SDK\Basic.cpp)")
    }
    (Resolve-Path $defaultSdk).Path
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) { throw "vswhere.exe not found at $vswhere" }
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'No VS C++ toolset found' }
$vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path $vcvars)) { throw "vcvars64.bat not found at $vcvars" }

$out = Join-Path $here $(if ($Rift) { 'build-rift' } else { 'build' })
New-Item -ItemType Directory -Force -Path $out | Out-Null
# Optional platform/EOS-redirect source for the published (-Rift) build.
# Only needed with -Rift: put your redirect's dllmain.cpp at eosredirect\dllmain.cpp
# (see eosredirect\README.md). A dev build never touches it.
$eos  = Join-Path $root 'eosredirect'
if ($Rift -and -not (Test-Path (Join-Path $eos 'dllmain.cpp'))) {
    throw ("published build needs eosredirect\dllmain.cpp - see eosredirect\README.md " +
           "(or build without -Rift for a dev build)")
}
# ImGui's config lives in the (untracked) ThirdParty folder; ours -- a non-fatal IM_ASSERT -- is kept here and copied in.
Copy-Item -Force (Join-Path $here 'imconfig_game.h') (Join-Path $imgui 'imconfig.h')
$defs = if ($Rift) { '/DGAME_EOS /DGAME_EMBEDDED /DGAME_SHARED_PE ' } else { '' }
$eosCl = if ($Rift) {
  "cl /nologo /c /O2 /MT /EHsc /GS- $defs/I`"$mh\include`" /Fo:eos_dllmain.obj `"$eos\dllmain.cpp`""
} else { 'echo dev build' }

# The generated SDK is enormous; /bigobj and a large /Zm are both required or cl runs out of heap.
$cl = "cl /nologo /c /O2 /MT /EHsc /GS- /std:c++20 /bigobj /Zm400 " +
      "/I`"$mh\include`" /I`"$imgui`" /I`"$imgui\backends`" /I`"$sdk`" " +
      "/DIMGUI_DISABLE_OBSOLETE_FUNCTIONS " + $defs

$cmds = @(
  "call `"$vcvars`"",
  "cd /d `"$out`"",
  "ml64 /nologo /c /Fo thunks.obj `"$here\thunks.asm`"",
  "$cl `"$here\dllmain.cpp`" `"$here\se_render.cpp`" `"$here\se_ui.cpp`" `"$here\se_game.cpp`" `"$here\se_sdk_glue.cpp`" `"$here\se_mcp_net.cpp`"",
  "$cl `"$sdk\SDK\Basic.cpp`" `"$sdk\SDK\CoreUObject_functions.cpp`"",
  "$cl `"$imgui\imgui.cpp`" `"$imgui\imgui_draw.cpp`" `"$imgui\imgui_tables.cpp`" `"$imgui\imgui_widgets.cpp`" `"$imgui\backends\imgui_impl_dx12.cpp`" `"$imgui\backends\imgui_impl_win32.cpp`"",
  $eosCl,
  "cl /nologo /c /O2 /MT `"$mh\src\buffer.c`" `"$mh\src\hook.c`" `"$mh\src\trampoline.c`" `"$mh\src\hde\hde64.c`"",
  "cl /nologo /LD /Fe:dsound.dll *.obj /link /DEF:`"$here\exports.def`" kernel32.lib user32.lib d3d12.lib dxgi.lib psapi.lib ws2_32.lib /MAP:dsound.map",
  "echo BUILD_OK"
) -join ' && '

# $ErrorActionPreference is 'Stop' for this script, and with `2>&1` PowerShell turns ANY stderr line
# from a native command into a terminating NativeCommandError. vcvars64.bat harmlessly prints
# "'vswhere.exe' is not recognized" on this machine and still initialises correctly (it goes on to
# print its banner and put cl.exe on PATH) -- but that one warning was enough to kill the script at
# this line, before a single file was compiled, while blaming vswhere. Let stderr be data here; the
# BUILD_OK marker below is what actually decides success.
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try   { $log = & cmd.exe /c $cmds 2>&1 }
finally { $ErrorActionPreference = $prevEap }

$log | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -or -not ($log -match 'BUILD_OK')) { throw "build failed (exit $LASTEXITCODE)" }

$dest = Join-Path $here 'dsound.dll'
if ($Rift) {
  New-Item -ItemType Directory -Force -Path (Join-Path $here 'rift') | Out-Null
  $dest = Join-Path $here 'rift\dsound.dll'
}
Copy-Item (Join-Path $out 'dsound.dll') $dest -Force
$sz = (Get-Item $dest).Length
Write-Host "[spec-editor] -> $dest  ($sz bytes)"
