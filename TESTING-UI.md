# Historical local preview notes

The final fitted-skin preview was approved by Derek on November 26, 2026 and promoted to 1.0.0-rc.7. The notes below document the earlier local-only test stages.

# Local UI preview: 1.0.0-rc.7-test.3

Installed for testing only. No commit, GitHub push, release tag or CurseForge upload has been made for this preview. Existing published screenshots and the upload kit are intentionally unchanged pending feedback.

## Try it

- Use /reload, open /bagbuffs, then Layout > Appearance > Bag Trim. Minimal remains the default for all profiles until selected.
- Compare 3x3, 1x8, 8x1 and a custom grid; try a partly filled last page. The trim follows visible slots, leaves the center transparent and does not consume empty-slot clicks.
- Switch back to Minimal. Position, manual slots, sorting mode and item keys should stay unchanged.
- Right-click a grid item while locked or unlocked. Try Favorite, Bind key, Hide and Settings. Middle-click still hides directly; restore items in Items & Keys.
- Bind key opens its prompt without opening settings. Escape cancels; occupied keys still ask for confirmation.
- Verify selected tabs, grid presets, appearance and Auto/Manual controls have a gold selected state. Hover Compact only and Favorite for explanations.
- Enter combat while the menu or binding prompt is open. Those controls should close; item clicks, keys and cooldowns should continue working with fixed slots.

Useful future screenshots: a locked 3x3 with Bag Trim, a 1x8 or 8x1 trim layout, the item context menu, and the updated Layout settings. These should be real in-game captures after the local test is accepted.

## Checks completed

Offline Lua parsing and runtime checks cover all 64 supported grid shapes, sparse and empty pages, edge tiling/fixed corners, combat guards, direct item binding, menu targets and profile/key preservation. Native artwork rendering and input still require the requested in-game test.

## Leather revision 2

Bright square gold outline removed. New softly rounded leather art and muted stitches replace it. The pouch menu is enlarged slightly and mounted on an attached leather tab at the bottom; all click shortcuts and unlocked drag-to-move remain. Page controls move below the tab. Hiding the pouch hides its tab too. Minimal restores the old standalone pouch position.

## Fitted skins revision 3

Each of the 64 supported occupied grid shapes now has its own complete prebuilt leather texture. No edge tiles repeat in the game. Corners remain fixed when icon size or spacing changes, while each full edge is drawn once. The leather is slightly deeper, with one broad top fold; the integrated pouch tab remains. The appearance follows the occupied shape on partial pages. Minimal, positions, manual slots and keys are unchanged.
