local _, P = ...

function P:GridEditActive()
    return not InCombatLockdown() and not self.db.locked
end

function P:ToggleMoveLock()
    if not self:CanChange() then return end
    self.db.locked=not self.db.locked; self:Refresh()
end

function P:StartGridMove()
    if not self.db.locked and not InCombatLockdown() then self.gridMoving=true; self.frame:StartMoving() end
end

function P:StopGridMove()
    if InCombatLockdown() then return end
    self.frame:StopMovingOrSizing()
    self.gridMoving=nil
    local x,y=self.frame:GetCenter(); local px,py=UIParent:GetCenter()
    if self:Number(x) and self:Number(y) and self:Number(px) and self:Number(py) then
        local scale=self.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        self.db.position={x=x*scale-px,y=y*scale-py}
    end
end

function P:CreateGridEditor()
    -- A separate hit layer intercepts editing drags without modifying item actions.
    -- Blizzard's visibility driver hides it during combat, before a combat click.
    local root=CreateFrame("Frame","BagBuffsGridEditor",UIParent,"SecureHandlerStateTemplate")
    self.gridEditor=root; self.gridEditButtons={}
    root:SetAllPoints(self.frame); root:SetFrameStrata("MEDIUM"); root:SetFrameLevel(self.frame:GetFrameLevel()+10)
    for i,button in ipairs(self.buttons) do
        local overlay=CreateFrame("Button",nil,root)
        self.gridEditButtons[i]=overlay; overlay:SetAllPoints(button); overlay:RegisterForDrag("LeftButton")
        overlay:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp")
        overlay.rim=overlay:CreateTexture(nil,"OVERLAY"); overlay.rim:SetAllPoints(); overlay.rim:SetTexture(self.media.."IconRim")
        overlay.rim:SetVertexColor(.94,.78,.47,.65)
        overlay:SetScript("OnDragStart",function() if button.item then self:StartGridItemDrag(button.item) end end)
        overlay:SetScript("OnDragStop",function() self:EndGridItemDrag() end)
        overlay:SetScript("OnMouseUp",function(_,button) if button=="LeftButton" then self:EndGridItemDrag() end end)
        overlay:SetScript("OnReceiveDrag",function() self:EndGridItemDrag() end)
        overlay:SetScript("OnClick",function(_,mouseButton)
            if mouseButton=="MiddleButton" then self:HideGridItem(button.item)
            elseif mouseButton=="RightButton" then
                if IsShiftKeyDown() then self:ToggleMoveLock()
                elseif button.item then self:ToggleItemMenu(button.item,overlay)
                else self:ToggleSettings() end
            end
        end)
        overlay:SetScript("OnEnter",function(b)
            GameTooltip:SetOwner(b,"ANCHOR_TOP"); GameTooltip:SetText(button.item and button.item.name or "Empty grid slot",.94,.78,.47)
            GameTooltip:AddLine("Drag to a grid slot. Occupied slots swap; empty slots stay where you leave them.\nShift-right-click the pouch to lock or unlock.\nLock the grid to click-use items.",.8,.8,.8,true)
            if button.item then GameTooltip:AddLine("Right-click: item menu. Middle-click: hide item. Restore in Items & Keys.",.8,.8,.8,true) end
            GameTooltip:Show()
        end)
        overlay:SetScript("OnLeave",function() GameTooltip:Hide() end)
        overlay:EnableMouseWheel(true); overlay:SetScript("OnMouseWheel",function(_,delta) self:ChangePage(delta>0 and -1 or 1) end)
    end
    local ghost=CreateFrame("Frame",nil,UIParent); self.gridDragGhost=ghost
    ghost:SetSize(32,32); ghost:SetFrameStrata("TOOLTIP"); ghost:EnableMouse(false)
    ghost.art=ghost:CreateTexture(nil,"ARTWORK"); ghost.art:SetAllPoints(); ghost.art:SetTexCoord(.08,.92,.08,.92); ghost:SetAlpha(.85)
    ghost:SetScript("OnUpdate",function(f)
        if InCombatLockdown() or not self.gridDragItemID then self:CancelGridDrag(); return end
        -- A custom visual drag does not always receive native OnDragStop.
        -- Poll the physical button as well, so it can never stick to the cursor.
        if self:Call(IsMouseButtonDown,"LeftButton")==false then self:EndGridItemDrag(); return end
        local x,y=GetCursorPosition(); local scale=UIParent:GetEffectiveScale()
        f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x/scale+12,y/scale-20)
    end)
    ghost:Hide()
    self:SyncGridEditing()
end

function P:SyncGridEditing()
    if not self.gridEditor or InCombatLockdown() then return end
    local active=self:GridEditActive()
    for i,overlay in ipairs(self.gridEditButtons) do
        overlay:SetShown(i<=self.db.columns*self.db.rows)
        overlay.rim:SetVertexColor(.94,.78,.47,self.buttons[i].item and .65 or .18)
    end
    local driver=active and "[combat] hide; show" or "hide"
    if self.gridEditDriver~=driver then
        RegisterStateDriver(self.gridEditor,"visibility",driver); self.gridEditDriver=driver
    end
    if not active then self:CancelGridDrag() end
end

function P:StartGridItemDrag(item)
    if not item or not self:GridEditActive() then return end
    self.gridDragItemID=item.id; self.gridDragGhost.art:SetTexture(item.icon)
    self.gridDragGhost:SetSize(self.db.size,self.db.size); self.gridDragGhost:Show()
    GameTooltip:Hide()
end

function P:GridDropSlot()
    if InCombatLockdown() then return end
    if not self.gridEditor or not self.gridEditor:IsShown() then return end
    local left,top=self.frame:GetLeft(),self.frame:GetTop()
    local x,y=GetCursorPosition(); local scale=self.frame:GetEffectiveScale()
    if self:Number(left) and self:Number(top) and self:Number(x) and self:Number(y) and self:Number(scale) and scale>0 then
        local dx,dy=x/scale-left,top-y/scale
        local d=self.db; local stride=d.size+d.gap
        local width,height=d.columns*stride-d.gap,d.rows*stride-d.gap
        if dx<0 or dy<0 or dx>=width or dy>=height then return end
        return (self.page-1)*d.columns*d.rows+math.floor(dy/stride)*d.columns+math.floor(dx/stride)+1
    end
    -- Fallback for clients that cannot yet provide usable frame coordinates.
    for i,overlay in ipairs(self.gridEditButtons) do
        local item=self.buttons[i].item
        if item and overlay:IsShown() and MouseIsOver(overlay) then return (self.page-1)*self.db.columns*self.db.rows+i end
    end
end

function P:GridDropTarget()
    local slot=self:GridDropSlot()
    return slot and self.slotItems[slot] and self.slotItems[slot].id or nil
end

function P:CancelGridDrag()
    self.gridDragItemID=nil
    if self.gridDragGhost then self.gridDragGhost:Hide() end
end

function P:EndGridItemDrag()
    local id=self.gridDragItemID
    if not id then return end
    local slot=self:GridDropSlot()
    local target
    if not slot and not InCombatLockdown() and self.settings and self.settings:IsShown() then
        for _,row in ipairs(self.itemRows or {}) do if row.item and MouseIsOver(row.frame) then target=row.item.id; break end end
    end
    self:CancelGridDrag()
    if slot then self:MoveItemToSlot(id,slot) elseif target then self:MoveItemTo(id,target) end
end
