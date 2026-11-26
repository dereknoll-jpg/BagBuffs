local P=TEST_NS
COMBAT=false; RunStateDrivers(); BagBuffsDB={}; P:InitializeDB()
BAGS[0]={{101,2},{102,2},{103,5},{104,1}}; BAGS[1]={}; P:Refresh()
if P.settings:IsShown() then P:ToggleSettings() end
assert(P.db.locked and not P.gridEditor:IsShown())
-- Opening the editor creates a non-consuming drag surface on the live grid.
P:ToggleSettings(); assert(not P.gridEditor:IsShown())
P:ToggleMoveLock(); assert(P.gridEditor:IsShown())
local first=P.buttons[1].item.id; local target=P.buttons[3].item.id
P.gridEditButtons[1].scripts.OnDragStart(); assert(P.gridDragItemID==first and P.gridDragGhost:IsShown())
P.gridDragGhost.scripts.OnUpdate(P.gridDragGhost)
HOVERED_FRAME=P.gridEditButtons[3]; P.gridEditButtons[1].scripts.OnDragStop()
assert(P.selected[3].id==first and not P.gridDragGhost:IsShown() and P.db.sortMode=="manual")
assert(P.buttons[1].attributes.type1=="item" and not P.gridEditButtons[1].attributes.type)
-- Dropping off-grid cancels without reordering or moving a bag object.
first=P.selected[1].id; P.gridEditButtons[1].scripts.OnDragStart(); HOVERED_FRAME=nil
P.gridEditButtons[1].scripts.OnDragStop(); assert(P.selected[1].id==first and not P.gridDragItemID)
-- Closing the editor restores ordinary item clicks when locked.
P:ToggleSettings(); P:ToggleMoveLock(); assert(not P.gridEditor:IsShown())
-- Shift-right-click the pouch unlocks editing without reopening settings.
SHIFT=true; P.launcher.scripts.OnClick(nil,"RightButton"); SHIFT=false
assert(not P.db.locked and P.gridEditor:IsShown() and not P.settings:IsShown())
first=P.buttons[1].item.id; HOVERED_FRAME=P.gridEditButtons[2]
P.gridEditButtons[1].scripts.OnDragStart(); P.gridEditButtons[1].scripts.OnDragStop()
assert(P.selected[2].id==first)
P.launcher.scripts.OnDragStart(); P.launcher.scripts.OnDragStop(); assert(type(P.db.position)=="table")
-- The native combat driver hides the hit layer without insecure mutations.
local assigned=P.buttons[1].attributes.item1
P.gridEditButtons[1].scripts.OnDragStart()
COMBAT=true; RunStateDrivers(); P.events.scripts.OnEvent(nil,"PLAYER_REGEN_DISABLED")
assert(not P.gridEditor:IsShown() and not P.gridDragGhost:IsShown())
assert(P.buttons[1].attributes.type1=="item" and P.buttons[1].attributes.item1==assigned)
P.gridEditButtons[1].scripts.OnDragStart(); assert(not P.gridDragItemID)
SHIFT=true; P.launcher.scripts.OnClick(nil,"RightButton"); SHIFT=false; assert(not P.db.locked)
COMBAT=false; RunStateDrivers(); P.events.scripts.OnEvent(nil,"PLAYER_REGEN_ENABLED"); P.events.scripts.OnUpdate(nil,.3)
assert(P.gridEditor:IsShown())
SHIFT=true; P.launcher.scripts.OnClick(nil,"RightButton"); SHIFT=false
assert(P.db.locked and not P.gridEditor:IsShown())
-- A narrow vertical layout keeps the pouch accessible when unlocked.
SlashCmdList.BAGBUFFS("layout 1x8"); P:ToggleMoveLock()
assert(P.launcher:IsShown() and not P.anchor:IsShown())
P:ToggleMoveLock(); SlashCmdList.BAGBUFFS("layout 3x3")
-- Cross-surface dragging: editor row onto live grid and back.
P:ToggleSettings(); P:ToggleMoveLock(); P:SelectSettingsTab("items"); P.listPage=1; P:SyncSettings()
local row=P.itemRows[1]; first=row.item.id
row.icon.scripts.OnDragStart(); HOVERED_FRAME=P.gridEditButtons[3]; row.icon.scripts.OnDragStop()
assert(P.selected[3].id==first)
first=P.buttons[1].item.id; P.gridEditButtons[1].scripts.OnDragStart(); HOVERED_FRAME=P.itemRows[4].frame
P.gridEditButtons[1].scripts.OnDragStop(); assert(P.selected[4].id==first)
P:ToggleSettings()
print("PASS direct grid dragging, canceled drops, icon lock toggle, narrow-layout icon access, native combat visibility and editor/grid cross-dragging")
