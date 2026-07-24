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
printf '%s ok, %s failed, %s warned\n' "$P" "$F" "$W"
if [ "$F" -gt 0 ]; then printf 'Failures:%b\n' "$FAILS"; exit 1; fi
