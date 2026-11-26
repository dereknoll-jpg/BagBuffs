# BagBuffs 1.0 release review

Updated November 25, 2026. Current build: **1.0.0-rc.6**. No game was opened for this review or the media package.

## What is ready

- BagBuffs branding, a renamed GitHub repository, and an automatic legacy-profile import that preserves old data, per-item keys and native grid-slot binding targets.

- Auto sorting by default removes gaps and unnecessary pages, with restorable Manual mode, Compact only, a pouch quick menu and a toggleable brief new-item highlight.
- Compact grid, automatic carried-bag discovery, duplicate stack counts, category filters, manual includes/exclusions and favorites.
- Layout presets/custom dimensions, movable settings window, direct grid reordering and per-character manual order.
- Pouch Shift-right-click lock toggle, pouch dragging for whole-grid movement, and a narrow-layout move-handle overlap fix.
- rc.2 fixes missed drag-stop callbacks with mouse-up/global/polling completion, supports empty-slot placement and swaps, and preserves saved slots while appending new acquisitions.
- Stable per-item quick bindings with conflict confirmation; the underlying normal key action returns after clearing a binding.
- Explicit item cooldown numbers and readable Recently Bandaged expiry, without an assumed duration.
- Separate edit hit areas: dragging does not rewrite the secure item actions. Native combat visibility hides editing areas in combat.
- Automated Lua 5.1 parsing and runtime scenarios for discovery, ordering, bindings, timers, restricted data, combat mutation guards, canceled drops and cross-surface dragging.
- Installable addon ZIP, original 400px/1024px icons, static banner and feature sheet, listing copy, changelog and upload guide.

## Remaining live verification

1. **Native drag and combat smoke test.** Confirm direct dragging never consumes an item; locked mouse clicks and item keybindings work; combat hides the editing layer and leaves items usable. Test key-down settings both ways and watch for blocked-action errors. The mock validates the intended state-driver contract but cannot prove the client dispatches events identically.
2. **Real cooldown sample.** Use a potion and bandage, including an interrupted channel. Compare countdowns with the game. Try Field Medicine if available. Hidden debuff timing must not produce an invented numeric timer.
3. **Upgrade and inventory coverage.** Load an existing character profile, reload, sort bags, loot a new supported consumable, exhaust/reacquire an item and inspect a dual-purpose item such as a rune. Test at least the player's normal consumable mix. Unknown and localized cases need clear manual recovery.
4. **Small-screen check.** Confirm the settings panel, binding prompt, narrow layout, icon lock shortcut and item text remain usable at the player's normal UI scale.
5. **Publication choices.** Verify the final Forever version tag in the uploader, confirm the desired license (All Rights Reserved supplied by default), and enable comments for feedback. The actual listing is not created by this package.
6. **Rename upgrade in the real client.** Extract all three addon folders over an existing install, restart, and check the imported profile on an existing character. Verify custom item keys and old native slot keys. Reload and confirm that later changes to the new profile are not overwritten by another import. The offline suite covers the migration data and aliases; the client controls saved-variable file loading.

These are validation gates, not requests for more features. The 1.0.0-rc.6 release candidate retains the existing feature set. Offline checks pass; the native-client checks below have not been observed in this release session. Use LIVE-CHECKS.md for the expanded checks.

## Changes I would defer to 1.1

- Optional rank grouping or a family flyout to reduce repeated potion/scroll ranks. Keep every item accessible and let players choose the rule; “strongest” needs reliable family and usability data.
- Optional active-food/scroll/weapon-coating status, once spell/enchant identities and restricted aura behavior have been validated.
- Search/filter in the editor and additional languages after collecting actual missed-item reports.

Avoid expanding 1.0 into automatic recommendations or one-click buff chains. The useful promise is visible supplies, dependable controls, and accurate information when the client exposes it.

## Media accuracy

The icon is original project branding. Banner and feature sheet were created with the built-in image generator and visibly identify themselves as illustrations rather than game screenshots. There are no gameplay captures or GIFs. This follows [CurseForge's artwork/disclosure guidance](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies).
