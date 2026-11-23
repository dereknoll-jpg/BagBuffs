local P=TEST_NS
local function event(e,arg) P.events.scripts.OnEvent(P.events,e,arg) end
local function tick() P.events.scripts.OnUpdate(P.events,.3) end
local function def(id,name,subclass,class) DEFS[id]={name=name,subclass=subclass,class=class} end
def(1,"Lesser Healing Potion",1)
def(2,"Lesser Mana Potion",1)
def(3,"Scroll of Strength",4)
def(4,"Dense Weightstone",6)
def(5,"Odd Soup",5); TIPS[5]="If you spend at least 10 sec eating you will become well fed."
def(6,"Plain Bread",5); TIPS[6]="Restores 300 health over 20 sec."
def(7,"Recipe: Flask of Speed",0,9)
def(8,"Rough Stone",0,7)
def(9,"Mystery Elixir",2)
def(10,"Flask of the Titans",3)
def(11,"Heavy Linen Bandage",7)
def(12,"Purification Potion",1)
def(13,"A Quest Bomb",0,12)
def(14,"Mystery Charm",0,15)
def(15,"Healthstone",0)
def(16,"Poison Resistance Potion",1)
def(17,"Crystal Charge",0)
def(18,"Raw Fish",5)
BAGS[0]={{1,2},{2,3},{3,4},{4,5},{5,6},{6,7},{7,1},{8,3},{9,1},{10,1},{11,5},{12,2},{13,1},{14,1},{15,1},{16,2},{17,5},{18,2}}
BAGS[1]={{1,3}}
event("ADDON_LOADED","SomeOtherAddon"); assert(not P.frame)
event("ADDON_LOADED","PocketBuffs")
assert(P.frame and #P.items==13 and #P.selected==11)
assert(P.buttons[1].item.id==15 or P.buttons[1].item.id==1)
local byID={}; for _,item in ipairs(P.items) do byID[item.id]=item end
assert(byID[1].count==5 and byID[5].category=="food")
assert(byID[6].category=="refreshment" and not byID[7] and not byID[8] and not byID[13] and not byID[14] and not byID[17])
assert(byID[16].category=="potion")
assert(P.pages==2 and P.buttons[9]:IsShown() and not P.buttons[10]:IsShown())
assert(P.frame.width==104 and P.frame.height==104)
for i=1,9 do assert(P.buttons[i].attributes.item1=="item:"..P.buttons[i].item.id) end
P:ChangePage(1); assert(P.page==2 and P.buttons[2]:IsShown() and not P.buttons[3]:IsShown())
P:ChangePage(-1)
SlashCmdList.POCKETBUFFS("layout 1x8"); assert(P.db.columns==1 and P.db.rows==8 and P.frame.width==32)
SlashCmdList.POCKETBUFFS("layout 8x1"); assert(P.frame.height==32 and P.db.columns==8)
SlashCmdList.POCKETBUFFS("layout 0x900"); assert(P.db.columns==8)
SlashCmdList.POCKETBUFFS("layout 3x3")
SlashCmdList.POCKETBUFFS("favorite 4"); assert(P.buttons[1].item.id==4 and P.buttons[1].attributes.unit==nil)
SlashCmdList.POCKETBUFFS("hide 4"); assert(not P.buttons[1].item)
SlashCmdList.POCKETBUFFS("restore 4"); assert(P.buttons[1].item.id==4)
SlashCmdList.POCKETBUFFS("include 14"); assert(P.db.included[14])
local included=false; for _,item in ipairs(P.items) do if item.id==14 then included=true end end; assert(included)
P:ToggleSettings(); assert(P.settings:IsShown()); P:ToggleSettings(); assert(not P.settings:IsShown())
local assigned=P.buttons[1].attributes.item1
COMBAT=true
BAGS[0]={{2,1},{3,1}}; BAGS[1]={}
event("BAG_UPDATE_DELAYED"); tick()
assert(P.pending and P.buttons[1].attributes.item1==assigned and P.buttons[1].item.id==4)
assert(P.buttons[1].count.text=="0")
SlashCmdList.POCKETBUFFS("layout 1x8"); assert(P.db.columns==3)
P:ChangePage(1); assert(P.page==1)
P:ToggleSettings(); assert(P.settings:IsShown()); P:SyncSettings(); P:ToggleSettings()
COMBAT=false; event("PLAYER_REGEN_ENABLED"); tick()
assert(not P.pending and #P.selected==2 and not P.buttons[1]:IsShown())
assert(P.buttons[4].item.id==2 and P.buttons[7].item.id==3)
-- Item attributes use IDs, so bag sorting cannot point an old button at a different item.
local itemID=P.selected[1].id
BAGS[0]={{3,2},{2,1}}; P:Refresh()
assert(P.selected[1].id==itemID)
-- Uncached information is requested and included on the subsequent load event.
def(20,"New Scroll",4); DEFS[20].uncached=true; BAGS[0]={{20,1}}
P:Refresh(); assert(REQUESTED==20 and #P.items==0)
DEFS[20].uncached=false; event("GET_ITEM_INFO_RECEIVED",20); tick(); assert(#P.items==1)
-- New Forever food with no catalog entry comes from its actual tooltip.
def(21,"New Forever Meal",5); BAGS[0]={{21,2}}; P:Refresh(); assert(#P.selected==0)
TIPS[21]="You become well fed and gain spell damage."; event("TOOLTIP_DATA_UPDATE",123); tick()
assert(#P.selected==1 and P.selected[1].category=="food")
-- Bank contents are outside bag indices; empty slots have no frame or mouse interception.
BAGS[-1]={{1,99}}; BAGS[0]={}; P:Refresh()
assert(#P.items==0 and not P.buttons[1]:IsShown() and not P.launcher:IsShown() and not P.pager:IsShown())
-- Restricted item records are ignored, without string conversion or comparison.
BAGS[0]={{SECRET,SECRET},{1,SECRET}}; P:Refresh(); assert(#P.items==1 and P.items[1].count==0)
COOLDOWNS[1]={SECRET,SECRET,SECRET}; P:UpdateVisuals()
-- Self-use trade goods must survive the normal crafting-material exclusion.
def(12662,"Demonic Rune",0,7); def(40,"Dark Rune",0,7); def(41,"Frost Oil",0); def(42,"Juju Power",0,12)
BAGS[0]={{12662,2},{40,1},{41,1},{42,2}}; P:Refresh()
assert(#P.items==4 and P.selected[1].category=="mana")
local categories={}; for _,item in ipairs(P.items) do categories[item.id]=item.category end
assert(categories[41]=="weapon" and categories[42]=="utility")
def(43,"An Offensive Potion",1); TIPS[43]="Use: Deals 100 fire damage to all enemies nearby."
BAGS[0]={{43,1},{1,1}}; P:Refresh(); assert(#P.items==1 and P.items[1].id==1)
SlashCmdList.POCKETBUFFS("layout 8x8"); assert(P.frame.width==284 and P.frame.height==284)
SlashCmdList.POCKETBUFFS("layout 3x3")
-- Per-character invalid settings recover; fractional dimensions normalize.
PocketBuffsDB={columns=99,rows=-1,size=0,scale=0/0,enabled={food="yes"}}; P:InitializeDB()
assert(P.db.columns==8 and P.db.rows==1 and P.db.size==20 and P.db.scale==1 and P.db.enabled.food==true)
print("PASS bag filtering, duplicate stacks, custom includes, favorites, transparent empties, paging, combat guards, async items, tooltip updates, secret data and saved settings")
