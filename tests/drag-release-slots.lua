local P=TEST_NS
COMBAT=false; LEFT_DOWN=true; RunStateDrivers(); BagBuffsDB={}; P:InitializeDB()
DEFS[201]={name="Healing Potion",subclass=1}; DEFS[202]={name="Mana Potion",subclass=1}
DEFS[203]={name="Scroll of Strength",subclass=4}; DEFS[204]={name="A New Healing Potion",subclass=1}
DEFS[205]={name="Another New Scroll",subclass=4}
BAGS[0]={{201,2},{202,2},{203,2}}; BAGS[1]={}
P:Refresh(); if P.settings:IsShown() then P:ToggleSettings() end
P:ToggleMoveLock(); assert(not P.db.locked)
assert(P.gridEditButtons[9]:IsShown() and P.buttons[9].point and not P.buttons[9]:IsShown())
P.frame.left=100; P.frame.top=500
local function aim(slot,scale)
    scale=scale or 1
    local capacity=P.db.columns*P.db.rows; local localSlot=(slot-1)%capacity
    CURSOR_X=(100+(localSlot%P.db.columns)*(P.db.size+P.db.gap)+P.db.size/2)*scale
    CURSOR_Y=(500-math.floor(localSlot/P.db.columns)*(P.db.size+P.db.gap)-P.db.size/2)*scale
end
-- Reproduce the reported path: the engine never sends OnDragStop. Physical
-- release polling must complete the drop into a previously empty grid slot.
local source=P.buttons[1].item.id
P.gridEditButtons[1].scripts.OnDragStart(); aim(9); LEFT_DOWN=false
P.gridDragGhost.scripts.OnUpdate(P.gridDragGhost)
assert(not P.gridDragItemID and not P.gridDragGhost:IsShown())
assert(P.db.slots[9]==source and P.db.slots[1]==0)
assert(P.buttons[9].item.id==source and not P.buttons[1]:IsShown())
-- Global mouse release also finalizes a drag, even if the source frame has lost focus.
LEFT_DOWN=true; P.gridEditButtons[2].scripts.OnDragStart(); aim(5); HOVERED_FRAME=nil
P.events.scripts.OnEvent(nil,"GLOBAL_MOUSE_UP","LeftButton")
assert(P.db.slots[5]==202 and P.db.slots[2]==0 and not P.gridDragGhost:IsShown())
-- Duplicate release notifications do not repeat or undo the drop.
P.gridEditButtons[2].scripts.OnDragStop(); P.events.scripts.OnEvent(nil,"GLOBAL_MOUSE_UP","LeftButton")
assert(P.db.slots[5]==202)
-- A release over another occupied slot swaps the two exact positions.
P.gridEditButtons[9].scripts.OnDragStart(); aim(3)
P.gridEditButtons[3].scripts.OnMouseUp(nil,"LeftButton")
assert(P.db.slots[3]==source and P.db.slots[9]==203)
P.gridEditButtons[3].scripts.OnClick(nil,"LeftButton"); assert(not P.settings:IsShown())
-- Release outside the grid cancels cleanly. It cannot leave a stuck ghost.
P.gridEditButtons[3].scripts.OnDragStart(); CURSOR_X=-100; CURSOR_Y=-100; LEFT_DOWN=false
P.gridDragGhost.scripts.OnUpdate(P.gridDragGhost)
assert(not P.gridDragItemID and not P.gridDragGhost:IsShown() and P.db.slots[3]==source)
-- Locking freezes positions. New acquisitions append, without moving any existing item.
P:ToggleMoveLock(); assert(P.db.locked)
local saved={}; for slot,id in ipairs(P.db.slots) do saved[slot]=id end
BAGS[0]={{204,1},{203,2},{202,2},{201,2}}; P:Refresh()
for slot,id in ipairs(saved) do assert(P.db.slots[slot]==id) end
assert(P.db.slots[10]==204 and P.pages==2)
BAGS[0][5]={205,1}; P:Refresh(); assert(P.db.slots[11]==205)
-- Reload preserves explicit empty slots, exact positions and discovery order.
P:InitializeDB(); P:Refresh()
assert(P.db.slots[1]==0 and P.db.slots[2]==0 and P.db.slots[3]==source)
assert(P.db.slots[5]==202 and P.db.slots[9]==203 and P.db.slots[10]==204 and P.db.slots[11]==205)
-- Running out leaves a transparent reserved slot; reacquisition returns to it.
BAGS[0]={{201,2},{203,2},{204,1},{205,1}}; P:Refresh(); assert(not P.buttons[5]:IsShown())
BAGS[0][5]={202,1}; P:Refresh(); assert(P.buttons[5].item.id==202)
-- Hit testing uses physical cursor coordinates correctly with UI scaling.
P:ToggleMoveLock(); LEFT_DOWN=true
local originalScale=P.frame.GetEffectiveScale; P.frame.GetEffectiveScale=function() return 1.5 end
aim(4,1.5); assert(P:GridDropSlot()==4)
P.frame.GetEffectiveScale=originalScale
P:ToggleMoveLock()
-- Existing rc.1 manual orders migrate without losing their order or key settings.
BagBuffsDB={sortMode="manual",order={203,201,202},bindings={[201]={key="F",weapon=false}}}
P:InitializeDB(); P:SetAutoSort(false)
assert(P.db.slots[1]==203 and P.db.slots[2]==201 and P.db.slots[3]==202)
assert(P.db.slots[4]==204 and P.db.slots[5]==205 and P.db.bindings[201].key=="F")
-- Explicit Manual mode stays stable until the player clicks Sort.
BagBuffsDB={}; P:InitializeDB(); BAGS[0]={{202,1},{203,1}}; P:SetAutoSort(false)
assert(P.db.slots[1]==202 and P.db.slots[2]==203)
BAGS[0][3]={201,1}; P:Refresh(); assert(P.db.slots[1]==202 and P.db.slots[2]==203 and P.db.slots[3]==201)
P:InitializeDB(); P:Refresh(); assert(P.db.slots[1]==202 and P.db.slots[3]==201)
P:SetSortMode("type"); assert(P.db.slots[1]==201 and P.db.slots[2]==202)
P.frame.left=nil; P.frame.top=nil; CURSOR_X=nil; CURSOR_Y=nil; LEFT_DOWN=true
print("PASS missing drag-stop recovery, global mouse release, empty-slot drops, exact swaps, scaled hit testing, stable slots, append-only discovery, reacquisition and rc.1 migration")
