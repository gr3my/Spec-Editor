// se_orion_build.h - Orion-compatible build configuration (the ONLY place for
// build-specific executable addresses and data-layout offsets).
//
// SpecEditor is a level editor for Orion Drift-compatible projects /
// reimplementations. It talks to the game through that game's own classes
// (AVRPlayerController, ALevelEditorPawn, AVRPawn, ADiscEntity, ULuauBehavior,
// the LE_* placeables, ...), so those names are compatibility requirements,
// not leftovers. Do not rename them.
//
// Supported builds in this release: none is pinned. Every executable address
// below is 0 (helper stays off) and every data offset is the last verified
// value. That is the fail-safe default: a helper whose function address is
// still 0 logs one line and skips; it never calls address 0. An unsupported
// build therefore loses the helpers that need addresses, nothing else.
//
// To target another Orion-compatible build:
//   1. Dump the build's SDK with Dumper-7 into gamesdk/<BUILD>/SDK and point
//      mod/build.ps1 at it ($env:GAME_SDK or gamesdk/YOUR_BUILD).
//   2. Re-derive each k*Fn executable address below (exe RVA off the module
//      base) and check each k*Off data offset against the new SDK dump.
//   3. Set SE_ORION_BUILD_ID to the build you verified against.
//   4. Rebuild the mod and run tests/e2e.txt before publishing levels.
//
// Never ship nonzero guesses: calling a wrong executable address crashes the
// process, while a 0 costs a log line.

#pragma once

#include <cstdint>

// Free-form label for the Orion-compatible build these values were verified
// against (e.g. "OrionDrift-Win64-Shipping <build>, 2026-09"). Empty in this
// release: no build is pinned, all helpers default off.
#define SE_ORION_BUILD_ID ""

// Build-specific executable addresses (exe RVAs) and data-layout offsets.
// Reversed from one Orion-compatible build; 0 = not configured for this build.
namespace gameaddr {
// ClientProgression*(UWorld*): reaches the replicated quest-definition set.
// Layout used with it: set pointer @+336, count int32 @+344, stride 0x128,
// title @+0xF0/+0xF8.
constexpr uintptr_t kClientProgressionFn = 0;
// Enable/disable writers for the local TEST toggle op (toggleable-component path).
constexpr uintptr_t kToggleEnableFn  = 0;
constexpr uintptr_t kToggleDisableFn = 0;
// OnRep for the team-list replication the join guard defers (0 = guard stays off).
constexpr uintptr_t kTeamListRepFn = 0;
// Data layout used with kTeamListRepFn: module slot, module state within the
// slot, and the team-count int read for the log line.
constexpr uintptr_t kTicketModuleSlotOff = 0x328;
constexpr uintptr_t kSlotModuleStateOff  = 0x300;
constexpr uintptr_t kTicketTeamCountOff  = 0x390;
}  // namespace gameaddr
