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

#### Checking it still works

The shortest run that exercises the gate and the happy path once. Steps 4 and 5 are the ones that catch a patch quietly moving something, since both depend on vanilla files this feature either copies or mirrors.

1. As a **Byzantine** ruler, open the `+` flyout and confirm the Governors button sits directly after Governments. Click it and confirm the map paints your vassals by role, and that the mode's name and description read as words rather than as raw keys.
2. Press **ctrl+shift+G** with the flyout closed and the map in view. It must switch modes. This is the half of the shortcut that only works because the key is declared a second time outside the flyout, so a failure here is silent and easy to miss.
3. Hover the flyout button and confirm the tooltip names ctrl+shift+G.
4. Open the Administrative Government panel and close it. The panel must still select this view on open and still drop back to Realms on close, exactly as it does without the mod.
5. Confirm the flyout is still four buttons wide on every row, with Landless Rulers at the end of the first and County Titles at the end of the second.
6. As a **feudal** ruler with no administration panel, confirm the Governors button is absent and ctrl+shift+G does nothing.
7. As a **vassal governor** inside an administrative realm, confirm the button is present, since the gate follows your top liege rather than you.
8. As a **Chinese or Japanese** ruler whose government carries an administration panel of its own, confirm the button is present.

### Mass Bolster Governance

Bolsters the government efficiency of many governors in one action, instead of opening each of them in turn.

Once your realm is settled, Bolstering Governance is where most of your influence goes, and spending it means clicking through governors one at a time. This adds a **Mass Bolster Governance** decision, and the keyboard shortcut **ctrl+shift+B**, either of which opens a panel. The shortcut goes straight there; the decision explains what it does first and then opens the same panel. Everything is chosen in that one scrolling window, and the **Bolster Governance** button at the bottom of it does the whole run in a single click.

In it you pick two things. First the method: the same five the game offers you when you bolster a single governor, Divert Resources, Grease Palms, and the three that test your diplomacy, stewardship or intrigue. Those three carry their success chance next to the name, the same figure the game shows in its own Possible Outcomes panel, so you can weigh a cheap gamble against a certainty without opening a governor to look. Second how far down the list to go, from the governors below -40% efficiency up to every governor the game will let you touch. The panel then tells you how many governors that comes to and what it will cost, and a level you cannot pay for in full is grayed out. Gold is only ever quoted for Grease Palms, since it is the only method that charges any.

There is also an **As Many As I Can Afford** setting, which works down the list spending what you have and stopping when it runs out. It starts with the governors who need it most. Grease Palms is the one method that charges a different price for each governor, since the bribe is scaled to what they earn, so when it is selected you also get to choose whether to spend on the worst governed first or on the cheapest first.

Below that is the list of governors the run will actually visit, worst governed first. Each row names the theme they hold and gives their portrait, name, age and current governance, colored and broken down on hover exactly as the character sheet does it, along with who they are to you and their house. Under Grease Palms it also shows what that governor will cost.

Untick any of them to exclude them, and the count and the bill above drop to match. The row keeps its place, so nothing jumps around under the cursor. Excluding a governor sticks with that governor, including across a succession.

Nothing here reaches past what you could already do by hand. Each bolster is the game's own, at the game's own price, with the game's own odds, so the three skill methods can still fail and still charge you when they do. Governors the game would refuse are refused here too: any already above 40% efficiency, and any you have bolstered or undermined within the last two years. Each one reports its result exactly as it would have if you had visited them yourself.

If you are a governor rather than the ruler at the top, your fellow governors are on the list, because those are the ones the game already lets you bolster.

The panel counts and prices things when you open it and whenever you change a setting, so if you leave it sitting while influence accrues, reopen a dropdown to bring the figures up to date. Whether you can actually afford what you are about to do is checked as it happens, so the totals going stale can only ever mean fewer governors bolstered, never a treasury in the red.

#### Checking it still works

The shortest run that exercises every gate and the happy path once. Start an administrative realm with several governors of differing efficiency.

1. As a **non-administrative** ruler, the decision is absent from the list and ctrl+shift+B does nothing.
2. As an administrative ruler, take the decision and confirm the panel opens. Close it, press ctrl+shift+B, and confirm the panel opens straight away with no decision window in between. Press it again and confirm the panel closes.
3. A governor already above 40% efficiency appears in no threshold, including Every Eligible Governor.
4. Bolster one governor by hand through the game's own interaction, reopen the panel, and confirm they have dropped out of the pool for the next two years.
5. Pick a threshold you cannot pay for and confirm it is grayed and unclickable. Drop to one you can and confirm the count matches the governors on the map.
6. Select Grease Palms and confirm the Order dropdown appears and the total starts quoting gold. Select any other method and confirm both go away.
7. Open a governor's own Bolster Governance window, read the success chance it shows for Burnish Reputation, and confirm the panel's Method list quotes the same number. The panel repeats the game's arithmetic rather than reading it, so this is the step that catches a drift.
8. Run **As Many As I Can Afford** with enough on hand for everyone and confirm it reaches all of them, not one. Then run it with enough for only two or three and confirm influence lands at or above zero, never below.
9. Click **Bolster Governance** at the bottom of the panel once, and confirm the whole selection is bolstered in that single click without leaving the page. The count and cost above should drop to reflect what is left.
10. Untick a governor and confirm the count and the total both drop, that the row stays exactly where it was, and that re-ticking restores both. Then untick one and bolster, and confirm they were left alone.
11. As a vassal governor rather than the ruler at the top, confirm your peers appear in the pool.
12. Save with the panel open, reload, and confirm it is shut and your settings survived.

**The test that actually matters** is that a mass bolster is indistinguishable from a hand-sent one. Record your influence, your gold, a governor's efficiency, their modifier, their efficiency stack and their cooldown. Bolster that governor by hand with Divert Resources and record every delta. Reload, then mass-bolster that same governor alone with the same method. Every delta must match exactly. Repeat for Grease Palms, whose gold price is worked out per governor and is the likeliest place for a mismatch to hide.

## Installing

Subscribe on the Workshop, or drop the folder into `Documents/Paradox Interactive/Crusader Kings III/mod` and enable it in the launcher.

## Compatibility

The Governors map mode is drawn by replacing one game interface file, `gui/shared/mapmodes.gui`. Any other mod that rearranges the map mode picker will replace the same file, and whichever of the two loads last wins. If the Governors button is missing while you are running another interface mod, load this one after it.

Mass Bolster Governance replaces no game file at all. Its panel is added alongside the game's own interface, and it changes nothing about the Bolster Governance interaction itself, so a mod that rebalances what a bolster costs or who may receive one is followed rather than fought.

Both features are safe to add to a game in progress, and neither costs you achievements: Crusader Kings III stopped disabling those for modded games in 1.9. Removing Mass Bolster Governance from a save leaves behind the handful of settings the panel remembered, which the game discards harmlessly. Nothing it did to a governor is undone, because everything it did was the game's own doing in the first place.
