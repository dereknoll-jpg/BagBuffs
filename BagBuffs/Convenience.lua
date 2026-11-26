local _, P = ...

function P:TrackNewItems(items)
    local current={}
    self.pendingNew=self.pendingNew or {}; self.newUntil=self.newUntil or {}
    for _,item in ipairs(items) do
        current[item.id]=item.count
        if self.inventorySnapshot and item.count>0 and (self.inventorySnapshot[item.id] or 0)==0
            and self.db.highlightNew and not self.db.ignored[item.id] and self.db.enabled[item.category] then
            self.pendingNew[item.id]=true
        end
    end
    for id in pairs(self.pendingNew) do if not current[id] then self.pendingNew[id]=nil end end
    for id in pairs(self.newUntil) do if not current[id] then self.newUntil[id]=nil end end
    self.inventorySnapshot=current
end

function P:NewItemAlpha(id,now)
    if not self.db.highlightNew then return 0 end
    if self.pendingNew[id] then self.newUntil[id]=now+8; self.pendingNew[id]=nil end
    local ending=self.newUntil[id]
    if not ending or ending<=now then self.newUntil[id]=nil; return 0 end
    return .9*math.min(1,(ending-now)/2)
end

function P:ToggleNewHighlights()
    self.db.highlightNew=not self.db.highlightNew
    if not self.db.highlightNew then self.pendingNew={}; self.newUntil={} end
    self:UpdateVisuals()
    if self.settings then self:SyncSettings() end
end

function P:TogglePouchMenu()
    if not self.pouchMenu then
        local menu=CreateFrame("Frame","BagBuffsPouchMenu",UIParent,"BackdropTemplate"); self.pouchMenu=menu
        menu:SetSize(248,244); menu:SetFrameStrata("DIALOG"); menu:SetClampedToScreen(true); menu:EnableMouse(true); self:Backdrop(menu)
        table.insert(UISpecialFrames,"BagBuffsPouchMenu")
        self:Label(menu,"BAGBUFFS",13,.94,.78,.47):SetPoint("TOPLEFT",12,-12)
        local function command(title,row,callback)
            local b=self:QuietButton(menu,title,224,function() menu:Hide(); callback() end)
            b:SetPoint("TOPLEFT",12,-36-(row-1)*28); return b
        end
        command("Settings",1,function() self:ToggleSettings() end)
        menu.auto=command("",2,function() self:SetAutoSort(not self.db.autoSort) end)
        command("Sort by type  (Ctrl-left-click)",3,function() self:SortNow("type") end)
        command("Compact only - keep order",4,function() self:CompactLayout() end)
        menu.highlights=command("",5,function() self:ToggleNewHighlights() end)
        menu.lock=command("",6,function() self:ToggleMoveLock() end)
        command("Close",7,function() end)
        menu:Hide()
    end
    local menu=self.pouchMenu
    if menu:IsShown() then menu:Hide(); return end
    menu:ClearAllPoints(); menu:SetPoint("TOPRIGHT",self.launcher,"BOTTOMRIGHT",0,-5)
    menu.auto.label:SetText(self.db.autoSort and "Auto sort: ON - switch to Manual" or "Auto sort: OFF - switch to Auto")
    menu.highlights.label:SetText(self.db.highlightNew and "New-item highlight: ON" or "New-item highlight: OFF")
    menu.lock.label:SetText(self.db.locked and "Unlock grid  (Shift-right-click)" or "Lock grid  (Shift-right-click)")
    menu:Show()
end
