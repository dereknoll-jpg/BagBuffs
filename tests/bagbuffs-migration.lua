local P=TEST_NS
COMBAT=false; RunStateDrivers(); P:CancelBinding(); P:CancelGridDrag()
local satchel={columns=3,rows=3,size=40,gap=5,scale=.8,locked=true,logo=true,
    position={x=111,y=-222},autoSort=false,autoSortBy="name",highlightNew=false,
    sortMode="manual",slots={202,0,201,203},order={202,0,201,203},
    favorites={[201]=true},ignored={[204]=true},included={[999]=true},enabled={food=false},
    bindings={[201]={key="CTRL-H",weapon=false},[41]={key="ALT-O",weapon=true}}}
SatchelSenseDB=satchel; PocketBuffsDB={columns=8}; BagBuffsDB=nil
P:InitializeDB()
assert(P.db~=satchel and P.db.migratedFrom=="SatchelSense")
assert(P.db.columns==3 and P.db.size==40 and P.db.scale==.8)
assert(P.db.position.x==111 and P.db.position.y==-222)
assert(not P.db.autoSort and not P.db.highlightNew and P.db.autoSortBy=="name")
assert(P.db.slots[2]==0 and P.db.slots[3]==201 and P.db.order[4]==203)
assert(P.db.favorites[201] and P.db.ignored[204] and P.db.included[999] and not P.db.enabled.food)
BAGS[0]={{201,2},{202,2},{203,2}}; BAGS[1]={}; P:Refresh()
assert(GetBindingAction("CTRL-H",true)=="CLICK BagBuffsUseItem201:LeftButton")
assert(GetBindingAction("ALT-O",true)=="CLICK BagBuffsUseItem41:LeftButton")
BASE_BINDINGS.F6="CLICK SatchelSenseButton3:LeftButton"
assert(SatchelSenseButton1.attributes.item1=="item:202" and SatchelSenseButton2.attributes.item1==nil)
assert(SatchelSenseButton3.attributes.item1=="item:201" and PocketBuffsButton3.attributes.item1=="item:201")
assert(GetBindingAction("F6",false)=="CLICK SatchelSenseButton3:LeftButton")
COMBAT=true; P:UpdateVisuals(); assert(SatchelSenseButton3.attributes.item1=="item:201"); COMBAT=false
P.db.position.x=333; P.db.bindings[201].key="SHIFT-H"; P.db.ignored[203]=true
assert(satchel.position.x==111 and satchel.bindings[201].key=="CTRL-H" and not satchel.ignored[203])
P:InitializeDB(); P:Refresh()
assert(P.db.position.x==333 and P.db.bindings[201].key=="SHIFT-H" and P.db.ignored[203])
assert(P.db.migratedFrom=="SatchelSense" and PocketBuffsDB.columns==8)
assert(SLASH_BAGBUFFS4=="/satchel" and SLASH_BAGBUFFS5=="/satchelsense" and SLASH_BAGBUFFS6=="/ss")
assert(SlashCmdList.SATCHELSENSE==SlashCmdList.BAGBUFFS and SlashCmdList.POCKETBUFFS==SlashCmdList.BAGBUFFS)
local current=BagBuffsDB; P.db=nil; BagBuffsSatchelReady=nil
P.events.scripts.OnEvent(nil,"ADDON_LOADED","BagBuffs")
assert(P.db==nil and BagBuffsDB==current)
BagBuffsSatchelReady=true; P:InitializeDB()
print("PASS SatchelSense priority import, exact manual slots, filters/highlights, deep-copy safety, item keys, both native slot aliases, old commands and idempotent reload")
