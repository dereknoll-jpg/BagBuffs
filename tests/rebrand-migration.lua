local P=TEST_NS
COMBAT=false; RunStateDrivers(); P:CancelBinding(); P:CancelGridDrag()
local legacy={columns=4,rows=2,size=36,gap=6,scale=.9,locked=true,logo=false,
    position={x=150,y=-90},sortMode="manual",slots={202,0,201,203},order={202,0,201,203},
    favorites={[201]=true},ignored={[204]=true},included={[999]=true},enabled={food=false},
    bindings={[201]={key="CTRL-F",weapon=false},[41]={key="ALT-O",weapon=true}}}
PocketBuffsDB=legacy; SatchelSenseDB=nil; P:InitializeDB()
assert(P.db~=legacy and P.db.migratedFrom=="PocketBuffs" and SatchelSenseDB==P.db)
assert(P.db.columns==4 and P.db.rows==2 and P.db.size==36 and P.db.gap==6 and P.db.scale==.9)
assert(P.db.position.x==150 and P.db.position.y==-90 and not P.db.logo)
assert(P.db.slots[1]==202 and P.db.slots[2]==0 and P.db.slots[3]==201)
assert(P.db.favorites[201] and P.db.ignored[204] and P.db.included[999] and P.db.enabled.food==false)
assert(P.db.bindings[201].key=="CTRL-F" and P.db.bindings[41].weapon)
P.db.position.x=175; P.db.bindings[201].key="SHIFT-F"
assert(legacy.position.x==150 and legacy.bindings[201].key=="CTRL-F")
BAGS[0]={{201,2},{202,2},{203,1}}; BAGS[1]={}; assert(P.db.autoSort and P.db.order[2]==0); P:SetAutoSort(false)
assert(GetBindingAction("SHIFT-F",true)=="CLICK SatchelSenseUseItem201:LeftButton")
assert(GetBindingAction("ALT-O",true)=="CLICK SatchelSenseUseItem41:LeftButton")
assert(P.itemBindingButtons[201].attributes.item=="item:201" and P.itemBindingButtons[41].attributes.unit==nil)
-- Native slot bindings from both account and character profiles keep their old
-- CLICK target. Secure aliases mirror the new visible slots, including holes.
BASE_BINDINGS["CTRL-1"]="CLICK PocketBuffsButton1:LeftButton"
BASE_BINDINGS["CTRL-3"]="CLICK PocketBuffsButton3:LeftButton"
assert(PocketBuffsButton1.attributes.item1=="item:202")
assert(PocketBuffsButton2.attributes.item1==nil)
assert(PocketBuffsButton3.attributes.item1=="item:201")
assert(GetBindingAction("CTRL-1",false)=="CLICK PocketBuffsButton1:LeftButton")
assert(SatchelSenseButton1.attributes.item1==PocketBuffsButton1.attributes.item1)
COMBAT=true; P:UpdateVisuals(); assert(PocketBuffsButton3.attributes.item1=="item:201")
COMBAT=false
-- A subsequent login uses the new profile and must not reimport stale values.
P:InitializeDB(); assert(P.db.position.x==175 and P.db.bindings[201].key=="SHIFT-F")
assert(PocketBuffsDB==legacy and legacy.bindings[201].key=="CTRL-F")
assert(SLASH_SATCHELSENSE1=="/satchel" and SLASH_SATCHELSENSE4=="/pbuff" and SLASH_SATCHELSENSE5=="/pocketbuffs")
SlashCmdList.POCKETBUFFS("layout 3x3"); assert(P.db.columns==3 and P.db.rows==3)
-- An incomplete replacement leaves the old addon available rather than opening
-- another HUD or silently initializing a blank imported profile.
local importedDB=SatchelSenseDB; SatchelSenseLegacyReady=nil; P.db=nil
P.events.scripts.OnEvent(nil,"ADDON_LOADED","SatchelSense")
assert(P.db==nil and SatchelSenseDB==importedDB)
SatchelSenseLegacyReady=true; P:InitializeDB()
print("PASS automatic per-character legacy import, deep-copy rollback safety, settings/slots/filters, item keys, old native CLICK bindings, idempotent reload and slash aliases")
