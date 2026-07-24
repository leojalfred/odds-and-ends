# Working on this mod

A CK3 **1.19.x** mod: a collection of small, independent quality-of-life fixes. Each feature stands alone, and the mod is the sum of them. `README.md` is the user-facing description of what ships; this file is how to change it without breaking it.

## Hard rules

- **Never touch anything outside this directory.** The game folder (`C:\Games\Steam\steamapps\common\Crusader Kings III`) is read-only reference: read it freely, never modify it. The same goes for other mods on disk, including `..\leo_vi_mass_vassal_directives`, which is a sibling project and not part of this one.
- **Quality of life means convenience, never capability.** Every feature must do something the player could already do by hand, faster or with fewer clicks. If a change would show information the game hides, reach a state vanilla forbids, or bypass a prerequisite, it is wrong. Mirror the game's own gating triggers rather than reimplementing them: when vanilla decides whether a thing is available, call vanilla's decision.
- **`README.md` must never mention AI or Claude.** Neither must anything else user-facing.
- **Never reference implementation phases, sessions, or process in comments.** Comments are for someone who has only ever seen the code.
- **Research the [wiki](https://ck3.paradoxwikis.com/Modding) first**, then the wider web, then the game files. The wiki usually answers faster than reverse-engineering `game/gui/*.gui`. Don't guess: CK3 modding is full of things that look impossible and aren't, and vice versa.

## The repo is the mod

`..\leo_vi_odds_and_ends.mod` points the launcher straight at this directory, so what you edit is what loads. There is no build step and nothing is generated: every file under `common/`, `gui/`, `localization/`, `events/` and so on is hand-written and is the shipped article. Dev files at the root (`CLAUDE.md`, `.claude/`, `.vscode/`, `tools/`) are ignored by the game.

Keep it that way unless a feature genuinely forces otherwise. If one ever does need generated output, mark the generated files unmistakably and put the generator in `tools/`, so nobody hand-edits an artifact.

## Features are self-contained

The mod's whole shape is "a bag of unrelated fixes", and it only stays maintainable if each one can be read, changed, or removed without touching the others.

- Every feature gets a **sub-prefix**: `leo_oae_<feature>_`. Files are named for the feature too (`common/scripted_triggers/leo_oae_<feature>_triggers.txt`), so everything one feature owns is greppable by one string.
- **No feature depends on another.** Shared helpers are allowed, but they live in plainly shared files (`leo_oae_shared_*`) and are the exception, not the habit.
- **Every feature carries its own gate.** A feature that only makes sense under a DLC, a government type, or some unlock checks that itself, and does nothing quietly when the check fails. It never assumes the player's game looks like the one it was written for.
- Each feature gets its own **README section** and its own line in the "Features" list below, so the file stays a map of what exists.

### Features

**Governors** (`leo_oae_govmap`) — puts vanilla's `admin_vassal_types_map` map mode, the one the Administrative Government panel opens on and drops on close, into the Additional Map Modes flyout. Pure GUI and localization: no script at all.

- `gui/shared/mapmodes.gui` is a **vanilla file override**, the mod's only one. A GUI widget cannot be injected into a type defined in another file, and the flyout closes on `_mouse_hierarchy_leave`, so a separate top-level widget cannot stand in for one either. The file is vanilla verbatim plus one `icon_button_mapmode`; `tools/check_compat_static.sh` diffs it against the installed game and fails on any change that is not ours. **Re-copy and re-insert after every patch.**
- The button's `visible` mirrors vanilla's own administration tab (`game/gui/hud.gui`, the four `widget_hud_main_tab` blocks). Vanilla writes it as four cases only to swap the button skin; the union is `Or(And(A, Not(B)), B)`, which collapses to `Or(A, B)` with no widening. If a patch changes what gates that tab, re-derive from `hud.gui` rather than patching the condition by hand.
- `admin_vassal_types_map` and `admin_vassal_types_map_desc` are the mod's **only unprefixed loc keys**, and have to be: the engine builds a map mode's name and description keys out of the map mode's own name. They are one-line aliases onto `leo_oae_govmap_name`/`_desc`, the way vanilla points its map mode names at `MAPMODE_*`. The compat check fails if vanilla ever defines them, which would make ours duplicates.
- The mode ships with no icon of its own. The button borrows `flat_icons/administrative.dds` and the name's texticon borrows `government_types/administrative_government.dds`, so the mod adds no art.

## Localization

The mod ships every language CK3 officially supports: english, french, german, spanish, russian, korean, simp_chinese, japanese, polish. English is the source of truth and hand-written (`localization/english/leo_oae_l_english.yml`); the others live at `localization/<lang>/leo_oae_l_<lang>.yml` and are **machine-generated, then hand-maintained**.

**Whenever you change an English localization value, update every translated file to match**: same keys in the same order, the changed value re-translated. Keep the CK3 markup identical across languages: concept links `[x|E]`, `$refs$`, `@icon!` tokens, `[recipient.GetX]` calls, `#weak`/`#V` … `#!` codes and `\n` are never translated, only the prose between them. In user-facing text the translations are described as **machine-generated**, never "AI" (see Hard rules).

Prefer reusing a vanilla loc key over writing a new one when the game already says exactly the right thing: it is free translation and it stays in step with the game's own wording.

## The limits that explain the design

These are engine facts, verified in game. Most odd-looking code in a CK3 mod follows from one of them.

### Real, and they are script-side

1. **Scripted effects cannot recurse.** Anything tree-shaped has to be capped at a fixed depth and unrolled by hand, one effect per level.
2. **A *script* variable name cannot be built at runtime.** `$X$` is a parse-time text macro, so a variable a script touches must be named literally in the source. This is what forces hand-written dispatch chains, and it is genuinely immovable.
3. **A trigger or condition cannot be chosen at runtime.** Write the chain once and drive it with a value staged into a temporary scope (`scope:leo_oae_...`), rather than duplicating the chain per case.
4. **GUI has no string comparison.** Only `Select_CString` (a selector) exists; there is no `IsEqual_CString` anywhere in vanilla. A datamodel item's identity is a string and can never be compared against a number in a variable. Work around it by having script pre-build one list per case and letting GUI pick the list by name, rather than filtering rows in GUI.

### Two things that look like limits and are not

Both were verified wrong in game, with working probes. They are recorded because believing them leads straight to generating hundreds of near-identical widgets.

- **A variable name in a *GUI binding* CAN be built at runtime.** `Var()` and `GetList()` both accept a computed `CString`, not just a literal. Vanilla does it: `Story.MakeScope.Var( StoryCycleVariableVisualization.GetVariableName )` (`game/gui/window_situation_list.gui:741`) and `GetList( ... GetVariableName )` (`:1071`). Combined with `Concatenate`, one widget can bind a different variable per datamodel item. `blockoverride` cannot parameterize a binding, which is true and beside the point: the answer is a datamodel, not `blockoverride`.
- **GUI CAN pass a number to script.** `MakeScopeValue`, `MakeScopeFlag` and `MakeScopeBool` exist alongside `AddScope` and arrive script-side as `scope:name`. Verified working, despite having zero vanilla call sites. `GetScriptedGui()` also accepts a **computed** name, so a row can dispatch to `leo_oae_set_5` without that string appearing anywhere in the file.

So a repeated list of controls should almost always be a `datamodel` over a script-built list, with one `item` template: labels via `Localize(Concatenate('leo_oae_', Scope.GetFlagName))`, clicks via `GetScriptedGui(Concatenate(...))`. Point a `datamodel` at a list name that was never created and the rows do not merely hide, they **cease to exist**, which is how gated content can cost nothing. Push gating into what script puts in the list rather than into per-row `visible` bindings.

## GUI facts worth not rediscovering

- **Reading script state needs no scripted GUI.** `.Var('x').GetValue` is a **CFixedPoint**: `EqualTo_CFixedPoint( GetPlayer.MakeScope.Var('x').GetValue, '(CFixedPoint)5' )`. Literals must be cast-and-quoted. Drives `visible`, and `frame` via `BoolTo1And2`.
- **A label can be built from a value**: `Localize(Concatenate('prefix_', IntToString(FixedPointToInt(Var('x').GetValue))))`. **Every value the variable can hold needs a key**, including `0`, which is what an unset variable reads.
- **Multiple `onclick` lines work and run in order.** `"[A][B]"` chaining does not exist.
- **No floating popups.** Draw order is tree order, there is no z-index for non-window widgets, and no datafunction returns a widget's position, so a dropdown opens in flow. Vanilla's native `dropDown` widget (`game/gui/shared/lists.gui:755`) does position its own list, but its items come from a `datamodel`, so it only helps where the options are data.
- **`margin` is padding inside a widget**, and an expanding widget is still stretched to its parent's width. To make a box narrower, put the inset on a parent. A hidden widget takes no space.
- **A widget that overflows its window still draws, but stops being clickable.** The window's input area ends at its own edge, so an over-long list looks fine and silently does nothing. A scrollbox clips instead, so this mostly bites on new windows.
- **An empty loc value renders no tooltip at all**, not an empty box. A runtime-built tooltip key can exist for every case and simply be blank where there is nothing worth saying.
- **`visible = no` does not prevent instantiation, only rendering and layout.** The engine property `visible_at_creation` exists precisely because widgets are created while hidden. Hiding a subtree saves nothing at load; only not creating it does.
- **`gui/scripted_widgets/` means "create this widget at game start", not on first open.** So a first-open hitch is the first *layout and text-shaping* pass over the whole tree, and widget **count** is the thing that matters.
- **The engine wipes GUI variables at the load-to-session transition.** A GUI variable set at startup cannot be relied on to survive into play, and a `state` `delay` meant to outlast the transition will not: the wipe fires first.
- **`alwaystransparent` is a per-widget pass-through, not a subtree input blocker.** Vanilla only ever puts it on a leaf inside a button, so the *button* gets the click. On a container it does nothing useful, because the children still take input. There is no property that makes a whole subtree ignore the mouse.
- **Overriding a vanilla GUI file replaces it wholesale**, so it collides with every other mod that touches the same file and goes stale on the next patch. Prefer adding a new file; when you must override, override the smallest file that does the job and record it under the feature's README section and in the compatibility check, because it is the first thing a patch breaks.
- **All `.txt`/`.gui`/`.yml` need a UTF-8 BOM. `descriptor.mod` and `..\leo_vi_odds_and_ends.mod` must NOT have one.**
- **Script variables and flags that only GUI ever reads trip the validator.** `-debug_mode` logs "set but is never used" because it scans script only and does not count GUI or localization. Keep `error.log` clean by referencing them from a scripted trigger that something actually calls.

## Verifying

There are no automated tests; the game is the test. Before handing back, check that every scripted GUI, loc key, effect and trigger the GUI names actually exists, **including names built at runtime by `Concatenate`**, which nothing else will catch. Then have the user load the mod with `-debug_mode` and watch `logs/error.log` for `leo_oae` lines. A clean `error.log` is a hard gate. `reload gui` refreshes GUI live; structural changes may need a restart.

Ask for a real in-game test of anything static checks cannot see: a name reached only by macro expansion, a loc key built at runtime, and above all **whether a feature's gate actually holds** (a character who should not see it does not, a character who should does).

### After a CK3 patch

Two steps, in order. The first is names, the second is everything names cannot tell you.

1. **`bash tools/check_compat_static.sh`** asserts every vanilla name the mod leans on against the installed game files. A FAIL means a patch renamed or removed something the mod mirrors; fix it before shipping. When a change adds a new vanilla dependency (a trigger, a flag, a concept, an overridden file or GUI type), add a line for it here so the next patch is checked, not remembered. Create the script the first time a feature depends on a vanilla name.
2. **The smoke test**: the shortest sequence of in-game steps that exercises every feature's gate and its happy path once. Keep it in the feature's README section as features land, so it stays runnable by someone who did not write the code. Names surviving a patch does not mean their meaning did, and that is what this catches.

## Conventions

- Prefix everything `leo_oae_`, and everything belonging to one feature `leo_oae_<feature>_`.
- Any numeric code stored in a player variable is **append-only**. Saved games hold those numbers, so renumbering silently rewrites the state of everyone already playing. A new entry takes the next free code no matter where it belongs in a displayed list; order the display separately.
- Scripted GUIs: `is_shown` = checked/selected state, `is_valid` = enabled, `effect` = onclick. Controls that read their own state from a variable need no entry at all.
- Comments say **why**, not what. The what is readable; the why is usually "the script language wouldn't let me do the obvious thing".
- **Text style.** Anything user-facing (game loc, `README.md`, the Workshop description) uses American spelling (recognize, gray, behavior, color, not recognise/grey/behaviour/colour) and no em-dash or spaced-hyphen separators between clauses. End the sentence and start a new one, or use a colon, parentheses, or a comma where that reads better. Genuine compound hyphens stay (quality-of-life, off-faith, duchy-tier). Hold comments and identifiers to the same spelling so the codebase stays consistent (`leo_oae_gray_*`, not `grey`).
