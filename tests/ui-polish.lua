local P=TEST_NS
COMBAT=false; P:CancelGridDrag(); P:CancelBinding(); P.dragItemID=nil; P.gridMoving=nil
BagBuffsDB={autoSort=false,slots={202,0,201},order={202,0,201},bindings={[201]={key="ALT-H"}},position={x=70,y=-80}}
P:InitializeDB(); BAGS[0]={{201,2},{202,2},{203,1}}; BAGS[1]={}; P:Refresh()
assert(P.db.appearance=="minimal" and not P.bagTrim:IsShown())
assert(not P.db.autoSort and P.db.slots[2]==0 and P.db.bindings[201].key=="ALT-H")
P:SetAppearance("trim"); assert(P.bagTrim:IsShown() and not P.bagTrim.mouseEnabled)
assert(P.db.position.x==70 and P.db.position.y==-80 and P.db.slots[3]==201)
assert(not P.bagTrim.parts.Top.horizTile and not P.bagTrim.parts.Left.vertTile)
P:InitializeDB(); P:Refresh(); assert(P.db.appearance=="trim" and not P.db.autoSort)
-- Every supported grid shape, including 1x8 / 8x1 and size/spacing extremes.
for i=1,64 do DEFS[3000+i]={name="Scroll of Testing "..i,subclass=4}; BAGS[0][i]={3000+i,1} end
P:SetAutoSort(true)
for columns=1,8 do for rows=1,8 do
    P.db.columns=columns; P.db.rows=rows
    P.db.size=({20,32,56})[(columns+rows)%3+1]
    P.db.gap=(columns+rows)%2==0 and 0 or 16
    P.db.scale=columns%2==0 and .5 or 2
    P:Refresh()
    assert(P.bagTrim.width==columns*(P.db.size+P.db.gap)-P.db.gap+40)
    assert(P.bagTrim.height==rows*(P.db.size+P.db.gap)-P.db.gap+40)
    assert(P.bagTrim.skin=="BagSkin"..columns.."x"..rows)
    for _,name in ipairs({"TL","TR","BL","BR","Top","Bottom","Left","Right"}) do
        local t=P.bagTrim.parts[name]
        assert(not t.horizTile and not t.vertTile and t.texture==P.media..P.bagTrim.skin)
        local uv=t.texCoords; assert(uv[1]>=0 and uv[2]<=1 and uv[1]<uv[2] and uv[3]>=0 and uv[4]<=1 and uv[3]<uv[4])
    end
    assert(P.bagTrim.parts.Top.width>0 and P.bagTrim.parts.Left.height>0)
    assert(P.bagTrim.parts.TL.width==28 and P.bagTrim.parts.TL.height==28)
    assert(P.buttons[1].attributes.type1=="item" and not P.buttons[1].attributes.type2)
end end
assert(P.launcher.width==24 and P.launcher.point[1]=="CENTER" and P.launcher.point[2]==P.bagTrim and P.launcher.point[3]=="BOTTOM")
assert(P.bagTrim.parts.Tab.alpha==1)
P.db.logo=false; P:Refresh(); assert(P.bagTrim.parts.Tab.alpha==0 and not P.launcher:IsShown())
P.db.logo=true; P:Refresh(); assert(P.bagTrim.parts.Tab.alpha==1 and P.launcher:IsShown())
P.db.columns=3; P.db.rows=3; P.db.size=32; P.db.gap=4; P.db.scale=1
BAGS[0]={{201,1},{202,1}}; P:Refresh()
assert(P.bagTrim.width==108 and P.bagTrim.height==72)
P:SetAutoSort(false); P.db.slots={0,0,0,0,0,0,0,201}; P.db.order=P:CopySlots(P.db.slots)
BAGS[0]={{201,1}}; P:Refresh()
assert(P.bagTrim.width==72 and P.bagTrim.height==72 and P.bagTrim.point[4]==16 and P.bagTrim.point[5]==-52)
assert(P.bagTrim.skin=="BagSkin1x1")
assert(P.buttons[8].item.id==201 and P.db.slots[1]==0)
BAGS[0]={}; P:Refresh(); assert(not P.bagTrim:IsShown())
P:SetAutoSort(true); BAGS[0]={{201,1},{202,1},{203,1}}; P:Refresh()
local first=P.buttons[1]; local id=first.item.id; local key=P.db.bindings[201].key
first.scripts.PostClick(first,"RightButton",true); assert(not P.itemMenu or not P.itemMenu:IsShown())
first.scripts.PostClick(first,"RightButton",false); assert(P.itemMenu:IsShown() and P.itemMenu.item.id==id)
P.itemMenu.commands.favorite.scripts.OnClick()
assert(P.db.favorites[id] and not P.itemMenu:IsShown() and P.db.bindings[201].key==key)
-- Binding directly from the menu needs neither an open nor constructed editor.
if P.settings:IsShown() then P:ToggleSettings() end
local panel=P.settings; P.settings=nil; P.bindingPrompt=nil
P:ToggleItemMenu(P.buttons[1].item,P.buttons[1]); local target=P.itemMenu.item.id
P.itemMenu.commands.bind.scripts.OnClick()
assert(P.bindingItem.id==target and P.bindingPrompt:IsShown() and P.bindingPrompt.parent==UIParent)
CTRL=true; P:CaptureBinding("J"); CTRL=false
assert(P.db.bindings[target].key=="CTRL-J" and not P.bindingPrompt:IsShown())
P.settings=panel
P:ToggleItemMenu(P.buttons[1].item,P.buttons[1]); local hidden=P.itemMenu.item.id
P.itemMenu.commands.hide.scripts.OnClick(); assert(P.db.ignored[hidden] and not P.itemMenu:IsShown())
P.db.ignored[hidden]=nil; P:Refresh()
if P.db.locked then P:ToggleMoveLock() end
P.gridEditButtons[1].scripts.OnClick(nil,"RightButton"); assert(P.itemMenu:IsShown())
P:Refresh(); assert(not P.itemMenu:IsShown()) -- Close stale targets after bag refreshes.
P:ToggleItemMenu(P.buttons[1].item,P.buttons[1]); HOVERED_FRAME=nil
P.events.scripts.OnEvent(nil,"GLOBAL_MOUSE_UP","LeftButton"); assert(not P.itemMenu:IsShown())
P:ToggleItemMenu(P.buttons[1].item,P.buttons[1]); P.itemMenu.commands.settings.scripts.OnClick()
assert(P.settings:IsShown() and P.settingsTab=="items")
P:SyncSettings(); assert(P.modeButtons.auto.selected and not P.modeButtons.manual.selected)
assert(P.appearanceButtons.trim.selected and not P.appearanceButtons.minimal.selected)
P:ToggleItemMenu(P.buttons[1].item,P.buttons[1]); COMBAT=true
P.events.scripts.OnEvent(nil,"PLAYER_REGEN_DISABLED"); assert(not P.itemMenu:IsShown())
local fixed=P.buttons[1].attributes.item1
P:SetAppearance("minimal"); P:ToggleItemMenu(P.buttons[1].item,P.buttons[1]); P:Refresh()
assert(P.db.appearance=="trim" and not P.itemMenu:IsShown() and P.buttons[1].attributes.item1==fixed)
COMBAT=false; RunStateDrivers(); P:Refresh(); P:SetAppearance("minimal")
assert(not P.bagTrim:IsShown() and P.appearanceButtons.minimal.selected)
assert(P.launcher.width==18 and P.launcher.point[1]=="BOTTOMRIGHT" and P.launcher.point[2]==P.frame)
print("PASS Minimal default, saved appearance, all 64 trim layouts, sparse/empty grids, fixed corners, non-repeating fitted skins, item menus, direct binding, selected controls and combat stability")
