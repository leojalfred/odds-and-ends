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
def  "map_mode_government_button (insertion point)" "gui/shared/mapmodes.gui" "map_mode_government_button"
file "button icon"    "gfx/interface/icons/flat_icons/administrative.dds"
file "texticon art"   "gfx/interface/icons/government_types/administrative_government.dds"
use  "CanChangeMapMode"                      "CanChangeMapMode"
use  "GetMapMode"                            "GetMapMode\("
use  "GetPlayer.GetTopLiege"                 "GetPlayer.GetTopLiege"

echo
echo "The overridden file"
# The mod ships a copy of vanilla's mapmodes.gui with one button added. A patch
# that edits that file leaves the copy stale and silently reverts the patch's
# changes for anyone running the mod. Expect a purely additive diff: our header
# and our block, nothing removed and nothing changed.
VAN="$GAME/gui/shared/mapmodes.gui"
OURS="$ROOT/gui/shared/mapmodes.gui"
if [ ! -f "$VAN" ] || [ ! -f "$OURS" ]; then
	printf '  FAIL  mapmodes.gui copy is diffable\n'; F=$((F+1))
	FAILS="$FAILS\n  - mapmodes.gui copy is diffable"
else
	# Anything the diff removes or rewrites means vanilla moved on without us.
	DRIFT="$(diff "$VAN" "$OURS" | grep -c '^<' || true)"
	# Line 1 always shows as a rewrite, because the header is prepended to it.
	if [ "$DRIFT" -le 1 ]; then
		printf '  ok    mapmodes.gui copy is vanilla plus our block only\n'; P=$((P+1))
	else
		printf '  FAIL  mapmodes.gui copy has drifted from vanilla (%s changed lines) - re-copy and re-insert\n' "$DRIFT"
		F=$((F+1)); FAILS="$FAILS\n  - mapmodes.gui copy has drifted from vanilla"
	fi
	if grep -q 'leo_oae_map_mode_governors_button' "$OURS"; then
		printf '  ok    our button is present in the copy\n'; P=$((P+1))
	else
		printf '  FAIL  our button is missing from the copy\n'
		F=$((F+1)); FAILS="$FAILS\n  - our button is missing from the copy"
	fi
fi

echo
printf '%s ok, %s failed, %s warned\n' "$P" "$F" "$W"
if [ "$F" -gt 0 ]; then printf 'Failures:%b\n' "$FAILS"; exit 1; fi
