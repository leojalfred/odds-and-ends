# Working on this mod

A CK3 **1.19.x** mod: a collection of small, independent quality-of-life fixes. Each feature stands alone, and the mod is the sum of them. `README.md` describes what ships and how to check it still works; this file is how to change it without breaking it.

**`README.md` is developer-facing**, not the Workshop page. The Workshop description is separate BBCode, generated when the mod is published, and is the only truly user-facing text besides the game localization. So `README.md` is where a feature's smoke test lives, alongside the prose describing it. It still follows the text style rules below, because it is read by people and quoted from when the Workshop description is written.

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

- `gui/shared/mapmodes.gui` is a **vanilla file override**, the mod's only one. A GUI widget cannot be injected into a type defined in another file, and the flyout closes on `_mouse_hierarchy_leave`, so a separate top-level widget cannot stand in for one either. It carries three marked edits: the Governors button after `map_mode_government_button`, and `map_mode_landless_rulers_button` and `map_mode_counties_button` each pulled up to the end of the row above, so the flyout stays four buttons wide without changing the order it reads in. **Re-copy and re-apply after every patch**, following the procedure written out in `tools/check_compat_static.sh`.
- Because that override *moves* vanilla widgets, it cannot be validated by diffing against vanilla: a legitimate edit and a patch's edit look alike. The check pins the **hash** of the vanilla file the copy was made from and fails when the installed one stops matching. A new edit to the copy means updating `VANILLA_SHA` only when the game file itself changed, never to silence a failure.
- The button's `visible` mirrors vanilla's own administration tab (`game/gui/hud.gui`, the four `widget_hud_main_tab` blocks). Vanilla writes it as four cases only to swap the button skin; the union is `Or(And(A, Not(B)), B)`, which collapses to `Or(A, B)` with no widening. If a patch changes what gates that tab, re-derive from `hud.gui` rather than patching the condition by hand.
- `admin_vassal_types_map` and `admin_vassal_types_map_desc` are the mod's **only unprefixed loc keys**, and have to be: the engine builds a map mode's name and description keys out of the map mode's own name. They are one-line aliases onto `leo_oae_govmap_name`/`_desc`, the way vanilla points its map mode names at `MAPMODE_*`. The compat check fails if vanilla ever defines them, which would make ours duplicates.
- The mode ships with no icon of its own. The button borrows `flat_icons/administrative.dds` and the name's texticon borrows `government_types/administrative_government.dds`, so the mod adds no art.
- **ctrl+shift+G** is declared twice, as vanilla declares its own map mode keys: on the flyout button for the tooltip hint, and in `gui/leo_oae_hotkeys.gui` (registered through `gui/scripted_widgets/`) to actually fire, since the flyout is hidden until opened. The key needs no binding of the mod's own, and the hotkey widget repeats the button's gate through `enabled`. See the two shortcut entries under GUI facts.

**Mass Bolster Governance** (`leo_oae_mbge`) — applies vanilla's `boost_efficiency_interaction` across the governor pool in one action, filtered by a government efficiency threshold. Opened by a decision or by **ctrl+shift+B**. Overrides no vanilla file.

- **The panel is our own window** (`gui/leo_oae_mbge_panel.gui`, registered through `gui/scripted_widgets/`), shown by the script variable `leo_oae_mbge_open`. The decision does nothing but set that variable, and **ctrl+shift+B** toggles it. Its `effect` is wrapped in `hidden_effect` so opening a window is not described as an outcome.
- **Building the panel into the decision's own window was tried and does not work. Do not try it again.** The full chain, verified in game: a decision's custom widget (`widget = { gui = ... }`, a new file under `gui/decision_view_widgets/`) is shown **only** if the decision also declares `decision_to_second_step_button` — without it the widget mounts and never appears, giving a blank window and an empty log. But declaring it makes `DecisionDetailView.HasNextStep` true, and `window_decisions_detail.gui:249-270` draws the next-step button and the confirm button under mutually exclusive `visible` conditions. So the confirm button can never share a page with the panel, and stepping across fires `ToggleCustomWidgetState`, which switches the panel off and vanilla's raw effect tooltip on. The primary action on that page can therefore never be the feature's own action. The compat check pins both halves of that arrangement, so if a patch ever decouples them this becomes possible again.
- Two further traps found on the way, worth knowing if a decision widget is ever wanted for something else: the controller must be `decision_option_list_controller` (`controller = default` has no gridbox wired up and logs `Missing gridbox '' in 'decisiondetail_view'`), and the widget must pin an explicit `size` (it mounts into a `dynamicgridbox`, which does not hand down an expanding height, so a `scrollbox` with only `layoutpolicy_vertical = expanding` resolves to zero and draws nothing, silently).
- **A long looping effect needs `hidden_effect` wherever its tooltip could be rendered.** The engine writes out every step: ten governors produce ten "You spend 30" lines plus, for the skill methods, ten full duel outcome tables. The panel's summary says the same in one line.
- The panel reprices when it opens and again whenever a dropdown is opened, so a window left sitting while influence accrues prices off current numbers.

- **The interaction is deliberately not fired.** `run_interaction` takes no `send_option`, so firing it would leave every `scope:*_boost` flag unset, the `switch` in `on_accept` would fall through to `fallback`, and the player would get a guaranteed success at the cheapest price with no duel rolled. The apply loop pays vanilla's cost block itself, writes vanilla's `on_send` cooldown, then calls `boost_governor_efficiency_success_effect` or `boost_governor_efficiency_duel_effect`. Those read only `scope:actor` and `scope:recipient`, which is what lets them be called without the interaction around them.
- **Eligibility is `is_character_interaction_valid`**, the engine asking the interaction itself, so a patch that regates Bolster Governance regates this for free. It is evaluated on the actor with the target named as recipient, hence the staged `scope:leo_oae_mbge_gov`. The interaction's `can_send` conditions are repeated alongside it because it is not certain the engine trigger covers `can_send`; repeating a condition can only narrow the pool. **If a recount ever reports zero targets at low influence, that trigger includes cost** and the repeated conditions become the whole gate.
- **The pool is `top_liege`'s vassals, not the player's.** Vanilla's `is_shown` asks for `recipient.top_liege = actor.top_liege`, so a player who is themselves a governor may bolster their peers. Looping over `root`'s vassals would quietly be narrower than vanilla.
- Prices come from vanilla's own constants (`minor_influence_value`, `medium_influence_value`, `medium_gold_value`), never from literals, so a rebalance patch is followed. Note vanilla's own `influence_boost` `send_option` checks for 60 while its cost block charges 90; the mod checks the real total, which is stricter and therefore safe.
- **Threshold codes 1-10 are append-only** and map to `t_m40 t_m30 t_m20 t_m10 t_0 t_10 t_20 t_30 t_all t_bud`. Code 9 is "every eligible governor" rather than "below 40" because vanilla's limit is *at most* 40, so a governor sitting exactly on 40 would otherwise be unreachable. Code 10 is the budget walk and never reaches `leo_oae_mbge_in_bucket_trigger`.
- Counts and costs are a snapshot from the last recount; **the Apply button's `is_valid` and a per-governor guard are what actually protect the treasury**, since both are re-asked live. Staleness can only ever bolster fewer governors than advertised.
- `ordered_vassal` sorts by `order_by` **descending**, so both budget orderings are negated script values.
- The smoke test and the fidelity test both live in this feature's `README.md` section. The fidelity test is the one that decides whether the hand-rolled payment is honest, so run it before shipping any change to the cost or the apply loop.

## Localization

The mod ships every language CK3 officially supports: english, french, german, spanish, russian, korean, simp_chinese, japanese, polish. English is the source of truth and hand-written (`localization/english/leo_oae_l_english.yml`); the others live at `localization/<lang>/leo_oae_l_<lang>.yml` and are **machine-generated, then hand-maintained**.

**Whenever you change an English localization value, update every translated file to match**: same keys in the same order, the changed value re-translated. Keep the CK3 markup identical across languages: concept links `[x|E]`, `$refs$`, `@icon!` tokens, `[recipient.GetX]` calls, `#weak`/`#V` … `#!` codes and `\n` are never translated, only the prose between them. In user-facing text the translations are described as **machine-generated**, never "AI" (see Hard rules).

Prefer reusing a vanilla loc key over writing a new one when the game already says exactly the right thing: it is free translation and it stays in step with the game's own wording.

## The limits that explain the design

These are engine facts, verified in game. Most odd-looking code in a CK3 mod follows from one of them.

### Real, and they are script-side

1. **Scripted effects cannot recurse.** Anything tree-shaped has to be capped at a fixed depth and unrolled by hand, one effect per level.
2. **An `ordered_*` iterator visits exactly one item unless given a range.** `every_*` iterates the whole list; `ordered_*` sorts and then takes only the top one, which is why vanilla uses it with `save_scope_as` to pick a single best candidate (`10_ach_effects.txt:2435`). To iterate many, pass `max = <n>` **and** `check_range_bounds = no`, as vanilla does (`01_fp1_wars.txt:1054`, commented "Basically, all of them"). Getting this wrong does not error: the loop silently does one item and everything downstream looks merely underwhelming rather than broken. `order_by` also sorts **descending**, so ascending needs a negated script value.
3. **A *script* variable name cannot be built at runtime.** `$X$` is a parse-time text macro, so a variable a script touches must be named literally in the source. This is what forces hand-written dispatch chains, and it is genuinely immovable.
4. **A trigger or condition cannot be chosen at runtime.** Write the chain once and drive it with a value staged into a temporary scope (`scope:leo_oae_...`), rather than duplicating the chain per case.
5. **GUI has no string comparison.** Only `Select_CString` (a selector) exists; there is no `IsEqual_CString` anywhere in vanilla. A datamodel item's identity is a string and can never be compared against a number in a variable. Work around it by having script pre-build one list per case and letting GUI pick the list by name, rather than filtering rows in GUI.

### Three things that look like limits and are not

The first two were verified wrong in game, with working probes. They are recorded because believing them leads straight to generating hundreds of near-identical widgets.

- **A variable name in a *GUI binding* CAN be built at runtime.** `Var()` and `GetList()` both accept a computed `CString`, not just a literal. Vanilla does it: `Story.MakeScope.Var( StoryCycleVariableVisualization.GetVariableName )` (`game/gui/window_situation_list.gui:741`) and `GetList( ... GetVariableName )` (`:1071`). Combined with `Concatenate`, one widget can bind a different variable per datamodel item. `blockoverride` cannot parameterize a binding, which is true and beside the point: the answer is a datamodel, not `blockoverride`.
- **GUI CAN pass a number to script.** `MakeScopeValue`, `MakeScopeFlag` and `MakeScopeBool` exist alongside `AddScope` and arrive script-side as `scope:name`. Verified working, despite having zero vanilla call sites. `GetScriptedGui()` also accepts a **computed** name, so a row can dispatch to `leo_oae_set_5` without that string appearing anywhere in the file.
- **Mods do not disable achievements.** CK3 stopped doing that in **1.9**, and it applies even to mods that alter the checksum, so adding `common/` script costs the player nothing. Do not hedge about achievements in user-facing text, and do not let the fear of them push a feature into being GUI-only.

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
- **There is no datafunction for a key binding, but the modifier names are loc keys.** The engine composes a widget's own shortcut hint from `PDX_TOOLTIP_SHORTCUT`, `SHORTCUT_KEY_MOD_ctrl|shift|alt|os` and `KEY_*` (`game/localization/*/keyboard_l_*.yml`), and that only happens for a widget that both declares a `shortcut` and shows a tooltip. To name a key in prose, reference those keys (`$SHORTCUT_KEY_MOD_ctrl$$SHORTCUT_KEY_MOD_shift$B`) rather than spelling it out: the game says Strg+ in German, Mayús+ in Spanish and Ctrl + with a space in Russian, and hand-written guesses get it wrong. Note `_os` is the Cmd/Windows key, so a binding written as `ctrl` stays Ctrl on macOS and needs no per-platform wording.
- **A mod cannot replace `gui/shortcuts.shortcuts`, and does not need to.** Vanilla pre-binds every key combination under a `### all the keys for modders ###` heading, one name per combination (`_g`, `_ctrl_shift_g`, `_alt_kp_4`, …), none of which vanilla itself uses. Name one from a widget's `shortcut` and the key is yours. Before claiming a combination, check that no vanilla binding whose name starts with a letter maps to the same keys.
- **A `shortcut` only fires while its widget is alive and taking input, so a hidden widget's shortcut does nothing.** This is why vanilla declares every map mode key twice: once on the button inside the Additional Map Modes flyout, which is hidden until opened and therefore only supplies the tooltip hint, and once in `hotkeys_HUD` (`game/gui/hud.gui`), a permanently present widget of nothing but shortcut-carrying buttons. A mod adds its own equivalent through `gui/scripted_widgets/` rather than overriding `hud.gui`. Gate such a widget with `enabled`, never `visible`: it has to stay alive to be listening.
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
