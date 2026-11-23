local P=TEST_NS
local function event(e,arg) P.events.scripts.OnEvent(P.events,e,arg) end
local function def(id,name,subclass) DEFS[id]={name=name,subclass=subclass} end
SatchelSenseDB={}; P:InitializeDB(); COOLDOWNS={}; HARMFUL={}; COMBAT=false
def(101,"Zebra Healing Potion",1); def(102,"Amber Mana Potion",1); def(103,"Linen Bandage",7); def(104,"Scroll of Agility",4)
BAGS[0]={{101,2},{102,2},{103,5},{104,1}}; BAGS[1]={}
P:Refresh(); P:SelectSettingsTab("items")
assert(P.selected[1].id==101 and P.selected[2].id==102)
P:SetSortMode("name"); assert(P.selected[1].id==102)
P:SetSortMode("type"); assert(P.selected[1].id==101)
assert(P:MoveItemTo(103,101)); assert(P.db.sortMode=="manual" and P.selected[1].id==103)
assert(P:MoveItem(104,-1)); assert(P.selected[3].id==104)
-- The editor's nonsecure icons support dragging without using bag items.
P:SyncSettings()
local source=P.itemRows[1]; local destination=P.itemRows[3]
local sourceID,targetID=source.item.id,destination.item.id
source.icon.scripts.OnDragStart(); HOVERED_FRAME=destination.frame; source.icon.scripts.OnDragStop()
assert(not P.dragItemID and P.selected[3].id==sourceID)
-- Manual order survives sorting bags, refresh and DB initialization (reload).
local order={}; for i,item in ipairs(P.selected) do order[i]=item.id end
BAGS[0]={{104,1},{103,5},{102,2},{101,2}}; P:Refresh()
for i,id in ipairs(order) do assert(P.selected[i].id==id) end
P:InitializeDB(); P:Refresh(); for i,id in ipairs(order) do assert(P.selected[i].id==id) end
local potion,bandage
for _,item in ipairs(P.items) do if item.id==101 then potion=item elseif item.id==103 then bandage=item end end
-- Capture modifiers; a key resolves to a persistent item button, not a changing slot.
P:StartBinding(potion); CTRL=true; P.bindingPrompt.scripts.OnKeyDown(nil,"F"); CTRL=false
assert(P.db.bindings[101].key=="CTRL-F" and not P.bindingItem)
local button=P.itemBindingButtons[101]
assert(button.attributes.item=="item:101" and button.attributes.unit=="player")
assert(GetBindingAction("CTRL-F",true)=="CLICK SatchelSenseUseItem101:LeftButton")
P:SetSortMode("name"); SlashCmdList.SATCHELSENSE("layout 1x1"); P:ChangePage(1)
assert(GetBindingAction("CTRL-F",true)=="CLICK SatchelSenseUseItem101:LeftButton")
-- Conflicting keys need a deliberate confirmation; underlying game bindings survive.
BASE_BINDINGS.G="TOGGLEBACKPACK"
P:StartBinding(bandage); P:CaptureBinding("G")
assert(P.bindingConflict=="G" and not P.db.bindings[103] and BASE_BINDINGS.G=="TOGGLEBACKPACK")
P.bindingPrompt.replace.scripts.OnClick()
assert(P.db.bindings[103].key=="G" and GetBindingAction("G",true)=="CLICK SatchelSenseUseItem103:LeftButton")
P:StartBinding(bandage); P:CaptureBinding("DELETE")
assert(not P.db.bindings[103] and GetBindingAction("G",true)=="TOGGLEBACKPACK")
P:StartBinding(potion); P:CaptureBinding("ESCAPE"); assert(P.db.bindings[101].key=="CTRL-F")
P:StartBinding(bandage); P:CaptureBinding("CTRL-F"); assert(P.bindingConflict)
P.bindingPrompt.replace.scripts.OnClick(); assert(not P.db.bindings[101] and P.db.bindings[103].key=="CTRL-F")
-- Item-specific keybindings persist while the item is temporarily absent.
BAGS[0]={{101,2}}; P:Refresh()
assert(GetBindingAction("CTRL-F",true)=="CLICK SatchelSenseUseItem103:LeftButton")
BAGS[0]={{101,2},{102,2},{103,5},{104,1}}; SlashCmdList.SATCHELSENSE("layout 3x3"); P:Refresh()
local function tile(id) for _,b in ipairs(P.buttons) do if b.item and b.item.id==id then return b end end end
-- Explicit countdowns work independently of the game's optional countdown text.
NOW=100; COOLDOWNS[101]={100,120,true}; COOLDOWNS[102]={100,120,true}; P:UpdateVisuals()
assert(tile(101).cooldownText.text=="2:00" and tile(102).cooldownText.text=="2:00")
NOW=131; P:UpdateVisuals(); assert(tile(101).cooldownText.text=="1:29")
NOW=161.2; P:UpdateVisuals(); assert(tile(101).cooldownText.text=="59")
NOW=220; P:UpdateVisuals(); assert(tile(101).cooldownText.text=="" and not tile(101).cooldown.cooldown)
-- Bandage lockout comes from actual aura expiry, including a reduced duration.
NOW=300; HARMFUL={{spellId=11196,name="Recently Bandaged",duration=50,expirationTime=350}}
event("UNIT_AURA","player"); assert(tile(103).cooldownText.text=="50" and tile(103).icon.desaturated)
assert(tile(103).cooldown.cooldown[1]==300 and tile(103).cooldown.cooldown[2]==50)
NOW=325; P:UpdateVisuals(); assert(tile(103).cooldownText.text=="25")
-- Only the player's harmful aura matters, and removal clears the lockout immediately.
HARMFUL={}; event("UNIT_AURA","target"); assert(tile(103).cooldownText.text=="25")
event("UNIT_AURA","player"); assert(tile(103).cooldownText.text=="" and not tile(103).icon.desaturated)
HARMFUL={{spellId=1305047,name="Recently Bandaged",duration=30,expirationTime=355}}
COOLDOWNS[103]={320,60,true}; P:UpdateVisuals(); assert(tile(103).cooldownText.text=="55")
-- Hidden timestamps never get coerced, and the UI does not invent a 60-second timer.
HARMFUL={{spellId=11196,name="Recently Bandaged",duration=SECRET,expirationTime=SECRET}}
P:UpdateVisuals(); assert(tile(103).cooldownText.text=="?" and tile(103).icon.desaturated)
HARMFUL={{spellId=SECRET,name=SECRET,duration=SECRET,expirationTime=SECRET}}
COOLDOWNS[103]={SECRET,SECRET,SECRET}; P:UpdateVisuals()
assert(tile(103).cooldownText.text=="")
-- Editing and capture terminate or refuse mutations in combat; the fixed actions still work.
HARMFUL={}; COOLDOWNS={}; P:StartBinding(potion)
COMBAT=true; event("PLAYER_REGEN_DISABLED"); assert(not P.bindingItem)
local first=P.selected[1].id; assert(not P:MoveItem(first,1)); assert(P.selected[1].id==first)
assert(not P:ApplyItemBinding(potion,"J")); P:StartBinding(potion); assert(not P.bindingItem)
P:UpdateVisuals(); P:Refresh(); assert(P.pending)
COMBAT=false; event("PLAYER_REGEN_ENABLED"); P.events.scripts.OnUpdate(nil,.3)
assert(not P.pending and GetBindingAction("CTRL-F",true)=="CLICK SatchelSenseUseItem103:LeftButton")
print("PASS manual drag/arrow ordering, reload persistence, item-bound keys, conflict confirmation, native binding restoration, shared potion countdowns, real bandage debuffs and combat guards")
