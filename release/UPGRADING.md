# Upgrading to SatchelSense

SatchelSense is the new name for PocketBuffs. Install the complete download over the earlier addon, allowing its files to be replaced, then restart WoW.

The ZIP contains two folders:

- **SatchelSense**: the renamed addon, with the new artwork and commands.
- **PocketBuffs**: a tiny bundled component displayed as **SatchelSense - Settings Import**. Its old folder name lets WoW find each character's existing save. It contains no separate grid or item actions and is required by the main addon.

Keep both enabled. No extra download is needed. Do not retain a second copy of the old full addon under another folder, and do not edit, move or delete files under WTF.

On first use for each character, SatchelSense copies the earlier profile into its own save. It retains layout and scale, screen position, manual order and exact slots, category filters, favorites, ignored/included items and item keybindings. The old profile remains intact. If the character already has a SatchelSense profile, that profile takes precedence and is not overwritten by another import.

Per-item keys continue to target the same item IDs. Older game-native slot bindings remain supported through secure aliases, without rewriting your account/character binding profile. New keys can be assigned under Items & Keys.

Use **`/satchel`**, **`/satchelsense`** or **`/ss`** for settings. **`/pbuff`** and **`/pocketbuffs`** remain aliases for existing habits and macros.

The import's data, idempotence and binding compatibility are covered by offline upgrade checks. The real client's saved-variable loading and key dispatch should be included in the final live verification.
