# Forever consumable research and implementation decisions

Checked **November 22, 2026**. The target is Blizzard's WoW Forever client and interface 16001, consistent with the existing Paladin TankKit project. This is not a Wrath 3.3.5 addon.

## Public data baseline

[The Forever Era's client-derived consumable index](https://theforeverera.com/en/consumables/) reports **325 entries** for build **1.60.1.70959**: 9 flasks, 81 elixirs, 88 potions, 104 buff foods, 16 weapon oils/stones and 27 scrolls. This is a useful reference set, not proof of a complete obtainable inventory. It separates client effects/recipes from inherited Classic vendor and drop data. Its shared-cooldown discussion also cautions that buff stacking cannot simply be inferred from those records.

The index includes all six traditional scroll stat families and multiple stone/oil ranks. This drove category discovery instead of a fixed list of endgame consumables. Its food and oil changes make Classic-only assumptions unsuitable. Its values are not copied into recommendation scores or fixed timers.

## Why the actual bag item is the source of truth

[Baked Salmon's client comparison](https://theforeverera.com/en/items/13935/) explicitly shows a new well-fed effect relative to its Classic entry. A food that an older database treats as restoration can therefore belong in this addon's buff-food category.

[ForeverDB's Nightfin Soup record](https://foreverdb.net/item/13931) also reports a changed well-fed effect, whereas [Forever Helper's earlier pre-launch record](https://wowforeverhelper.com/item/13931/nightfin-soup) describes unchanged compared fields and omits that detailed use effect. These records reflect different builds and comparison scopes. SatchelSense reads the current bag tooltip and does not prescribe either site's stat value or duration.

[QuestCore's Demonic Rune entry](https://questcorehq.com/wowdb/forever/item/12662/demonic-rune) places it among trade goods while showing its mana-restoration use and health cost. This is a concrete counterexample to filtering solely on item class “Consumable.” Item 12662 receives an explicit mana exception. Narrow English family matches cover additional dual-purpose self-use items without admitting every crafting reagent or quest item.

## Discovery coverage

This table describes implemented rules, not a claim of exhaustive live verification. A family match accepts newly acquired ranks when their client metadata or English text matches; no rank, duration or potency is invented.

| Family | How it is surfaced | Boundaries |
| --- | --- | --- |
| Health recovery | Healing/health potion and draught names; healthstones; readable restorative potion text | Hybrid health/mana potions stay among utility potions |
| Mana recovery | Mana potions/draughts; mana gem names; runes; restorative potion text | Runes retain their native health cost; this addon never recommends using them automatically |
| Scrolls | Scroll subclass or consumable names beginning “Scroll of” | Recipes are rejected; no assumption that a scroll stacks with a class buff |
| Buff food and drink | Food/drink subclass with readable well-fed or buff wording; a small source-checked exception | Plain bread, water and raw food stay in the optional refreshment category unless the client supplies buff wording |
| Weapon coatings | Weightstones, sharpening stones, wizard/mana/frost/shadow oils and recognized rogue poison names | Click starts native item targeting; does not overwrite an imbue automatically |
| Other item enhancements | Enhancement class/subclasses; armor kits, shield spikes, scopes, counterweights and named fishing lures | Includes permanent item enhancements where reported by those classes; native compatibility and confirmations apply |
| Elixirs and flasks | Their consumable subclasses and English family names | No copied “battle/guardian” stacking system; no assumed best choice |
| Bandages | Bandage subclass/name | Player targeting; native combat/first-aid restrictions apply |
| Other self buffs | Recognized Juju/crystal families and readable self-buff/restoration text | Offensive crystal charges are deliberately absent from the named crystal matches |
| Fun/utility consumables | Recognized transformation wording, Noggenfogger and specific self-use families | Unknown or oddly classified objects can be manually included |

Equipment and trinkets, mount/pet items, recipes, generic crafting materials and arbitrary quest objects are outside automatic discovery. Explicit English enemy-damage tooltips are rejected unless they also describe a self benefit; unfamiliar or localized offensive potions can still need manual exclusion. A consumable's appearance in the grid does not imply class, profession, equipment or zone eligibility. All ranks stay visible as distinct item IDs. Identical stacks merge.

## Source-checked ID exceptions

Only category identity is bundled. The addon uses the client's current item name, icon, minimum level, tooltip and cooldown.

| ID | Identity | Reference |
| --- | --- | --- |
| 9421 | Major Healthstone | [QuestCore record](https://questcorehq.com/wowdb/forever/item/9421/major-healthstone) |
| 8008 | Mana Ruby | [QuestCore consumables index](https://questcorehq.com/wowdb/forever/items?class=0), linked item identity; detail fetch unavailable during research |
| 13444 | Major Mana Potion | [QuestCore record](https://questcorehq.com/wowdb/forever/item/13444/major-mana-potion) |
| 10309 | Scroll of Agility IV | [QuestCore index](https://questcorehq.com/wowdb/forever/items?class=0), linked identity; detail fetch unavailable |
| 18251 | Core Armor Kit | [QuestCore index](https://questcorehq.com/wowdb/forever/items?class=0), linked identity; detail fetch unavailable |
| 13935 | Baked Salmon | [Client comparison](https://theforeverera.com/en/items/13935/) |
| 20744 | Minor Wizard Oil | [Client comparison](https://theforeverera.com/en/items/20744/) |
| 12662 | Demonic Rune | [QuestCore record](https://questcorehq.com/wowdb/forever/item/12662/demonic-rune) |

Family-name heuristics have lower confidence than these identity checks and numeric client categories. They need broader live inventory sampling. A manually included item appears under Other self buffs; it still needs to be in carried bags and that category needs to be enabled.

## Client API research

The following are Blizzard's generated API descriptions and UI implementation, mirrored from the **forever** branch. These are the primary implementation references.

- [Container documentation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua): carried-bag enumeration and stack records. Only bag indices 0 through the equipped bag count are scanned; bank/storage are excluded.
- [Item documentation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua): item class/subclass, icon, level, asynchronous item loading and native cooldowns. No fabricated universal potion cooldown is used.
- [Item constants](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemConstantsDocumentation.lua): numeric consumable and enhancement categories. Client-family differences remain a live verification item.
- [Tooltip information](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua): bag-item tooltip lines. Hidden data is ignored, not coerced or bypassed.
- [Secure action implementation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua): player-initiated item actions. Item IDs are assigned before combat and retained until combat ends. This is why paging and automatic reordering cannot happen during combat.

The UI does not infer general buff duration, current buff coverage or stacking conflicts from an item name. Version 0.2.0 adds a narrowly scoped Recently Bandaged reader: IDs 11196 and 1305047 plus client-localized names, scanned only on the player's harmful auras. It uses readable duration/expiration values and chooses the longer of that lockout and the item's cooldown. It never guesses a fixed duration. The [Forever UnitAura API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua) is the implementation reference. [Client-data research of Field Medicine](https://bindonforever.com/notes/legacy-system) identifies the older aura ID and a duration reduction; this is why a fixed timer would be inappropriate. An identifiable debuff with hidden timing shows `?`.

Quick key capture follows the modifier/mouse input conventions checked in [AceGUI's upstream keybinding widget](https://github.com/WoWUIDev/Ace3/blob/master/AceGUI-3.0/widgets/AceGUIWidget-Keybinding.lua). No Ace library is bundled. Per-item secure buttons and per-character override bindings keep keys attached to an item ID rather than a changing slot. The normal game binding profile is preserved; conflicting assignments require an explicit editor confirmation. This pattern was also checked against the installed Forever addons' override-binding calls. Native input dispatch remains a live-client check.

Direct grid editing uses a separate hit layer instead of clearing or replacing the secure item action. A native `RegisterStateDriver` visibility rule hides that layer in combat; normal secure item attributes remain assigned throughout. The offline suite models the driver contract and rejects insecure protected mutations, but native hit testing, exact transition timing and click dispatch still require the live-client pass. Gallery media was created without opening the game and is explicitly labeled as promotional/feature illustration.

## CurseForge artwork and naming

[CurseForge's submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips) requests original square PNG project art, at least 400 pixels per side, and a distinct concise project name. The supplied avatar is exactly 400×400. Game compatibility and functional keywords belong in the summary/description rather than a crowded project title. Artwork here is an original generated pouch illustration, not a borrowed spell or game-logo graphic.

Name searches did not reveal an obvious WoW addon collision for the leading candidates during this pass. Search absence is not a guarantee of name availability; check the intended CurseForge slug when choosing the final name.

## Remaining live verification

The offline suite validates discovery and protected-layout behavior using realistic API shapes. It cannot prove the real client's click dispatch, tooltip availability, native targeting cursor, item compatibility, or visual rendering. Follow [the live checklist](release/LIVE-CHECKS.md) before labeling a public release stable.
