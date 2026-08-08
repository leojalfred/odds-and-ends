#!/usr/bin/env bash
# Static compatibility check.
#
# Every vanilla name this mod leans on, asserted against the installed game
# files. Run it after a CK3 patch: if Paradox renamed or removed something the
# mod mirrors, a line here turns FAIL and points at what broke, instead of
# finding out from a player.
#
#   bash tools/check_compat_static.sh
#   GAME_DIR=/path/to/game bash tools/check_compat_static.sh
#
# Two kinds of check. A "def" is strong: a specific definition must exist in a
# specific corner of the game files, and a miss is a FAIL. A "use" is a proxy
# for an engine built-in that has no definition file (a datafunction like
# CanChangeMapMode): the best a file scan can do is confirm vanilla still
# references it, so a miss is a WARN worth a look, not a certain break.
#
# This checks names, not behavior. A name that still exists but changed meaning
# passes here and is caught only by the smoke test in README.md. Run both after
# a patch.
#
# Exit status is non-zero if any def FAILs. WARNs do not fail the run.
set -uo pipefail

GAME="${GAME_DIR:-C:/Games/Steam/steamapps/common/Crusader Kings III/game}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

P=0; F=0; W=0
FAILS=""

_g() { grep -rqsE -- "$2" "$1" 2>/dev/null; }          # <path> <regex>

def()  { # <label> <subdir under GAME> <regex>   strong, FAIL on miss
	if _g "$GAME/$2" "$3"; then printf '  ok    %s\n' "$1"; P=$((P+1))
	else printf '  FAIL  %s\n' "$1"; F=$((F+1)); FAILS="$FAILS\n  - $1"; fi
}
ndef() { # <label> <subdir under GAME> <regex>   strong, FAIL if PRESENT
	if _g "$GAME/$2" "$3"; then printf '  FAIL  %s\n' "$1"; F=$((F+1)); FAILS="$FAILS\n  - $1"
	else printf '  ok    %s\n' "$1"; P=$((P+1)); fi
}
use()  { # <label> <regex>                        proxy against GUI, WARN on miss
	if _g "$GAME/gui" "$2"; then printf '  ok    %s\n' "$1"; P=$((P+1))
	else printf '  warn  %s (vanilla GUI no longer uses it - verify by hand)\n' "$1"; W=$((W+1)); fi
}
suse() { # <label> <regex>                        the same for script built-ins
	if _g "$GAME/common" "$2"; then printf '  ok    %s\n' "$1"; P=$((P+1))
	else printf '  warn  %s (vanilla script no longer uses it - verify by hand)\n' "$1"; W=$((W+1)); fi
}
file() { # <label> <path under GAME>              strong, FAIL if missing
	if [ -f "$GAME/$2" ]; then printf '  ok    %s\n' "$1"; P=$((P+1))
	else printf '  FAIL  %s\n' "$1"; F=$((F+1)); FAILS="$FAILS\n  - $1"; fi
}

echo "Checking against: $GAME"
[ -d "$GAME" ] || { echo "  game directory not found - set GAME_DIR"; exit 2; }

echo
echo "The map mode itself"
# The mode the button selects. If this goes, the feature has nothing to select.
def  "admin_vassal_types_map map mode defined" \
     "gfx/map/map_modes/map_modes.txt" "^admin_vassal_types_map = [{]"
# The reason the mode is worth surfacing: it is the one the administrative
# government panel opens on. If the panel stops using it, ours is no longer
# "the same view" and the description is a lie.
def  "administration panel still opens on it" \
     "gui/window_government_administration.gui" "SetMapMode\( *'admin_vassal_types_map' *\)"
# Two loc keys the mod defines in vanilla's namespace, because the engine
# derives a map mode's name and description keys from the map mode's name.
# Harmless while vanilla leaves them undefined; a duplicate the moment it
# does not.
ndef "vanilla still leaves its loc keys undefined" \
     "localization" "^ *admin_vassal_types_map(_desc)?:"

echo
echo "The gate (mirrors vanilla's own administration tab)"
def  "noble_families government rule"        "common/governments" "noble_families = yes"
def  "celestial_government"                  "common/governments" "^celestial_government = [{]"
def  "japan_administrative_government"       "common/governments" "japan_administrative_government = [{]"
def  "japan_feudal_government"               "common/governments" "^japan_feudal_government = [{]"
# The tab whose visibility the button's own visibility copies. If vanilla
# regates it, re-derive the button's condition from hud.gui.
def  "administration tab gated the same way"  "gui/hud.gui" \
     "Character.GetGovernment.HasRule\( *'noble_families' *\)"

echo
echo "What the button is built from"
def  "icon_button_mapmode type"              "gui/shared/buttons.gui" "type icon_button_mapmode"
def  "flowcontainer_additional_mapmodes type" "gui/shared/mapmodes.gui" "type flowcontainer_additional_mapmodes"
def  "map_mode_government_button (our button follows it)" "gui/shared/mapmodes.gui" "map_mode_government_button"
file "button icon"    "gfx/interface/icons/flat_icons/administrative.dds"
file "texticon art"   "gfx/interface/icons/government_types/administrative_government.dds"
use  "CanChangeMapMode"                      "CanChangeMapMode"
use  "GetMapMode"                            "GetMapMode\("
use  "GetPlayer.GetTopLiege"                 "GetPlayer.GetTopLiege"

echo
echo "The keyboard shortcut"
# The mod binds no key of its own: CK3 does not let a mod replace
# shortcuts.shortcuts, so vanilla pre-binds every combination under a heading
# that says as much, and the mod just names one. If that block goes, the
# shortcut silently stops resolving.
def  "the modders' key block still exists"   "gui/shortcuts.shortcuts" "all the keys for modders"
def  "_ctrl_shift_g still bound"             "gui/shortcuts.shortcuts" "_ctrl_shift_g = \"ctrl\+shift\+g\""
# Nothing in vanilla may claim ctrl+shift+G, or the two fight over the key. The
# leading letter excludes the modders' own _ctrl_shift_g, which is the binding
# we name; every real action's name starts with a letter.
ndef "ctrl+shift+G is still ours alone"      "gui/shortcuts.shortcuts" \
     "^[[:space:]]*[a-zA-Z][a-zA-Z0-9_]* = \"ctrl\+shift\+[gG]\""
# The always-present widget carrying the key is modelled on this one.
def  "hotkeys_HUD (the pattern we copy)"     "gui/hud.gui" "type hotkeys_HUD"
def  "scripted widget loader"                "gui/scripted_widgets" "widget"

echo
echo "The overridden file"
# The mod ships a copy of vanilla's mapmodes.gui, edited. A patch that touches
# that file leaves the copy stale, and anyone running the mod silently keeps the
# old panel. The copy cannot be checked by diffing it against vanilla, because
# the edit deliberately moves vanilla buttons between rows: a legitimate diff and
# a patch's diff look alike. So pin the vanilla file this copy was made from
# instead, and fail the moment the installed one stops matching.
#
# Re-copying, when this fails:
#   1. cp "$GAME/gui/shared/mapmodes.gui" gui/shared/mapmodes.gui
#   2. Re-apply the header comment, keeping the UTF-8 BOM first in the file.
#   3. In flowcontainer_additional_mapmodes, re-apply the reflow: move
#      map_mode_landless_rulers_button to the end of the first row, move
#      map_mode_counties_button to the end of the second, and add the Governors
#      button after map_mode_government_button in the third. That keeps reading
#      order across the whole flyout identical to vanilla's while leaving every
#      row four wide.
#   4. Update VANILLA_SHA below to the new hash the failure prints.
VANILLA_SHA="da8ba748c8d6e1ed05e0acfbc46f88963757291db8f2d37ed1fbd8b3802bcd40"
VAN="$GAME/gui/shared/mapmodes.gui"
OURS="$ROOT/gui/shared/mapmodes.gui"
if [ ! -f "$VAN" ] || [ ! -f "$OURS" ]; then
	printf '  FAIL  mapmodes.gui copy is checkable\n'; F=$((F+1))
	FAILS="$FAILS\n  - mapmodes.gui copy is checkable"
else
	GOT="$(sha256sum "$VAN" | cut -d' ' -f1)"
	if [ "$GOT" = "$VANILLA_SHA" ]; then
		printf '  ok    copy was made from the installed vanilla file\n'; P=$((P+1))
	else
		printf '  FAIL  vanilla mapmodes.gui has changed - re-copy and re-apply (new hash %s)\n' "$GOT"
		F=$((F+1)); FAILS="$FAILS\n  - vanilla mapmodes.gui has changed since the copy was made"
	fi
	# Cheap proof the re-copy was actually finished, not just pasted over.
	for want in leo_oae_map_mode_governors_button map_mode_landless_rulers_button map_mode_counties_button; do
		if grep -q "$want" "$OURS"; then
			printf '  ok    %s present in the copy\n' "$want"; P=$((P+1))
		else
			printf '  FAIL  %s missing from the copy\n' "$want"
			F=$((F+1)); FAILS="$FAILS\n  - $want missing from the copy"
		fi
	done
fi

echo
echo "Mass Bolster Governance - the interaction it stands in for"
# The whole feature is this one interaction, applied many times. If it is
# renamed or removed, nothing here has anything to do.
def  "boost_efficiency_interaction defined" \
     "common/character_interactions" "^boost_efficiency_interaction = [{]"
# The two effects the mass action calls in place of the interaction's on_accept.
# These are vanilla's own, which is what makes a mass bolster identical to a
# hand-sent one. They read scope:actor and scope:recipient and nothing else; if
# that stops being true, the run breaks quietly rather than loudly.
def  "boost_governor_efficiency_success_effect" \
     "common/scripted_effects" "^boost_governor_efficiency_success_effect = [{]"
def  "boost_governor_efficiency_duel_effect" \
     "common/scripted_effects" "^boost_governor_efficiency_duel_effect = [{]"
# The duel effect takes the skill by macro. All three we pass must still be
# accepted, and the interaction must still route them the same way.
def  "on_accept still routes the three skill options" \
     "common/character_interactions" "boost_governor_efficiency_duel_effect = [{] SKILL = stewardship [}]"
# The panel quotes the odds on the three skill methods, which means it repeats
# vanilla's duel arithmetic rather than reading it. Each of these three numbers
# is one the mod hardcodes a mirror of, so a rebalance that changes any of them
# turns every percentage on screen into a lie without anything else noticing.
def  "duel target rating"        "common/script_values" "^mediocre_skill_rating = "
def  "duel skew per skill point" "common/scripted_effects" "value = scope:duel_value[[:space:]]*$|multiplier = 1\.5"
def  "duel weight floor"         "common/scripted_effects" "min = -49"
# The cooldown is a variable list on the recipient, not a cooldown field, so the
# mass action has to write it by hand. Both names are read when deciding who is
# still eligible.
def  "efficiency_boosters cooldown list"  "common/character_interactions" "name = efficiency_boosters"
def  "efficiency_damagers cooldown list"  "common/character_interactions" "name = efficiency_damagers"

echo
echo "Mass Bolster Governance - what it counts and what it charges"
# Efficiency as the interface states it, which is what the thresholds compare
# against and what vanilla's own eligibility limit is written in.
def  "governor_efficiency_presented"      "common/script_values" "^governor_efficiency_presented = [{]"
def  "boost_efficiency_maximum_value"     "common/script_values" "^boost_efficiency_maximum_value = "
# The three constants the cost block is built from. Reading vanilla's own names
# rather than hardcoding 30, 60 and the gold formula is what keeps a mass
# bolster priced exactly like a hand-sent one after a rebalance.
def  "minor_influence_value"              "common/script_values" "^minor_influence_value = "
def  "medium_influence_value"             "common/script_values" "^medium_influence_value = "
def  "medium_gold_value"                  "common/script_values" "^medium_gold_value = [{]"
# The cost block itself, so a patch that changes which currencies are charged,
# or drops the per-recipient gold, is caught rather than silently mispriced.
def  "cost is still minor influence plus medium gold" \
     "common/character_interactions" "value = scope:recipient\.medium_gold_value"

echo
echo "Mass Bolster Governance - script built-ins it leans on"
# Engine triggers and effects with no definition file of their own. The best a
# file scan can do is confirm vanilla still uses them.
suse "is_character_interaction_valid"     "is_character_interaction_valid = [{]"
suse "is_governor"                        "is_governor = yes"
suse "ordered_vassal with order_by"       "ordered_vassal = [{]"
suse "government_allows = administrative" "government_allows = administrative"
suse "change_influence"                   "change_influence = [{]"
suse "remove_short_term_gold"             "remove_short_term_gold = "
# The pool is top_liege's vassals, not the player's, because that is what the
# interaction's own is_shown asks for. If this clause goes, re-derive the
# iterator rather than leaving it as it is.
def  "recipient shares the actor's top liege" \
     "common/character_interactions" "top_liege = scope:actor\.top_liege"

echo
echo "Mass Bolster Governance - the panel and the way in"
def  "admin decision group still exists"  "common/decision_group_types" "^admin = [{]"
file "decision picture"  "gfx/interface/illustrations/decisions/decision_misc.dds"
# Why the panel is a window of ours and not the decision's own body. A decision
# widget is shown only if the decision declares a second step, and declaring one
# makes the window draw its next-step button in place of its confirm button, so
# Bolster Governance could never be the primary action on that page. These two
# pin that arrangement: if a patch ever decouples them, the panel could move
# into the decision window and this is what would say so.
def  "next-step and confirm are still mutually exclusive" \
     "gui/window_decisions_detail.gui" "Not\( DecisionDetailView.HasNextStep \)"
def  "stepping across still toggles the custom widget" \
     "gui/window_decisions_detail.gui" "ToggleCustomWidgetState"
use  "header_pattern"        "type header_pattern = "
# Copied into the panel rather than overridden, because vanilla sets
# button_trigger = none on both and that would swallow our onclick. Re-diff the
# copies in gui/leo_oae_mbge_panel.gui when these change.
def  "button_drop type"      "gui/shared/buttons.gui" "type button_drop = "
def  "button_dropdown type"  "gui/shared/buttons.gui" "type button_dropdown = "
use  "Background_DropDown"   "template Background_DropDown"
use  "text_label_left"       "type text_label_left = "
use  "scrollbox_content block"        "block \"scrollbox_content\""
use  "scrollbox_background_fade block" "block \"scrollbox_background_fade\""
def  "on_game_start_after_lobby" "common/on_action" "^on_game_start_after_lobby = [{]"
# The shortcut. Same arrangement as the map mode's: vanilla pre-binds the
# combination, the mod only names it.
def  "_ctrl_shift_b still bound"          "gui/shortcuts.shortcuts" "_ctrl_shift_b = \"ctrl\+shift\+b\""
ndef "ctrl+shift+B is still ours alone"   "gui/shortcuts.shortcuts" \
     "^[[:space:]]*[a-zA-Z][a-zA-Z0-9_]* = \"ctrl\+shift\+[bB]\""

echo
echo "Mass Bolster Governance - vanilla text it reuses"
# The five method names and the button are pointed at vanilla's own keys, so
# they translate for free and stay in step with the game's wording. A rename
# here shows up on screen as a raw key.
def  "influence_boost_desc"    "localization/english" "^ *influence_boost_desc:"
def  "gold_boost_desc"         "localization/english" "^ *gold_boost_desc:"
def  "diplomacy_boost_desc"    "localization/english" "^ *diplomacy_boost_desc:"
def  "stewardship_boost_desc"  "localization/english" "^ *stewardship_boost_desc:"
def  "intrigue_boost_desc"     "localization/english" "^ *intrigue_boost_desc:"
def  "boost_efficiency_interaction (button label)" \
     "localization/english" "^ *boost_efficiency_interaction:"
def  "governor_efficiency concept"  "common/game_concepts" "^governor_efficiency = [{]"
def  "governor concept"             "common/game_concepts" "^governor = [{]"
# Linked as [diplomacy|E] and friends, which are aliases rather than concepts in
# their own right.
def  "skill concept aliases"        "common/game_concepts" "alias = [{] diplomacy_i diplomacy [}]"

echo
printf '%s ok, %s failed, %s warned\n' "$P" "$F" "$W"
if [ "$F" -gt 0 ]; then printf 'Failures:%b\n' "$FAILS"; exit 1; fi
