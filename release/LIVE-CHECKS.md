# In-client checks before stable release

## Automatic organizing in 1.0.0-rc.4

- Upgrade a profile with gaps and items on page two. Verify Auto is selected and items fill page one before spilling over. Choose Manual and verify the previous exact layout returns.
- Loot a new scroll, exhaust a potion, hide an item and change categories. Auto should close gaps and retain type/name order; Manual should preserve slots.
- Ctrl-left-click the pouch: type sort and compact without opening settings. Right-click for the quick menu; test Auto/Manual, Compact only, highlights and lock. Shift-right-click must still toggle the lock.
- Verify new discoveries have a gold rim for eight seconds, including when first viewing another page. Login inventory and additional stacks should stay quiet. Disable highlights and verify no glow remains.
- Acquire items during combat and during a drag; positions must wait until the fight or drag ends. Verify item keys continue to use the same items.

## SatchelSense rename upgrade

- Install both bundled folders over the old addon and keep Settings Import enabled. Restart WoW to discover the new addon.
- On an existing character, verify layout, screen position, empty slots, filters, favorites, exclusions/includes and item keys. Test an older native grid-slot key too.
- Change a SatchelSense preference, reload, and verify it remains changed. The old profile must not overwrite it on every login.
- Confirm only one grid is present. The import component must have no independent HUD, timers or item actions.

This release has passed offline Lua checks. No live WoW session was available during creation.

1. Install both bundled folders with SatchelSense and Settings Import enabled. Confirm no load error and verify the custom pouch icon appears in the addon list and `/satchel` header.
2. Carry duplicate healing and mana potions, a stat scroll, buff food, plain food, an oil or stone, and a bandage. Check that identical stacks combine, buff food appears, and plain food appears only when enabled.
3. Loot or buy a new eligible item; move/split/sort stacks, consume the last of one item, then reload. Check counts, discovery, removals and saved preferences.
4. Left-click a potion or scroll with an enemy targeted: it must apply to the player. Verify keybindings do the same and a click consumes exactly one item. Test the game's key-down setting both ways.
5. Use an oil or stone: verify that native item targeting opens and you can choose the correct equipped weapon. Check that canceling and replacement confirmations behave normally. Try armor kits and fishing lures separately.
6. Test 3×3, 1×8, 8×1 and custom dimensions; change size, gap, scale and position. Confirm empty slots do not block camera or world interaction. Hide the launcher and use `/satchel` to restore it.
7. Carry more than nine eligible item types. Check next/previous/wheel paging and favorites; verify no item disappears from the page set.
8. Enter combat, consume a potion, move a stack and acquire an eligible item. Check existing counts/cooldowns update but actions and positions stay fixed. Try paging and layout changes: they must be refused. Confirm the full grid refreshes after combat.
9. Test native item cooldowns, including shared potion cooldowns, and a minimum-level item. Check too-high items dim and real game errors remain informative.
10. Test Demonic Rune and other dual-purpose objects; confirm raw stone, recipes, offensive bombs, trinkets and bank contents are absent from automatic discovery. Use a manual include and exclusion, then reload.
11. Check the actual client's numeric consumable subclasses against representative bag items. Capture unfamiliar item IDs and tooltips for discovery improvements. Non-English clients need explicit food/utility coverage review.

Capture real gameplay screenshots after these pass. Do not publish a mockup as an in-game capture.

## Direct grid editing in 1.0.0-rc.2

- Unlock and drag directly between grid slots. Confirm no item gets consumed. Drop into an empty slot, swap two occupied slots, and release outside the grid to cancel. The floating drag image must disappear on release, even if the source never receives drag-stop.
- Close the editor, Shift-right-click the pouch to unlock, then drag grid items and drag the pouch to move the whole display. Shift-right-click again to lock; left-click an item and confirm normal use resumes.
- Test a 1x8 grid: the move handle must not cover the pouch. Try UI scale and icon-size extremes.
- Enter combat while unlocked and while a grid drag is in progress. The edit hit layer must hide and the normal item buttons must remain usable. Repeat with ActionButtonUseKeyDown on and off. Check for blocked-action/taint errors.
- Check grid-to-editor and editor-to-grid drops, changes across pages, and saved order after reload.
- Lock the grid while settings remain open: direct grid dragging must stop. Pick up a new scroll/potion, sort bags, reload and reacquire an exhausted item. In Manual mode, existing slots must stay unchanged and newly detected items must append after the saved layout.

## Version 0.2.0 additions

- Open Items & Keys, drag an editor item icon onto another row, and use the move arrows across a page boundary. Compare the resulting live grid; reload and confirm saved order. Switch Auto / Manual and By type / A - Z and confirm manual order is retained.
- Bind a potion with a modifier key. Sort it, change grid pages, hide its icon, run out and acquire more. The key must always reference the same item ID. Check side mouse and wheel capture separately.
- Try an occupied action-bar key; cancel and confirm the old action remains. Accept reassignment, then clear it with Backspace/Delete and confirm the old action returns. Escape must cancel capture. Entering combat must cancel capture and refuse edits while existing bound items remain usable.
- Use a potion and check the centered countdown and shared potion cooldowns with the game's cooldown-number option disabled.
- Bandage yourself, stop the channel, and compare all bandage icons against the actual Recently Bandaged debuff. Test duration-reducing effects if available. No invented timer should appear when aura timestamps are unavailable.
