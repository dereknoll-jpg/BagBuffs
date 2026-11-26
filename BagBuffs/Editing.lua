local _, P = ...

function P:SetManualOrder(items)
    local wanted,positions={},{}
    for _,item in ipairs(items) do wanted[item.id]=true end
    for slot,id in ipairs(self.db.slots) do if wanted[id] then positions[#positions+1]=slot end end
    for index,item in ipairs(items) do
        local slot=positions[index] or (#self.db.slots+1)
        self.db.slots[slot]=item.id
    end
    self:RememberManualSlots()
end

function P:MoveItemTo(id,targetID)
    if not self:CanChange() then return false end
    local items,from,to={}
    for i,item in ipairs(self.selected or {}) do
        items[i]=item
        if item.id==id then from=i end
        if item.id==targetID then to=i end
    end
    if not from or not to or from==to then return false end
    local item=table.remove(items,from); table.insert(items,to,item)
    self:SetManualOrder(items); self:Refresh(); return true
end

function P:MoveItem(id,delta)
    for i,item in ipairs(self.selected or {}) do
        if item.id==id then
            local target=self.selected[i+delta]
            if target then return self:MoveItemTo(id,target.id) end
            return false
        end
    end
    return false
end

function P:SetSortMode(mode)
    if mode=="manual" then self:SetAutoSort(false)
    elseif mode=="type" or mode=="name" then self:SortNow(mode) end
end

function P:EditorItems()
    local result,seen={},{}
    for _,item in ipairs(self.selected or {}) do result[#result+1]=item; seen[item.id]=true end
    for _,item in ipairs(self.items or {}) do if not seen[item.id] then result[#result+1]=item end end
    return result
end

function P:EndItemDrag()
    local id=self.dragItemID; self.dragItemID=nil
    local gridTarget=not InCombatLockdown() and self:GridDropSlot() or nil
    if id and gridTarget then self:MoveItemToSlot(id,gridTarget)
    elseif id and not InCombatLockdown() then
        for _,row in ipairs(self.itemRows or {}) do
            if row.item and MouseIsOver(row.frame) then self:MoveItemTo(id,row.item.id); break end
        end
    end
    if self.settings then self:SyncSettings() end
end

function P:BindingButtonName(id) return "BagBuffsUseItem"..id end

function P:BindingLabel(id)
    local binding=self.db.bindings[id]
    return type(binding)=="table" and type(binding.key)=="string" and binding.key or "Bind key"
end

function P:SyncItemBindings()
    if InCombatLockdown() then self.bindingsDirty=true; return end
    if not self.bindingsDirty then return end
    if not self.bindingOwner then self.bindingOwner=CreateFrame("Frame",nil,UIParent); self.itemBindingButtons={} end
    ClearOverrideBindings(self.bindingOwner)
    for id,binding in pairs(self.db.bindings) do
        if self:Number(id) and id>0 and id==math.floor(id) and type(binding)=="table" and type(binding.key)=="string" and binding.key~="" then
            local b=self.itemBindingButtons[id]
            if not b then
                b=CreateFrame("Button",self:BindingButtonName(id),self.bindingOwner,"SecureActionButtonTemplate")
                self.itemBindingButtons[id]=b; b:SetSize(1,1); b:SetPoint("TOPLEFT",UIParent,"TOPLEFT",0,0)
                b:EnableMouse(false); b:RegisterForClicks("AnyUp","AnyDown")
            end
            b:SetAttribute("type","item"); b:SetAttribute("item","item:"..id)
            if binding.weapon then b:SetAttribute("unit",nil) else b:SetAttribute("unit","player") end
            SetOverrideBindingClick(self.bindingOwner,true,binding.key,self:BindingButtonName(id),"LeftButton")
        end
    end
    self.bindingsDirty=false
end

function P:ApplyItemBinding(item,key)
    if not self:CanChange() then return false end
    if key then
        for id,binding in pairs(self.db.bindings) do
            if type(binding)=="table" and binding.key==key then self.db.bindings[id]=nil end
        end
        self.db.bindings[item.id]={key=key,weapon=item.category=="weapon"}
    else self.db.bindings[item.id]=nil end
    self.bindingsDirty=true; self:SyncItemBindings(); self:UpdateVisuals()
    if self.settings then self:SyncSettings() end
    return true
end

function P:CancelBinding()
    self.bindingItem=nil; self.bindingConflict=nil
    if self.bindingPrompt then self.bindingPrompt:Hide() end
end

function P:CaptureBinding(key)
    if not self.bindingItem then return end
    if InCombatLockdown() then self:CancelBinding(); return end
    if key=="ESCAPE" then self:CancelBinding(); return end
    if key=="LSHIFT" or key=="RSHIFT" or key=="LCTRL" or key=="RCTRL" or key=="LALT" or key=="RALT" or key=="UNKNOWN" then return end
    if key=="BUTTON1" or key=="BUTTON2" then return end
    if key=="BACKSPACE" or key=="DELETE" then self:ApplyItemBinding(self.bindingItem,nil); self:CancelBinding(); return end
    local chord=(IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")..key
    local action=self:Call(GetBindingAction,chord,true)
    local own="CLICK "..self:BindingButtonName(self.bindingItem.id)..":LeftButton"
    local conflict=self:Readable(action) and type(action)=="string" and action~="" and action~=own and action or nil
    -- Inspect our own saved map too (including when native binding inspection is unavailable).
    for id,binding in pairs(self.db.bindings) do
        if id~=self.bindingItem.id and type(binding)=="table" and binding.key==chord then conflict="another BagBuffs item" end
    end
    if conflict then
        self.bindingConflict=chord
        local label=_G["BINDING_NAME_"..conflict] or conflict
        self.bindingPrompt.message:SetText(chord.." is already used by "..label..".\nUse it for "..self.bindingItem.name.." while BagBuffs is active?")
        self.bindingPrompt.replace:Show()
    else self:ApplyItemBinding(self.bindingItem,chord); self:CancelBinding() end
end

function P:StartBinding(item)
    if not item or not self:CanChange() then return end
    if not self.bindingPrompt then
        local f=CreateFrame("Frame",nil,self.settings,"BackdropTemplate"); self.bindingPrompt=f
        f:SetSize(590,190); f:SetPoint("CENTER"); f:SetFrameLevel(self.settings:GetFrameLevel()+30)
        self:Backdrop(f); f:EnableMouse(true); f:EnableKeyboard(true); f:SetPropagateKeyboardInput(false)
        f.message=self:Label(f,"",13); f.message:SetPoint("TOPLEFT",18,-20); f.message:SetSize(554,68)
        self:Label(f,"Esc: cancel   /   Backspace or Delete: clear binding",11,.6,.65,.68):SetPoint("TOPLEFT",18,-102)
        local cancel=self:QuietButton(f,"Cancel",92,function() self:CancelBinding() end); cancel:SetPoint("BOTTOMRIGHT",-18,18)
        f.replace=self:QuietButton(f,"Use this key",120,function()
            if self.bindingItem and self.bindingConflict then self:ApplyItemBinding(self.bindingItem,self.bindingConflict) end
            self:CancelBinding()
        end); f.replace:SetPoint("BOTTOMRIGHT",-118,18)
        f:SetScript("OnKeyDown",function(_,key) self:CaptureBinding(key) end)
        f:SetScript("OnMouseDown",function(_,button)
            local keys={MiddleButton="BUTTON3",Button4="BUTTON4",Button5="BUTTON5"}
            if keys[button] then self:CaptureBinding(keys[button]) end
        end)
        f:EnableMouseWheel(true); f:SetScript("OnMouseWheel",function(_,delta) self:CaptureBinding(delta>0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
    end
    self.bindingItem=item; self.bindingConflict=nil
    self.bindingPrompt.message:SetText("Press a key for "..item.name..".\nModifiers, middle/side mouse buttons and wheel are supported.")
    self.bindingPrompt.replace:Hide(); self.bindingPrompt:Show()
end
