# Leo VI's Odds and Ends

A collection of small quality-of-life fixes for **Crusader Kings III (1.19.x)**. Each one is independent: they share nothing, and any of them would be worth having on its own.

Nothing here changes what your character is allowed to do. Every feature is a shortcut to something the game already lets you reach, gated by the game's own rules about who may reach it.

It requires **no DLC**. Features that only make sense alongside one check for it themselves and stay out of the way otherwise.

The mod ships in every language Crusader Kings III supports. English is written by hand; the other translations are machine-generated and corrected by hand, so an awkward line is a bug worth reporting.

## Features

### Governors

Adds a **Governors** map mode to the map mode picker, under the `+` for additional map modes, right after Governments.

It is the view the game already switches to whenever you open your Administrative Government panel: your direct vassals painted by the role each of them holds. Until now that view came with the panel sitting on top of it, and the moment you closed the panel to see the map, the game put you back on Realms. This makes it a map mode like any other, so you can read it, keep it, and zoom around in it.

It has a keyboard shortcut like the other map modes: **ctrl+shift+G**. G already carries two map modes, and this is the free combination nearest to it. Nothing in the game uses it, so no existing shortcut is taken away.

The button appears only if you could open that panel in the first place. In practice that means your realm runs on administrative government, whether you rule it or serve in it, along with the Chinese and Japanese governments that have an administration panel of their own. Everyone else never sees it.

Nothing else changes. The panel still selects the view when it opens and still drops back to Realms when it closes, exactly as it always did.

Fitting a fifth button into the governments row would have widened the whole picker, so Landless Rulers and County Titles each shift up to the end of the row above. Every row stays four wide and the picker reads in the same order it always has.

## Installing

Subscribe on the Workshop, or drop the folder into `Documents/Paradox Interactive/Crusader Kings III/mod` and enable it in the launcher.

## Compatibility

The Governors map mode is drawn by replacing one game interface file, `gui/shared/mapmodes.gui`. Any other mod that rearranges the map mode picker will replace the same file, and whichever of the two loads last wins. If the Governors button is missing while you are running another interface mod, load this one after it.
