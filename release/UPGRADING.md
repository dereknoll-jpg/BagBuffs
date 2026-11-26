# Upgrading to BagBuffs

BagBuffs is the new name for SatchelSense (originally PocketBuffs). Install the complete download over the previous addon, replace its files, and restart WoW so it discovers the new BagBuffs folder.

Install all three folders from the addon ZIP:

- **BagBuffs** is the addon and its single grid.
- **SatchelSense** is displayed as **BagBuffs - SatchelSense Settings Import**. It loads your previous SatchelSense character profile.
- **PocketBuffs** is displayed as **BagBuffs - Settings Import**. It supports profiles from the original name.

Keep all three enabled. The two import components have no grids or item actions. They replace the previous full addon folders, so only one interface runs. No files under WTF need to be edited, moved or deleted.

On first use per character, BagBuffs copies the SatchelSense profile if present, otherwise the original PocketBuffs profile. An existing BagBuffs profile always takes precedence. Old profiles remain intact and are never rewritten by the import.

Your layout, scale, screen position, exact manual slots, sorting choice, category filters, favorites, hidden/included items, highlight preferences and item keybindings carry over. A current Manual profile stays Manual; the rename does not force Auto sorting on again.

Native grid-slot keys from both previous names retain their original targets through secure aliases. Item keys continue targeting the same item IDs. Normal account and character keybinding profiles are not rewritten.

Use **/bagbuffs**, **/bb** or **/bagbuff** for settings. **/satchel**, **/satchelsense**, **/ss**, **/pbuff** and **/pocketbuffs** remain supported.

Offline checks cover both upgrade paths, priority, deep-copy safety, exact slots, key targets and repeated reloads. Saved-variable loading and native input should still be checked in the real client after restarting.
