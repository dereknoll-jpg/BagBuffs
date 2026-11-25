local P=TEST_NS
COMBAT=false; CTRL=false; SHIFT=false; P:CancelGridDrag(); P.dragItemID=nil; P.gridMoving=nil
SatchelSenseDB={sortMode="manual",slots={202,0,0,0,0,0,0,0,0,201},bindings={[201]={key="ALT-H"}}}
P:InitializeDB(); BAGS[0]={{201,2},{202,2},{203,1}}; BAGS[1]={}; NOW=1000; P:Refresh()
assert(P.db.autoSort and P.pages==1 and #P.db.slots==3)
assert(P.db.slots[1]==201 and P.db.slots[2]==202 and P.db.slots[3]==203)
assert(P.db.order[10]==201 and P.db.order[2]==0)
assert(P.buttons[1].newGlow.alpha==0) -- Login establishes a baseline.
assert(GetBindingAction("ALT-H",true)=="CLICK SatchelSenseUseItem201:LeftButton")
P:SetAutoSort(false); assert(P.db.slots[10]==201 and P.pages==2)
P:CompactLayout(); assert(not P.db.autoSort and P.pages==1)
assert(P.db.slots[1]==202 and P.db.slots[2]==201 and P.db.slots[3]==203)
P:SetAutoSort(true); assert(P.db.slots[1]==201)
BAGS[0]={{202,1},{203,1},{204,1}}; P:Refresh()
assert(P.db.slots[1]==204 and P.db.slots[2]==202 and #P.db.slots==3 and P.pages==1)
assert(P.buttons[1].newGlow.alpha>0)
NOW=1007; P:UpdateVisuals(); assert(P.buttons[1].newGlow.alpha>0 and P.buttons[1].newGlow.alpha<.9)
NOW=1009; P:UpdateVisuals(); assert(P.buttons[1].newGlow.alpha==0)
BAGS[0][3][2]=5; P:Refresh(); assert(P.buttons[1].newGlow.alpha==0) -- More of an existing stack is quiet.
P.db.ignored[204]=true; P:Refresh(); assert(#P.db.slots==2 and P.db.slots[1]==202)
P.db.ignored[204]=nil; P:Refresh()
P:SetAutoSort(false); P:MoveItemToSlot(203,9); assert(not P.db.autoSort)
local before=P.settings:IsShown(); CTRL=true
P.launcher.scripts.OnClick(nil,"LeftButton"); CTRL=false
assert(P.settings:IsShown()==before and not P.db.autoSort and #P.db.slots==3 and P.pages==1)
P.launcher.scripts.OnClick(nil,"RightButton"); assert(P.pouchMenu:IsShown())
P.launcher.scripts.OnClick(nil,"RightButton"); assert(not P.pouchMenu:IsShown())
P:SetAutoSort(true)
local fixed=P.buttons[1].attributes.item1
COMBAT=true; BAGS[0][4]={201,1}; P:Refresh()
assert(P.pending and P.buttons[1].attributes.item1==fixed)
COMBAT=false; P:Refresh(); assert(P.db.slots[1]==204 and #P.db.slots==4)
local i=P:SlotForItem(201); assert(P.buttons[i].newGlow.alpha>0)
assert(GetBindingAction("ALT-H",true)=="CLICK SatchelSenseUseItem201:LeftButton")
P:ToggleNewHighlights(); assert(not P.db.highlightNew and P.buttons[i].newGlow.alpha==0)
P:ToggleNewHighlights(); assert(P.buttons[i].newGlow.alpha==0)
-- Off-page discoveries get their full highlight when first brought into view.
P.db.columns=1; P.db.rows=1; BAGS[0][5]={205,1}; P:Refresh()
assert(P.pendingNew[205] and not P.newUntil[205])
NOW=1100; P:ChangePage(P:SlotForItem(205)-1)
assert(P.buttons[1].item.id==205 and P.buttons[1].newGlow.alpha>0 and P.newUntil[205]==1108)
-- Refreshes cannot move a tile out from under an active drag.
local snapshot=table.concat(P.db.slots,","); P.gridDragItemID=205
BAGS[0][6]={10,1}; P:Refresh(); assert(P.pending and table.concat(P.db.slots,",")==snapshot)
P.gridDragItemID=nil; P:Refresh(); assert(#P.db.slots==6)
P:MoveItemToSlot(205,8); assert(not P.db.autoSort and P.db.slots[8]==205)
P:InitializeDB(); P:Refresh(); assert(not P.db.autoSort and P.db.slots[8]==205)
print("PASS automatic gap removal, default upgrade with manual recovery, compaction, pouch shortcuts, discovery highlights, combat/drag deferral and item key stability")

-- Direct hiding uses the displayed item and commits only on mouse release.
P:SetAutoSort(true); P.db.columns=3; P.db.rows=3; P:Refresh()
local item=P.buttons[1].item; local open=P.settings:IsShown()
P.buttons[1].scripts.PostClick(P.buttons[1],"MiddleButton",true)
assert(not P.db.ignored[item.id])
P.buttons[1].scripts.PostClick(P.buttons[1],"MiddleButton",false)
assert(P.db.ignored[item.id] and P.settings:IsShown()==open)
assert(P.buttons[1].item.id~=item.id and #P.db.slots==5)
P:InitializeDB(); P:Refresh(); assert(P.db.ignored[item.id])
P.db.ignored[item.id]=nil; P:Refresh()
P:MoveItemToSlot(item.id,8); if P.db.locked then P:ToggleMoveLock() end
P.gridEditButtons[8].scripts.OnClick(nil,"MiddleButton")
assert(P.db.ignored[item.id] and P.db.slots[8]==item.id and not P.buttons[8]:IsShown())
P.gridEditButtons[9].scripts.OnClick(nil,"MiddleButton") -- Empty cells do nothing.
P.db.ignored[item.id]=nil; P:Refresh(); assert(P.buttons[8].item.id==item.id)
COMBAT=true; P.buttons[8].scripts.PostClick(P.buttons[8],"MiddleButton",false)
assert(not P.db.ignored[item.id] and P.buttons[8].item.id==item.id)
COMBAT=false
assert(P.db.bindings[201].key=="ALT-H")
print("PASS middle-click hide, release-only dispatch, unlocked overlay, empty cells, Auto compaction, Manual slots, persistence and combat guard")
